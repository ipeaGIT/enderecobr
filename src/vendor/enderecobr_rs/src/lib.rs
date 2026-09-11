#![doc = include_str!("../README.md")]

use std::borrow::Cow;
use unicode_normalization::UnicodeNormalization;

use itertools::Itertools;
use regex::{Regex, RegexSet};

pub mod bairro;
pub mod cep;
pub mod complemento;
pub mod dado_faltante;
pub mod estado;
pub mod logradouro;
pub mod metaphone;
pub mod municipio;
pub mod numero;
pub mod numero_extenso;
pub mod separador_endereco;
pub mod tipo_logradouro;

/// Representa um endereço separado em seus atributos constituintes.
#[derive(Debug, PartialEq, Default)]
pub struct Endereco {
    pub logradouro: Option<String>,
    pub numero: Option<String>,
    pub complemento: Option<String>,
    pub localidade: Option<String>,
}

impl Endereco {
    /// Obtém o logradouro padronizado, utilizando a função [padronizar_logradouros].
    pub fn logradouro_padronizado(&self) -> Option<String> {
        self.logradouro
            .as_ref()
            .map(|x| padronizar_logradouros(x.as_str()))
    }

    /// Obtém o número padronizado, utilizando a função [padronizar_numeros].
    pub fn numero_padronizado(&self) -> Option<String> {
        self.numero.as_ref().map(|x| padronizar_numeros(x.as_str()))
    }

    /// Obtém o complemento padronizado, utilizando a função [padronizar_complementos].
    pub fn complemento_padronizado(&self) -> Option<String> {
        self.complemento
            .as_ref()
            .map(|x| padronizar_complementos(x.as_str()))
    }

    /// Obtém a localidade padronizada, utilizando a função [padronizar_bairros].
    pub fn localidade_padronizada(&self) -> Option<String> {
        self.localidade
            .as_ref()
            .map(|x| padronizar_bairros(x.as_str()))
    }

    /// Obtém uma nova struct [Endereco] com todos os campos padronizados,
    /// utilizando os métodos anteriores.
    pub fn endereco_padronizado(&self) -> Endereco {
        Endereco {
            logradouro: self.logradouro_padronizado(),
            numero: self.numero_padronizado(),
            complemento: self.complemento_padronizado(),
            localidade: self.localidade_padronizada(),
        }
    }

    /// Obtém uma representação textual dos atributos desta struct,
    /// separados por vírgula, caso existam.
    pub fn formatar(&self) -> String {
        [
            &self.logradouro,
            &self.numero,
            &self.complemento,
            &self.localidade,
        ]
        .iter()
        .filter_map(|opt| opt.as_deref())
        .map(|x| x.trim())
        .join(", ")
    }
}

/// Representa um par de "regexp replace". Usado internamente no [Padronizador].
#[derive(Debug)]
pub struct ParSubstituicao {
    regexp: Regex,
    substituicao: String,
    regexp_ignorar: Option<Regex>,
}

impl ParSubstituicao {
    fn new(regex: &str, substituicao: &str, regex_ignorar: Option<&str>) -> Self {
        ParSubstituicao {
            regexp: Regex::new(regex).expect("Expressão regular inválida"),
            substituicao: substituicao.to_uppercase().to_string(),
            regexp_ignorar: regex_ignorar
                .map(|r| Regex::new(r).expect("Expressão regular para `regexp_ignorar` inválida")),
        }
    }
}

/// Estrutura responsável por padronizar textos de endereços com base em regras de substituição
/// regulares condicionais.
///
/// O `Padronizador` permite definir regras de substituição com expressões regulares, incluindo
/// condições de exclusão (`regexp_ignorar`). Ele otimiza o processamento usando um [`RegexSet`]
/// para identificar rapidamente quais regras se aplicam a cada estágio da padronização.
#[derive(Default)]
pub struct Padronizador {
    substituicoes: Vec<ParSubstituicao>,
    grupo_regex: RegexSet,
}

