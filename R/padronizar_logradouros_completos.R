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
#'   representam no dataframe (valores do vetor). A função
#'   `correspondencia_logradouro()` facilita a criação deste vetor, fazendo
#'   também algumas verificações do conteúdo imputado. Caso deseje criar o vetor
#'   manualmente, note que seus nomes devem ser os mesmos nomes dos parâmetros
#'   da função `correspondencia_logradouro()`.
#' @param manter_cols_extras Um logical. Se colunas não especificadas em
#'   `campos_do_logradouro` devem ser mantidas no output ou não (por exemplo,
#'   uma coluna com a informação de bairro ou com o id do conjunto de dados
#'   sendo padronizado). Por padrão, `TRUE`.
#' @param checar_tipos Um logical. Se a ocorrência de duplicatas entre os tipos
#'   e nomes dos logradouros deve ser verificada ao combiná-los (por exemplo,
#'   quando o tipo é descrito como "RUA" e o nome é descrito como "RUA
#'   BOTAFOGO"). Por padrão, `FALSE`.
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
#'   nome_do_logradouro = "logradouro",
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
#' enderecos <- data.frame(
#'   tipoLogradouro = "r",
#'   logradouro = "r ns sra da piedade",
#'   nroLogradouro = 20
#' )
#' padronizar_logradouros_completos(enderecos, campos, checar_tipos = TRUE)
#'
#' @export
padronizar_logradouros_completos <- function(
  enderecos,
  campos_do_logradouro = correspondencia_logradouro(),
  manter_cols_extras = TRUE,
  checar_tipos = FALSE
) {
  checkmate::assert_data_frame(enderecos)
  checkmate::assert_logical(manter_cols_extras, any.missing = FALSE, len = 1)
  checkmate::assert_logical(checar_tipos, any.missing = FALSE, len = 1)
  checa_campos_do_logradouro(campos_do_logradouro, enderecos)

  checa_se_nome_ausente(campos_do_logradouro)

  enderecos_padrao <- data.table::as.data.table(enderecos)

  # enderecos_padrao é alterado in-place nas funções a seguir, por isso não é
  # necessário atribuir seus resultados a nenhuma variável

  int_padronizar_nome(enderecos_padrao, campos_do_logradouro)

  if ("numero" %in% names(campos_do_logradouro)) {
    int_padronizar_numero(enderecos_padrao, campos_do_logradouro)
  }

  if ("tipo_de_logradouro" %in% names(campos_do_logradouro)) {
    int_padronizar_tipo(enderecos_padrao, campos_do_logradouro, checar_tipos)
  }

  data.table::setnames(
    enderecos_padrao,
    old = ".tmp_log_padrao",
    new = "logradouro_completo_padr"
  )

  if (!manter_cols_extras) {
    campos_extras <- setdiff(names(enderecos), campos_do_logradouro)
    enderecos_padrao[, (campos_extras) := NULL]
  }

  return(enderecos_padrao[])
}

int_padronizar_nome <- function(enderecos_padrao, campos_do_logradouro) {
  prog <- mensagem_progresso_endbr("Padronizando nomes dos logradouros...")

  enderecos_padrao[
    ,
    .tmp_log_padrao := padronizar_logradouros(
      enderecos_padrao[[campos_do_logradouro["nome_do_logradouro"]]]
    )
  ]

  cli::cli_progress_done(id = prog)
}

int_padronizar_numero <- function(enderecos_padrao, campos_do_logradouro) {
  prog <- mensagem_progresso_endbr("Padronizando n\u00fameros...")

  enderecos_padrao[
    ,
    .tmp_num_padrao := padronizar_numeros(
      enderecos_padrao[[campos_do_logradouro["numero"]]]
    )
  ]

  cli::cli_progress_done(id = prog)
  prog <- mensagem_progresso_endbr(
    "Trazendo n\u00fameros para o logradouro completo..."
  )

  enderecos_padrao[
    ,
    .tmp_log_padrao := data.table::fcase(
      is.na(.tmp_log_padrao), .tmp_num_padrao,
      is.na(.tmp_num_padrao), .tmp_log_padrao,
      !is.na(.tmp_log_padrao) & !is.na(.tmp_num_padrao), paste(.tmp_log_padrao, .tmp_num_padrao)
    )
  ]
  enderecos_padrao[, .tmp_num_padrao := NULL]

  cli::cli_progress_done(id = prog)
}

