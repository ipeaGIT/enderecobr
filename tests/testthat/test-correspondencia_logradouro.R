tester <- function(tipo_de_logradouro = "tipo_de_logradouro",
                   logradouro = "logradouro",
                   numero = "numero") {
  correspondencia_logradouro(
    tipo_de_logradouro = tipo_de_logradouro,
    logradouro = logradouro,
    numero = numero
  )
}

test_that("da erro com inputs != de caracteres", {
  expect_error(tester(tipo_de_logradouro = 1))
  expect_error(tester(tipo_de_logradouro = c("oi", "ola")))
  expect_error(tester(logradouro = 1))
  expect_error(tester(logradouro = c("oi", "ola")))
  expect_error(tester(numero = 1))
  expect_error(tester(numero = c("oi", "ola")))
})

test_that("retorna vetor de caracteres", {
  expect_identical(
    tester(),
    c(
      tipo_de_logradouro = "tipo_de_logradouro",
      logradouro = "logradouro",
      numero = "numero"
    )
  )

  expect_identical(
    tester(tipo_de_logradouro = "oi", logradouro = "ola", numero = "hello"),
    c(tipo_de_logradouro = "oi", logradouro = "ola", numero = "hello")
  )
})
