use std::sync::LazyLock;

use crate::Padronizador;

pub fn criar_padronizador_numeros() -> Padronizador {
    let mut padronizador = Padronizador::default();
    padronizador
        // Apaga pares de caracteres comuns
        .adicionar(r"\((.*?)\)", " $1")
        .adicionar("\"(.*?)\"", " $1")
        .adicionar(r"'(.*?)'", " $1")
        // Regexp adicional: remove espaços em branco repetidos
        .adicionar(r"\s{2,}", " ")
        // Apaga qualquer coisa que não seja letra ou número no inicio ou fim
        .adicionar(r"^[^A-Z0-9]+|[^A-Z0-9]+$", "")
        // Remove prefixo de número
        .adicionar(
            r"^N(O|OS|\.O|U|UM|NUMERO| )?( |\.|:| |O|-|\*)*([0-9]+)",
            "$3",
        )
        // Regexp Original: (?<!\.)\b0+(\d+)\b
        // 015 -> 15, 00001 -> 1, 0180 0181 -> 180 181, mas não 1.028 -> 1.28
        // A ideia da regexp original é tirar zeros à esquerda que não sejam separadores de milhar.
        // Como Rust não aceita look around, tentei adaptar.
        .adicionar(r"(^|[^.])\b0+(\d+)\b", "$1$2")
        // separador de milhar
        .adicionar(r"(\d+)\.(\d{3})", "$1$2")
        // SN ou S.N. ou S N ou .... -> S/N
        .adicionar(
            r"^(S|SE|SEM)?(\/|;|-|\\|\.| )*(N|N\.)(A|O|E|U|C|R|S|UM|UME|UMER|UMERO)?(0| |º|\.)*$",
            "S/N",
        )
        .adicionar(r"^N(AO|O)? TEM$", "S/N")
        .adicionar(r"^(SEM NUMERO|NULL|NA|IGNORADO)$", "S/N")
        .adicionar(r"^(X|0|-)+$", "S/N")
        // Substitui range de números pelo o primeiro número
        .adicionar(r"^(\d+)([,/-]\d+)+$", "$1")
        // Regexp adicional: string vazia => S/N
        .adicionar("^$", "S/N");

    padronizador.preparar();
    padronizador
}

// Em Rust, a constant é criada durante a compilação, então só posso chamar funções muito restritas
// quando uso `const`. Nesse caso,  como tenho uma construção complexa da struct `Padronizador`,
// tenho que usar static com inicialização Lazy (o LazyLock aqui previne condições de corrida).
static PADRONIZADOR_NUMEROS: LazyLock<Padronizador> = LazyLock::new(criar_padronizador_numeros);

/// Padroniza uma string representando números de logradouros.
///
/// # Exemplo
/// ```
/// use enderecobr_rs::padronizar_numeros;
/// assert_eq!(padronizar_numeros("0210"), "210");
/// assert_eq!(padronizar_numeros("001"), "1");
/// assert_eq!(padronizar_numeros("1"), "1");
/// assert_eq!(padronizar_numeros(""), "S/N");
/// assert_eq!(padronizar_numeros("S N"), "S/N");
/// assert_eq!(padronizar_numeros("S/N"), "S/N");
/// assert_eq!(padronizar_numeros("SN"), "S/N");
/// assert_eq!(padronizar_numeros("0180 0181"), "180 181");
/// ```
///
/// # Detalhes
/// Operações realizadas durante a padronização:
/// - remoção de espaços em branco antes e depois dos números e de espaços em branco em excesso entre números;
/// - remoção de zeros à esquerda;
/// - substituição de números vazios e de variações de SN (SN, S N, S.N., S./N., etc) por S/N.
///
/// Note que existe uma etapa de compilação das expressões regulares utilizadas,
/// logo a primeira execução desta função pode demorar um pouco a mais.
///
pub fn padronizar_numeros(valor: &str) -> String {
    // Forma de obter a variável lazy
    let padronizador = &*PADRONIZADOR_NUMEROS;
    padronizador.padronizar(valor)
}

