test_that("da erro com inputs != de caracteres e estados", {
  expect_error(padronizar_estados(as.factor(21)))
})

test_that("padroniza corretamente", {
  expect_equal(padronizar_estados("21"), "MARANHAO")
  expect_equal(padronizar_estados("021"), "MARANHAO")
  expect_equal(padronizar_estados(" 21 "), "MARANHAO")
  expect_equal(padronizar_estados("ma"), "MARANHAO")
  expect_equal(padronizar_estados(NA_character_), NA_character_)
  expect_equal(padronizar_estados(""), NA_character_)

  expect_equal(padronizar_estados(21), "MARANHAO")
  expect_equal(padronizar_estados(NA_integer_), NA_character_)
  expect_equal(padronizar_estados(c(21, NA)), c("MARANHAO", NA_character_))

  expect_equal(padronizar_estados("MARANHÃO"), "MARANHAO")
})

test_that("lida com vetores vazios corretamente", {
  expect_equal(padronizar_estados(character(0)), character(0))
  expect_equal(padronizar_estados(integer(0)), character(0))
  expect_equal(padronizar_estados(numeric(0)), character(0))
})

# issue #26 - https://github.com/ipeaGIT/enderecobr/issues/26
test_that("não recicla valores do vetor de estados original", {
  estados <- c(rep("RIO DE JANEIRO", 2), "ACRE")

  resultado <- padronizar_estados(estados)
  expect_false(identical(resultado, rep("RIO DE JANEIRO", 3)))
  expect_equal(resultado, c(rep("RIO DE JANEIRO", 2), "ACRE"))
})
