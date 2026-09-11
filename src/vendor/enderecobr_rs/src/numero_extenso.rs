use std::{borrow::Cow, sync::LazyLock};

use regex::Regex;

const ATE_CEM: [&str; 101] = [
    "ZERO",
    "UM",
    "DOIS",
    "TRES",
    "QUATRO",
    "CINCO",
    "SEIS",
    "SETE",
    "OITO",
    "NOVE",
    "DEZ",
    "ONZE",
    "DOZE",
    "TREZE",
    "QUATORZE",
    "QUINZE",
    "DEZESSEIS",
    "DEZESSETE",
    "DEZOITO",
    "DEZENOVE",
    "VINTE",
    "VINTE E UM",
    "VINTE E DOIS",
    "VINTE E TRES",
    "VINTE E QUATRO",
    "VINTE E CINCO",
    "VINTE E SEIS",
    "VINTE E SETE",
    "VINTE E OITO",
    "VINTE E NOVE",
    "TRINTA",
    "TRINTA E UM",
    "TRINTA E DOIS",
    "TRINTA E TRES",
    "TRINTA E QUATRO",
    "TRINTA E CINCO",
    "TRINTA E SEIS",
    "TRINTA E SETE",
    "TRINTA E OITO",
    "TRINTA E NOVE",
    "QUARENTA",
    "QUARENTA E UM",
    "QUARENTA E DOIS",
    "QUARENTA E TRES",
    "QUARENTA E QUATRO",
    "QUARENTA E CINCO",
    "QUARENTA E SEIS",
    "QUARENTA E SETE",
    "QUARENTA E OITO",
    "QUARENTA E NOVE",
    "CINQUENTA",
    "CINQUENTA E UM",
    "CINQUENTA E DOIS",
    "CINQUENTA E TRES",
    "CINQUENTA E QUATRO",
    "CINQUENTA E CINCO",
    "CINQUENTA E SEIS",
    "CINQUENTA E SETE",
    "CINQUENTA E OITO",
    "CINQUENTA E NOVE",
    "SESSENTA",
    "SESSENTA E UM",
    "SESSENTA E DOIS",
    "SESSENTA E TRES",
    "SESSENTA E QUATRO",
    "SESSENTA E CINCO",
    "SESSENTA E SEIS",
    "SESSENTA E SETE",
    "SESSENTA E OITO",
    "SESSENTA E NOVE",
    "SETENTA",
    "SETENTA E UM",
    "SETENTA E DOIS",
    "SETENTA E TRES",
    "SETENTA E QUATRO",
    "SETENTA E CINCO",
    "SETENTA E SEIS",
    "SETENTA E SETE",
    "SETENTA E OITO",
    "SETENTA E NOVE",
    "OITENTA",
    "OITENTA E UM",
    "OITENTA E DOIS",
    "OITENTA E TRES",
    "OITENTA E QUATRO",
    "OITENTA E CINCO",
    "OITENTA E SEIS",
    "OITENTA E SETE",
    "OITENTA E OITO",
    "OITENTA E NOVE",
    "NOVENTA",
    "NOVENTA E UM",
    "NOVENTA E DOIS",
    "NOVENTA E TRES",
    "NOVENTA E QUATRO",
    "NOVENTA E CINCO",
    "NOVENTA E SEIS",
    "NOVENTA E SETE",
    "NOVENTA E OITO",
    "NOVENTA E NOVE",
    "CEM",
];

const CENTENAS: [&str; 10] = [
    "",
    "CENTO",
    "DUZENTOS",
    "TREZENTOS",
    "QUATROCENTOS",
    "QUINHENTOS",
    "SEISCENTOS",
    "SETECENTOS",
    "OITOCENTOS",
    "NOVECENTOS",
];

const ORDENS_GRANDEZA: [(&str, &str); 7] = [
    ("MIL", "MIL"),
    ("UM MILHAO", "MILHOES"),
    ("UM BILHAO", "BILHOES"), // Só i32 vai até aqui...
    ("UM TRILHAO", "TRILHOES"),
    ("UM QUADRILHAO", "QUADRILHOES"),
    ("UM QUINTILHAO", "QUINTILHOES"),
    ("UM SEXTILHAO", "SEXTILHOES"),
];

