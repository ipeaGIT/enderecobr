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
#' @param combinar_logradouro Um logical. Se os campos que descrevem o
#'   logradouro (tipo, nome e número, por exemplo) devem ser combinados em um
#'   único campo de logradouro completo. Nesse caso, o parâmetro `logradouro` da
#'   `correspondencia_campos()` deve ser interpretado como o nome do logradouro.
#'   Por padrão, `FALSE`.
#'
#' @return Um dataframe com colunas adicionais, representando os campos de
#'   endereço padronizados.
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
#' padronizar_enderecos(enderecos, campos, combinar_logradouro = TRUE)
#'
#' @export
padronizar_enderecos <- function(
  enderecos,
  campos_do_endereco = correspondencia_campos(),
  manter_cols_extras = TRUE,
  combinar_logradouro = FALSE
) {
  checkmate::assert_data_frame(enderecos)
  checkmate::assert_logical(manter_cols_extras, any.missing = FALSE, len = 1)
  checkmate::assert_logical(combinar_logradouro, any.missing = FALSE, len = 1)
  checa_campos_do_endereco(campos_do_endereco, enderecos)

  enderecos_padrao <- data.table::as.data.table(enderecos)

  campos_padronizados <- paste0(campos_do_endereco, "_padr")
  names(campos_padronizados) <- names(campos_do_endereco)

  relacao_campos <- tibble::tribble(
    ~nome_campo,          ~nome_formatado,       ~funcao,
    "tipo_de_logradouro", "tipos de logradouro", padronizar_tipos_de_logradouro,
    "logradouro",         "logradouros",         padronizar_logradouros,
    "numero",             "n\u00fameros",        padronizar_numeros,
    "complemento",        "complementos",        padronizar_complementos,
    "cep",                "CEPs",                padronizar_ceps,
    "bairro",             "bairros",             padronizar_bairros,
    "municipio",          "munic\u00edpios",     padronizar_municipios,
    "estado",             "estados",             padronizar_estados
  )

  if (combinar_logradouro) {
    campos_do_logradouro <- c("tipo_de_logradouro", "logradouro", "numero")

    enderecos_padrao <- int_padronizar_ends_com_log_compl(
      enderecos_padrao,
      campos_do_endereco,
      campos_do_logradouro
    )

    relacao_campos <- subset(
      relacao_campos,
      ! nome_campo %in% campos_do_logradouro
    )
  }

  purrr::pwalk(
    relacao_campos,
    function(nome_campo, nome_formatado, funcao) {
      if (nome_campo %in% names(campos_do_endereco)) {
        col_orig <- campos_do_endereco[nome_campo]
        col_padr <- campos_padronizados[nome_campo]

        prog <- mensagem_progresso_endpad(
          paste0("Padronizando ", nome_formatado, "...")
        )

        enderecos_padrao[, c(col_padr) := funcao(enderecos[[col_orig]])]

        cli::cli_progress_done(id = prog)
      }
    }
  )

  campos_extras <- setdiff(names(enderecos), campos_do_endereco)

  if (!manter_cols_extras) {
    enderecos_padrao[, (campos_extras) := NULL]
  } else {
    data.table::setcolorder(enderecos_padrao, campos_extras)
  }

  return(enderecos_padrao[])
}

int_padronizar_ends_com_log_compl <- function(enderecos_padrao,
                                              campos_do_endereco,
                                              campos_do_logradouro) {
  campos_do_log_listados <- campos_do_endereco[
    which(names(campos_do_endereco) %in% campos_do_logradouro)
  ]

  if (length(campos_do_log_listados) > 0) {
    names(campos_do_log_listados) <- sub(
      "^logradouro$",
      "nome_do_logradouro",
      names(campos_do_log_listados)
    )

    enderecos_padrao <- padronizar_logradouros_completos(
      enderecos_padrao,
      campos_do_logradouro = campos_do_log_listados
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
      "tipo_de_logradouro",
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
