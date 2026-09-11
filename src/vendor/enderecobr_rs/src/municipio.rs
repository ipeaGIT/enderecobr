use itertools::Itertools;
use rustc_hash::{FxHashMap, FxHashSet};
use std::sync::LazyLock;

use crate::{metaphone::metaphone, normalizar, Padronizador};

static PADRONIZADOR: LazyLock<Padronizador> = LazyLock::new(criar_padronizador);

static MUNICIPIOS_MAP: LazyLock<FxHashMap<String, String>> = LazyLock::new(criar_municipio_map);

/// Sinônimos de nomes de municípios mantidos manualmente.
///
/// Cada par `(de, para)` mapeia um nome alternativo/antigo para o nome canônico
/// (já normalizado, sem acentos). As fontes de cada entry estão nos comentários.
/// Estes sinônimos são registrados por último na construção do mapa (ver
/// [`criar_municipio_map`]), então só entram quando a chave ainda não existe.
const ALIAS: &[(&str, &str)] = &[
    ("TRAJANO DE MORAIS", "TRAJANO DE MORAES"), // https://pt.wikipedia.org/wiki/Trajano_de_Moraes#cite_note-6
    ("POXOREO", "POXOREU"),                     // https://pt.wikipedia.org/wiki/Poxor%C3%A9u
    ("SERIDO", "SAO VICENTE DO SERIDO"), // https://pt.wikipedia.org/wiki/S%C3%A3o_Vicente_do_Serid%C3%B3#cite_note-7
    ("AUGUSTO SEVERO", "CAMPO GRANDE"), // https://pt.wikipedia.org/wiki/Campo_Grande_(Rio_Grande_do_Norte)
    ("FLORINIA", "FLORINEA"),           // https://pt.wikipedia.org/wiki/Flor%C3%ADnea
    ("FORTALEZA DO TABOCAO", "TABOCAO"), // https://pt.wikipedia.org/wiki/Taboc%C3%A3o
    ("SAO VALERIO DA NATIVIDADE", "SAO VALERIO"), // https://pt.wikipedia.org/wiki/S%C3%A3o_Val%C3%A9rio
    ("CAMPO DE SANTANA", "TACIMA"),               // https://pt.wikipedia.org/wiki/Tacima
    ("JANUARIO CICCO", "BOA SAUDE"),              // https://pt.wikipedia.org/wiki/Boa_Sa%C3%BAde
    ("SAO DOMINGOS DE POMBAL", "SAO DOMINGOS"), // https://pt.wikipedia.org/wiki/S%C3%A3o_Domingos_(Para%C3%ADba)
];

/// Constrói o [`Padronizador`] da **primeira etapa** de [`padronizar_municipios`].
///
/// Esta etapa não resolve nomes: apenas normaliza a entrada para que ela possa
/// ser usada como chave de busca no mapa (ver [`criar_municipio_map`]). Em ordem:
///
/// 1. remove zeros à esquerda de tokens numéricos (códigos IBGE);
/// 2. colapsa espaços múltiplos em um único espaço;
/// 3. remove qualquer caractere que não seja letra maiúscula, dígito, espaço,
///    hífen ou apóstrofo (`[^ A-Z0-9'-]`). A retirada de acentos e a conversão
///    para maiúsculas fica a cargo de [`normalizar`], aplicada na construção do
///    mapa; a entrada do usuário passa por [`Padronizador::padronizar`] que já
///    normaliza.
///
/// O resultado desta etapa é uma *chave exata* procurada no mapa. Caso não haja
/// correspondência exata, [`padronizar_municipios`] tenta ainda uma segunda
/// busca fonética ([`padronizar_para_pareamento`]).
pub fn criar_padronizador() -> Padronizador {
    let mut padronizador = Padronizador::default();

    padronizador
        .adicionar(r"\b0+(\d+)\b", "$1") // Remove zeros na frente
        .adicionar(r"\s{2,}", " ") // Remove espaços extra
        // Remove qualquer carácter que não aparece na tabela de municípios
        // PS: a normalização já tira acentos
        .adicionar(r"[^ A-Z0-9'-]", "");

    padronizador.preparar();
    padronizador
}