/// Converte sequências de dígitos em uma string para seus equivalentes por extenso em português.
///
/// A função percorre a string de entrada e, ao encontrar números inteiros (em formato ASCII),
/// os substitui pelo nome completo do número (ex: "2" → "dois"), utilizando a função `numero_por_extenso`.
///
/// # Notas
/// - Números muito grandes ou inválidos (ex: overflow no parse para `i32`) são deixados inalterados.
/// - Não trata número negativos ou decimais.
/// - Se a string de entrada não contém nenhum dígito ASCII, a função retorna imediatamente uma referência
///   emprestada (`Cow::Borrowed`) para evitar alocação.
///
/// # Exemplos
/// ```rust
/// use enderecobr_rs::numero_extenso::padronizar_numeros_por_extenso;
/// assert_eq!(padronizar_numeros_por_extenso("RUA 2"), "RUA DOIS");
/// assert_eq!(padronizar_numeros_por_extenso("RUA -2"), "RUA -DOIS");
/// assert_eq!(padronizar_numeros_por_extenso("RUA -2.2"), "RUA -DOIS.DOIS");
/// assert_eq!(padronizar_numeros_por_extenso("Sem números"), "Sem números");
/// ```
///
pub fn padronizar_numeros_por_extenso(texto: &str) -> Cow<'_, str> {
    // Retorna imediatamente a mesma referência de string
    // caso não existam números na string
    if !texto.as_bytes().iter().any(|c| c.is_ascii_digit()) {
        return Cow::Borrowed(texto);
    }

    let mut numero_atual = String::new();
    let mut resultado = String::with_capacity(texto.len() + 5);

    for caracter in texto.chars() {
        if caracter.is_ascii_digit() {
            // Achei um número, adiciono ele na minha string de números.
            numero_atual.push(caracter);
        } else {
            // Quando não é um número
            if !numero_atual.is_empty() {
                // Se existia um número na string, devo salvar ele por extenso...
                match numero_atual.parse::<i32>() {
                    Ok(n) => resultado.push_str(&numero_por_extenso(n)),
                    Err(_) => resultado.push_str(&numero_atual),
                }

                // ... E limpar número atual.
                numero_atual.clear();
            }
            // Salvo o carácter atual (não número) no resultado final
            resultado.push(caracter);
        }
    }

    // Finalizo salvando o número pendente.
    if !numero_atual.is_empty() {
        match numero_atual.parse::<i32>() {
            Ok(n) => resultado.push_str(&numero_por_extenso(n)),
            Err(_) => resultado.push_str(&numero_atual),
        }
    }

    // Retorno um resultado owned (borrow seria quando é só uma referência)
    Cow::Owned(resultado)
}

