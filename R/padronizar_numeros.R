#' Padronizar números de logradouros
#'
#' Padroniza um vetor de caracteres ou números representando números de
#' logradouros. Veja a seção *Detalhes* para mais informações sobre a
#' padronização.
#'
#' @param numeros Um vetor de caracteres ou números. Os números de logradouro a
#'   serem padronizados.
#'
#' @return Um vetor de caracteres com os números de logradouros padronizados.
#'
#' @section Detalhes:
#' Operações realizadas durante a padronização:
#'
#' - conversão para caracter, se o input for numérico;
#' - remoção de espaços em branco antes e depois dos números e de espaços em
#' branco em excesso entre números;
#' - remoção de zeros à esquerda;
#' - substituição de números vazios e de variações de SN (SN, S N, S.N., S./N.,
#' etc) por S/N.
#'
#' @examples
#' numeros <- c("0210", "001", "1", "", "S N", "S/N", "SN", "0180  0181")
#' padronizar_numeros(numeros)
#'
#' numeros <- c(210, 1, 10000, NA)
#' padronizar_numeros(numeros)
#'
#' @export
padronizar_numeros <- function(numeros) {
  checkmate::assert(
    checkmate::check_character(numeros),
    checkmate::check_numeric(numeros),
    combine = "or"
  )

  if (is.numeric(numeros)) {
    numeros_na <- which(is.na(numeros))

    numeros_padrao <- formatC(numeros, format = "d")
    numeros_padrao[numeros_na] <- "S/N"

    return(numeros_padrao)
  }

  # alguns numeros podem vir vazios ou como NAs, fazendo com que as operacoes
  # abaixo nao convertam seus valores adequadamente. nesses casos, identificamos
  # seus indices para manualmente imputar "S/N" ao final

  numeros_padrao <- stringr::str_squish(numeros)
  numeros_padrao <- toupper(numeros_padrao)
  numeros_padrao <- stringi::stri_trans_general(numeros_padrao, "Latin-ASCII")
  numeros_padrao <- stringr::str_replace_all(
    numeros_padrao,
    c(
      r"{(?<!\.)\b0+(\d+)\b}" = "\\1", # 015 -> 15, 00001 -> 1, 0180 0181 -> 180 181, mas não 1.028 -> 1.28

      r"{(\d+)\.(\d{3})}" = "\\1\\2", # separador de milhar

      r"{S\.?( |\/)?N(O|\u00BA)?\.?}" = "S/N", # SN ou S.N. ou S N ou .... -> S/N
      r"{SEM NUMERO}" = "S/N",
      r"{^(X|0|-)+$}" = "S/N"
    )
  )

  numeros_padrao[is.na(numeros_padrao) | numeros_padrao == ""] <- "S/N"

  return(numeros_padrao)
}
