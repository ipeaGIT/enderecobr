tester <- function(tipos = "R") {
  padronizar_tipos_de_logradouro(tipos)
}

test_that("da erro com inputs != de caracteres", {
  expect_error(tester(12))
})

test_that("lida com vetores vazios corretamente", {
  expect_equal(tester(character(0)), character(0))
})

test_that("padroniza corretamente", {
  skip_if_not_installed("tibble")

  gabarito <- tibble::tribble(
    ~original,    ~padronizado_esperado,
    " RUA ",      "RUA",
    "rua",        "RUA",
    "RU\u00C1",   "RUA", # RUÁ
    "RUA..",      "RUA",
    "..RUA",      ". RUA",
    "1.000",      "1000",
    "ROD.UM",     "RODOVIA UM",
    "RUA - UM",   "RUA UM",
    "RUA . UM",   "RUA UM",
    "RUA.",       "RUA",
    "\"",         "'",
    "AA",         NA_character_,
    "AAAAAA",     NA_character_,
    "1111",       NA_character_,
    "-",          NA_character_,
    "--",         NA_character_,

    "R",          "RUA",
    "R.",         "RUA",
    "RA",         "RUA",
    "RA.",        "RUA",
    "RU",         "RUA",
    "RU.",        "RUA",

    "ROD",        "RODOVIA",
    "ROD.",       "RODOVIA",
    "RDV",        "RODOVIA",
    "RDV.",       "RODOVIA",

    "AV",         "AVENIDA",
    "AV.",        "AVENIDA",
    "AVE",        "AVENIDA",
    "AVE.",       "AVENIDA",
    "AVN",        "AVENIDA",
    "AVN.",       "AVENIDA",
    "AVD",        "AVENIDA",
    "AVD.",       "AVENIDA",
    "AVDA",       "AVENIDA",
    "AVDA.",      "AVENIDA",
    "AVI",        "AVENIDA",
    "AVI.",       "AVENIDA",

    "EST",        "ESTRADA",
    "EST.",       "ESTRADA",
    "ESTR",       "ESTRADA",
    "ESTR.",      "ESTRADA",

    "PC",         "PRACA",
    "PC.",        "PRACA",
    "PCA",        "PRACA",
    "PCA.",       "PRACA",
    "PRC",        "PRACA",
    "PRC.",       "PRACA",

    "BC",         "BECO",
    "BC.",        "BECO",
    "BEC",        "BECO",
    "BEC.",       "BECO",
    "BCO",        "BECO",
    "BCO.",       "BECO",

    "TV",         "TRAVESSA",
    "TV.",        "TRAVESSA",
    "TRV",        "TRAVESSA",
    "TRV.",       "TRAVESSA",
    "TRAV",       "TRAVESSA",
    "TRAV.",      "TRAVESSA",
    "TRA",        "TRAVESSA",
    "TRA.",       "TRAVESSA",

    "PQ",         "PARQUE",
    "PQ.",        "PARQUE",
    "PRQ",        "PARQUE",
    "PRQ.",       "PARQUE",
    "PARQ",       "PARQUE",
    "PARQ.",      "PARQUE",
    "PQE",        "PARQUE",
    "PQE.",       "PARQUE",
    "PQUE",       "PARQUE",
    "PQUE.",      "PARQUE",

    "AL",         "ALAMEDA",
    "AL.",        "ALAMEDA",
    "ALA",        "ALAMEDA",
    "ALA.",       "ALAMEDA",
    "ALM",        "ALAMEDA",
    "ALM.",       "ALAMEDA",
    "RODOVIA AL", "RODOVIA AL",

    "LOT",        "LOTEAMENTO",
    "LOT.",       "LOTEAMENTO",

    "VL",         "VILA",
    "VL.",        "VILA",
    "VIL",        "VILA",
    "VIL.",       "VILA",

    "LAD",        "LADEIRA",
    "LAD.",       "LADEIRA",

    "DIS",        "DISTRITO",
    "DIS.",       "DISTRITO",
    "DIST",       "DISTRITO",
    "DIST.",      "DISTRITO",
    "DISTR",      "DISTRITO",
    "DISTR.",     "DISTRITO",

    "LAR",        "LARGO",
    "LAR.",       "LARGO",
    "LRG",        "LARGO",
    "LRG.",       "LARGO",
    "LGO",        "LARGO",
    "LGO.",       "LARGO",

    "AER",        "AEROPORTO",
    "AER.",       "AEROPORTO",
    "AEROP",      "AEROPORTO",
    "AEROP.",     "AEROPORTO",

    "FAZ",        "FAZENDA",
    "FAZ.",       "FAZENDA",
    "FAZE",       "FAZENDA",
    "FAZE.",      "FAZENDA",
    "FAZEN",      "FAZENDA",
    "FAZEN.",     "FAZENDA",

    "CON",        "CONDOMINIO",
    "CON.",       "CONDOMINIO",
    "COND",       "CONDOMINIO",
    "COND.",      "CONDOMINIO",

    "SIT",        "SITIO",
    "SIT.",       "SITIO",

    "RES",        "RESIDENCIAL",
    "RES.",       "RESIDENCIAL",
    "RESID",      "RESIDENCIAL",
    "RESID.",     "RESIDENCIAL",

    "QU",         "QUADRA",
    "QU.",        "QUADRA",
    "QUA",        "QUADRA",
    "QUA.",       "QUADRA",
    "QUAD",       "QUADRA",
    "QUAD.",      "QUADRA",
    "QD",         "QUADRA",
    "QD.",        "QUADRA",
    "QDR",        "QUADRA",
    "QDR.",       "QUADRA",
    "QDRA",       "QUADRA",
    "QDRA.",      "QUADRA",

    "CHA",        "CHACARA",
    "CHA.",       "CHACARA",
    "CHAC",       "CHACARA",
    "CHAC.",      "CHACARA",

    "OUTROS", NA_character_
  )

  expect_equal(tester(gabarito$original), gabarito$padronizado_esperado)
})
