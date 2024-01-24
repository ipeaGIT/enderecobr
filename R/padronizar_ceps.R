#' Padronizar CEPs
#'
#' Padroniza um vetor de CEPs. Veja a seção *Detalhes* para mais informações
#' sobre a padronização.
#'
#' @param ceps Um vetor de caracteres ou números. Os CEPs a serem padronizados.
#'
#' @return Um vetor de caracteres com os CEPs padronizados.
#'
#' @section Detalhes:
#' Operações realizadas durante a padronização:
#'
#' 1. conversão para caracter, se o input for numérico;
#' 2. adição de zeros à esquerda, se o input contiver menos de 8 dígitos;
#' 3. remoção de espaços em branco, pontos e vírgulas;
#' 4. adição de traço separando o radical (5 primeiros dígitos) do sufixo (3
#' últimos digitos).
#'
#' @examples
#' ceps <- c("22290-140", "22.290-140", "22290 140", "22290140")
#' padronizar_ceps(ceps)
#'
#' ceps <- c(22290140, 1000000, NA)
#' padronizar_ceps(ceps)
#'
#' @export
padronizar_ceps <- function(ceps) {
  checkmate::assert(
    checkmate::check_character(ceps),
    checkmate::check_numeric(ceps),
    combine = "or"
  )

  # alguns ceps podem vir vazios e devem permanecer vazios ao final. nesse caso,
  # a chamada da str_pad() abaixo faz com que esses ceps virem '00000000'. para
  # evitar que o resultado contenha esses valores, identificamos o indice dos
  # ceps vazios para ao final "reesvazia-los"

  indice_cep_vazio <- which(ceps == "" | is.na(ceps))

  ceps_padrao <- if (is.numeric(ceps)) {
    formatC(ceps, width = 8, format = "d", flag = 0)
  } else {
    ceps
  }

  ceps_padrao <- stringr::str_pad(ceps_padrao, width = 8, pad = "0")
  ceps_padrao <- stringr::str_replace_all(
    ceps_padrao,
    c(
      "\\.|,| " = "",
      "(\\d{5})(\\d{3})" = "\\1-\\2"
    )
  )

  ceps_padrao[indice_cep_vazio] <- ""

  return(ceps_padrao)
}
