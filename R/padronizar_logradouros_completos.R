#' Padronizar logradouros completos
#'
#' Padroniza o logradouro completo a partir de diversos campos (tipo de
#' logradouro, nome do logradouro e número), garantindo a consistência da
#' informação.
#'
#' @param enderecos Um dataframe. Os endereços a serem padronizados. Ao menos
#'   uma de suas colunas deve corresponder a um campo do logradouro.
#' @param campos_do_logradouro Um vetor nomeado de caracteres. A correspondência
#'   entre os campos a serem padronizados (nomes do vetor) e as colunas que os
#'   representam no dataframe (valores em si). a função
#'   `correspondencia_logradouro()` facilita a criação deste vetor, fazendo
#'   também algumas verificações do conteúdo imputado. caso deseje criar o vetor
#'   manualmente, note que seus nomes devem ser os mesmos nomes dos parâmetros
#'   da função `correspondencia_logradouro()`.
#' @param manter_cols_extras Um logical. Se colunas não especificadas em
#'   `campos_do_logradouro` devem ser mantidas no output ou não (por exemplo,
#'   uma coluna com a informação de bairro ou com o id do conjunto de dados
#'   sendo padronizado). Por padrão, `TRUE`.
#'
#' @return Caso `manter_cols_extras` seja `TRUE`, o mesmo dataframe de input,
#'   mas sem as colunas descrevendo o logradouro e com uma coluna padronizada
#'   adicional `logradouro_completo`. Caso `manter_cols_extras` seja `FALSE`, um
#'   dataframe de apenas uma coluna, `logradouro_completo`.
#'
#' @examples
#' enderecos <- data.frame(
#'   id = 1,
#'   tipoLogradouro = "r",
#'   logradouro = "ns sra da piedade",
#'   nroLogradouro = 20,
#'   complemento = "qd 20",
#'   cep = 25220020,
#'   bairro = "jd botanico",
#'   codmun_dom = 3304557,
#'   uf_dom = "rj"
#' )
#'
#' campos <- correspondencia_logradouro(
#'   tipo_de_logradouro = "tipoLogradouro",
#'   logradouro = "logradouro",
#'   numero = "nroLogradouro"
#' )
#'
#' padronizar_logradouros_completos(enderecos, campos)
#'
#' padronizar_logradouros_completos(
#'   enderecos,
#'   campos,
#'   manter_cols_extras = FALSE
#' )
#'
#' @export
padronizar_logradouros_completos <- function(
    enderecos,
    campos_do_logradouro = correspondencia_logradouro(),
    manter_cols_extras = TRUE
) {
  checkmate::assert_data_frame(enderecos)
  checkmate::assert_logical(manter_cols_extras, any.missing = FALSE, len = 1)
  checa_campos_do_logradouro(campos_do_logradouro, enderecos)

  enderecos_padrao <- data.table::as.data.table(enderecos)

  campos_extras <- setdiff(names(enderecos), campos_do_logradouro)
  campos_finais <- if (manter_cols_extras) {
    c(campos_extras, "logradouro_completo")
  } else {
    "logradouro_completo"
  }

  enderecos_padrao[
    ,
    .tmp_tipo_padrao := padronizar_tipos_de_logradouro(
      enderecos[[campos_do_logradouro["tipo_de_logradouro"]]]
    )
  ]
  enderecos_padrao[
    ,
    .tmp_log_padrao := padronizar_logradouros(
      enderecos[[campos_do_logradouro["logradouro"]]]
    )
  ]
  enderecos_padrao[
    ,
    .tmp_num_padrao := padronizar_numeros(
      enderecos[[campos_do_logradouro["numero"]]]
    )
  ]

  enderecos_padrao[
    ,
    logradouro_completo := data.table::fcase(
      is.na(.tmp_log_padrao), .tmp_num_padrao,
      is.na(.tmp_num_padrao), .tmp_log_padrao,
      !is.na(.tmp_log_padrao) & !is.na(.tmp_num_padrao), paste(.tmp_log_padrao, .tmp_num_padrao)
    )
  ]
  enderecos_padrao[
    ,
    logradouro_completo := data.table::fcase(
      is.na(.tmp_tipo_padrao), logradouro_completo,
      is.na(logradouro_completo), .tmp_tipo_padrao,
      !is.na(.tmp_tipo_padrao) & !is.na(logradouro_completo), paste(.tmp_tipo_padrao, logradouro_completo)
    )
  ]
  enderecos_padrao[
    ,
    c(".tmp_tipo_padrao", ".tmp_log_padrao", ".tmp_num_padrao") := NULL
  ]

  campos_a_remover <- setdiff(names(enderecos), campos_finais)
  enderecos_padrao[, (campos_a_remover) := NULL]

  if (manter_cols_extras) {
    data.table::setcolorder(enderecos_padrao, campos_extras)
  }

  return(enderecos_padrao[])
}