/// Padroniza uma string representando números de logradouros para o formato numérico.
///
/// # Exemplo
/// ```
/// use enderecobr_rs::padronizar_numeros_para_int;
/// assert_eq!(padronizar_numeros_para_int("0210"), Some(210));
/// assert_eq!(padronizar_numeros_para_int("001"), Some(1));
/// assert_eq!(padronizar_numeros_para_int("1"), Some(1));
/// assert_eq!(padronizar_numeros_para_int("0"), None);
/// assert_eq!(padronizar_numeros_para_int(""), None);
/// assert_eq!(padronizar_numeros_para_int("S/N"), None);
/// assert_eq!(padronizar_numeros_para_int("0180 0181"), None);
/// ```
///
/// # Detalhes
/// Operações realizadas durante a padronização:
/// - remoção de espaços em branco antes e depois dos números e de espaços em branco em excesso entre números;
/// - remoção de zeros à esquerda;
/// - substituição de números vazios e de variações de SN (SN, S N, S.N., S./N., etc) por None
///
/// Note que existe uma etapa de compilação das expressões regulares utilizadas,
/// logo a primeira execução desta função pode demorar um pouco a mais.
///
pub fn padronizar_numeros_para_int(valor: &str) -> Option<u32> {
    let valor_padronizado = padronizar_numeros(valor);
    if valor_padronizado == "S/N" {
        return None;
    }
    match valor_padronizado.parse::<u32>() {
        Ok(0) | Err(_) => None,
        Ok(numero) => Some(numero),
    }
}

/// Padroniza um tipo numérico para uma representação textual de números de logradouros.
/// Substitui todos valores menores ou iguais a zero para "S/N" e trunca valores decimais.
///
/// # Exemplo
/// ```
/// use enderecobr_rs::padronizar_numeros_para_string;
/// assert_eq!(padronizar_numeros_para_string(210), "210");
/// assert_eq!(padronizar_numeros_para_string(1.1), "1");
/// assert_eq!(padronizar_numeros_para_string(0), "S/N");
/// assert_eq!(padronizar_numeros_para_string(-11), "S/N");
/// ```
///
pub fn padronizar_numeros_para_string<T: Into<f64> + Copy>(valor: T) -> String {
    // A ideia da função é aceitar qualquer tipo que possa ser convertido para double,
    // e então processar de forma unificada.
    let val: f64 = valor.into();
    if val <= 0.0 {
        "S/N".to_string()
    } else {
        val.trunc().to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn padroniza_corretamente_numero() {
        assert_eq!(padronizar_numeros_para_string(0), "S/N");
        assert_eq!(padronizar_numeros_para_string(1), "1");
        assert_eq!(padronizar_numeros_para_string(1.1), "1");
    }

    #[test]
    fn padroniza_corretamente_character() {
        let test_cases = [
            (" 1 ", "1"),
            ("s/n", "S/N"),
            ("NÚMERO", "S/N"),
            ("0001", "1"),
            ("01 02", "1 2"),
            ("20.100", "20100"),
            ("20.100 20.101", "20100 20101"),
            ("1.028", "1028"), // mistura dos dois casos acima - issue #37 (https://github.com/ipeaGIT/enderecobr/issues/37)
            ("SN", "S/N"),
            ("SNº", "S/N"),
            ("S N", "S/N"),
            ("S Nº", "S/N"),
            ("S.N.", "S/N"),
            ("S.Nº.", "S/N"),
            ("S. N.", "S/N"),
            ("S. Nº.", "S/N"),
            ("S/N", "S/N"),
            ("S/Nº", "S/N"),
            ("S./N.", "S/N"),
            ("S./Nº.", "S/N"),
            ("SEM NUMERO", "S/N"),
            ("X", "S/N"),
            ("XX", "S/N"),
            ("0", "S/N"),
            ("00", "S/N"),
            ("-", "S/N"),
            ("--", "S/N"),
            ("", "S/N"),
        ];

        for (input, expected) in test_cases {
            assert_eq!(padronizar_numeros(input), expected);
        }
    }

    #[test]
    fn test_padronizar_numeros_para_int() {
        let casos = [
            (" 1 ", Some(1)),
            ("s/n", None),
            ("NÚMERO", None),
            ("0001", Some(1)),
            ("01 02", None),
            ("20.100", Some(20100)),
            ("20.100 20.101", None),
            ("1.028", Some(1028)),
            ("SN", None),
            ("SNº", None),
            ("S N", None),
            ("S Nº", None),
            ("S.N.", None),
            ("S.Nº.", None),
            ("S. N.", None),
            ("S. Nº.", None),
            ("S/N", None),
            ("S/Nº", None),
            ("S./N.", None),
            ("S./Nº.", None),
            ("S./N. S N", None),
            ("SEM NUMERO", None),
            ("X", None),
            ("XX", None),
            ("0", None),
            ("00", None),
            ("-", None),
            ("--", None),
            ("", None),
        ];

        for (entrada, esperado) in casos {
            assert_eq!(padronizar_numeros_para_int(entrada), esperado);
        }
    }
}
