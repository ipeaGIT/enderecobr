#' Padronizar endereços
#'
#' Padroniza um dataframe contendo diversos campos de um endereço.
#'
#' @param enderecos Um dataframe. Os endereços a serem padronizados. Cada uma de
#'   suas colunas deve corresponder a um campo do endereço (e.g. logradouro,
#'   cidade, bairro, etc).
#' @param campos_do_endereco Um vetor nomeado de caracteres. A correspondência
#'   entre os campos a serem padronizados (nomes do vetor) e as colunas que os
#'   representam no dataframe (valores em si). A função
#'   `correspondencia_campos()` facilita a criação deste vetor, fazendo também
#'   algumas verificações do conteúdo imputado. Argumentos dessa função com
#'   valor `NULL` são ignorados, e ao menos um valor diferente de nulo deve ser
#'   fornecido. Caso deseje criar o vetor manualmente, note que seus nomes devem
#'   ser os mesmos nomes dos parâmetros da função `correspondencia_campos()`.
#'
#' @return Um dataframe com os campos de endereço padronizados.
#'
#' @examples
#' path <- file.path(
#'   Sys.getenv("RESTRICTED_DATA_PATH"),
#'   "B_CADASTRO/CPF/20230816_cpf.csv"
#' )
#' cpf <- data.table::fread(path, nrows = 1000)
#'
#' campos <- correspondencia_campos(
#'   logradouro = "logradouro",
#'   numero = "nroLogradouro",
#'   complemento = "complemento",
#'   cep = "cep",
#'   bairro = "bairro",
#'   municipio = "codmun_dom",
#'   estado = "uf_dom"
#' )
#'
#' enderecos_padronizados <- padronizar_enderecos(cpf, campos)
#'
#' @export
padronizar_enderecos <- function(
  enderecos,
  campos_do_endereco = correspondencia_campos()
) {
  checkmate::assert_data_frame(enderecos)
  checa_campos_do_endereco(campos_do_endereco, enderecos)

  campos_presentes <- names(campos_do_endereco)[!is.null(campos_do_endereco)]

  enderecos_padrao <- data.table::data.table()
  enderecos_padrao[
    ,
    (names(campos_do_endereco)) := character(nrow(enderecos))
  ]

  if ("logradouro" %in% campos_presentes) {
    enderecos_padrao$logradouro <- padronizar_logradouros(
      enderecos[[campos_do_endereco["logradouro"]]]
    )
  }

  if ("numero" %in% campos_presentes) {
    enderecos_padrao$numero <- padronizar_numeros(
      enderecos[[campos_do_endereco["numero"]]]
    )
  }

  if ("complemento" %in% campos_presentes) {
    enderecos_padrao$complemento <- padronizar_complementos(
      enderecos[[campos_do_endereco["complemento"]]]
    )
  }

  if ("cep" %in% campos_presentes) {
    enderecos_padrao$cep <- padronizar_ceps(
      enderecos[[campos_do_endereco["cep"]]]
    )
  }

  if ("bairro" %in% campos_presentes) {
    enderecos_padrao$bairro <- padronizar_bairros(
      enderecos[[campos_do_endereco["bairro"]]]
    )
  }

  if ("municipio" %in% campos_presentes) {
    enderecos_padrao$municipio <- padronizar_municipios(
      enderecos[[campos_do_endereco["municipio"]]]
    )
  }

  if ("estado" %in% campos_presentes) {
    enderecos_padrao$estado <- padronizar_estados(
      enderecos[[campos_do_endereco["estado"]]]
    )
  }

  return(enderecos_padrao)
}

checa_campos_do_endereco <- function(campos_do_endereco, enderecos) {
  col <- checkmate::makeAssertCollection()
  checkmate::assert_character(
    campos_do_endereco,
    any.missing = FALSE,
    add = col
  )
  checkmate::assert_names(
    names(campos_do_endereco),
    type = "unique",
    subset.of = c(
      "logradouro",
      "numero",
      "complemento",
      "cep",
      "bairro",
      "municipio",
      "estado"
    ),
    add = col
  )
  checkmate::assert_names(
    campos_do_endereco,
    subset.of = names(enderecos),
    add = col
  )
  checkmate::reportAssertions(col)

  return(invisible(TRUE))
}
