test_that("da erro com inputs != de caracteres", {
  expect_error(padronizar_logradouros(12))
})

test_that("padroniza corretamente", {
  # complicado fazer um teste pra cada uma das regexs usadas. testando só um
  # basiquinho da manipulação, depois pensamos melhor se vale a pena fazer um
  # teste pra cada regex ou não

  expect_equal(padronizar_logradouros("r. gen.. glicério"), "RUA GENERAL GLICERIO")
  expect_equal(padronizar_logradouros(NA_character_), "")
})

test_that("lida com vetores vazios corretamente", {
  expect_equal(padronizar_logradouros(character(0)), character(0))
})
