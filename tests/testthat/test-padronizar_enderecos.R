enderecos <- data.frame(
  id = 1,
  logradouro = "r ns sra da piedade",
  numero = 20,
  complemento = "qd 20",
  cep = 25220020,
  bairro = "jd botanico",
  municipio = 3304557,
  estado = "rj"
)

tester <- function(enderecos = get("enderecos", envir = parent.frame()),
                   campos_do_endereco = correspondencia_campos(
                     logradouro = "logradouro",
                     numero = "numero",
                     complemento = "complemento",
                     cep = "cep",
                     bairro = "bairro",
                     municipio = "municipio",
                     estado = "estado"
                   ),
                   manter_cols_extras = TRUE) {
  padronizar_enderecos(enderecos, campos_do_endereco, manter_cols_extras)
}

test_that("da erro com inputs incorretos", {
  expect_error(tester(as.list(enderecos)))

  expect_error(tester(campos_do_endereco = c(logradouro = 1)))
  expect_error(tester(campos_do_endereco = c(oie = "logradouro")))
  expect_error(tester(campos_do_endereco = c(logradouro = "oie")))

  expect_error(tester(manter_cols_extras = 1))
  expect_error(tester(manter_cols_extras = NA))
  expect_error(tester(manter_cols_extras = c(TRUE, TRUE)))
})

test_that("retorna enderecos padronizados", {
  # as padronizacoes em si sao testadas em outros arquivos, aqui checamos apenas
  # se os valores estao de fato sendo padronizados ou nao
  expect_identical(
    tester(),
    data.table::data.table(
      id = 1,
      logradouro = "r ns sra da piedade",
      numero = 20,
      complemento = "qd 20",
      cep = 25220020,
      bairro = "jd botanico",
      municipio = 3304557,
      estado = "rj",
      logradouro_padr = "RUA NOSSA SENHORA DA PIEDADE",
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
      "logradouro", "numero", "complemento", "cep", "bairro", "municipio",
      "estado",
      "logradouro_padr", "numero_padr", "complemento_padr", "cep_padr",
      "bairro_padr", "municipio_padr", "estado_padr"
    )
  )

  expect_identical(
    names(tester(manter_cols_extras = FALSE)),
    c(
      "logradouro", "numero", "complemento", "cep", "bairro", "municipio",
      "estado",
      "logradouro_padr", "numero_padr", "complemento_padr", "cep_padr",
      "bairro_padr", "municipio_padr", "estado_padr"
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
