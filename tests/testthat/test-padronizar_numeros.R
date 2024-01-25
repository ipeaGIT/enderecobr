test_that("da erro com inputs != de caracteres e numeros", {
  expect_error(padronizar_numeros(as.factor(22290140)))
})

test_that("padroniza corretamente", {
  expect_equal(padronizar_numeros("00001"), "1")
  expect_equal(padronizar_numeros("0000"), "0")
  expect_equal(padronizar_numeros("01   02"), "1 2")
  expect_equal(padronizar_numeros(""), "S/N")
  expect_equal(padronizar_numeros("SN"), "S/N")
  expect_equal(padronizar_numeros("S N"), "S/N")
  expect_equal(padronizar_numeros("S.N."), "S/N")
  expect_equal(padronizar_numeros("S. N."), "S/N")
  expect_equal(padronizar_numeros("S/N"), "S/N")
  expect_equal(padronizar_numeros("S./N."), "S/N")
  expect_equal(padronizar_numeros("S./N. S N"), "S/N S/N")
  expect_equal(padronizar_numeros(NA_character_), "S/N")

  expect_equal(padronizar_numeros(1), "1")
  expect_equal(padronizar_numeros(NA_integer_), "S/N")
  expect_equal(padronizar_numeros(c(1, 2000, NA)), c("1", "2000", "S/N"))
})

test_that("lida com vetores vazios corretamente", {
  expect_equal(padronizar_numeros(character(0)), character(0))
  expect_equal(padronizar_numeros(integer(0)), character(0))
  expect_equal(padronizar_numeros(numeric(0)), character(0))
})
