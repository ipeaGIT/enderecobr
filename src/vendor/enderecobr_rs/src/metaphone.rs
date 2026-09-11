use std::{borrow::Cow, sync::LazyLock};

use itertools::Itertools;

use crate::Padronizador;

pub fn criar_padronizador_metaphone() -> Padronizador {
    // Baseado na implementação em R de [https://github.com/ipeadata-lab/metaphonebr/blob/main/R/metaphonebr.R].

    let mut padronizador = Padronizador::default();

    padronizador
        .adicionar("[^A-Z ]+", "") // Remove non space nor letter characters
        // Remove silent 'H'  at the beggining of each word.
        // Example: "Helena Silva" -> "ELENA SILVA"
        .adicionar(r"\bH", "")
        // Resolve casos como THIAGO ou THOME
        .adicionar(r"\bTH", "T")
        // Phonetic Simplification: similar digraphs
        // Transforms common sounding digraphs to simplify their phonetic representation.
        .adicionar("LH", "1")
        .adicionar("NH", "3")
        // Transform "CH" in "X" ( /\u0283/ sound)
        .adicionar("CH", "X")
        // Transform "SH" in "X" (For foreign names with  /\u0283/ sound)
        .adicionar("SH", "X")
        // Transform "SCH" in "X" (som /\u0283/ or /sk/ , here opted simplifying X)
        .adicionar("SCH", "X") // Design decision, could vary to SK sound
        .adicionar("PH", "F")
        // Treat "SC" according to subsequent vowell
        // If "SC" followed by E or I, Transform in "S"
        // **Nota**: Regexp original é SC(?=[EI]), que usa um look-around, tive que adaptar.
        .adicionar("SC([EI])", "S$1")
        // If "SC" (ou XC) followed by A, O or U, Transform in "SK".
        // For consistency with 'C' becoming 'K', 'SC' becomes 'SK' here.
        // **Nota**: Regexp original é SC(?=[AOU]), que usa um look-around, tive que adaptar.
        .adicionar("SC([AOU])", "SK$1")
        // Treat "QU" digraph: remove silent U before e E or I
        // \u00dc treated in previous function
        // **Nota**: Regexp original é QU(?=[EI]), que usa um look-around, tive que adaptar.
        .adicionar("QU([EI])", "K$1") // QUE, QUI -> KE, KI
        // "QU" seguido de A, O -> K (simplified by design decision, generally U is pronounced in this case)
        .adicionar("QU", "K") // # QUanto -> KANTO (simplified)
        // Phonetic Simplification: Similar Consonants
        // Represent similar consonants with single representation.
        // Transform "\u00c7" in "S"
        // **NOTA**: o Ç é naturalmente removido no pré processamento,
        // tenho que tratar antes de chamar o padronizador.
        // .adicionar("Ç", "S")
        //
        // Letter C: if followed by E or I, Transform in "S"
        .adicionar("C([EI])", "S$1")
        // Letter C: if not followeb by E or I (and not part of CH, SC, previously treated), Transform in "K"
        // **Nota**: Adaptei a regex original `C(?![EIH])` para remover o look-around.
        // Supostamente, ele já tratava os casos problemáticos antes, mas preferi
        // forçar a substituição somente no caso das vogais A, O e U.
        .adicionar("C([AOU])", "K$1") // remaining C become K
        // Letter G: if followed by E or I, Transform in "J" (GUE/GUI previosuly treated)
        .adicionar("G([EI])", "J$1")
        // Remaining G  (followed by A, O, U or consonant) remains G, not K.
        // Q always becomes "K" (QU previously treated, but there may be isolated Q along fullnames)
        .adicionar("Q", "K")
        // Transform "W" in "V" (or "U" depending on pronounciation, design decision as V is common in BR)
        .adicionar("W", "V")
        // Transform "Y" in "I"
        .adicionar("Y", "I")
        // Transform all occurrences of "Z" in "S"
        .adicionar("Z", "S")
        // Convert N, M, or any nasalized sound (represented by vowel+M/N) in word ending.
        // Original Methaphone centers on consonants. Here, a simplification:
        // AO, AN, AM -> OM (or numerical code)
        // EN, in -> EM
        // IN, IM -> IM
        // ON, OM -> OM
        // UN, UM -> UM
        // Simplifiying for ending N becoming M (as in its original)
        .adicionar(r"N\b", "M")
        // Compress duplicated vowels sequences.
        // Exemplo: "REEBA" -> "REBA"
        // Remove adjacent duplicated letters.
        // **Nota**: No código original, ele comprime primeiro vogal e comprime depois qualquer sequencia
        // repetida de caracteres usando um backreference `([AEIOU])\\1+` e `(\\w)\\1+`.
        // Chamei uma só vez e com os valores hardcoded.
        // **Nota 2**: Não funcionaria de qualquer forma: tem que apagar as repetições adhoc mesmo.
        // .adicionar(r"(A{2,}|B{2,}|C{2,}|D{2,}|E{2,}|F{2,}|G{2,}|H{2,}|I{2,}|J{2,}|K{2,}|L{2,}|M{2,}|N{2,}|O{2,}|P{2,}|Q{2,}|R{2,}|S{2,}|T{2,}|U{2,}|V{2,}|W{2,}|X{2,}|Y{2,}|Z{2,}|0{2,}|1{2,}|2{2,}|3{2,}|4{2,}|5{2,}|6{2,}|7{2,}|8{2,}|9{2,})", "$1")
        // // **Nota**: No código original, ele chama isso no início e no fim, só precisaria no fim...
        .adicionar(r"\s{2,}", " "); // Ensures single spacing

    padronizador.preparar();
    padronizador
}