impl Padronizador {
    /// Adiciona múltiplas regras de substituição a partir de uma lista de triplas.
    ///
    /// Cada entrada é um slice de até três elementos: `[regex, substituição, ignorar]`.
    /// Valores ausentes (`None`) são descartados e as triplas serão interpretados da seguinte forma:
    /// - Se existir um elemento não nulo: equivalente a `[regex, '']`;
    /// - Se existirem dois elementos não nulos: equivalente a `[regex, substituição]`;
    /// - Se existirem três ou mais elementos não nulos: equivalente a `[regex, substituição,
    /// ignorar]`;
    ///
    /// O método [`preparar`](Self::preparar) é chamado automaticamente no término da execução.
    ///
    /// Este método é projetado para interoperabilidade com linguagens dinâmicas (ex: Python),
    /// onde estruturas heterogêneas são comuns.
    pub fn adicionar_pares(&mut self, pares: &[&[Option<&str>]]) {
        for p in pares {
            let mut valores = p.iter().filter_map(|i| *i);
            match (valores.next(), valores.next(), valores.next()) {
                (None, _, _) => (),
                (Some(a), None, _) => {
                    self.adicionar(a, "");
                }
                (Some(a), Some(b), None) => {
                    self.adicionar(a, b);
                }
                (Some(a), Some(b), Some(c)) => {
                    self.adicionar_com_ignorar(a, b, c);
                }
            }
        }
        self.preparar();
    }

    /// Adiciona regras de substituição a partir de três vetores paralelos: regexes, substituições
    /// e regexes de exclusão opcional.
    ///
    /// O método [`preparar`](Self::preparar) é chamado automaticamente no término da execução.
    ///
    /// Todos os vetores devem ter o mesmo comprimento. O terceiro vetor pode conter `None`
    /// para indicar ausência de condição de exclusão.
    ///
    /// Este formato facilita a integração com R, onde dados tabulares são naturais.
    ///
    /// # Panics
    ///
    /// Panic se os vetores não tiverem o mesmo tamanho.
    pub fn adicionar_vetores(
        &mut self,
        regexes: &[&str],
        substituicao: &[&str],
        regex_ignorar: &[Option<&str>],
    ) {
        assert!(
            regexes.len() == substituicao.len() && regexes.len() == regex_ignorar.len(),
            "O tamanho dos três vetores devem ser iguais."
        );

        for ((r, s), i) in regexes.iter().zip(substituicao).zip(regex_ignorar) {
            if let Some(regex_ignorar) = i {
                self.adicionar_com_ignorar(r, s, regex_ignorar);
            } else {
                self.adicionar(r, s);
            }
        }
        self.preparar();
    }

    /// Adiciona uma regra simples de substituição: toda ocorrência de `regex` será substituída
    /// por `substituicao`.
    ///
    /// A expressão regular é compilada imediatamente. Use [`preparar`](Self::preparar) após
    /// adicionar as regras para o correto funcionamento da padronização.
    ///
    /// Retorna uma referência mutável para encadeamento (builder pattern).
    pub fn adicionar(&mut self, regex: &str, substituicao: &str) -> &mut Self {
        self.substituicoes
            .push(ParSubstituicao::new(regex, substituicao, None));
        self
    }

    /// Adiciona uma regra condicional de substituição: `regex` será substituído por `substituicao`
    /// apenas se `regexp_ignorar` **não** corresponder ao texto.
    ///
    /// Ambas as expressões regulares são compiladas imediatamente.
    ///
    /// Útil para evitar substituições em contextos indesejados (ex: não converter "R" em "RUA"
    /// dentro de "APT R 10").
    ///
    /// Use [`preparar`](Self::preparar) após adicionar as regras para o correto funcionamento da padronização.
    ///
    /// Retorna uma referência mutável para encadeamento (padrão builder).
    pub fn adicionar_com_ignorar(
        &mut self,
        regex: &str,
        substituicao: &str,
        regexp_ignorar: &str,
    ) -> &mut Self {
        self.substituicoes.push(ParSubstituicao::new(
            regex,
            substituicao,
            Some(regexp_ignorar),
        ));
        self
    }

    /// Compila o conjunto de expressões regulares principais em um [`RegexSet`] para acelerar
    /// a detecção de matches durante a padronização. Essencial para o correto funcionamento
    /// da função de padronização.
    ///
    /// Deve ser chamado após adicionar, antes de usar [`padronizar`](Self::padronizar).
    pub fn preparar(&mut self) {
        let regexes: Vec<&str> = self
            .substituicoes
            .iter()
            .map(|par| par.regexp.as_str())
            .collect();

        // Não deveria acontecer: O erro já deveria ocorrer na construção do objeto.
        self.grupo_regex = RegexSet::new(regexes).expect("Regex inválida: Erro interno");
    }

