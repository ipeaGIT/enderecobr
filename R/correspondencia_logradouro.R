#' Correspondência entre os campos do logradouro completo e as colunas que os
#' descrevem
#'
#' Cria um vetor de caracteres que especifica as colunas que representam os
#' campos de logradouro (tipo, nome e número) em um dataframe de endereços.
#'
#' @param tipo_de_logradouro O nome da coluna que representa o tipo de
#'   logradouro no dataframe de endereços.
#' @param nome_do_logradouro O nome da coluna que representa o nome do
#'   logradouro no dataframe de endereços.
#' @param numero O nome da coluna que representa o numero do logradouro no
#'   dataframe de endereços.
#'
#' @return Um vetor nomeado de caracteres, em que os nomes representam os campos
#'   do logradouro e os valores as colunas que os descrevem no dataframe.
#'
#' @examples
#' correspondencia_logradouro(
#'   tipo_de_logradouro = "tipo_de_logradouro",
#'   nome_do_logradouro = "logradouro",
#'   numero = "numero"
#' )
#'
#' @export
correspondencia_logradouro <- function(tipo_de_logradouro = NULL,
                                       nome_do_logradouro = NULL,
                                       numero = NULL) {
  col <- checkmate::makeAssertCollection()
  checkmate::assert_string(tipo_de_logradouro, null.ok = TRUE, add = col)
  checkmate::assert_string(nome_do_logradouro, null.ok = TRUE, add = col)
  checkmate::assert_string(numero, null.ok = TRUE, add = col)
  checkmate::reportAssertions(col)

  vetor_correspondencia <- c(
    tipo_de_logradouro = tipo_de_logradouro,
    nome_do_logradouro = nome_do_logradouro,
    numero = numero
  )

  if (is.null(vetor_correspondencia)) erro_correspondencia_logradouro_nula()

  return(vetor_correspondencia)
}

erro_correspondencia_logradouro_nula <- function() {
  erro_endpad(
    paste0(
      "Ao menos um dos argumentos da {.fn correspondencia_logradouro} ",
      "deve ser diferente de {.code NULL}."
    ),
    call = rlang::caller_env()
  )
}
