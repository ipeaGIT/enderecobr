#' Correspondência entre os campos do endereço e as colunas que os descrevem
#'
#' Cria um vetor de caracteres que especifica as colunas que representam cada
#' campo de endereço em um dataframe.
#'
#' @param tipo_de_logradouro,logradouro,numero,complemento,cep,bairro,municipio,estado
#'   Uma string. O nome da coluna que representa o respectivo campo de endereço
#'   no dataframe. Pode ser `NULL`, no caso do campo não estar listado. Ao menos
#'   um dos campos deve receber um valor não nulo.
#'
#' @return Um vetor nomeado de caracteres, em que os nomes representam os campos
#'   do endereço e os valores as colunas que os descrevem no dataframe.
#'
#' @examples
#' enderecos <- data.frame(
#'   id = 1,
#'   tipo = "r",
#'   log = "ns sra da piedade",
#'   nroLogradouro = 20,
#'   compl = "qd 20",
#'   cep = 25220020,
#'   bairro = "jd botanico",
#'   codmun_dom = 3304557,
#'   uf_dom = "rj"
#' )
#'
#' # dado o dataframe acima, a seguinte chamada cria a correspondencia entre
#' # suas colunas e os campos
#' correspondencia_campos(
#'   tipo_de_logradouro = "tipo",
#'   logradouro = "log",
#'   numero = "nroLogradouro",
#'   complemento = "compl",
#'   cep = "cep",
#'   bairro = "bairro",
#'   municipio = "codmun_dom",
#'   estado = "uf_dom"
#' )
#'
#' @export
correspondencia_campos <- function(tipo_de_logradouro = NULL,
                                   logradouro = NULL,
                                   numero = NULL,
                                   complemento = NULL,
                                   cep = NULL,
                                   bairro = NULL,
                                   municipio = NULL,
                                   estado = NULL) {
  col <- checkmate::makeAssertCollection()
  checkmate::assert_string(tipo_de_logradouro, null.ok = TRUE, add = col)
  checkmate::assert_string(logradouro, null.ok = TRUE, add = col)
  checkmate::assert_string(numero, null.ok = TRUE, add = col)
  checkmate::assert_string(complemento, null.ok = TRUE, add = col)
  checkmate::assert_string(cep, null.ok = TRUE, add = col)
  checkmate::assert_string(bairro, null.ok = TRUE, add = col)
  checkmate::assert_string(municipio, null.ok = TRUE, add = col)
  checkmate::assert_string(estado, null.ok = TRUE, add = col)
  checkmate::reportAssertions(col)

  vetor_correspondencia <- c(
    tipo_de_logradouro = tipo_de_logradouro,
    logradouro = logradouro,
    numero = numero,
    complemento = complemento,
    cep = cep,
    bairro = bairro,
    municipio = municipio,
    estado = estado
  )

  if (is.null(vetor_correspondencia)) erro_correspondencia_nula()

  return(vetor_correspondencia)
}

erro_correspondencia_nula <- function() {
  erro_endpad(
    paste0(
      "Ao menos um dos argumentos da {.fn correspondencia_campos} ",
      "deve ser diferente de {.code NULL}."
    ),
    call = rlang::caller_env()
  )
}
