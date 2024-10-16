test_that("da erro com inputs != de caracteres", {
  expect_error(correspondencia_campos(logradouro = 1))
  expect_error(correspondencia_campos(logradouro = c("oi", "ola")))
  expect_error(correspondencia_campos(numero = 1))
  expect_error(correspondencia_campos(numero = c("oi", "ola")))
  expect_error(correspondencia_campos(complemento = 1))
  expect_error(correspondencia_campos(complemento = c("oi", "ola")))
  expect_error(correspondencia_campos(cep = 1))
  expect_error(correspondencia_campos(cep = c("oi", "ola")))
  expect_error(correspondencia_campos(bairro = 1))
  expect_error(correspondencia_campos(bairro = c("oi", "ola")))
  expect_error(correspondencia_campos(municipio = 1))
  expect_error(correspondencia_campos(municipio = c("oi", "ola")))
  expect_error(correspondencia_campos(estado = 1))
  expect_error(correspondencia_campos(estado = c("oi", "ola")))
})

test_that("da erro quando todos os inputs sao nulos", {
  expect_snapshot_error(
    correspondencia_campos(),
    class = c("erro_endpad_correspondencia_nula", "erro_endpad")
  )
})

test_that("retorna vetor de caracteres", {
  expect_identical(
    correspondencia_campos(
      logradouro = "oi",
      numero = "ola",
      complemento = "hola",
      cep = "hi",
      bairro = "hello",
      municipio = "shalom",
      estado = "salaam"
    ),
    c(
      logradouro = "oi",
      numero = "ola",
      complemento = "hola",
      cep = "hi",
      bairro = "hello",
      municipio = "shalom",
      estado = "salaam"
    )
  )

  expect_identical(
    correspondencia_campos(logradouro = "oi", numero = "ola"),
    c(logradouro = "oi", numero = "ola")
  )
})
