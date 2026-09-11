use rustc_hash::FxHashMap;
use std::sync::LazyLock;

use crate::{normalizar, Padronizador};

// TODO: ver se essa é a melhor forma de definir essa struct

#[derive(Debug, Clone, Copy)]
struct Estado {
    pub codigo: &'static str,
    pub nome: &'static str,
    pub sigla: &'static str,
}

// Em Rust, a constant é criada durante a compilação, então só posso chamar funções muito restritas
// quando uso `const`. Nesse caso, como tenho uma construção complexa da struct `Padronizador`,
// tenho que usar static com inicialização Lazy (o LazyLock aqui previne condições de corrida).

static ESTADOS_MAP: LazyLock<FxHashMap<String, &'static Estado>> = LazyLock::new(criar_estado_map);

// O trecho &'static indica que estou referenciando uma posição de memória estática,
// o que evita cópias desnecessárias.

fn criar_estado_map() -> FxHashMap<String, &'static Estado> {
    let mut estados = FxHashMap::<String, &'static Estado>::default();
    ESTADOS.iter().for_each(|e| {
        estados.insert(e.sigla.to_string(), e);
        estados.insert(e.codigo.to_string(), e);
        estados.insert(normalizar(e.nome).into_owned(), e);
    });
    estados.shrink_to_fit();
    estados
}

static PADRONIZADOR: LazyLock<Padronizador> = LazyLock::new(criar_padronizador);

fn criar_padronizador() -> Padronizador {
    let mut padronizador = Padronizador::default();

    padronizador.adicionar(r"\b0+(\d+)\b", "$1");
    // remove qualquer coisa que não seja letras, números ou espaço
    padronizador.adicionar(r"[^ 0-9A-Z]", "");
    padronizador.adicionar(r"\s{2,}", " "); // reduz os espaços em branco
    padronizador.adicionar(r"^\s+|\s+$", ""); // faz um trim improvisado

    padronizador.preparar();
    padronizador
}

// ====== Funções Públicas =======

/// Padroniza uma string representando estados brasileiros para sua sigla de duas letras.
///
/// # Exemplo
/// ```
/// use enderecobr_rs::padronizar_estados_para_sigla;
/// assert_eq!(padronizar_estados_para_sigla("21"), "MA");
/// assert_eq!(padronizar_estados_para_sigla("021"), "MA");
/// assert_eq!(padronizar_estados_para_sigla("MA"), "MA");
/// assert_eq!(padronizar_estados_para_sigla(" 21"), "MA");
/// assert_eq!(padronizar_estados_para_sigla(" MA "), "MA");
/// assert_eq!(padronizar_estados_para_sigla("ma"), "MA");
/// assert_eq!(padronizar_estados_para_sigla(""), "");
/// assert_eq!(padronizar_estados_para_sigla("me"), "");
/// assert_eq!(padronizar_estados_para_sigla("maranhao"), "MA");
/// assert_eq!(padronizar_estados_para_sigla("banana"), "");
/// assert_eq!(padronizar_estados_para_sigla("@  @  @ Maranhão !!!"), "MA")
/// ```
///
/// # Detalhes
/// Operações realizadas durante a padronização:
/// - remoção de espaços em branco antes e depois dos valores e remoção de espaços em excesso entre palavras;
/// - conversão de caracteres para caixa alta;
/// - remoção de zeros à esquerda;
/// - busca, a partir do código numérico ou da abreviação da UF, do nome completo de cada estado;
///
pub fn padronizar_estados_para_sigla(valor: &str) -> &'static str {
    let padronizador = &*PADRONIZADOR;
    let valor_padr = padronizador.padronizar_cow(valor);

    let mapa = &*ESTADOS_MAP;
    mapa.get(&valor_padr.into_owned())
        .map(|e| e.sigla)
        .unwrap_or("")
}

