library(enderecobr)

# open input data
data_path <- system.file("extdata/large_sample.parquet", package = "geocodebr")
input_df <- arrow::read_parquet(data_path)


microbenchmark::microbenchmark(
  strng = enderecobr::padronizar_logradouros(input_df$logradouro),
  times = 10,
  unit = 'milliseconds'
)

fields <- enderecobr::correspondencia_campos(
  logradouro = 'logradouro',
  numero = 'numero',
  cep = 'cep',
  bairro = 'bairro',
  municipio = 'municipio',
  estado = 'uf'
)



microbenchmark::microbenchmark(
  stable = padronizar_enderecos(
    enderecos = input_df,
    campos_do_endereco = fields),
  times = 10,
  unit = 'seconds'
)

# Unit: seconds
#   expr      min        lq      mean    median        uq      max neval
# stable 0.846576 0.8657611 0.9549316 0.8858335 0.9168495 1.976345    20



# using r2e
devtools::load_all('.')

fields <- correspondencia_campos(
  logradouro = 'logradouro',
  numero = 'numero',
  cep = 'cep',
  bairro = 'bairro',
  municipio = 'municipio',
  estado = 'uf'
)

microbenchmark::microbenchmark(
  re2 = padronizar_enderecos(
    enderecos = input_df,
    campos_do_endereco = fields),
  times = 10,
  unit = 'seconds'
)

# Unit: seconds
# expr      min       lq     mean  median       uq      max neval
#  re2 1.119335 1.133411 1.207905 1.17996 1.204361 1.532617    10


Substituindo stringr::str_replace_all por re2::re2_replace_all






microbenchmark::microbenchmark(
  re2 = enderecobr::padronizar_ceps(input_df$cep),
  times = 10,
  unit = 'milliseconds'
)
Unit: milliseconds
expr     min      lq     mean  median      uq     max neval
strng 22.2053 22.6214 29.47018 23.4063 24.1326 85.0139    10
  re2 21.1998 21.7154 24.32691 23.48435 25.7784 30.9073    10


microbenchmark::microbenchmark(
  re2 = enderecobr::padronizar_bairros2(input_df$bairro),
  re1 = enderecobr::padronizar_bairros(input_df$bairro),
  times = 20,
  unit = 'milliseconds'
)
Unit: milliseconds
expr    min       lq     mean   median       uq      max neval
strng 94.9868 96.15615 103.6096 97.63395 104.119 178.1253    20
re2  122.8479 124.4116 134.8104 132.3798 143.436 151.1574    20




microbenchmark::microbenchmark(
  re2 = enderecobr::padronizar_municipios(input_df$municipio),
  times = 20,
  unit = 'milliseconds'
)
Unit: milliseconds
expr      min       lq     mean   median       uq     max neval
strng 4.582102 4.821601 8.244796 5.21730  5.633351 66.5248    20
  re2 4.711802 5.287351 6.710166 5.50945  5.601751 28.0534    20


microbenchmark::microbenchmark(
  re2 = enderecobr::padronizar_estados(input_df$uf),
  times = 10,
  unit = 'milliseconds'
)
Unit: milliseconds
expr      min       lq     mean   median      uq      max neval
strng 3.819901 3.937501 16.94684 4.102151 15.0094 103.4202    10
re2 3.705101 3.9474    6.94326 4.10695 4.254901 26.3574    10




microbenchmark::microbenchmark(
  re2 = enderecobr::padronizar_logradouros(input_df$logradouro),
  times = 10,
  unit = 'milliseconds'
)
Unit: milliseconds
expr      min       lq     mean   median       uq      max neval
strng 610.7025 618.8433 632.2883 633.0015 643.9654 660.3918    10
  re2 819.2605 822.3127 863.4108 836.9283 849.8264 1011.434    10





microbenchmark::microbenchmark(
  re2 = re2::re2_replace_all('CTO',"\\bCTO\\b\\.?", "CENTRO"),
  str = stringr::str_replace_all('CTO',c("\\bCTO\\b\\.?"= "CENTRO")),
  times = 10,
  unit = 'milliseconds'
)
Unit: milliseconds
expr      min       lq      mean   median       uq      max neval
re2 0.059701 0.063401 0.0765512 0.076651 0.084002 0.114201    10
str 0.255802 0.265300 0.3007111 0.270051 0.276302 0.535401    10