/// Converte um número inteiro para sua representação por extenso em português.
///
/// Retorna uma referência estática (`Cow::Borrowed`) quando possível (números até 100),
/// ou uma string alocada dinamicamente (`Cow::Owned`) para casos compostos (negativos, grandes números).
///
/// # Exemplos
///
/// ```
/// use enderecobr_rs::numero_extenso::numero_por_extenso;
/// assert_eq!(numero_por_extenso(0), "ZERO");
/// assert_eq!(numero_por_extenso(42), "QUARENTA E DOIS");
/// assert_eq!(numero_por_extenso(-1500), "MENOS MIL E QUINHENTOS");
/// assert_eq!(numero_por_extenso(2_001_000), "DOIS MILHOES E MIL");
/// ```
pub fn numero_por_extenso(n: i32) -> Cow<'static, str> {
    // Função auxiliar: converte números de 0 a 999
    // Retorna a referência estática para os casos até 100
    fn resolver_centenas(n: u32) -> Cow<'static, str> {
        // Se for menor que 100, usa a tabela ATE_CEM
        if let Some(valor) = ATE_CEM.get(n as usize) {
            return Cow::Borrowed(valor);
        }

        let centena = n / 100; // extrai a casa das centenas
        let dezenas = n % 100; // resto (dezenas e unidades)

        // Estimativa da média do tamanho final
        let mut resultado = String::with_capacity(10);

        if centena > 0 {
            if let Some(valor) = CENTENAS.get(centena as usize) {
                // Adiciona palavra da centena (ex: "DUZENTOS")
                resultado.push_str(valor);
            }
        }

        if centena > 0 && dezenas > 0 {
            // Espaço entre centena e dezenas, se ambas existirem
            resultado.push_str(" E ");
        }

        if dezenas > 0 {
            if let Some(valor) = ATE_CEM.get(dezenas as usize) {
                // Adiciona parte das dezenas (ex: "VINTE E CINCO")
                resultado.push_str(valor);
            }
        }

        Cow::Owned(resultado)
    }

    let num_abs = n.unsigned_abs();

    if (0..1000).contains(&num_abs) {
        // Caso base: número entre 0 e 999
        // Curiosamente esta é a forma "rustônica" de escrever isso,
        // segundo o clippy.
        return if n >= 0 {
            resolver_centenas(num_abs)
        } else {
            Cow::Owned(format!("MENOS {}", resolver_centenas(num_abs)))
        };
    }

    // Determina a maior ordem de grandeza
    // (ex: milhão → 6 dígitos → ilog10/3 = 2 ordens de grandeza)
    let maior_ordem_grandeza = num_abs.ilog10() / 3;

    let mut base = 10u32.pow(maior_ordem_grandeza * 3); // 1, 1_000, 1_000_000, etc.
    let mut valor_restante = num_abs;

    // Estimativa/chute do tamanho esperado da string
    let mut resultado = String::with_capacity(20);
    if n < 0 {
        // Começa com "MENOS" se o número for negativo
        resultado.push_str("MENOS");
    }

    // Processa do maior para o menor agrupamento de 3 dígitos
    for ordem_grandeza in (0..=maior_ordem_grandeza).rev() {
        // Se restar menos de 1000, processa diretamente e termina
        if valor_restante > 0 && valor_restante < 1000 {
            if !resultado.is_empty() {
                // Adiciono o E quando estou no "ultimo termo" do número,
                // seja dezenas ou centenas redondas (ex: QUINHENTOS).
                if valor_restante < 100 || valor_restante % 100 == 0 {
                    resultado.push_str(" E ");
                } else {
                    resultado.push(' ');
                }
            }
            resultado.push_str(&resolver_centenas(valor_restante));
            break;
        }

        let mais_significativo = valor_restante / base; // grupo atual (3 dígitos)
        valor_restante %= base; // valor restante que ainda falta processar
        base /= 1000; // Prepara base para a próxima iteração

        if mais_significativo == 0 {
            // pula grupos vazios (ex: 1_000_001 não menciona "ZERO MIL")
            continue;
        }

        if !resultado.is_empty() {
            // Adiciono o E quando estou no "ultimo termo" do número.
            if valor_restante == 0 {
                resultado.push_str(" E ");
            } else {
                // Adiciona espaço caso já tenha algo na string
                resultado.push(' ');
            }
        }

        // Se o grupo de 3 dígitos for diferente de 1, que já é resolvido
        // no vetor ORDENS_GRANDEZA, escreve o número desse grupo (ex: "DOIS")
        // para receber o sufixo no if abaixo (ex: "MIL")
        if mais_significativo != 1 {
            resultado.push_str(&resolver_centenas(mais_significativo));
            resultado.push(' ');
        }

        // Seleciona o sufixo singular ou plural baseado no valor do
        // grupo de 3 dígitos
        if let Some((singular, plural)) = ORDENS_GRANDEZA.get((ordem_grandeza - 1) as usize) {
            if mais_significativo == 1 {
                resultado.push_str(singular);
            } else {
                resultado.push_str(plural);
            }
        }
    }

    Cow::Owned(resultado)
}

// Em Rust, a constant é criada durante a compilação, então só posso chamar funções muito restritas
// quando uso `const`.
static REGEX_ROMANO: LazyLock<Regex> = LazyLock::new(criar_regex_romano);
static REGEX_ROMANO_TRIAGEM: LazyLock<Regex> = LazyLock::new(criar_regex_romano_triagem);

