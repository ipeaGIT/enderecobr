# tmpfile <- tempfile(fileext = ".zip")
# download.file(
#   "https://geoftp.ibge.gov.br/organizacao_do_territorio/estrutura_territorial/divisao_territorial/2022/DTB_2022.zip",
#   destfile = tmpfile
# )
#
# tmpdir <- tempfile("dtb_2022")
# zip::unzip(tmpfile, exdir = tmpdir)
#
# codigos <- readxl::read_xls(
#   file.path(tmpdir, "RELATORIO_DTB_BRASIL_MUNICIPIO.xls"),
#   range = "A7:M5577"
# )
#
#
# gostaria de ter usado o codigo acima pra baixar a tabela que relaciona estados
# e municipios com seus codigo, mas infelizmente nao consigo ler o arquivo acima
# usando a readxl::read_xls(). aparentemente o arquivo esta com algum problema.
# a solucao que encontrei foi baixar o arquivo manualmente e, tambem
# manualmente, salvar o arquivo como .xls na pasta data-raw. a partir dai
# comecei a conseguir ler os dados usando a read_xls()

arquivo_xls <- "data-raw/RELATORIO_DTB_BRASIL_MUNICIPIO.xls"
codigos <- readxl::read_xls(arquivo_xls, range = "A7:M5577")

codigos <- dplyr::select(
  codigos,
  codigo_estado = UF,
  nome_estado = Nome_UF,
  codigo_muni = `Código Município Completo`,
  nome_muni = Nome_Município
)
codigos <- dplyr::mutate(
  codigos,
  nome_estado = toupper(stringi::stri_trans_general(nome_estado, "Latin-ASCII")),
  nome_muni = toupper(stringi::stri_trans_general(nome_muni, "Latin-ASCII"))
)

# codigos_municipios

codigos_municipios <- dplyr::select(codigos, -nome_estado)
usethis::use_data(codigos_municipios, overwrite = TRUE)

# codigos_estados

codigos_estados <- dplyr::select(codigos, codigo_estado, nome_estado)
codigos_estados <- unique(codigos_estados)

abrev_estados <- geobr::read_state("all", 2010)
abrev_estados <- sf::st_drop_geometry(abrev_estados)
abrev_estados <- dplyr::select(abrev_estados, code_state, abbrev_state)
abrev_estados$code_state <- as.character(abrev_estados$code_state)

codigos_estados <- dplyr::left_join(
  codigos_estados,
  abrev_estados,
  by = dplyr::join_by(codigo_estado == code_state)
)
codigos_estados <- dplyr::rename(codigos_estados, abrev_estado = abbrev_state)

usethis::use_data(codigos_estados, overwrite = TRUE)
