test_that("da erro com inputs != de caracteres", {
  expect_error(padronizar_complementos(12))
})

test_that("padroniza corretamente", {
  # complicado fazer um teste pra cada uma das regexs usadas. testando só um
  # basiquinho da manipulação, depois pensamos melhor se vale a pena fazer um
  # teste pra cada regex ou não

  expect_equal(padronizar_complementos("qd 5 bl 7"), "QUADRA 5 BLOCO 7")
  expect_equal(padronizar_complementos(NA_character_), NA_character_)
  expect_equal(padronizar_complementos(""), NA_character_)
})

test_that("lida com vetores vazios corretamente", {
  expect_equal(padronizar_complementos(character(0)), character(0))
})