/// Gera a **chave fonética** usada para o pareamento tolerante a variações ortográficas.
///
/// Aplicada quando a busca exata no [`criar_municipio_map`] falha. Transforma um
/// nome (já normalizado, sem acentos/maiúsculas) numa chave fonética via
/// [`metaphone`], precedida de três normalizações que aumentam a taxa de casamento:
///
/// 1. **hífens → espaços**: `OLHO-D'AGUA` vira `OLHO D'AGUA`;
/// 2. **colapso de letras duplicadas** (preservando `SS` e `RR`, que carregam som
///    próprio em português);
/// 3. **remoção de preposições** intermediárias (`DE`, `DA`, `DO`, `DAS`, `DOS`,
///    `DEL`, `E`), que variam entre grafias sem mudar o nome de fundo.
///
/// A chave final é *intencionalmente com perdas* e serve só para casamento
/// aproximado — nomes diferentes podem colidir (ex.: `CASTELO`/`CASTELLO`
/// reduzem ao mesmo código após o colapso do `LL`). Em caso de colisão, vence a
/// entrada primeiro registrada no mapa (casos canônicos são inseridos antes dos
/// derivados; ver [`criar_municipio_map`]), o que garante que a forma canônica do
/// município apareça no lugar da variante. O pareamento fonético só é tentado
/// quando não há correspondência exata, então grafias corretas nunca são
/// sobrescritas.
fn padronizar_para_pareamento(mun: &str) -> String {
    // Pré-requisito: a string já passou por `criar_padronizador` (sem acentos,
    // em maiúscula, só com [A-Z0-9 -']).

    const PREPOSICOES: &[&str] = &["DE", "DA", "DO", "DAS", "DOS", "DEL", "E"];

    // --- 1. Troca hífens por espaços ---
    let sem_hifen = mun.replace('-', " ");

    // --- 2. Remove letras duplicadas consecutivas (exceto SS e RR, que têm som
    //         próprio em português). Nota: este colapso é com perdas e pode
    //         fundir nomes distintos (ex.: CASTELO ≡ CASTELLO); a ordem de
    //         inserção no mapa resolve a colisão a favor da forma canônica. ---
    let mut chars: Vec<char> = sem_hifen.chars().collect();
    chars.dedup_by(|a, b| *a == *b && *a != 'S' && *a != 'R');
    let dedup: String = chars.into_iter().collect();

    // --- 3. Remove preposições (vão e voltam entre grafias; não discriminam) ---
    let mut resultado = String::with_capacity(dedup.len());
    for palavra in dedup.split_whitespace() {
        if !PREPOSICOES.contains(&palavra) {
            if !resultado.is_empty() {
                resultado.push(' ');
            }
            resultado.push_str(palavra);
        }
    }

    metaphone(&resultado)
}

/// Expande um nome com apóstrofos em suas variantes de grafia comum.
///
/// Para nomes como `LAGOA D'ANTA DE SANT'ANA` (que já devem estar normalizados,
/// sem acentos), gera as formas usuais sem o apóstrofo:
/// - substituindo `'` por espaço (`SANT'ANA` → `SANT ANA`);
/// - removendo `'` (`SANT'ANA` → `SANTANA`);
/// - e abrindo em duas palavras a partir da letra seguinte (`SANT'ANA` →
///   `SANTA ANA`), forma que cobre erros de separação entre `SANT'` e `SANTA`.
///
/// Retorna as variantes **já passadas por [`padronizar_para_pareamento`]** (chaves
/// fonéticas) e em ordem determinística (`sorted`), prontas para registro como
/// chaves adicionais no mapa. Nomes sem apóstrofo devolvem um vetor vazio.
///
/// # Segurança
/// Os offsets vindos de `match_indices("'")` são em *bytes*; como o apóstrofo é
/// ASCII (1 byte) e, nesta etapa, o texto está normalizado (sem acentos) e
/// contém apenas `[A-Z0-9 -']`, o caractere imediatamente após o apóstrofo é
/// sempre ASCII, então os `get(i+1..)` não correm risco de partir um multibyte.
fn nomes_alternativos(mun: &str) -> Vec<String> {
    let mut alternativas = FxHashSet::default();

    if mun.contains('\'') {
        alternativas.insert(mun.replace('\'', " "));
        alternativas.insert(mun.replace('\'', ""));
        for (i, _) in mun.match_indices('\'') {
            let alternativa = format!(
                "{}{} {}",
                mun.get(..i).unwrap_or(""),
                mun.get(i + 1..i + 2).unwrap_or(""),
                mun.get(i + 1..).unwrap_or("")
            );
            alternativas.insert(padronizar_para_pareamento(&alternativa));
        }
    }

    alternativas.into_iter().sorted().collect()
}