pub fn criar_regex_romano() -> Regex {
    // Aceita 3999, depois disso começa a usar um traço em cima, que não existe em ASCII.
    // Como essa regexp é só para validar o resultado da triagem, uso as âncoras
    // de inicio e fim para garantir que toda a string é válida.
    Regex::new(r"(?i)^M*(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})$")
        .expect("Regex romano inválida (bug interno)")
}

pub fn criar_regex_romano_triagem() -> Regex {
    Regex::new(r"(?i)\b[MDCLXVI]+\b").expect("Regex romano triagem inválida (bug interno)")
}

/// Substitui números romanos em um texto por suas representações por extenso (em palavras).
/// Apenas sequências que formam números romanos válidos (1–3999) são convertidas.
/// Evita alocação de Strings usando `Cow::Borrowed` se nenhuma substituição for feita.
///
/// # Exemplos
///
/// ```
/// use enderecobr_rs::numero_extenso::padronizar_numero_romano_por_extenso;
/// assert_eq!(padronizar_numero_romano_por_extenso("Capítulo IX"), "Capítulo NOVE");
/// assert_eq!(
///     padronizar_numero_romano_por_extenso("Séculos XV e XX"),
///     "Séculos QUINZE e VINTE"
/// );
/// assert_eq!(
///     padronizar_numero_romano_por_extenso("Rei João VI e Papa Bento XVI"),
///     "Rei João SEIS e Papa Bento DEZESSEIS"
/// );
/// ```
pub fn padronizar_numero_romano_por_extenso(valor: &str) -> Cow<'_, str> {
    let mut resultado_opt: Option<String> = None;
    let mut ultimo = 0usize;

    // Uso uma regexp de triagem porque o resultado ficou muito mais rápido no benchmark
    // do que quando se usa direto a regexp que só captura grupos válidos.
    for m in REGEX_ROMANO_TRIAGEM.find_iter(valor) {
        let inicio = m.start();
        let fim = m.end();
        let romano = m.as_str();

        // A triagem não captura string vazia, mas vou manter
        // porque tive problemas com isso.
        if inicio == fim || !REGEX_ROMANO.is_match(romano) {
            continue;
        }

        // Instancia a String apenas no primeiro match
        let trecho_atual = resultado_opt.get_or_insert_with(|| String::with_capacity(valor.len()));

        // Copia trecho antes do match
        let valor_antes_match = valor
            .get(ultimo..inicio)
            .expect("String deveria ter caracteres entre [ultimo, inicio]");

        trecho_atual.push_str(valor_antes_match);

        let n = romano_para_inteiro(romano);
        trecho_atual.push_str(numero_por_extenso(n).as_ref());

        ultimo = fim;
    }

    match resultado_opt {
        None => Cow::Borrowed(valor),
        Some(mut s) => {
            s.push_str(
                valor
                    .get(ultimo..)
                    .expect("String '{valor}' deveria ter caracteres após {ultimo}"),
            );
            Cow::Owned(s)
        }
    }
}