    /// Aplica todas as regras de substituição ao texto de entrada até que nenhuma nova
    /// substituição seja possível.
    ///
    /// O texto é primeiro normalizado (remoção de acentos, conversão para maiúsculas e
    /// remoção de espaços extras). As regras são aplicadas em ordem, mas apenas
    /// se a condição de exclusão (se presente) não for satisfeita.
    ///
    /// Retorna uma nova `String` com o texto padronizado.
    pub fn padronizar(&self, valor: &str) -> String {
        self.padronizar_cow(valor).to_string()
    }

    // Função otimizada para não re-alocar strings quando desnecessário.
    // TODO: Adaptar demais métodos para aceitar e retornar Cow<str>
    fn padronizar_cow<'a>(&self, valor: &'a str) -> Cow<'a, str> {
        let mut preproc = normalizar(valor);
        let mut ultimo_idx: Option<usize> = None;

        while self.grupo_regex.is_match(&preproc) {
            let idx_substituicao = self
                .grupo_regex
                .matches(&preproc)
                .iter()
                .find(|idx| ultimo_idx.map_or(true, |ultimo| *idx > ultimo));

            let Some(idx) = idx_substituicao else {
                break;
            };

            ultimo_idx = idx_substituicao;
            let Some(par) = self.substituicoes.get(idx) else {
                break; // Não deveria acontecer.
            };

            // FIXME: essa solução dá problema quando eu tenho mais de um match da regexp
            // original. Precisaria de uma heurística melhor.
            if par
                .regexp_ignorar
                .as_ref()
                .map(|r| r.is_match(&preproc))
                .unwrap_or(false)
            {
                continue;
            }

            let novo_valor = par.regexp.replace_all(&preproc, par.substituicao.as_str());
            // Se chegou aqui, é porque a string deveria sofrer modificação e, consequentemente,
            // retornar um Cow::Owned.
            preproc = match novo_valor {
                Cow::Owned(novo) => Cow::Owned(novo),
                Cow::Borrowed(_) => preproc, // Não deveria acontecer
            };
        }

        preproc
    }

    /// Retorna todas as regras atuais como um vetor de triplas.
    ///
    /// Cada tripla contém: `(regex, substituicao, regex_ignorar)`.
    ///
    /// Útil para inspeção ou incremento dos padrões.
    ///
    pub fn obter_pares(&self) -> Vec<(&str, &str, Option<&str>)> {
        self.substituicoes
            .iter()
            .map(|par| {
                (
                    par.regexp.as_str(),
                    par.substituicao.as_str(),
                    par.regexp_ignorar.as_ref().map(Regex::as_str),
                )
            })
            .collect()
    }

    /// Retorna as regras como três vetores paralelos: regexes, substituições e regexes de exclusão.
    ///
    /// Ideal para uso em R, onde estruturas vetoriais são preferidas.
    ///
    /// Retorna uma tupla de vetores `(regex, substituicao, ignorar)`, onde `ignorar` é um vetor de `Option<&str>`.
    pub fn obter_vetores(&self) -> (Vec<&str>, Vec<&str>, Vec<Option<&str>>) {
        let regex = self
            .substituicoes
            .iter()
            .map(|par| par.regexp.as_str())
            .collect();
        let subst = self
            .substituicoes
            .iter()
            .map(|par| par.substituicao.as_str())
            .collect();
        let ignorar = self
            .substituicoes
            .iter()
            .map(|par| par.regexp_ignorar.as_ref().map(Regex::as_str))
            .collect();
        (regex, subst, ignorar)
    }
}