/// Padroniza uma string representando estados brasileiros para seu código do IBGE.
///
/// # Exemplo
/// ```
/// use enderecobr_rs::padronizar_estados_para_codigo;
/// assert_eq!(padronizar_estados_para_codigo("21"), "21");
/// assert_eq!(padronizar_estados_para_codigo("021"), "21");
/// assert_eq!(padronizar_estados_para_codigo("MA"), "21");
/// assert_eq!(padronizar_estados_para_codigo(" 21"), "21");
/// assert_eq!(padronizar_estados_para_codigo(" MA "), "21");
/// assert_eq!(padronizar_estados_para_codigo("ma"), "21");
/// assert_eq!(padronizar_estados_para_codigo(""), "");
/// assert_eq!(padronizar_estados_para_codigo("me"), "");
/// assert_eq!(padronizar_estados_para_codigo("maranhao"), "21");
/// assert_eq!(padronizar_estados_para_codigo("banana"), "");
/// assert_eq!(padronizar_estados_para_codigo("@  @  @ Maranhão !!!"), "21");
/// ```
///
/// # Detalhes
/// Operações realizadas durante a padronização:
/// - remoção de espaços em branco antes e depois dos valores e remoção de espaços em excesso entre palavras;
/// - conversão de caracteres para caixa alta;
/// - remoção de zeros à esquerda;
/// - busca, a partir do código numérico ou da abreviação da UF, do nome completo de cada estado;
///
pub fn padronizar_estados_para_codigo(valor: &str) -> &'static str {
    let padronizador = &*PADRONIZADOR;
    let valor_padr = padronizador.padronizar_cow(valor);

    let mapa = &*ESTADOS_MAP;
    mapa.get(&valor_padr.into_owned())
        .map(|e| e.codigo)
        .unwrap_or("")
}

/// Padroniza uma string representando estados brasileiros para seu nome por extenso,
/// porém sem diacríticos.
///
/// # Exemplo
/// ```
/// use enderecobr_rs::padronizar_estados_para_nome;
/// assert_eq!(padronizar_estados_para_nome("21"), "MARANHAO");
/// assert_eq!(padronizar_estados_para_nome("021"), "MARANHAO");
/// assert_eq!(padronizar_estados_para_nome("MA"), "MARANHAO");
/// assert_eq!(padronizar_estados_para_nome(" 21"), "MARANHAO");
/// assert_eq!(padronizar_estados_para_nome(" MA "), "MARANHAO");
/// assert_eq!(padronizar_estados_para_nome("ma"), "MARANHAO");
/// assert_eq!(padronizar_estados_para_nome(""), "");
/// assert_eq!(padronizar_estados_para_nome("me"), "");
/// assert_eq!(padronizar_estados_para_nome("maranhao"), "MARANHAO");
/// assert_eq!(padronizar_estados_para_nome("@  @  @ Maranhão !!!"), "MARANHAO");
/// ```
///
/// # Detalhes
/// Operações realizadas durante a padronização:
/// - remoção de espaços em branco antes e depois dos valores e remoção de espaços em excesso entre palavras;
/// - conversão de caracteres para caixa alta;
/// - remoção de zeros à esquerda;
/// - busca, a partir do código numérico ou da abreviação da UF, do nome completo de cada estado;
///
pub fn padronizar_estados_para_nome(valor: &str) -> &'static str {
    let padronizador = &*PADRONIZADOR;
    let valor_padr = padronizador.padronizar_cow(valor);

    let mapa = &*ESTADOS_MAP;
    mapa.get(&valor_padr.into_owned())
        .map(|e| e.nome)
        .unwrap_or("")
}

// ============ Dados Brutos ============