/// Converte um número romano em sua representação por extenso (número inteiro).
///
/// Aceita entradas em maiúsculas ou minúsculas. A conversão segue a regra padrão de números romanos,
/// onde símbolos menores à esquerda de maiores são subtraídos. Suporta valores de 1 a 3999.
///
/// # Exemplos
///
/// ```
/// use enderecobr_rs::numero_extenso::romano_para_inteiro;
/// assert_eq!(romano_para_inteiro("IX"), 9);
/// assert_eq!(romano_para_inteiro("xlII"), 42);
/// assert_eq!(romano_para_inteiro("MCMXC"), 1990);
/// assert_eq!(romano_para_inteiro("mmmcmxcix"), 3999);
/// ```
///
/// # Notas
///
/// - Caracteres inválidos são tratados como 0 e podem gerar resultados inesperados.
/// - Não valida se a sequência romana é gramaticalmente correta (ex: "IIII" retorna 4).
pub fn romano_para_inteiro(s: &str) -> i32 {
    let mut total = 0;
    let mut prev = 0;

    for c in s.chars().rev() {
        let atual: i32 = match c.to_ascii_uppercase() {
            'I' => 1,
            'V' => 5,
            'X' => 10,
            'L' => 50,
            'C' => 100,
            'D' => 500,
            'M' => 1000,
            _ => 0,
        };

        total += if atual < prev { -atual } else { atual };
        prev = atual;
    }

    total
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn testes_basicos() {
        assert_eq!(numero_por_extenso(0), "ZERO");
        assert_eq!(numero_por_extenso(1), "UM");
        assert_eq!(numero_por_extenso(10), "DEZ");
        assert_eq!(numero_por_extenso(15), "QUINZE");
        assert_eq!(numero_por_extenso(25), "VINTE E CINCO");
        assert_eq!(numero_por_extenso(100), "CEM");
        assert_eq!(numero_por_extenso(101), "CENTO E UM");
        assert_eq!(numero_por_extenso(200), "DUZENTOS");
        assert_eq!(numero_por_extenso(999), "NOVECENTOS E NOVENTA E NOVE");
    }

    #[test]
    fn testes_milhares() {
        assert_eq!(numero_por_extenso(1000), "MIL");
        assert_eq!(numero_por_extenso(1500), "MIL E QUINHENTOS");
        assert_eq!(numero_por_extenso(2001), "DOIS MIL E UM");
        assert_eq!(
            numero_por_extenso(12345),
            "DOZE MIL TREZENTOS E QUARENTA E CINCO"
        );
    }

    #[test]
    fn testes_milhoes() {
        // Casos básicos de milhões
        assert_eq!(numero_por_extenso(1_000_000), "UM MILHAO");
        assert_eq!(numero_por_extenso(2_000_000), "DOIS MILHOES");
        assert_eq!(numero_por_extenso(10_000_000), "DEZ MILHOES");
        assert_eq!(numero_por_extenso(11_000_000), "ONZE MILHOES");
        assert_eq!(numero_por_extenso(20_000_000), "VINTE MILHOES");
        assert_eq!(numero_por_extenso(99_000_000), "NOVENTA E NOVE MILHOES");

        // Combinados com milhares e unidades
        assert_eq!(
            numero_por_extenso(1_234_567),
            "UM MILHAO DUZENTOS E TRINTA E QUATRO MIL QUINHENTOS E SESSENTA E SETE"
        );
        assert_eq!(numero_por_extenso(2_001_001), "DOIS MILHOES MIL E UM");
        assert_eq!(
            numero_por_extenso(99_999_999),
            "NOVENTA E NOVE MILHOES NOVECENTOS E NOVENTA E NOVE MIL NOVECENTOS E NOVENTA E NOVE"
        );

        // Casos limites
        assert_eq!(numero_por_extenso(1_000_001), "UM MILHAO E UM");
        assert_eq!(numero_por_extenso(1_001_000), "UM MILHAO E MIL");
        assert_eq!(numero_por_extenso(1_000_100), "UM MILHAO E CEM");
    }

    #[test]
    fn testes_billhoes() {
        // Casos básicos de bilhões
        assert_eq!(numero_por_extenso(1_000_000_000), "UM BILHAO");
        assert_eq!(numero_por_extenso(2_000_000_000), "DOIS BILHOES");

        // Combinados com milhões, milhares e unidades
        assert_eq!(
        numero_por_extenso(1_234_567_890),
        "UM BILHAO DUZENTOS E TRINTA E QUATRO MILHOES QUINHENTOS E SESSENTA E SETE MIL OITOCENTOS E NOVENTA"
    );
        assert_eq!(
            numero_por_extenso(2_001_001_001),
            "DOIS BILHOES UM MILHAO MIL E UM"
        );

        // Casos limites
        assert_eq!(numero_por_extenso(1_000_000_001), "UM BILHAO E UM");
        assert_eq!(numero_por_extenso(1_001_000_000), "UM BILHAO E UM MILHAO");
        assert_eq!(numero_por_extenso(1_000_100_000), "UM BILHAO E CEM MIL");
        assert_eq!(numero_por_extenso(1_000_001_000), "UM BILHAO E MIL");
    }

    #[test]
    fn testes_negativos() {
        assert_eq!(numero_por_extenso(-1), "MENOS UM");
        assert_eq!(numero_por_extenso(-100), "MENOS CEM");
        assert_eq!(
            numero_por_extenso(-1234),
            "MENOS MIL DUZENTOS E TRINTA E QUATRO"
        );
    }

    #[test]
    fn testes_limites() {
        assert_eq!(numero_por_extenso(i32::MAX), "DOIS BILHOES CENTO E QUARENTA E SETE MILHOES QUATROCENTOS E OITENTA E TRES MIL SEISCENTOS E QUARENTA E SETE");
        assert_eq!(numero_por_extenso(i32::MIN), "MENOS DOIS BILHOES CENTO E QUARENTA E SETE MILHOES QUATROCENTOS E OITENTA E TRES MIL SEISCENTOS E QUARENTA E OITO");
    }

    #[test]
    fn test_basic() {
        assert_eq!(romano_para_inteiro("I"), 1);
        assert_eq!(romano_para_inteiro("III"), 3);
        assert_eq!(romano_para_inteiro("V"), 5);
        assert_eq!(romano_para_inteiro("X"), 10);
        assert_eq!(romano_para_inteiro("L"), 50);
        assert_eq!(romano_para_inteiro("C"), 100);
        assert_eq!(romano_para_inteiro("D"), 500);
        assert_eq!(romano_para_inteiro("M"), 1000);
    }

    #[test]
    fn test_subtractive_pairs() {
        assert_eq!(romano_para_inteiro("IV"), 4);
        assert_eq!(romano_para_inteiro("IX"), 9);
        assert_eq!(romano_para_inteiro("XL"), 40);
        assert_eq!(romano_para_inteiro("XC"), 90);
        assert_eq!(romano_para_inteiro("CD"), 400);
        assert_eq!(romano_para_inteiro("CM"), 900);
    }

    #[test]
    fn test_mixed() {
        assert_eq!(romano_para_inteiro("MCMXLIV"), 1944);
        assert_eq!(romano_para_inteiro("MMXXV"), 2025);
        assert_eq!(romano_para_inteiro("MCMLXXXIV"), 1984);
        assert_eq!(romano_para_inteiro("MMMCMXCIX"), 3999);
    }

    #[test]
    fn test_lowercase() {
        assert_eq!(romano_para_inteiro("mcmxliv"), 1944);
        assert_eq!(romano_para_inteiro("mmxxv"), 2025);
    }

    #[test]
    fn test_edge_cases() {
        assert_eq!(romano_para_inteiro("MXA"), 1010); // carácter inválido (A) ignorado
        assert_eq!(romano_para_inteiro(""), 0); // zerado mesmo
        assert_eq!(romano_para_inteiro("IIII"), 4); // sem validação
    }

    #[test]
    fn teste_numero_romano_extenso() {
        // Sem nenhum algarismo romano
        assert_eq!(padronizar_numero_romano_por_extenso("RUA AZUL"), "RUA AZUL");

        // Número com vários caracteres
        assert_eq!(
            padronizar_numero_romano_por_extenso("MMMDCCCLXXXVIII"),
            "TRES MIL OITOCENTOS E OITENTA E OITO"
        );

        // Pior caso
        assert_eq!(
            padronizar_numero_romano_por_extenso("Rua xiii de xi de MMXXV de maio, vixi"),
            "Rua TREZE de ONZE de DOIS MIL E VINTE E CINCO de maio, vixi"
        );
    }

    #[test]
    fn teste_padronizacao_string_por_extenso() {
        // Caso de borda
        assert_eq!(padronizar_numeros_por_extenso(""), "");

        // Caso sem número
        assert_eq!(padronizar_numeros_por_extenso("RUA AZUL"), "RUA AZUL");

        // Caso simples
        assert_eq!(
            padronizar_numeros_por_extenso("RUA 222"),
            "RUA DUZENTOS E VINTE E DOIS"
        );

        assert_eq!(
            padronizar_numeros_por_extenso("RUA 2 LOTE B"),
            "RUA DOIS LOTE B"
        );

        // Só número
        assert_eq!(padronizar_numeros_por_extenso("1001"), "MIL E UM");

        // Vários números na string
        assert_eq!(
            padronizar_numeros_por_extenso("RUA 222 NUMERO 14 APT 101"),
            "RUA DUZENTOS E VINTE E DOIS NUMERO QUATORZE APT CENTO E UM"
        );
    }
}
