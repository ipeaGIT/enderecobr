use std::{borrow::Cow, sync::LazyLock};

use crate::{normalizar, IdentificadorPadroes};

pub fn criar_identificador_dado_faltante() -> IdentificadorPadroes {
    let mut identificador = IdentificadorPadroes::default();
    identificador.adicionar(&[
        r"^(SI|NS|NI|NA)$".to_string(),
        r"^DESCON[^ ]*$".to_string(),
        r"^S(EM)? *INFO[^ ]*$".to_string(),
        r"^N(AO)? *(CONSTA|TEM|SEI)?$".to_string(),
        r"^N(AO)? *(POSSUI|LOCALIZ|ESPECIF|INFO|FORNEC|EXIST|PENS|LEMB|SAB)[^ ]*$".to_string(),
        r"^N(AO)? *SABE *INFO[^ ]*$".to_string(),
    ]);

    identificador
}

static IDENTIFICADOR: LazyLock<IdentificadorPadroes> =
    LazyLock::new(criar_identificador_dado_faltante);

/// Identifica se uma string representa um dado faltante.
///
/// # Exemplo
/// ```
/// use enderecobr_rs::is_dado_faltante;
/// assert_eq!(is_dado_faltante("SI"), true);
/// assert_eq!(is_dado_faltante("SEM INFORMAÇÃO"), true);
/// assert_eq!(is_dado_faltante("NA"), true);
/// assert_eq!(is_dado_faltante("N CONSTA"), true);
/// assert_eq!(is_dado_faltante("RUA B"), false);
/// ```
pub fn is_dado_faltante(valor: &str) -> bool {
    let identificador = &*IDENTIFICADOR;
    identificador.identificar(&normalizar(valor))
}

/// Retorna uma string vazia caso o input seja um dado faltante. Vide [`is_dado_faltante`].
pub fn zerar_dado_faltante<'a>(valor: &'a str) -> Cow<'a, str> {
    let identificador = &*IDENTIFICADOR;
    if identificador.identificar(valor) {
        Cow::Borrowed("")
    } else {
        Cow::Borrowed(valor)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn checagem_simples() {
        assert_eq!(zerar_dado_faltante("NAO POSSUI"), "");
        assert_eq!(zerar_dado_faltante("RUA A"), "RUA A");

        assert_eq!(is_dado_faltante("NAO POSSUI"), true);
        assert_eq!(is_dado_faltante("RUA A"), false);
        assert_eq!(is_dado_faltante("VL SILVANIA"), false);
    }
}
