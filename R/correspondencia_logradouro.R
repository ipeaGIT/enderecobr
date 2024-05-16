#' Correspondência entre os campos de logradouro e tipo de logradouro e suas
#' colunas
#'
#' Cria um vetor de caracteres que especifica as colunas que representam os
#' campos de logradouro e tipo de logradouro em um dataframe.
#'
#' @param tipo_de_logradouro O nome da coluna que representa o tipo de
#'   logradouro no dataframe de endereços.
#' @param logradouro O nome da coluna que representa o logradouro no dataframe
#'   de endereços.
#'
#' @return Um vetor nomeado de caracteres, cujos nomes são `tipo_de_logradouro`
#'   e `logradouro` e os valores as respectivas colunas que os descrevem no
#'   dataframe de endereços.
#'
#' @examples
#' correspondencia_logradouro(
#'   tipo_de_logradouro = "tipo_de_logradouro",
#'   logradouro = "logradouro"
#' )
#'
#' @export
correspondencia_logradouro <- function(tipo_de_logradouro, logradouro) {
  col <- checkmate::makeAssertCollection()
  checkmate::assert_string(tipo_de_logradouro, add = col)
  checkmate::assert_string(logradouro, add = col)
  checkmate::reportAssertions(col)

  vetor_correspondencia <- c(
    tipo_de_logradouro = tipo_de_logradouro,
    logradouro = logradouro
  )

  return(vetor_correspondencia)
}