/// Constrói o mapa de municípios usado por [`padronizar_municipios`].
///
/// As chaves reconhecidas e seus valores (nome canônico normalizado):
///
/// | chave | exemplo | vem de |
/// |---|---|---|
/// | nome canônico | `"RIO DE JANEIRO"` | própria linha do CSV |
/// | código IBGE completo | `"3304557"` | coluna `cod_ibge` |
/// | código IBGE sem dígito verificador | `"330455"` | mesmos 6 dígitos de cima |
/// | chave fonética do nome | [`padronizar_para_pareamento`] | derivada |
/// | variantes de apóstrofo | [`nomes_alternativos`] | derivada |
/// | sinônimos manuais | [`ALIAS`] | tabela constante |
///
/// # Ordem de inserção e resolução de colisões
///
/// As entradas são registradas em três fases, **nesta ordem**:
///
/// 1. **Canônicas** — nomes e códigos do CSV, inseridas com [`HashMap::insert`]
///    (sobrescrevem). Isso garante que o nome oficial prevalece sobre qualquer
///    chave derivada que por acaso coincida com ele.
/// 2. **Fonéticas/alternativas** — derivadas de cada nome via
///    [`padronizar_para_pareamento`] e [`nomes_alternativos`], inseridas com
///    [`entry().or_insert()`][HashMap::entry] (não sobrescrevem). Assim, quando
///    duas grafias distintas colapsam para a mesma chave fonética (ex.:
///    `CASTELO`/`CASTELLO`, `PRESIDENTE CASTELO`/`PRESIDENTE CASTELLO`), o
///    vencedor é sempre a primeira forma canônica inserida — nunca a errada.
/// 3. **Sinônimos manuais** — [`ALIAS`], também via `entry().or_insert()`,
///    registrados por último para não roubar chaves já legítimas.
///
/// `padronizar_municipios` consulta primeiro a chave exata e só depois a chave
/// fonética, então entradas canônicas nunca são desalojadas.
///
/// # Robustez do parse do CSV
///
/// O CSV é embutido em tempo de compilação via `include_str!`. Linhas com número
/// de campos diferente de três são **ignoradas** (com `eprintln!` em `debug`)
/// em vez de panicar, para que um eventual edit só de dados no arquivo não
/// derrube o processo inteiro em produção. Como o mapa é construído sob
/// `LazyLock`, um `panic!` aqui abortaria o programa no primeiro acesso.
pub fn criar_municipio_map() -> FxHashMap<String, String> {
    // a include_str! embute a string no código em tempo de compilação.
    let municipios_csv: &str = include_str!("data/municipios.csv");
    let mut mapa = FxHashMap::<String, String>::default();

    // Como eu quero varrer esses dados duas vezes,
    // mantenho ele processado em memória.
    let mut dados_municipios = Vec::<(String, String, String)>::default();
    for linha in municipios_csv.lines().skip(1) {
        // Pula linhas em branco (ex.: editores que adicionam \n final).
        if linha.is_empty() {
            continue;
        }

        // Aceita somente linhas com exatamente 3 campos. Caso contrário,
        // registra (em debug) e segue, em vez de panicar dentro do LazyLock.
        let mut cols = linha.split(',');
        let (Some(codigo), Some(nome), Some(uf), None) =
            (cols.next(), cols.next(), cols.next(), cols.next())
        else {
            #[cfg(debug_assertions)]
            eprintln!("Linha ignorada (esperado 3 campos): {linha}");
            continue;
        };

        dados_municipios.push((
            codigo.to_owned(),
            normalizar(nome).to_string(),
            uf.to_owned(),
        ));
    }

    // Primeiro adiciono os casos canônicos na listagem.
    // Inseridos com `insert` (sobrescrevem), de modo que o nome oficial
    // prevalece sobre qualquer chave derivada que por acaso coincida.
    for (codigo, nome, _) in &dados_municipios {
        // Preciso dos nome originais para validar os município
        // Lembrando que o nome já está normalizado.
        mapa.insert(nome.clone(), nome.clone());

        // Adiciona código do ibge no mapa
        mapa.insert(codigo.to_string(), nome.clone());

        // Erro comum: código IBGE sem o último dígito
        if let Some(codigo_reduzido) = codigo.get(..codigo.len() - 1) {
            mapa.insert(codigo_reduzido.to_string(), nome.clone());
        }
    }

    // Segunda varredura para adicionar os casos alternativos (não sobrescrevem).
    for (_, nome, _) in &dados_municipios {
        // Adiciono uma versão do nome, com o pré processamento agressivo,
        // quando não existir essa versão no dicionário.
        mapa.entry(padronizar_para_pareamento(nome.as_str()))
            .or_insert(nome.clone());

        // Adiciono mais uma versão alternativa, dessa vez, expandido os nomes:
        // SANT'ANA => SANT ANA, SANTANA, SANTA ANA
        for alternativo in nomes_alternativos(nome.as_str()) {
            mapa.entry(padronizar_para_pareamento(&alternativo))
                .or_insert(nome.clone());
        }
    }

    // Por fim, adiciono os ALIAS quando eles ainda não existirem nos demais casos.
    for (de, para) in ALIAS {
        // Alias puro:
        mapa.entry(de.to_string()).or_insert(para.to_string());

        // Com a padronização agressiva.
        mapa.entry(padronizar_para_pareamento(de))
            .or_insert(para.to_string());

        // Com os nomes alternativos junto com a padronização agressiva.
        for alternativo in nomes_alternativos(de) {
            mapa.entry(padronizar_para_pareamento(&alternativo))
                .or_insert(para.to_string());
        }
    }

    mapa
}

