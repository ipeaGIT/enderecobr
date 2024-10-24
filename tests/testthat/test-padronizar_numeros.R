tester <- function(numeros = "01") padronizar_numeros(numeros)

test_that("da erro com inputs != de caracteres e numeros", {
  expect_error(tester(as.factor(22290140)))
})

test_that("lida com vetores vazios corretamente", {
  expect_equal(tester(character(0)), character(0))
  expect_equal(tester(integer(0)), character(0))
  expect_equal(tester(numeric(0)), character(0))
})

test_that("padroniza corretamente - numero", {
  gabarito <- tibble::tribble(
    ~original,   ~padronizado_esperado,
    1,           "1",
    1.1,         "1",
    NA_integer_, "S/N",
    NA_real_,    "S/N"
  )

  expect_equal(tester(gabarito$original), gabarito$padronizado_esperado)
})

test_that("padroniza corretamente - caracter", {
  gabarito <- tibble::tribble(
    ~original,     ~padronizado_esperado,
    " 1 ",           "1",
    "s/n",           "S/N",
    "NÚMERO",        "NUMERO",

    "0001",          "1",
    "01 02",         "1 2",

    "20.100",        "20100",
    "20.100 20.101", "20100 20101",

    "SN",            "S/N",
    "SNº",           "S/N",
    "S N",           "S/N",
    "S Nº",          "S/N",
    "S.N.",          "S/N",
    "S.Nº.",         "S/N",
    "S. N.",         "S/N",
    "S. Nº.",        "S/N",
    "S/N",           "S/N",
    "S/Nº",          "S/N",
    "S./N.",         "S/N",
    "S./Nº.",        "S/N",
    "S./N. S N",     "S/N S/N",
    "SEM NUMERO",    "S/N",
    "X",             "S/N",
    "XX",            "S/N",
    "0",             "S/N",
    "00",            "S/N",
    "-",             "S/N",
    "--",            "S/N",

    "",              "S/N",
    NA_character_,   "S/N"
  )

  expect_equal(tester(gabarito$original), gabarito$padronizado_esperado)
})
