#' Correspondência entre os campos do logradouro completo e as colunas que os
#' descrevem
#'
#' Cria um vetor de caracteres que especifica as colunas que representam os
#' campos de logradouro (tipo, nome e número) em um dataframe de endereços.
#'
#' @param tipo_de_logradouro O nome da coluna que representa o tipo de
#'   logradouro no dataframe de endereços.
#' @param logradouro O nome da coluna que representa o nome do logradouro no
#'   dataframe de endereços.
#' @param numero O nome da coluna que representa o numero do logradouro no
#'   dataframe de endereços.
#'
#' @return Um vetor nomeado de caracteres, em que os nomes representam os campos
#'   do logradouro e os valores as colunas que os descrevem no dataframe.
#'
#' @examples
#' correspondencia_logradouro(
#'   tipo_de_logradouro = "tipo_de_logradouro",
#'   logradouro = "logradouro",
#'   numero = "numero"
#' )
#'
#' @export
correspondencia_logradouro <- function(tipo_de_logradouro, logradouro, numero) {
  col <- checkmate::makeAssertCollection()
  checkmate::assert_string(tipo_de_logradouro, add = col)
  checkmate::assert_string(logradouro, add = col)
  checkmate::assert_string(numero, add = col)
  checkmate::reportAssertions(col)

  vetor_correspondencia <- c(
    tipo_de_logradouro = tipo_de_logradouro,
    logradouro = logradouro,
    numero = numero
  )

  return(vetor_correspondencia)
}