/// Função utilitária usada internamente para normalizar uma string para processamento posterior,
/// removendo seus diacríticos e caracteres especiais.
///
/// # Exemplo
/// ```
/// use enderecobr_rs::normalizar;
/// assert_eq!(normalizar("Olá, mundo"), "OLA, MUNDO");
/// assert_eq!(normalizar("R. DO AÇAÍ 15º"), "R. DO ACAI 15O");
/// ```
///
pub fn normalizar(valor: &str) -> Cow<'_, str> {
    let valor = valor.trim();

    if valor.is_ascii() {
        if valor
            .bytes()
            .all(|c| !c.is_ascii_alphabetic() || c.is_ascii_uppercase())
        {
            return Cow::Borrowed(valor.trim());
        }
        return Cow::Owned(valor.trim().to_ascii_uppercase());
    }

    valor
        .nfkd()
        .filter(|c| c.is_ascii())
        .map(|c| c.to_ascii_uppercase())
        .collect()
}

/// Wrapper fino sobre o RegexSet para permitir localizar padrões rapidamente.
#[derive(Default)]
pub struct IdentificadorPadroes {
    padroes: Vec<String>,
    regex_set: RegexSet,
}

impl IdentificadorPadroes {
    pub fn adicionar(&mut self, regexs: &[String]) -> &mut Self {
        self.padroes.extend(regexs.iter().map(|x| x.to_owned()));
        self.regex_set =
            RegexSet::new(self.padroes.iter()).expect("RegexSet inválida: erro de compilação.");
        self
    }

    pub fn identificar(&self, valor: &str) -> bool {
        self.regex_set.is_match(valor)
    }
}

pub use bairro::padronizar_bairros;
pub use cep::padronizar_cep;
pub use cep::padronizar_cep_leniente;
pub use cep::padronizar_cep_numerico;
pub use complemento::padronizar_complementos;
pub use dado_faltante::is_dado_faltante;
pub use estado::padronizar_estados_para_codigo;
pub use estado::padronizar_estados_para_nome;
pub use estado::padronizar_estados_para_sigla;
pub use logradouro::padronizar_logradouros;
pub use municipio::padronizar_municipios;
pub use numero::padronizar_numeros;
pub use numero::padronizar_numeros_para_int;
pub use numero::padronizar_numeros_para_string;
pub use tipo_logradouro::padronizar_tipo_logradouro;

#[cfg(feature = "experimental")]
pub use separador_endereco::padronizar_endereco_bruto;

#[cfg(feature = "experimental")]
pub use separador_endereco::separar_endereco;

/// Função utilitária utilizada nas ferramentas de CLI para selecionar um padronizador facilmente
/// via uma string descritiva.
pub fn obter_padronizador_por_tipo(tipo: &str) -> Result<fn(&str) -> String, &str> {
    match tipo {
        "logradouro" | "logr" => Ok(padronizar_logradouros),
        "tipo_logradouro" | "tipo_logr" => Ok(padronizar_tipo_logradouro),
        "numero" | "num" => Ok(padronizar_numeros),
        "bairro" => Ok(padronizar_bairros),
        "complemento" | "comp" => Ok(padronizar_complementos),
        "estado" => Ok(|x| padronizar_estados_para_sigla(x).to_string()),
        "estado_nome" => Ok(|x| padronizar_estados_para_nome(x).to_string()),
        "estado_codigo" => Ok(|x| padronizar_estados_para_codigo(x).to_string()),
        "municipio" | "mun" => Ok(padronizar_municipios),
        "cep" => Ok(|cep| padronizar_cep(cep).unwrap_or_else(|_| String::new())),
        "cep_leniente" => Ok(padronizar_cep_leniente),
        "metaphone" => Ok(metaphone::metaphone),
        "dado_faltante" => Ok(|x| is_dado_faltante(x).to_string()),

        #[cfg(feature = "experimental")]
        "completo" => Ok(padronizar_endereco_bruto),

        #[cfg(feature = "experimental")]
        "separar" => Ok(|val| format!("{:?}", separar_endereco(val))),

        #[cfg(feature = "experimental")]
        "separar_padronizar" => {
            Ok(|val| format!("{:?}", separar_endereco(val).endereco_padronizado()))
        }

        _ => Err("Nenhum padronizador encontrado"),
    }
}

