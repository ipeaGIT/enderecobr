# arquivo auxiliar para facilitar o teste manual com grandes bases de enderecos

detectar_sem_na <- function(string, padrao) {
  result <- string[str_detect(string, padrao)]
  result[!is.na(result)]
}

# cad unico

arquivo <- file.path(
  Sys.getenv("RESTRICTED_DATA_PATH"),
  paste0("CADASTRO_UNICO/parquet/cad_familia_122011.parquet")
)
colunas_a_manter <- c(
  "co_familiar_fam", # identificador
  "co_uf", # estado
  "cd_ibge_cadastro", # municipio
  "no_localidade_fam", # bairro, povoado, vila, etc
  "no_tip_logradouro_fam", # tipo de logradouro
  "no_tit_logradouro_fam", # titulo (e.g. general, papa, santa, etc)
  "no_logradouro_fam", # logradouro
  "nu_logradouro_fam", # numero
  "nu_cep_logradouro_fam", # cep
  "ds_complemento_fam" # complemento
)

original <- arrow::open_dataset(arquivo)
original <- dplyr::select(original, dplyr::all_of(colunas_a_manter))
original <- data.table::setDT(dplyr::collect(original))
tipos <- original$no_tip_logradouro_fam
table(tipos)

# cpf

path <- file.path(
  Sys.getenv("RESTRICTED_DATA_PATH"),
  "B_CADASTRO/CPF/20230816_cpf.csv"
)
colunas_a_manter <- c(
  "cpf", # identificador
  "uf_dom", # estado
  "codmun_dom", # municipio
  "cep",
  "bairro",
  "tipoLogradouro",
  "logradouro",
  "nroLogradouro"
)
original <- data.table::fread(
  path,
  select = list(character = colunas_a_manter),
  na.strings = "",
  nrows = 2500000
)
tipos <- original$tipoLogradouro
table(tipos)