int_padronizar_tipo <- function(enderecos_padrao,
                                campos_do_logradouro,
                                checar_tipos) {
  prog <- mensagem_progresso_endbr("Padronizando tipos de logradouro...")

  enderecos_padrao[
    ,
    .tmp_tipo_padrao := padronizar_tipos_de_logradouro(
      enderecos_padrao[[campos_do_logradouro["tipo_de_logradouro"]]]
    )
  ]

  cli::cli_progress_done(id = prog)

  if (checar_tipos) {
    prog <- mensagem_progresso_endbr(
      "Verificando duplicatas entre o tipo e o nome do logradouro..."
    )

    enderecos_padrao[
      ,
      .prim_palav_logr := stringr::word(.tmp_log_padrao, start = 1)
    ]
    enderecos_padrao[
      ,
      .tmp_tipo_padrao := data.table::fifelse(
        .prim_palav_logr == .tmp_tipo_padrao,
        NA_character_,
        .tmp_tipo_padrao
      )
    ]
    enderecos_padrao[, .prim_palav_logr := NULL]

    cli::cli_progress_done(id = prog)
  }

  prog <- mensagem_progresso_endbr(
    "Trazendo tipos de logradouro para o logradouro completo..."
  )

  enderecos_padrao[
    ,
    .tmp_log_padrao := data.table::fcase(
      is.na(.tmp_tipo_padrao), .tmp_log_padrao,
      is.na(.tmp_log_padrao), .tmp_tipo_padrao,
      !is.na(.tmp_tipo_padrao) & !is.na(.tmp_log_padrao), paste(.tmp_tipo_padrao, .tmp_log_padrao)
    )
  ]
  enderecos_padrao[, .tmp_tipo_padrao := NULL]

  cli::cli_progress_done(id = prog)
}

# checks ------------------------------------------------------------------

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
    subset.of = c("tipo_de_logradouro", "nome_do_logradouro", "numero"),
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

checa_se_nome_ausente <- function(campos_do_logradouro) {
  if (! "nome_do_logradouro" %in% names(campos_do_logradouro)) {
    erro_nome_do_logradouro_ausente()
  }
}

# erros -------------------------------------------------------------------

erro_nome_do_logradouro_ausente <- function() {
  # a padronizar_logradouros_completos() pode tanto ser chamada individualmente
  # ou como parte da função padronizar_enderecos(), quando combinar_logradouro é
  # TRUE. nesse caso, precisamos que o erro aponte pra chamada da
  # padronizar_enderecos(), já que o usuário não sabe que a
  # logradouros_completos é chamda internamente. pra isso, verificamos as
  # chamadas feitas na stack e, caso seja feita pela função interna usada na
  # padronizar_enderecos(), mudamos o caller_env do erro

  n_caller_env <- 2

  chamada_upstream <- tryCatch(sys.call(-3), error = function(cnd) NULL)
  if (!is.null(chamada_upstream)) {
    funcao_upstream <- as.name(chamada_upstream[[1]])
    if (funcao_upstream == "int_padronizar_ends_com_log_compl") {
      n_caller_env <- 4
    }
  }

  erro_endbr(
    c(
      paste0(
        "N\u00e3o \u00e9 poss\u00edvel fazer uma padroniza\u00e7\u00e3o de ",
        "logradouro completo sem o nome do logradouro."
      ),
      "i" = paste0(
        "Por favor informe uma coluna com a informa\u00e7\u00e3o de nome do ",
        "logradouro."
      )
    ),
    call = rlang::caller_env(n = n_caller_env)
  )
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
