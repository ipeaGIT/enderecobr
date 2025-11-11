rextendr::document()
devtools::install(quick = TRUE) # Força compilação em modo release
devtools::load_all()

# Rodando testes unitários
# rextendr::document()
# testthat::test_package('enderecobr')

print("Carregando Dataset")
dados <- arrow::read_parquet("/home/gabriel/ipea/enderecobr-rs/scripts/crf/dados/treino.parquet")

print("Realizando benchmark")

n <- 5

microbenchmark::microbenchmark(
  padronizar_ceps_rs(rep(dados$cep, n)),
  padronizar_ceps(rep(dados$cep, n)),
  times = 5
)

microbenchmark::microbenchmark(
  padronizar_estados_rs(rep(dados$uf, n)),
  padronizar_estados(rep(dados$uf, n)),
  times = 5
)

microbenchmark::microbenchmark(
  padronizar_numeros_rs(rep(dados$numero, n)),
  padronizar_numeros(rep(dados$numero, n)),
  times = 5
)


microbenchmark::microbenchmark(
  padronizar_municipios_rs(rep(dados$municipio, n)),
  padronizar_municipios(rep(dados$municipio, n)),
  times = 5
)

microbenchmark::microbenchmark(
  padronizar_bairros_rs(rep(dados$localidade, n)),
  padronizar_bairros(rep(dados$localidade, n)),
  times = 5
)

microbenchmark::microbenchmark(
  padronizar_logradouros_rs(rep(dados$logradouro, n)),
  padronizar_logradouros(rep(dados$logradouro, n)),
  times = 5
)

microbenchmark::microbenchmark(
  padronizar_complementos_rs(rep(dados$complemento, n)),
  padronizar_complementos(rep(dados$complemento, n)),
  times = 5
)
