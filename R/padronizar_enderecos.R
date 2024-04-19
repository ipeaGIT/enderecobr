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
#' @param manter_cols_extras Um logical. Se colunas não especificadas em
#'   `campos_do_endereco` devem ser mantidas ou não (por exemplo, uma coluna de
#'   id do conjunto de dados sendo padronizado). Por padrão, `TRUE`.
#'
#' @return Um dataframe com os campos de endereço padronizados.
#'
#' @examples
#' enderecos <- data.frame(
#'   id = 1,
#'   logradouro = "r ns sra da piedade",
#'   nroLogradouro = 20,
#'   complemento = "qd 20",
#'   cep = 25220020,
#'   bairro = "jd botanico",
#'   codmun_dom = 3304557,
#'   uf_dom = "rj"
#' )
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
#' padronizar_enderecos(enderecos, campos)
#'
#' padronizar_enderecos(enderecos, campos, manter_cols_extras = FALSE)
#'
#' @export
padronizar_enderecos <- function(
  enderecos,
  campos_do_endereco = correspondencia_campos(),
  manter_cols_extras = TRUE
) {
  checkmate::assert_data_frame(enderecos)
  checkmate::assert_logical(manter_cols_extras, any.missing = FALSE, len = 1)
  checa_campos_do_endereco(campos_do_endereco, enderecos)

  enderecos_padrao <- data.table::as.data.table(enderecos)

  campos_extras <- setdiff(
    names(enderecos),
    c(campos_do_endereco, names(campos_do_endereco))
  )
  campos_finais <- if (manter_cols_extras) {
    c(campos_extras, names(campos_do_endereco))
  } else {
    names(campos_do_endereco)
  }

  if ("logradouro" %in% campos_finais) {
    enderecos_padrao[
      ,
      logradouro := padronizar_logradouros(
        enderecos[[campos_do_endereco["logradouro"]]]
      )
    ]
  }

  if ("numero" %in% campos_finais) {
    enderecos_padrao[
      ,
      numero := padronizar_numeros(
        enderecos[[campos_do_endereco["numero"]]]
      )
    ]
  }

  if ("complemento" %in% campos_finais) {
    enderecos_padrao[
      ,
      complemento := padronizar_complementos(
        enderecos[[campos_do_endereco["complemento"]]]
      )
    ]
  }

  if ("cep" %in% campos_finais) {
    enderecos_padrao[
      ,
      cep := padronizar_ceps(
        enderecos[[campos_do_endereco["cep"]]]
      )
    ]
  }

  if ("bairro" %in% campos_finais) {
    enderecos_padrao[
      ,
      bairro := padronizar_bairros(
        enderecos[[campos_do_endereco["bairro"]]]
      )
    ]
  }

  if ("municipio" %in% campos_finais) {
    enderecos_padrao[
      ,
      municipio := padronizar_municipios(
        enderecos[[campos_do_endereco["municipio"]]]
      )
    ]
  }

  if ("estado" %in% campos_finais) {
    enderecos_padrao[
      ,
      estado := padronizar_estados(
        enderecos[[campos_do_endereco["estado"]]]
      )
    ]
  }

  campos_a_remover <- setdiff(names(enderecos), campos_finais)
  enderecos_padrao[, (campos_a_remover) := NULL]

  if (manter_cols_extras) {
    data.table::setcolorder(enderecos_padrao, campos_extras)
  }

  return(enderecos_padrao[])
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
