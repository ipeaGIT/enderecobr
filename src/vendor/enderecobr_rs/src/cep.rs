// ====== Funções Públicas =======

/// Padroniza CEPs em formato numérico para uma string formatada.
///
/// Completa com zeros à esquerda, caso necessário, e retorna erro se o valor numérico
/// for maior do que o tamanho permitido para CEPs.
///
/// # Exemplo
/// ```
/// use enderecobr_rs::padronizar_cep_numerico;
/// let cep = padronizar_cep_numerico(123456);
/// assert_eq!(cep, Ok("00123-456".to_string()));
/// ```
///
pub fn padronizar_cep_numerico(valor: i32) -> Result<String, String> {
    if valor >= 99_999_999 {
        return Err("CEP com muitos dígitos".to_string());
    }
    Ok(format!("{:05}-{:03}", valor / 1000, valor % 1000))
}

/// Padroniza CEPs em formato textual para uma string formatada, retornando possíveis erros.
///
/// Esta função ignora quaisquer caracteres de pontuação, além de completar com zeros à esquerda quando necessário.
///
/// # Exemplo
/// ```
/// use enderecobr_rs::padronizar_cep;
/// let cep = padronizar_cep("12345-6");
/// assert_eq!(cep, Ok("00123-456".to_string()));
///
/// let cep_grande = padronizar_cep("123456789");
/// assert_eq!(cep_grande, Err("CEP com muitos dígitos".to_string()));
///
/// let cep_invalido = padronizar_cep("123456e");
/// assert_eq!(cep_invalido, Err("CEP com caracteres inválidos".to_string()));
/// ```
///
pub fn padronizar_cep(valor: &str) -> Result<String, String> {
    if valor
        .chars()
        .any(|c| !c.is_ascii_punctuation() && !c.is_numeric() && !c.is_whitespace())
    {
        return Err("CEP com caracteres inválidos".to_string());
    }

    if valor.trim().is_empty() {
        return Ok(String::new());
    }

    let valor_numerico: String = valor
        .bytes()
        .filter_map(|c| {
            if c.is_ascii_digit() {
                Some(c as char)
            } else {
                None
            }
        })
        .collect();

    if valor_numerico.len() > 8 {
        return Err("CEP com muitos dígitos".to_string());
    }

    // Padding na esquerda
    let mut cep = format!("{:0>8}", valor_numerico);
    cep.insert(5, '-'); // Garanto que não ocorre panic
    Ok(cep)
}

/// Padroniza CEPs em formato textual para uma string formatada, tentando corrigir possíveis erros.
///
/// Esta função ignora quaisquer caracteres não numéricos, além de remover números extras e completar com zeros à
/// esquerda quando necessário.
///
/// # Exemplo
/// ```
/// use enderecobr_rs::padronizar_cep_leniente;
/// let cep = padronizar_cep_leniente("a123b45  6");
/// assert_eq!(cep, "00123-456".to_string());
/// ```
///
pub fn padronizar_cep_leniente(valor: &str) -> String {
    if valor.is_empty() {
        return String::new();
    }

    let digitos: String = valor
        .bytes()
        .filter_map(|c| {
            if c.is_ascii_digit() {
                Some(c as char)
            } else {
                None
            }
        })
        .take(8)
        .collect();

    // Padding na esquerda
    let mut cep = format!("{:0>8}", digitos);
    cep.insert(5, '-');
    cep
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn erro_quando_cep_contem_letra() {
        let erro_esperado = Err("CEP com caracteres inválidos".to_string());

        assert_eq!(padronizar_cep("botafogo"), erro_esperado);
        assert_eq!(padronizar_cep("oie"), erro_esperado);
        assert_eq!(padronizar_cep("hehe"), erro_esperado);
    }

    #[test]
    fn erro_quando_cep_contem_mais_de_8_digitos() {
        let erro_esperado = Err("CEP com muitos dígitos".to_string());

        assert_eq!(padronizar_cep_numerico(100000000), erro_esperado);
        assert_eq!(padronizar_cep("222290-140"), erro_esperado);
    }

    #[test]
    fn padroniza_corretamente() {
        assert_eq!(padronizar_cep("22290-140").unwrap(), "22290-140");
        assert_eq!(padronizar_cep("22290 140").unwrap(), "22290-140");
        assert_eq!(padronizar_cep("22290- 140").unwrap(), "22290-140");
        assert_eq!(padronizar_cep("22.290-140").unwrap(), "22290-140");
        assert_eq!(padronizar_cep(" 22290  140 ").unwrap(), "22290-140");
        assert_eq!(padronizar_cep("01000-000").unwrap(), "01000-000");
        assert_eq!(padronizar_cep("1000000").unwrap(), "01000-000");
        assert_eq!(padronizar_cep(" 1000000").unwrap(), "01000-000");

        // Teste novo
        assert_eq!(padronizar_cep("   ").unwrap(), "");

        assert_eq!(padronizar_cep_numerico(22290140).unwrap(), "22290-140");
    }
    #[test]
    fn padroniza_cep_forma_leniente() {
        assert_eq!(padronizar_cep_leniente(""), "");
        assert_eq!(padronizar_cep_leniente("a123b45  6"), "00123-456");
    }
}