const ESTADOS: [Estado; 27] = [
    Estado {
        codigo: "11",
        nome: "RONDONIA",
        sigla: "RO",
    },
    Estado {
        codigo: "12",
        nome: "ACRE",
        sigla: "AC",
    },
    Estado {
        codigo: "13",
        nome: "AMAZONAS",
        sigla: "AM",
    },
    Estado {
        codigo: "14",
        nome: "RORAIMA",
        sigla: "RR",
    },
    Estado {
        codigo: "15",
        nome: "PARA",
        sigla: "PA",
    },
    Estado {
        codigo: "16",
        nome: "AMAPA",
        sigla: "AP",
    },
    Estado {
        codigo: "17",
        nome: "TOCANTINS",
        sigla: "TO",
    },
    Estado {
        codigo: "21",
        nome: "MARANHAO",
        sigla: "MA",
    },
    Estado {
        codigo: "22",
        nome: "PIAUI",
        sigla: "PI",
    },
    Estado {
        codigo: "23",
        nome: "CEARA",
        sigla: "CE",
    },
    Estado {
        codigo: "24",
        nome: "RIO GRANDE DO NORTE",
        sigla: "RN",
    },
    Estado {
        codigo: "25",
        nome: "PARAIBA",
        sigla: "PB",
    },
    Estado {
        codigo: "26",
        nome: "PERNAMBUCO",
        sigla: "PE",
    },
    Estado {
        codigo: "27",
        nome: "ALAGOAS",
        sigla: "AL",
    },
    Estado {
        codigo: "28",
        nome: "SERGIPE",
        sigla: "SE",
    },
    Estado {
        codigo: "29",
        nome: "BAHIA",
        sigla: "BA",
    },
    Estado {
        codigo: "31",
        nome: "MINAS GERAIS",
        sigla: "MG",
    },
    Estado {
        codigo: "32",
        nome: "ESPIRITO SANTO",
        sigla: "ES",
    },
    Estado {
        codigo: "33",
        nome: "RIO DE JANEIRO",
        sigla: "RJ",
    },
    Estado {
        codigo: "35",
        nome: "SAO PAULO",
        sigla: "SP",
    },
    Estado {
        codigo: "41",
        nome: "PARANA",
        sigla: "PR",
    },
    Estado {
        codigo: "42",
        nome: "SANTA CATARINA",
        sigla: "SC",
    },
    Estado {
        codigo: "43",
        nome: "RIO GRANDE DO SUL",
        sigla: "RS",
    },
    Estado {
        codigo: "50",
        nome: "MATO GROSSO DO SUL",
        sigla: "MS",
    },
    Estado {
        codigo: "51",
        nome: "MATO GROSSO",
        sigla: "MT",
    },
    Estado {
        codigo: "52",
        nome: "GOIAS",
        sigla: "GO",
    },
    Estado {
        codigo: "53",
        nome: "DISTRITO FEDERAL",
        sigla: "DF",
    },
];

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn padroniza_corretamente() {
        assert_eq!(padronizar_estados_para_nome("21"), "MARANHAO");
        assert_eq!(padronizar_estados_para_nome("021"), "MARANHAO");
        assert_eq!(padronizar_estados_para_nome(" 21 "), "MARANHAO");
        assert_eq!(padronizar_estados_para_nome("ma"), "MARANHAO");
        assert_eq!(padronizar_estados_para_nome(""), ""); // NA
        assert_eq!(padronizar_estados_para_nome("MARANHÃO"), "MARANHAO");

        assert_eq!(padronizar_estados_para_sigla("21"), "MA");
        assert_eq!(padronizar_estados_para_sigla("021"), "MA");
        assert_eq!(padronizar_estados_para_sigla(" 21 "), "MA");
        assert_eq!(padronizar_estados_para_sigla("ma"), "MA");
        assert_eq!(padronizar_estados_para_sigla(""), ""); // NA
        assert_eq!(padronizar_estados_para_sigla("MARANHÃO"), "MA");

        assert_eq!(padronizar_estados_para_codigo("MARANHAO"), "21");

        assert_eq!(padronizar_estados_para_nome("MARANHÃO"), "MARANHAO");
        assert_eq!(padronizar_estados_para_codigo("Banana"), "");
        assert_eq!(padronizar_estados_para_sigla("Banana"), "");
    }
}
