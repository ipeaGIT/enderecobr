use enderecobr_rs::{
    padronizar_bairros, padronizar_cep, padronizar_cep_numerico, padronizar_complementos,
    padronizar_estados_para_nome, padronizar_estados_para_sigla, padronizar_logradouros,
    padronizar_municipios, padronizar_numeros, padronizar_tipo_logradouro,
};
use extendr_api::prelude::*;
use extendr_api::ToVectorValue;
use std::collections::HashMap;

/// Função utilitária interna usada para fazer o tratamento em comum
/// dos dados vindos do R para os casos de string.
fn mapear_com_cache<F>(x: Strings, fun: F) -> Strings
where
    F: Fn(&str) -> String,
{
    let mut cache = HashMap::<&str, Rstr>::new();

    x.iter()
        .map(|xi| match xi.is_na() {
            true => Rstr::na(),
            false => {
                let chave = xi.as_str();
                if let Some(valor_cacheado) = cache.get(&chave) {
                    return valor_cacheado.clone();
                }
                let res_fun = fun(chave);
                let res_r = if res_fun.is_empty() {
                    Rstr::na()
                } else {
                    Rstr::from(res_fun)
                };
                cache.insert(chave, res_r.clone());
                res_r
            }
        })
        .collect::<Strings>()
}

#[extendr]
pub fn padronizar_bairros_rs(x: Strings) -> Strings {
    mapear_com_cache(x, padronizar_bairros)
}

#[extendr]
pub fn padronizar_complementos_rs(x: Strings) -> Strings {
    mapear_com_cache(x, padronizar_complementos)
}

#[extendr]
pub fn padronizar_logradouros_rs(x: Strings) -> Strings {
    mapear_com_cache(x, padronizar_logradouros)
}

#[extendr]
pub fn padronizar_tipos_de_logradouros_rs(x: Strings) -> Strings {
    mapear_com_cache(x, padronizar_tipo_logradouro)
}

#[extendr]
pub fn padronizar_municipios_rs(x: Strings) -> Strings {
    mapear_com_cache(x, padronizar_municipios)
}

#[extendr]
pub fn padronizar_ceps_rs(x: Strings) -> Strings {
    mapear_com_cache(x, |cep| match padronizar_cep(cep) {
        Ok(val) => val,
        Err(val) => format!("Erro: {}", val),
    })
}

#[extendr]
pub fn padronizar_ceps_numericos_rs(x: Integers) -> Strings {
    x.iter()
        .map(|xi| match xi.is_na() {
            true => Rstr::na(),
            false => match padronizar_cep_numerico(xi.to_integer()) {
                Ok(cep) => Rstr::from(cep),
                Err(err) => Rstr::from(format!("Erro: {}", err.to_string())),
            },
        })
        .collect::<Strings>()
}

#[extendr]
pub fn padronizar_numeros_rs(x: Strings) -> Strings {
    mapear_com_cache(x, padronizar_numeros)
}

// Por algum motivo, na documentação consta para usar #[extendr(default = "value)],
// porém ele só está aceitando o método supostamente depreciado #[default = "value"].
// https://github.com/extendr/extendr/pull/952/files

#[extendr]
pub fn padronizar_estados_rs(x: Strings, #[default = "'por_extenso'"] formato: Robj) -> Strings {
    if formato.as_str() == Some("sigla") {
        return mapear_com_cache(x, padronizar_estados_para_sigla);
    } else {
        return mapear_com_cache(x, padronizar_estados_para_nome);
    }
}

// https://extendr.rs/user-guide/type-mapping/into-list.html#intolist-vs-external-pointers

#[extendr]
pub struct Padronizador {
    pub interno: enderecobr_rs::Padronizador,
}

// Função factory simples para o Padronizador.
// Não sei como faria um construtor em R...
#[extendr]
pub fn novo_padronizador(
    #[default = "list()"] pares_subst: HashMap<&str, Strings>,
) -> Padronizador {
    let mut padr = Padronizador {
        interno: enderecobr_rs::Padronizador::default(),
    };

    if pares_subst.len() > 0 {
        padr.adicionar_substituicoes(pares_subst);
    }
    padr
}

#[extendr]
impl Padronizador {
    // https://extendr.rs/user-guide/type-mapping/collections.html#working-with-mixed-types