// ====== Funções Públicas =======
/// Padroniza uma string representando um município brasileiro.
///
/// Retorna o **nome canônico** (normalizado, sem acentos, em maiúsculas) segundo
/// a listagem do IBGE, ou uma **string vazia** se o valor não puder ser resolvido
/// para nenhum município conhecido.
///
/// # Contrato de retorno
///
/// - Valores reconhecidos → nome canônico completo (eventuais erros ortográficos
///   e nomes antigos are resolvidos; ver [`criar_municipio_map`]).
/// - **Valores irreconhecíveis → `""`** (string vazia). Esta é a diferença em
///   relação a versões anteriores, que devolviam a entrada limpa; agora a
///   função sempre devolve um identificador válido ou vazio, nunca um texto
///   ambíguo. Em pipelines de massa, trate `""` como "município desconhecido".
///
/// A resolução segue duas tentativas, em ordem:
///
/// 1. **busca exata** da entrada padronizada como chave direta do mapa;
/// 2. se falhar, **busca fonética** via [`padronizar_para_pareamento`], que
///    tolera variações e pequenos erros de grafia.
///
/// Quando mais de um município mapeia para a mesma chave fonética, vence a
/// entrada canônica inserida primeiro (ver a ordem de fases em
/// [`criar_municipio_map`]); grafias exatas jamais são desalojadas porque a
/// busca exata (passo 1) tem precedência.
///
/// # Exemplos
///
/// ```
/// use enderecobr_rs::padronizar_municipios;
/// assert_eq!(padronizar_municipios("3304557"), "RIO DE JANEIRO");
/// assert_eq!(padronizar_municipios("003304557"), "RIO DE JANEIRO");
/// assert_eq!(padronizar_municipios("  3304557  "), "RIO DE JANEIRO");
/// assert_eq!(padronizar_municipios("RIO DE JANEIRO"), "RIO DE JANEIRO");
/// assert_eq!(padronizar_municipios("rio de janeiro"), "RIO DE JANEIRO");
/// assert_eq!(padronizar_municipios("SÃO PAULO"), "SAO PAULO");
/// assert_eq!(padronizar_municipios("PARATI"), "PARATY");
/// assert_eq!(padronizar_municipios("AUGUSTO SEVERO"), "CAMPO GRANDE");
/// assert_eq!(padronizar_municipios("SAO VALERIO DA NATIVIDADE"), "SAO VALERIO");
/// // Valores irreconhecíveis devolvem string vazia:
/// assert_eq!(padronizar_municipios(""), "");
/// assert_eq!(padronizar_municipios("BANANA"), "");
/// assert_eq!(padronizar_municipios("!!!!"), "");
/// // Ruído moderno é descartado antes da busca:
/// assert_eq!(padronizar_municipios("PARATI!!!!"), "PARATY");
/// // Variações ortográficas casam pela busca fonética:
/// assert_eq!(padronizar_municipios("LAGOA DANTA"), "LAGOA D'ANTA");
/// ```
///
/// # Detalhes
/// Operações realizadas durante a padronização:
/// - remoção de espaços em branco antes e depois das strings e remoção de espaços em excesso entre palavras;
/// - conversão de caracteres para caixa alta;
/// - remoção de zeros à esquerda;
/// - remoção de qualquer caractere que não seja `A-Z`, `0-9`, espaço, hífen ou apóstrofo;
/// - busca, a partir do código numérico, do nome completo de cada município;
/// - remoção de acentos e caracteres não ASCII, correção de erros ortográficos frequentes e atualização
///   de nomes conforme listagem de municípios do IBGE de 2022.
///
/// Note que existe uma etapa de compilação das expressões regulares utilizadas,
/// logo a primeira execução desta função pode demorar um pouco a mais (o mapa
/// de municípios também é construído preguiçosamente, uma única vez).
///
pub fn padronizar_municipios(valor: &str) -> String {
    let res = PADRONIZADOR.padronizar(valor);

    let municipios = &*MUNICIPIOS_MAP;
    municipios
        .get(&res)
        .or_else(|| municipios.get(&padronizar_para_pareamento(&res)))
        .cloned()
        .unwrap_or_default()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn padroniza_corretamente() {
        assert_eq!(padronizar_municipios("3304557"), "RIO DE JANEIRO");
        assert_eq!(padronizar_municipios("330455"), "RIO DE JANEIRO");
        assert_eq!(padronizar_municipios("03304557"), "RIO DE JANEIRO");
        assert_eq!(padronizar_municipios("0330455"), "RIO DE JANEIRO");
        assert_eq!(padronizar_municipios(" 3304557 "), "RIO DE JANEIRO");
        assert_eq!(padronizar_municipios("rio de janeiro"), "RIO DE JANEIRO");
        assert_eq!(padronizar_municipios(""), ""); // string vazia → string vazia
        assert_eq!(padronizar_municipios("SÃO PAULO"), "SAO PAULO");
        assert_eq!(padronizar_municipios("MOJI MIRIM"), "MOGI MIRIM");
        assert_eq!(padronizar_municipios("PARATI"), "PARATY");
        assert_eq!(padronizar_municipios("PARATI!!!!"), "PARATY");
        assert_eq!(padronizar_municipios("BANANA"), "");
        assert_eq!(padronizar_municipios("LAGOA D'ANTA"), "LAGOA D'ANTA");
        assert_eq!(padronizar_municipios("LAGOA DANTA"), "LAGOA D'ANTA");
        assert_eq!(padronizar_municipios("LAGOA D ANTA"), "LAGOA D'ANTA");
        assert_eq!(padronizar_municipios("LAGOA DA ANTA"), "LAGOA D'ANTA");
    }

    #[test]
    fn testa_nomes_alternativos() {
        assert_eq!(
            nomes_alternativos("LAGOA D'ANTA DE SANT'ANA"),
            vec![
                "LAGOA ANTA SANTANA",
                "LAGOA D ANTA DE SANT ANA",
                "LAGOA DANTA DE SANTANA",
                "LAGOA DANTA SANTA ANA"
            ]
        );
    }

    #[test]
    fn padroniza_casos_especificos() {
        // Testa os casos específicos que estavam anteriormente como expressões regulares
        assert_eq!(padronizar_municipios("MOJI MIRIM"), "MOGI MIRIM");
        assert_eq!(padronizar_municipios("GRAO PARA"), "GRAO-PARA");
        assert_eq!(padronizar_municipios("BIRITIBA-MIRIM"), "BIRITIBA MIRIM");
        assert_eq!(
            padronizar_municipios("SAO LUIS DO PARAITINGA"),
            "SAO LUIZ DO PARAITINGA"
        );
        assert_eq!(
            padronizar_municipios("TRAJANO DE MORAIS"),
            "TRAJANO DE MORAES"
        );
        assert_eq!(padronizar_municipios("PARATI"), "PARATY");
        assert_eq!(
            padronizar_municipios("LAGOA DO ITAENGA"),
            "LAGOA DE ITAENGA"
        );
        assert_eq!(
            padronizar_municipios("ELDORADO DOS CARAJAS"),
            "ELDORADO DO CARAJAS"
        );
        assert_eq!(
            padronizar_municipios("SANTANA DO LIVRAMENTO"),
            "SANT'ANA DO LIVRAMENTO"
        );
        assert_eq!(
            padronizar_municipios("BELEM DE SAO FRANCISCO"),
            "BELEM DO SAO FRANCISCO"
        );
        assert_eq!(
            padronizar_municipios("SANTO ANTONIO DO LEVERGER"),
            "SANTO ANTONIO DE LEVERGER"
        );
        assert_eq!(padronizar_municipios("POXOREO"), "POXOREU");
        assert_eq!(
            padronizar_municipios("SAO THOME DAS LETRAS"),
            "SAO TOME DAS LETRAS"
        );
        assert_eq!(
            padronizar_municipios("OLHO-D'AGUA DO BORGES"),
            "OLHO D'AGUA DO BORGES"
        );
        assert_eq!(padronizar_municipios("ITAPAGE"), "ITAPAJE");
        assert_eq!(
            padronizar_municipios("MUQUEM DE SAO FRANCISCO"),
            "MUQUEM DO SAO FRANCISCO"
        );
        assert_eq!(padronizar_municipios("DONA EUSEBIA"), "DONA EUZEBIA");
        assert_eq!(padronizar_municipios("PASSA-VINTE"), "PASSA VINTE");
        assert_eq!(
            padronizar_municipios("AMPARO DE SAO FRANCISCO"),
            "AMPARO DO SAO FRANCISCO"
        );
        assert_eq!(padronizar_municipios("BRASOPOLIS"), "BRAZOPOLIS");
        assert_eq!(padronizar_municipios("SERIDO"), "SAO VICENTE DO SERIDO");
        assert_eq!(padronizar_municipios("IGUARACI"), "IGUARACY");
        assert_eq!(padronizar_municipios("AUGUSTO SEVERO"), "CAMPO GRANDE");
        assert_eq!(padronizar_municipios("FLORINIA"), "FLORINEA");
        assert_eq!(padronizar_municipios("FORTALEZA DO TABOCAO"), "TABOCAO");
        assert_eq!(
            padronizar_municipios("SAO VALERIO DA NATIVIDADE"),
            "SAO VALERIO"
        );
    }
}