// Em Rust, a constant é criada durante a compilação, então só posso chamar funções muito restritas
// quando uso `const`. Nesse caso,  como tenho uma construção complexa da struct `Padronizador`,
// tenho que usar static com inicialização Lazy (o LazyLock aqui previne condições de corrida).
static PADRONIZADOR_METAPHONE: LazyLock<Padronizador> = LazyLock::new(criar_padronizador_metaphone);

/// Gera um código fonético (Metaphone-BR adaptado) para nomes em português.
///
/// Aplica uma série de transformações fonéticas a um nome para gerar um código
/// que representa sua pronúncia aproximada em português brasileiro.
/// O objetivo é agrupar nomes com sonoridade similar, mesmo que escritos de forma diferente.
///
/// # Detalhes do processo
///
/// O processamento inclui:
///
/// 1. Pré-processamento: remoção de acentos, números e conversão para maiúsculas.
/// 2. Remoção de letras silenciosas (H inicial).
/// 3. Simplificação de dígrafos comuns (LH, NH, CH, SC, QU, etc.).
/// 4. Simplificação de consoantes com sonoridade similar (C/K/S, G/J, Z/S, etc.).
/// 5. Tratamento de sons nasais finais.
/// 6. Remoção de vogais duplicadas.
/// 7. Remoção/compactação de espaços e letras duplicadas.
///
/// Esta é uma adaptação que não segue rigorosamente nenhum algoritmo Metaphone publicado,
/// mas foi inspirada neles, considerando o contexto do português brasileiro.
///
/// # Exemplo
///
/// ```
/// use enderecobr_rs::metaphone::metaphone;
/// assert_eq!(metaphone("João Silva"), "JOAO SILVA");
/// assert_eq!(metaphone("Marya"), "MARIA");
/// assert_eq!(metaphone("Helena"), "ELENA");
/// assert_eq!(metaphone("Philippe"), "FILIPE");
/// assert_eq!(metaphone("Chavier"), "XAVIER");
/// assert_eq!(metaphone("Maçã"), "MASA");
/// ```
///
pub fn metaphone(valor: &str) -> String {
    // **NOTA**: o Ç é naturalmente removido no pré processamento,
    // tenho que tratar antes de chamar o padronizador.

    let tem_cedilha = valor.chars().any(|c| "Çç".contains(c));
    // Evita criação desnecessária de nova string
    let _valor: Cow<_> = if tem_cedilha {
        Cow::Owned(
            valor
                .chars()
                .map(|c| match c {
                    'Ç' => 'S',
                    'ç' => 's',
                    c => c,
                })
                .collect::<String>(),
        )
    } else {
        Cow::Borrowed(valor)
    };

    // Forma de obter a variável lazy
    let padronizador = &*PADRONIZADOR_METAPHONE;

    padronizador
        .padronizar(&_valor)
        .chars()
        // Não consigo remover caracteres duplicados por regexp do Rust,
        // pela falta de backreferences, logo tenho que fazer na mão.
        .dedup()
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn padroniza_corretamente() {
        assert_eq!(metaphone("MARYA CHAVIER HELENA PHILIPE CALHEIROS FILHA MANHA CHICO SCHMIDT SCENA ESCOVA QUILO MAÇÃ maçã THIAGO"), "MARIA XAVIER ELENA FILIPE KA1EIROS FI1A MA3A XIKO SXMIDT SENA ESKOVA KILO MASA MASA TIAGO");
    }
}
