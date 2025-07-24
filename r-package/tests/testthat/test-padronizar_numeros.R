tester <- function(numeros = "01", formato = "character") {
  padronizar_numeros(numeros, formato)
}

test_that("da erro com inputs incorretos", {
  expect_error(tester(as.factor(22290140)))

  expect_error(tester(formato = 1))
  expect_error(tester(formato = "oie"))
  expect_error(tester(formato = c("character", "character")))
})

test_that("lida com vetores vazios corretamente", {
  expect_equal(tester(character(0)), character(0))
  expect_equal(tester(integer(0)), character(0))
  expect_equal(tester(numeric(0)), character(0))
})

test_that("padroniza corretamente - numero", {
  # por padrão, formata como character

  gabarito <- tibble::tribble(
    ~original,   ~padronizado_esperado,
    0,           "S/N", # issue #38 (https://github.com/ipeaGIT/enderecobr/issues/38)
    1,           "1",
    1.1,         "1",
    NA_integer_, "S/N",
    NA_real_,    "S/N"
  )
  expect_equal(tester(gabarito$original), gabarito$padronizado_esperado)

  # caso especificado, formata como integer

  gabarito <- tibble::tribble(
    ~original,   ~padronizado_esperado,
    0,           NA_integer_,
    1,           1,
    1.1,         1,
    NA_integer_, NA_integer_,
    NA_real_,    NA_integer_
  )
  expect_equal(
    tester(gabarito$original, formato = "integer"),
    gabarito$padronizado_esperado
  )
})

test_that("padronizacao character->integer gera warning com certos inputs", {
  expect_snapshot(
    res <- tester(c("1", "1 2 ", "A"), formato = "integer"),
    cnd_class = TRUE
  )
})

test_that("padroniza corretamente - character", {
  # por padrão, formata como character

  gabarito <- tibble::tribble(
    ~original,       ~padronizado_esperado,
    " 1 ",           "1",
    "s/n",           "S/N",
    "NÚMERO",        "NUMERO",

    "0001",          "1",
    "01 02",         "1 2",

    "20.100",        "20100",
    "20.100 20.101", "20100 20101",

    "1.028",         "1028", # mistura dos dois casos acima - issue #37 (https://github.com/ipeaGIT/enderecobr/issues/37)

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

  # caso especificado, formata como integer

  gabarito <- tibble::tribble(
    ~original,       ~padronizado_esperado,
    " 1 ",           1,
    "s/n",           NA_integer_,
    "NÚMERO",        NA_integer_,

    "0001",          1,
    "01 02",         NA_integer_,

    "20.100",        20100,
    "20.100 20.101", NA_integer_,

    "1.028",         1028,

    "SN",            NA_integer_,
    "SNº",           NA_integer_,
    "S N",           NA_integer_,
    "S Nº",          NA_integer_,
    "S.N.",          NA_integer_,
    "S.Nº.",         NA_integer_,
    "S. N.",         NA_integer_,
    "S. Nº.",        NA_integer_,
    "S/N",           NA_integer_,
    "S/Nº",          NA_integer_,
    "S./N.",         NA_integer_,
    "S./Nº.",        NA_integer_,
    "S./N. S N",     NA_integer_,
    "SEM NUMERO",    NA_integer_,
    "X",             NA_integer_,
    "XX",            NA_integer_,
    "0",             NA_integer_,
    "00",            NA_integer_,
    "-",             NA_integer_,
    "--",            NA_integer_,

    "",              NA_integer_,
    NA_character_,   NA_integer_
  )

  expect_equal(
    suppressWarnings(tester(gabarito$original, formato = "integer")),
    gabarito$padronizado_esperado
  )
})

