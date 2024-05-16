tester <- function(tipo_de_logradouro = "tipo_de_logradouro",
                   logradouro = "logradouro") {
  correspondencia_logradouro(
    tipo_de_logradouro = tipo_de_logradouro,
    logradouro = logradouro
  )
}

test_that("da erro com inputs != de caracteres", {
  expect_error(tester(tipo_de_logradouro = 1))
  expect_error(tester(tipo_de_logradouro = c("oi", "ola")))
  expect_error(tester(logradouro = 1))
  expect_error(tester(logradouro = c("oi", "ola")))
})

test_that("retorna vetor de caracteres", {
  expect_identical(
    tester(),
    c(
      tipo_de_logradouro = "tipo_de_logradouro",
      logradouro = "logradouro"
    )
  )

  expect_identical(
    tester(tipo_de_logradouro = "oi", logradouro = "ola"),
    c(tipo_de_logradouro = "oi", logradouro = "ola")
  )
})
