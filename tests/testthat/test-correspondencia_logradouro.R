tester <- function(tipo_de_logradouro = NULL,
                   nome_do_logradouro = NULL,
                   numero = NULL) {
  correspondencia_logradouro(
    tipo_de_logradouro = tipo_de_logradouro,
    nome_do_logradouro = nome_do_logradouro,
    numero = numero
  )
}

test_that("da erro com inputs != de caracteres", {
  expect_error(tester(tipo_de_logradouro = 1))
  expect_error(tester(tipo_de_logradouro = c("oi", "ola")))
  expect_error(tester(nome_do_logradouro = 1))
  expect_error(tester(nome_do_logradouro = c("oi", "ola")))
  expect_error(tester(numero = 1))
  expect_error(tester(numero = c("oi", "ola")))
})

test_that("da erro quando todos os inputs sao nulos", {
  expect_snapshot_error(
    correspondencia_logradouro(),
    class = c("erro_endpad_correspondencia_logradouro_nula", "erro_endpad")
  )
})

test_that("retorna vetor de caracteres", {
  expect_identical(
    tester(
      tipo_de_logradouro = "tipo",
      nome_do_logradouro = "nome",
      numero = "numero"
    ),
    c(
      tipo_de_logradouro = "tipo",
      nome_do_logradouro = "nome",
      numero = "numero"
    )
  )

  expect_identical(
    tester(nome_do_logradouro = "ola"),
    c(nome_do_logradouro = "ola")
  )
})

