test_that("da erro com inputs != de caracteres", {
  expect_error(padronizar_bairros(12))
})

test_that("padroniza corretamente", {
  # complicado fazer um teste pra cada uma das regexs usadas. testando só um
  # basiquinho da manipulação, depois pensamos melhor se vale a pena fazer um
  # teste pra cada regex ou não

  expect_equal(padronizar_bairros("JARDIM  BOTÂNICO"), "JARDIM BOTANICO")
  expect_equal(padronizar_bairros("jardim botanico"), "JARDIM BOTANICO")
  expect_equal(padronizar_bairros("jd..botanico"), "JARDIM BOTANICO")
  expect_equal(padronizar_bairros(NA_character_), "")
  expect_equal(padronizar_bairros(""), "")
})

test_that("lida com vetores vazios corretamente", {
  expect_equal(padronizar_bairros(character(0)), character(0))
})
