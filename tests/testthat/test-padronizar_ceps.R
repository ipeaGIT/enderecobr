test_that("da erro com inputs != de caracteres e numeros", {
  expect_error(padronizar_ceps(as.factor(22290140)))
})

test_that("da erro quando cep contem letra", {
  expect_snapshot_error(padronizar_ceps("botafogo"), class = "cep_com_letra")

  expect_snapshot_error(
    padronizar_ceps(c(NA, "oie", NA, "hehe")),
    class = "cep_com_letra"
  )

  expect_snapshot_error(padronizar_ceps(base::letters), class = "cep_com_letra")
})

test_that("da erro quando cep contem mais de 8 digitos", {
  expect_snapshot_error(
    padronizar_ceps(100000000),
    class = "cep_com_digitos_demais"
  )

  expect_error(padronizar_ceps("222290-140"), class = "cep_com_digitos_demais")

  expect_snapshot_error(
    padronizar_ceps(c(10000000, 100000000, 100000000)),
    class = "cep_com_digitos_demais"
  )

  expect_snapshot_error(
    padronizar_ceps(rep(100000000, 20)),
    class = "cep_com_digitos_demais"
  )
})

test_that("padroniza corretamente", {
  expect_equal(padronizar_ceps("22290-140"), "22290-140")
  expect_equal(padronizar_ceps("22290 140"), "22290-140")
  expect_equal(padronizar_ceps("22290- 140"), "22290-140")
  expect_equal(padronizar_ceps("22.290-140"), "22290-140")
  expect_equal(padronizar_ceps(22290140), "22290-140")
  expect_equal(padronizar_ceps(" 22290  140 "), "22290-140")
  expect_equal(padronizar_ceps("01000-000"), "01000-000")
  expect_equal(padronizar_ceps("1000000"), "01000-000")
  expect_equal(padronizar_ceps(" 1000000"), "01000-000")
  expect_equal(padronizar_ceps(1000000), "01000-000")
  expect_equal(padronizar_ceps(NA_character_), "")
  expect_equal(padronizar_ceps(NA_integer_), "")

  expect_equal(
    padronizar_ceps(c(22290140, 1000000)),
    c("22290-140", "01000-000")
  )
})

test_that("lida com vetores vazios corretamente", {
  expect_equal(padronizar_ceps(character(0)), character(0))
  expect_equal(padronizar_ceps(integer(0)), character(0))
  expect_equal(padronizar_ceps(numeric(0)), character(0))
})
