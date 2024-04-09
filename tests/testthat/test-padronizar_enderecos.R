enderecos <- data.frame(
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
                   )) {
  padronizar_enderecos(enderecos, campos_do_endereco)
}

test_that("da erro com inputs incorretos", {
  expect_error(tester(as.list(enderecos)))

  expect_error(tester(campos_do_endereco = c(logradouro = 1)))
  expect_error(tester(campos_do_endereco = c(oie = "logradouro")))
  expect_error(tester(campos_do_endereco = c(logradouro = "oie")))
})

test_that("retorna enderecos padronizados", {
  # as padronizacoes em si sao testadas em outros arquivos, aqui checamos apenas
  # se os valores estao de fato sendo padronizados ou nao
  expect_identical(
    tester(),
    data.table::data.table(
      logradouro = "RUA NOSSA SENHORA DA PIEDADE",
      numero = "20",
      complemento = "QUADRA 20",
      cep = "25220-020",
      bairro = "JARDIM BOTANICO",
      municipio = "RIO DE JANEIRO",
      estado = "RIO DE JANEIRO"
    )
  )
})
