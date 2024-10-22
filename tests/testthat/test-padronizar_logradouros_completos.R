enderecos <- data.frame(
  id = 1,
  tipo = "r",
  logradouro = "ns sra da piedade",
  numero = 20
)

tester <- function(enderecos = get("enderecos", envir = parent.frame()),
                   campos_do_logradouro = correspondencia_logradouro(
                     tipo_de_logradouro = "tipo",
                     nome_do_logradouro = "logradouro",
                     numero = "numero"
                   ),
                   manter_cols_extras = TRUE,
                   checar_tipos = FALSE) {
  padronizar_logradouros_completos(
    enderecos,
    campos_do_logradouro,
    manter_cols_extras,
    checar_tipos
  )
}

test_that("da erro com inputs incorretos", {
  expect_error(tester(as.list(enderecos)))

  expect_error(tester(campos_do_logradouro = c(nome_do_logradouro = 1)))
  expect_error(tester(campos_do_logradouro = c(oie = "logradouro")))
  expect_error(tester(campos_do_logradouro = c(nome_do_logradouro = "oie")))

  expect_error(tester(manter_cols_extras = 1))
  expect_error(tester(manter_cols_extras = NA))
  expect_error(tester(manter_cols_extras = c(TRUE, TRUE)))

  expect_error(tester(checar_tipos = 1))
  expect_error(tester(checar_tipos = NA))
  expect_error(tester(checar_tipos = c(TRUE, TRUE)))
})

test_that("da erro quando nome do logradouro nao eh especificado", {
  expect_snapshot(
    tester(
      campos_do_logradouro = correspondencia_logradouro(
        tipo_de_logradouro = "tipo",
        numero = "numero"
      )
    ),
    error = TRUE,
    cnd_class = TRUE
  )
})

test_that("printa mensagens de progresso quando verboso", {
  rlang::local_options(endereco_padrao.verbose = "verbose")

  # os tempos de execução variam entre execuções, então precisamos removê-los do
  # snapshot. caso contrário, o snapshot consideraria que as mensagens mudaram

  # com os 3 campos
  expect_snapshot(
    res <- tester(),
    transform = function(x) sub("\\[\\d+.*\\]", "[xxx ms]", x)
  )

  # com tipo e nome
  expect_snapshot(
    res <- tester(
      campos_do_logradouro = correspondencia_logradouro(
        tipo_de_logradouro = "tipo",
        nome_do_logradouro = "logradouro"
      )
    ),
    transform = function(x) sub("\\[\\d+.*\\]", "[xxx ms]", x)
  )

  # com tipo e nome quando verifica duplicatas
  expect_snapshot(
    res <- tester(
      campos_do_logradouro = correspondencia_logradouro(
        tipo_de_logradouro = "tipo",
        nome_do_logradouro = "logradouro"
      ),
      checar_tipos = TRUE
    ),
    transform = function(x) sub("\\[\\d+.*\\]", "[xxx ms]", x)
  )

  # com nome e numero
  expect_snapshot(
    res <- tester(
      campos_do_logradouro = correspondencia_logradouro(
        nome_do_logradouro = "logradouro",
        numero = "numero"
      )
    ),
    transform = function(x) sub("\\[\\d+.*\\]", "[xxx ms]", x)
  )
})

test_that("retorna logradouros completos padronizados", {
  # com os 3 campos
  expect_identical(
    tester(),
    data.table::data.table(
      id = 1,
      tipo = "r",
      logradouro = "ns sra da piedade",
      numero = 20,
      logradouro_completo_padr = "RUA NOSSA SENHORA DA PIEDADE 20"
    )
  )

  # com tipo e nome
  expect_identical(
    tester(
      campos_do_logradouro = correspondencia_logradouro(
        tipo_de_logradouro = "tipo",
        nome_do_logradouro = "logradouro"
      )
    ),
    data.table::data.table(
      id = 1,
      tipo = "r",
      logradouro = "ns sra da piedade",
      numero = 20,
      logradouro_completo_padr = "RUA NOSSA SENHORA DA PIEDADE"
    )
  )

  # com nome e numero
  expect_identical(
    tester(
      campos_do_logradouro = correspondencia_logradouro(
        nome_do_logradouro = "logradouro",
        numero = "numero"
      )
    ),
    data.table::data.table(
      id = 1,
      tipo = "r",
      logradouro = "ns sra da piedade",
      numero = 20,
      logradouro_completo_padr = "NOSSA SENHORA DA PIEDADE 20"
    )
  )
})

test_that("respeita manter_cols_extras", {
  # colunas mantidas
  expect_identical(
    names(tester(manter_cols_extras = TRUE)),
    c("id", "tipo", "logradouro", "numero", "logradouro_completo_padr")
  )

  # colunas dropadas, todos os campos sendo usados
  expect_identical(
    names(tester(manter_cols_extras = FALSE)),
    c("tipo", "logradouro", "numero", "logradouro_completo_padr")
  )

  # colunas dropadas, potenciais campos nao sendo usados
  expect_identical(
    names(
      tester(
        campos_do_logradouro = correspondencia_logradouro(
          nome_do_logradouro = "logradouro",
          numero = "numero"
        ),
        manter_cols_extras = FALSE
      )
    ),
    c("logradouro", "numero", "logradouro_completo_padr")
  )
})

test_that("checa duplicatas entre tipos e nomes quando checar_tipos=TRUE", {
  ends <- data.frame(tipo = "r", logradouro = "r ns sra da piedade")

  expect_identical(
    tester(
      ends,
      campos_do_logradouro = correspondencia_logradouro(
        tipo_de_logradouro = "tipo",
        nome_do_logradouro = "logradouro"
      ),
      checar_tipos = FALSE
    ),
    data.table::data.table(
      tipo = "r",
      logradouro = "r ns sra da piedade",
      logradouro_completo_padr = "RUA RUA NOSSA SENHORA DA PIEDADE"
    )
  )

  expect_identical(
    tester(
      ends,
      campos_do_logradouro = correspondencia_logradouro(
        tipo_de_logradouro = "tipo",
        nome_do_logradouro = "logradouro"
      ),
      checar_tipos = TRUE
    ),
    data.table::data.table(
      tipo = "r",
      logradouro = "r ns sra da piedade",
      logradouro_completo_padr = "RUA NOSSA SENHORA DA PIEDADE"
    )
  )
})
