enderecos <- data.frame(
  id = 1,
  tipo = "r",
  log = "ns sra da piedade",
  numero = 20,
  complemento = "qd 20",
  cep = 25220020,
  bairro = "jd botanico",
  municipio = 3304557,
  estado = "rj"
)

tester <- function(enderecos = get("enderecos", envir = parent.frame()),
                   campos_do_endereco = correspondencia_campos(
                     tipo_de_logradouro = "tipo",
                     logradouro = "log",
                     numero = "numero",
                     complemento = "complemento",
                     cep = "cep",
                     bairro = "bairro",
                     municipio = "municipio",
                     estado = "estado"
                   ),
                   manter_cols_extras = TRUE,
                   combinar_logradouro = FALSE) {
  padronizar_enderecos(
    enderecos,
    campos_do_endereco,
    manter_cols_extras,
    combinar_logradouro
  )
}

test_that("da erro com inputs incorretos", {
  expect_error(tester(as.list(enderecos)))

  expect_error(tester(campos_do_endereco = c(logradouro = 1)))
  expect_error(tester(campos_do_endereco = c(oie = "logradouro")))
  expect_error(tester(campos_do_endereco = c(logradouro = "oie")))

  expect_error(tester(manter_cols_extras = 1))
  expect_error(tester(manter_cols_extras = NA))
  expect_error(tester(manter_cols_extras = c(TRUE, TRUE)))

  expect_error(tester(combinar_logradouro = 1))
  expect_error(tester(combinar_logradouro = NA))
  expect_error(tester(combinar_logradouro = c(TRUE, TRUE)))
})

test_that("funciona mas da warning quando colunas com nome padrao ja existem", {
  # testando com 1, 2 e 3 itens pra ver pluralização e separadores na mensagem

  ends <- data.frame(
    logradouro_padr = "r ns sra da piedade",
    numero_padr = 20,
    estado_padr = 23
  )

  expect_snapshot(
    res <- tester(ends, correspondencia_campos(logradouro = "logradouro_padr")),
    cnd_class = TRUE
  )
  expect_identical(
    res,
    data.table::data.table(
      numero_padr = 20,
      estado_padr = 23,
      logradouro_padr = "RUA NOSSA SENHORA DA PIEDADE"
    )
  )

  expect_snapshot(
    res <- tester(
      ends,
      correspondencia_campos(
        logradouro = "logradouro_padr",
        numero = "numero_padr"
      )
    ),
    cnd_class = TRUE
  )
  expect_identical(
    res,
    data.table::data.table(
      estado_padr = 23,
      logradouro_padr = "RUA NOSSA SENHORA DA PIEDADE",
      numero_padr = "20"
    )
  )

  expect_snapshot(
    res <- tester(
      ends,
      correspondencia_campos(
        logradouro = "logradouro_padr",
        numero = "numero_padr",
        estado = "estado_padr"
      )
    ),
    cnd_class = TRUE
  )
  expect_identical(
    res,
    data.table::data.table(
      logradouro_padr = "RUA NOSSA SENHORA DA PIEDADE",
      numero_padr = "20",
      estado_padr = "CEARA"
    )
  )
})

test_that("erro de nome do nome de log ausente eh atribuido a pad enderecos", {
  ends <- data.frame(tipo = "r", numero = 20)

  expect_snapshot(
    tester(
      ends,
      correspondencia_campos(tipo_de_logradouro = "tipo", numero = "numero"),
      combinar_logradouro = TRUE
    ),
    error = TRUE,
    cnd_class = TRUE
  )
})

test_that("printa mensagens de progresso quando verboso", {
  rlang::local_options(endereco_padrao.verbose = "verbose")

  # os tempos de execução variam entre execuções, então precisamos removê-los do
  # snapshot. caso contrário, o snapshot consideraria que as mensagens mudaram

  expect_snapshot(
    res <- tester(),
    transform = function(x) sub("\\[\\d+.*\\]", "[xxx ms]", x)
  )

  expect_snapshot(
    res <- tester(combinar_logradouro = TRUE),
    transform = function(x) sub("\\[\\d+.*\\]", "[xxx ms]", x)
  )
})

