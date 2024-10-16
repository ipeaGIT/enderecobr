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
                   manter_cols_extras = TRUE) {
  padronizar_logradouros_completos(
    enderecos,
    campos_do_logradouro,
    manter_cols_extras
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
})

test_that("da erro quando apenas um campo eh especificado", {
  expect_snapshot_error(
    tester(
      campos_do_logradouro = correspondencia_logradouro(numero = "numero")
    ),
    class = c("erro_endpad_apenas_um_campo_presente", "erro_endpad")
  )
})

test_that("da erro quando nome do logradouro nao eh especificado", {
  expect_snapshot_error(
    tester(
      campos_do_logradouro = correspondencia_logradouro(
        tipo_de_logradouro = "tipo",
        numero = "numero"
      )
    ),
    class = c("erro_endpad_nome_do_logradouro_ausente", "erro_endpad")
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
