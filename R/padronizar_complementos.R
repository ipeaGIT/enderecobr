#' Padronizar complementos
#'
#' Padroniza um vetor de caracteres representando complementos de logradouros.
#' Veja a seção *Detalhes* para mais informações sobre a padronização.
#'
#' @param complementos Um vetor de caracteres. Os complementos a serem
#'   padronizados.
#'
#' @return Um vetor de caracteres com os complementos padronizados.
#'
#' @section Detalhes:
#' Operações realizadas durante a padronização:
#'
#' 1. remoção de espaços em branco antes e depois das strings e remoção de
#' espaços em excesso entre palavras;
#' 2. conversão de caracteres para caixa alta;
#' 3. remoção de acentos e caracteres não ASCII;
#' 4. adição de espaços após abreviações sinalizadas por pontos;
#' 5. substituição de abreviações pelos termos completos.
#'
#' @examples
#' complementos <- c("", "QD1 LT2 CS3", "APTO. 405")
#' padronizar_complementos(complementos)
#'
#' @export
padronizar_complementos <- function(complementos) {
  checkmate::assert_character(complementos)

  complementos_dedup <- unique(complementos)

  # alguns complementos podem vir vazios e devem permanecer vazios ao final.
  # identificamos o indice dos complementos vazios para "reesvazia-los" ao final,
  # ja que a sequencia de operacoes abaixo acabaria atribuindo um valor a eles

  indice_complemento_vazio <- which(is.na(complementos) | complementos == "")

  complementos_padrao_dedup <- stringr::str_squish(complementos_dedup)
  complementos_padrao_dedup <- toupper(complementos_padrao_dedup)
  complementos_padrao_dedup <- stringi::stri_trans_general(
    complementos_padrao_dedup,
    "Latin-ASCII"
  )

  complementos_padrao_dedup <- stringr::str_replace_all(
    complementos_padrao_dedup,
    c(
      # pontuacao
      r"{\.\.+}" = ".",          # remover pontos repetidos
      r"{(\d+)\.(\d{3})}" = "\\1\\2", # pontos usados como separador de milhares
      # r"{(\d+)\.(\d+)}" = "\\1,\\2", # pontos usados como separador de decimais (nao sei se esse vale, tem muitas poucas observacoes e ela sao meio ambiguas. no caso do cpf, por exemplo, tem so "BL 3.1 APTO 204", "KM 7.5", "2.2 BLOCO G" e "34.5KV" no primeiro milhao de observacoes)
      r"{\.([^ ])}" = "\\. \\1", # garantir que haja espaco depois do ponto
      r"{ - }" = " ",

      # localidades
      r"{\bAP(T(O|\u00BA)?|ART)?\.?(\d)}" = "APARTAMENTO \\3", # \u00BA = º, usado pro check não reclamar da presença de caracteres não-ascii
      r"{(\d)AP(T(O|\u00BA)?|ART(AMENTO)?)?\b\.?}" = "\\1 APARTAMENTO",
      r"{\bAP(T(O|\u00BA)?|ART)?\b\.?}" = "APARTAMENTO",
      r"{\bAPARTAMENTO\b: ?}" = "APARTAMENTO ",

      r"{\bBLC?\.?(\d)}" = "BLOCO \\1",
      r"{(\d)BLC?\b\.?}" = "\\1 BLOCO",
      r"{\bBLC?\b\.?}" = "BLOCO",
      r"{\bBLOCO\b: ?}" = "BLOCO ",

      r"{\bQD\.?(\d)}" = "QUADRA \\1",
      r"{(\d)QD\b\.?}" = "\\1 QUADRA",
      r"{\bQD\b\.?}" = "QUADRA",
      r"{\bQUADRA\b: ?}" = "QUADRA ",

      r"{\bLT\.?(\d)}" = "LOTE \\1",
      r"{(\d)LT\b\.?}" = "\\1 LOTE",
      r"{\bLT\b\.?}" = "LOTE",
      r"{\bLOTE\b: ?}" = "LOTE ",

      r"{\bCS\.?(\d)}" = "CASA \\1", # CSA?     o que quer dizer FDS? talvez FUNDOS
      r"{(\d)CS\b\.?}" = "\\1 CASA",
      r"{\bCS\b\.?}" = "CASA",
      r"{\bCASA\b: ?}" = "CASA ",

      r"{\bC(ON)?J\.?(\d)}" = "CONJUNTO \\2",
      r"{(\d)C(ON)?J\b\.?}" = "\\1 CONJUNTO",
      r"{\bC(ON)?J\b\.?}" = "CONJUNTO",
      r"{\bC(ON)?J\b: ?}" = "CONJUNTO "
    )
  )

  names(complementos_padrao_dedup) <- complementos_dedup
  complementos_padrao <- complementos_padrao_dedup[complementos]
  names(complementos_padrao) <- NULL

  complementos_padrao[indice_complemento_vazio] <- NA_character_

  return(complementos_padrao)
}