test_that("retorna enderecos padronizados", {
  # as padronizacoes em si sao testadas em outros arquivos, aqui checamos apenas
  # se os valores estao de fato sendo padronizados ou nao
  expect_identical(
    tester(),
    data.table::data.table(
      id = 1,
      tipo = "r",
      log = "ns sra da piedade",
      numero = 20,
      complemento = "qd 20",
      cep = 25220020,
      bairro = "jd botanico",
      municipio = 3304557,
      estado = "rj",
      tipo_de_logradouro_padr = "RUA",
      logradouro_padr = "NOSSA SENHORA DA PIEDADE",
      numero_padr = "20",
      complemento_padr = "QUADRA 20",
      cep_padr = "25220-020",
      bairro_padr = "JARDIM BOTANICO",
      municipio_padr = "RIO DE JANEIRO",
      estado_padr = "RIO DE JANEIRO"
    )
  )
})

test_that("respeita manter_cols_extras", {
  # as padronizacoes em si sao testadas em outros arquivos, aqui checamos apenas
  # se os valores estao de fato sendo padronizados ou nao
  expect_identical(
    names(tester(manter_cols_extras = TRUE)),
    c(
      "id",
      "tipo", "log", "numero", "complemento", "cep", "bairro", "municipio",
      "estado",
      "tipo_de_logradouro_padr", "logradouro_padr", "numero_padr",
      "complemento_padr", "cep_padr", "bairro_padr", "municipio_padr",
      "estado_padr"
    )
  )

  expect_identical(
    names(tester(manter_cols_extras = FALSE)),
    c(
      "tipo", "log", "numero", "complemento", "cep", "bairro", "municipio",
      "estado",
      "tipo_de_logradouro_padr", "logradouro_padr", "numero_padr",
      "complemento_padr", "cep_padr", "bairro_padr", "municipio_padr",
      "estado_padr"
    )
  )

  expect_identical(
    names(tester(manter_cols_extras = FALSE, combinar_logradouro = TRUE)),
    c(
      "tipo", "log", "numero", "complemento", "cep", "bairro", "municipio",
      "estado",
      "logradouro_completo_padr", "complemento_padr", "cep_padr", "bairro_padr",
      "municipio_padr", "estado_padr"
    )
  )
})

# issue #13 - https://github.com/ipeaGIT/enderecopadrao/issues/13
test_that("funciona qnd coluna existe mas nao eh pra ser padronizada", {
  ends <- data.frame(logradouro = "r ns sra da piedade", numero = 20)
  expect_identical(
    tester(ends, correspondencia_campos(logradouro = "logradouro")),
    data.table::data.table(
      numero = 20,
      logradouro = "r ns sra da piedade",
      logradouro_padr = "RUA NOSSA SENHORA DA PIEDADE"
    )
  )
})

test_that("combina colunas de logradouro quando pedido", {
  expect_identical(
    tester(combinar_logradouro = FALSE),
    data.table::data.table(
      id = 1,
      tipo = "r",
      log = "ns sra da piedade",
      numero = 20,
      complemento = "qd 20",
      cep = 25220020,
      bairro = "jd botanico",
      municipio = 3304557,
      estado = "rj",
      tipo_de_logradouro_padr = "RUA",
      logradouro_padr = "NOSSA SENHORA DA PIEDADE",
      numero_padr = "20",
      complemento_padr = "QUADRA 20",
      cep_padr = "25220-020",
      bairro_padr = "JARDIM BOTANICO",
      municipio_padr = "RIO DE JANEIRO",
      estado_padr = "RIO DE JANEIRO"
    )
  )

  expect_identical(
    tester(combinar_logradouro = TRUE),
    data.table::data.table(
      id = 1,
      tipo = "r",
      log = "ns sra da piedade",
      numero = 20,
      complemento = "qd 20",
      cep = 25220020,
      bairro = "jd botanico",
      municipio = 3304557,
      estado = "rj",
      logradouro_completo_padr = "RUA NOSSA SENHORA DA PIEDADE 20",
      complemento_padr = "QUADRA 20",
      cep_padr = "25220-020",
      bairro_padr = "JARDIM BOTANICO",
      municipio_padr = "RIO DE JANEIRO",
      estado_padr = "RIO DE JANEIRO"
    )
  )
})