/////////////////

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_obter_pares_e_vetores_vazios() {
        let pad = Padronizador::default();
        assert_eq!(pad.obter_pares(), vec![]);
        assert_eq!(pad.obter_vetores(), (vec![], vec![], vec![]));
    }

    #[test]
    fn test_adicionar_pares() {
        let mut pad = Padronizador::default();
        pad.adicionar_pares(&[
            &[Some("R"), Some("RUA")],                         // par (regex, subst)
            &[Some("AV"), Some("AVENIDA"), Some("COMERCIAL")], // tripla com ignorar
            &[Some("ESC"), None, Some("ESCOLA")],              // ignora None
            &[None],                                           // ignora totalmente
        ]);

        let pares = pad.obter_pares();
        assert_eq!(
            pares,
            vec![
                ("R", "RUA", None),
                ("AV", "AVENIDA", Some("COMERCIAL")),
                ("ESC", "ESCOLA", None),
            ]
        );

        let (regex, subst, ignorar) = pad.obter_vetores();
        assert_eq!(regex, vec!["R", "AV", "ESC"]);
        assert_eq!(subst, vec!["RUA", "AVENIDA", "ESCOLA"]);
        assert_eq!(ignorar, vec![None, Some("COMERCIAL"), None]);
    }

    #[test]
    fn test_adicionar_vetores() {
        let mut pad = Padronizador::default();
        pad.adicionar_vetores(
            &["NUM", "R", "AV"],
            &["NUMERO", "RUA", "AVENIDA"],
            &[None, Some("R$"), Some("AVENIDA COMERCIAL")],
        );

        let pares = pad.obter_pares();
        assert_eq!(
            pares,
            vec![
                ("NUM", "NUMERO", None),
                ("R", "RUA", Some("R$")),
                ("AV", "AVENIDA", Some("AVENIDA COMERCIAL")),
            ]
        );

        let (regex, subst, ignorar) = pad.obter_vetores();
        assert_eq!(regex, vec!["NUM", "R", "AV"]);
        assert_eq!(subst, vec!["NUMERO", "RUA", "AVENIDA"]);
        assert_eq!(ignorar, vec![None, Some("R$"), Some("AVENIDA COMERCIAL")]);
    }

    #[test]
    #[should_panic(expected = "O tamanho dos três vetores devem ser iguais.")]
    fn test_adicionar_vetores_tamanho_diferente() {
        let mut pad = Padronizador::default();
        pad.adicionar_vetores(&["a"], &["b"], &[Some("x"), Some("y")]);
    }

    #[test]
    fn test_adicionar_pares_somente_regex() {
        // Arm `(Some(a), None, _)`: apenas regex, substituição vazia.
        let mut pad = Padronizador::default();
        pad.adicionar_pares(&[&[Some("X")], &[Some("Y"), None]]);

        assert_eq!(pad.obter_pares(), vec![("X", "", None), ("Y", "", None)]);
    }

    #[test]
    fn test_endereco_campos_padronizados() {
        let endereco = Endereco {
            logradouro: Some("r. gen.. glicério".to_string()),
            numero: Some("001".to_string()),
            complemento: Some("apto. 405".to_string()),
            localidade: Some("jd botânico".to_string()),
        };

        assert_eq!(
            endereco.logradouro_padronizado(),
            Some("RUA GENERAL GLICERIO".to_string())
        );
        assert_eq!(endereco.numero_padronizado(), Some("1".to_string()));
        assert_eq!(
            endereco.complemento_padronizado(),
            Some("APARTAMENTO 405".to_string())
        );
        assert_eq!(
            endereco.localidade_padronizada(),
            Some("JARDIM BOTANICO".to_string())
        );
    }

    #[test]
    fn test_endereco_padronizado_completo() {
        let endereco = Endereco {
            logradouro: Some("r. do aço".to_string()),
            numero: Some("210".to_string()),
            complemento: Some("qd 5".to_string()),
            localidade: Some("prq ind".to_string()),
        };

        let esperado = Endereco {
            logradouro: Some("RUA DO ACO".to_string()),
            numero: Some("210".to_string()),
            complemento: Some("QUADRA 5".to_string()),
            localidade: Some("PARQUE INDUSTRIAL".to_string()),
        };
        assert_eq!(endereco.endereco_padronizado(), esperado);
    }

    #[test]
    fn test_endereco_padronizado_campos_none() {
        // Campos `None` permanecem `None` após padronização.
        let endereco = Endereco::default();
        assert_eq!(endereco.endereco_padronizado(), Endereco::default());

        let endereco_parcial = Endereco {
            logradouro: Some("r. x".to_string()),
            ..Default::default()
        };
        let esperado = Endereco {
            logradouro: Some("RUA X".to_string()),
            ..Default::default()
        };
        assert_eq!(endereco_parcial.endereco_padronizado(), esperado);
    }

    #[test]
    fn test_endereco_formatar() {
        // Campos None são omitidos; campos com texto são retrimados.
        let endereco = Endereco {
            logradouro: Some("  RUA A  ".to_string()),
            numero: Some("123".to_string()),
            complemento: None,
            localidade: Some("CENTRO".to_string()),
        };
        assert_eq!(endereco.formatar(), "RUA A, 123, CENTRO");
    }

    #[test]
    fn test_endereco_formatar_vazio() {
        assert_eq!(Endereco::default().formatar(), "");
    }

    #[test]
    fn test_obter_padronizador_por_tipo() {
        // Logradouro
        assert_eq!(
            obter_padronizador_por_tipo("logradouro").unwrap()("r. gen"),
            "RUA GENERAL"
        );
        assert_eq!(
            obter_padronizador_por_tipo("logr").unwrap()("r. gen"),
            "RUA GENERAL"
        );

        // Tipo de logradouro
        assert_eq!(
            obter_padronizador_por_tipo("tipo_logradouro").unwrap()("R"),
            "RUA"
        );
        assert_eq!(
            obter_padronizador_por_tipo("tipo_logr").unwrap()("AVE"),
            "AVENIDA"
        );

        // Número
        assert_eq!(obter_padronizador_por_tipo("numero").unwrap()("001"), "1");
        assert_eq!(obter_padronizador_por_tipo("num").unwrap()("001"), "1");

        // Bairro
        assert_eq!(
            obter_padronizador_por_tipo("bairro").unwrap()("prq ind"),
            "PARQUE INDUSTRIAL"
        );

        // Complemento
        assert_eq!(
            obter_padronizador_por_tipo("complemento").unwrap()("apto 405"),
            "APARTAMENTO 405"
        );
        assert_eq!(
            obter_padronizador_por_tipo("comp").unwrap()("apto 405"),
            "APARTAMENTO 405"
        );

        // Estado (sigla, nome, código)
        assert_eq!(obter_padronizador_por_tipo("estado").unwrap()("21"), "MA");
        assert_eq!(
            obter_padronizador_por_tipo("estado_nome").unwrap()("21"),
            "MARANHAO"
        );
        assert_eq!(
            obter_padronizador_por_tipo("estado_codigo").unwrap()("MA"),
            "21"
        );

        // Município
        assert_eq!(
            obter_padronizador_por_tipo("municipio").unwrap()("3304557"),
            "RIO DE JANEIRO"
        );
        assert_eq!(
            obter_padronizador_por_tipo("mun").unwrap()("3304557"),
            "RIO DE JANEIRO"
        );

        // CEP
        assert_eq!(
            obter_padronizador_por_tipo("cep").unwrap()("12345-6"),
            "00123-456"
        );
        assert_eq!(
            obter_padronizador_por_tipo("cep_leniente").unwrap()("a123b45  6"),
            "00123-456"
        );

        // CEP inválido retorna string vazia
        assert_eq!(obter_padronizador_por_tipo("cep").unwrap()("999999999"), "");

        // Metaphone
        assert_eq!(
            obter_padronizador_por_tipo("metaphone").unwrap()("João Silva"),
            "JOAO SILVA"
        );

        // Dado faltante
        assert_eq!(
            obter_padronizador_por_tipo("dado_faltante").unwrap()("SI"),
            "true"
        );
        assert_eq!(
            obter_padronizador_por_tipo("dado_faltante").unwrap()("RUA B"),
            "false"
        );
    }

    #[test]
    fn test_obter_padronizador_por_tipo_invalido() {
        assert_eq!(
            obter_padronizador_por_tipo("banana"),
            Err("Nenhum padronizador encontrado")
        );
        assert_eq!(
            obter_padronizador_por_tipo(""),
            Err("Nenhum padronizador encontrado")
        );
    }
}