    // Espero em R o que seria uma list(regex=c(), subst=c(), ignorar=c())
    // Algumas validações são feitas da pior forma possível: com `panic!`.
    fn adicionar_substituicoes(&mut self, pares_subst: HashMap<&str, Strings>) {
        // Obrigo que nada seja NA aqui.
        let vec_regex: Vec<&str> = pares_subst
            .get("regex")
            .expect("Os pares devem ter um atributo 'regexp'")
            .iter()
            .map(|xi| match xi.is_na() {
                true => panic!("'regexp' não podem ser NA"),
                false => xi.as_str(),
            })
            .collect();

        // Os NA viram string vazia aqui (substituição por nada)
        let vec_subst: Vec<&str> = pares_subst
            .get("subst")
            .expect("Os pares devem ter um atributo 'subst'")
            .iter()
            .map(|xi| match xi.is_na() {
                true => "",
                false => xi.as_str(),
            })
            .collect();

        // NAs aqui viram simplesmente None
        let vec_ignorar: Vec<Option<&str>> = if let Some(ignorar) = pares_subst.get("ignorar") {
            ignorar
                .iter()
                .map(|xi| match xi.is_na() {
                    true => None,
                    false => Some(xi.as_str()),
                })
                .collect()
        } else {
            // Caso o atributo ignorar não exista na list(), crio uma vazia com a mesma
            // quantidade de elementos de `regex`.
            vec![None; vec_regex.len()]
        };

        assert!(vec_regex.len() == vec_subst.len() && vec_regex.len() == vec_ignorar.len());

        self.interno
            .adicionar_vetores(&vec_regex, &vec_subst, &vec_ignorar);
    }

    fn padronizar(&self, valor: Strings) -> Strings {
        // Similar às funções de padronização pré-definidas, crio um cache local durante a
        // execução.
        mapear_com_cache(valor, |x| self.interno.padronizar(x))
    }

    fn obter_substituicoes(&self) -> List {
        // Retorno uma lista do R com os atributos iguais ao recebidos no método de
        // adicionar_substituicoes.
        // https://extendr.rs/user-guide/type-mapping/collections.html
        //
        let (regex, subst, ignorar) = self.interno.obter_vetores();
        let mut res: HashMap<&str, Strings> = HashMap::with_capacity(3);

        // O `Strings::from_values` já resolve
        res.insert("regex", Strings::from_values(regex));
        res.insert("subst", Strings::from_values(subst));

        // O `Strings::from_values` não funciona aqui porque é um vetor de Option
        let ignorar_strings: Strings = ignorar
            .iter()
            .map(|opt| match opt {
                None => Rstr::na(),
                Some(val) => Rstr::from_string(val),
            })
            .collect();

        res.insert("ignorar", ignorar_strings);
        List::from_hashmap(res).unwrap()
    }
}

// ============= Padronizadores predefinidos ============
// A ideia é liberar para personalização.

#[extendr]
fn obter_padronizador_logradouros() -> Padronizador {
    Padronizador {
        interno: enderecobr_rs::logradouro::criar_padronizador_logradouros(),
    }
}

#[extendr]
fn obter_padronizador_numeros() -> Padronizador {
    Padronizador {
        interno: enderecobr_rs::numero::criar_padronizador_numeros(),
    }
}

#[extendr]
fn obter_padronizador_bairros() -> Padronizador {
    Padronizador {
        interno: enderecobr_rs::bairro::criar_padronizador_bairros(),
    }
}

#[extendr]
fn obter_padronizador_complementos() -> Padronizador {
    Padronizador {
        interno: enderecobr_rs::complemento::criar_padronizador_complemento(),
    }
}

#[extendr]
fn obter_padronizador_tipos_logradouros() -> Padronizador {
    Padronizador {
        interno: enderecobr_rs::tipo_logradouro::criar_padronizador_tipo_logradouro(),
    }
}

extendr_module! {
    mod enderecobr;
    fn padronizar_bairros_rs;
    fn padronizar_complementos_rs;
    fn padronizar_logradouros_rs;
    fn padronizar_tipos_de_logradouros_rs;
    fn padronizar_municipios_rs;
    fn padronizar_numeros_rs;
    fn padronizar_estados_rs;
    fn padronizar_ceps_rs;
    fn padronizar_ceps_numericos_rs;
    impl Padronizador;
    fn novo_padronizador;
    fn obter_padronizador_logradouros;
    fn obter_padronizador_tipos_logradouros;
    fn obter_padronizador_complementos;
    fn obter_padronizador_bairros;
    fn obter_padronizador_numeros;
}