checa_campos_do_logradouro <- function(campos_do_logradouro, enderecos) {
  col <- checkmate::makeAssertCollection()
  checkmate::assert_character(
    campos_do_logradouro,
    any.missing = FALSE,
    add = col
  )
  checkmate::assert_names(
    names(campos_do_logradouro),
    type = "unique",
    subset.of = c("tipo_de_logradouro", "logradouro", "numero"),
    add = col
  )
  checkmate::assert_names(
    campos_do_logradouro,
    subset.of = names(enderecos),
    add = col
  )
  checkmate::reportAssertions(col)

  return(invisible(TRUE))
}

tipos_de_logradouro_possiveis <- c(
  "AREA", "ACESSO", "ACAMPAMENTO", "ACESSO LOCAL", "ADRO", "AREA ESPECIAL",
  "AEROPORTO", "ALAMEDA", "AVENIDA MARGINAL DIREITA",
  "AVENIDA MARGINAL ESQUERDA", "ANEL VIARIO", "ANTIGA ESTRADA", "ARTERIA",
  "ALTO", "ATALHO", "AREA VERDE", "AVENIDA", "AVENIDA CONTORNO",
  "AVENIDA MARGINAL", "AVENIDA VELHA", "BALNEARIO", "BECO", "BURACO",
  "BELVEDERE", "BLOCO", "BALAO", "BLOCOS", "BULEVAR", "BOSQUE", "BOULEVARD",
  "BAIXA", "CAIS", "CALCADA", "CAMINHO", "CANAL", "CHACARA", "CHAPADAO",
  "CICLOVIA", "CIRCULAR", "CONJUNTO", "CONJUNTO MUTIRAO", "COMPLEXO VIARIO",
  "COLONIA", "COMUNIDADE", "CONDOMINIO", "CORREDOR", "CAMPO", "CORREGO",
  "CONTORNO", "DESCIDA", "DESVIO", "DISTRITO", "ENTRE BLOCO",
  "ESTRADA INTERMUNICIPAL", "ENSEADA", "ENTRADA PARTICULAR", "ENTRE QUADRA",
  "ESCADA", "ESCADARIA", "ESTRADA ESTADUAL", "ESTRADA VICINAL",
  "ESTRADA DE LIGACAO", "ESTRADA MUNICIPAL", "ESPLANADA", "ESTRADA DE SERVIDAO",
  "ESTRADA", "ESTRADA VELHA", "ESTRADA ANTIGA", "ESTACAO", "ESTADIO",
  "ESTANCIA", "ESTRADA PARTICULAR", "ESTACIONAMENTO", "EVANGELICA", "ELEVADA",
  "EIXO INDUSTRIAL", "FAVELA", "FAZENDA", "FERROVIA", "FONTE", "FEIRA", "FORTE",
  "GALERIA", "GRANJA", "NUCLEO HABITACIONAL", "ILHA", "INDETERMINADO", "ILHOTA",
  "JARDIM", "JARDINETE", "LADEIRA", "LAGOA", "LAGO", "LOTEAMENTO", "LARGO",
  "LOTE", "MERCADO", "MARINA", "MODULO", "PROJECAO", "MORRO", "MONTE", "NUCLEO",
  "NUCLEO RURAL", "OUTEIRO", "PARALELA", "PASSEIO", "PATIO", "PRACA",
  "PRACA DE ESPORTES", "PARADA", "PARADOURO", "PONTA", "PRAIA", "PROLONGAMENTO",
  "PARQUE MUNICIPAL", "PARQUE", "PARQUE RESIDENCIAL", "PARALELA", "PASSAGEM",
  "PASSAGEM DE PEDESTRE", "PASSAGEM SUBTERRANEA", "PONTE", "PORTO", "QUADRA",
  "QUINTA", "QUINTAS", "RUA", "RUA INTEGRACAO", "RUA DE LIGACAO",
  "RUA PARTICULAR", "RUA VELHA", "RAMAL", "RECREIO", "RECANTO", "RETIRO",
  "RESIDENCIAL", "RETA", "RUELA", "RAMPA", "RODO ANEL", "RODOVIA", "ROTULA",
  "RUA DE PEDESTRE", "MARGEM", "RETORNO", "SEGUNDA AVENIDA", "SITIO",
  "SERVIDAO", "SETOR", "SUBIDA", "TRINCHEIRA", "TERMINAL", "TRECHO", "TREVO",
  "TUNEL", "TRAVESSA", "TRAVESSA PARTICULAR", "TRAVESSA VELHA", "UNIDADE",
  "VIA", "VIA COLETORA", "VIA LOCAL", "VIA DE ACESSO", "VALA", "VIA COSTEIRA",
  "VIADUTO", "VIA EXPRESSA", "VEREDA", "VIA ELEVADO", "VILA", "VIELA", "VALE",
  "VIA LITORANEA", "VIA DE PEDESTRE", "VARIANTE", "ZIGUE-ZAGUE"
)
