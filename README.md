
# enderecobr <img align="right" src="man/figures/logo.svg" alt="" width="180">

[![CRAN
status](https://www.r-pkg.org/badges/version/enderecobr)](https://CRAN.R-project.org/package=enderecobr)
[![B
status](https://github.com/ipeaGIT/enderecobr/workflows/check/badge.svg)](https://github.com/ipeaGIT/enderecobr/actions?query=workflow%3Acheck)
[![CRAN/METACRAN Total
downloads](https://cranlogs.r-pkg.org/badges/grand-total/enderecobr?color=blue)](https://CRAN.R-project.org/package=enderecobr)
[![Codecov test
coverage](https://codecov.io/gh/ipeaGIT/enderecobr/branch/main/graph/badge.svg)](https://app.codecov.io/gh/ipeaGIT/enderecobr?branch=main)
[![Lifecycle:
stable](https://lifecycle.r-lib.org/articles/figures/lifecycle-stable.svg)](https://lifecycle.r-lib.org/articles/stages.html)

**enderecobr** é um pacote de R que permite padronizar endereços
brasileiros a partir de diferentes critérios. Os métodos de padronização
atualmente incluem apenas manipulações de strings, não oferecendo
suporte a correspondências probabilísticas entre strings.

## Instalação

A última versão estável pode ser baixada do CRAN com o comando a seguir:

``` r
install.packages("enderecobr")
```

Caso prefira, a versão em desenvolvimento também pode ser usada. Para
isso, use o seguinte comando:

``` r
# install.packages("remotes")
remotes::install_github("ipeaGIT/enderecobr")
```

## Utilização

Esta seção visa oferecer apenas uma visão geral das funcionalidades do
pacote. Para mais detalhes, leia a vignette introdutória:

- [**enderecobr**: padronizador de endereços
  brasileiros](https://ipeagit.github.io/enderecobr/articles/enderecobr.html)

O **enderecobr** disponibiliza funções para padronizar diferentes campos
de um endereço. A `padronizar_enderecos()`, carro-chefe do pacote, atua
de forma simultânea sobre os vários campos que podem compor um endereço.
Para isso, ela recebe um dataframe e a correspondência entre suas
colunas e os campos a serem padronizados:

``` r
library(enderecobr)

enderecos <- data.frame(
  logradouro = "r ns sra da piedade",
  nroLogradouro = 20,
  complemento = "qd 20",
  cep = 25220020,
  bairro = "jd botanico",
  codmun_dom = 3304557,
  uf_dom = "rj"
)

campos <- correspondencia_campos(
  logradouro = "logradouro",
  numero = "nroLogradouro",
  complemento = "complemento",
  cep = "cep",
  bairro = "bairro",
  municipio = "codmun_dom",
  estado = "uf_dom"
)

padronizar_enderecos(enderecos, campos_do_endereco = campos)
#>             logradouro nroLogradouro complemento      cep      bairro
#>                 <char>         <num>      <char>    <num>      <char>
#> 1: r ns sra da piedade            20       qd 20 25220020 jd botanico
#>    codmun_dom uf_dom              logradouro_padr numero_padr complemento_padr
#>         <num> <char>                       <char>      <char>           <char>
#> 1:    3304557     rj RUA NOSSA SENHORA DA PIEDADE          20        QUADRA 20
#>     cep_padr     bairro_padr municipio_padr    estado_padr
#>       <char>          <char>         <char>         <char>
#> 1: 25220-020 JARDIM BOTANICO RIO DE JANEIRO RIO DE JANEIRO
```

Por trás dos panos, essa função utiliza diversas outras funções que
padronizam campos de forma individual. Cada uma delas recebe um vetor
com valores não padronizados e retorna um vetor de mesmo tamanho com os
respectivos valores padronizados. Algumas das funções disponíveis são
apresentadas a seguir:

``` r
estados <- c("21", " 21", "MA", " MA ", "ma", "MARANHÃO")
padronizar_estados(estados)
#> [1] "MARANHAO" "MARANHAO" "MARANHAO" "MARANHAO" "MARANHAO" "MARANHAO"

municipios <- c(
  "3304557", "003304557", " 3304557 ", "RIO DE JANEIRO", "rio de janeiro",
  "SÃO PAULO"
)
padronizar_municipios(municipios)
#> [1] "RIO DE JANEIRO" "RIO DE JANEIRO" "RIO DE JANEIRO" "RIO DE JANEIRO"
#> [5] "RIO DE JANEIRO" "SAO PAULO"

bairros <- c(
  "PRQ IND",
  "NSA SEN DE FATIMA",
  "ILHA DO GOV",
  "VL OLIMPICA",
  "NUC RES"
)
padronizar_bairros(bairros)
#> [1] "PARQUE INDUSTRIAL"       "NOSSA SENHORA DE FATIMA"
#> [3] "ILHA DO GOVERNADOR"      "VILA OLIMPICA"          
#> [5] "NUCLEO RESIDENCIAL"

ceps <- c("22290-140", "22.290-140", "22290 140", "22290140")
padronizar_ceps(ceps)
#> [1] "22290-140" "22290-140" "22290-140" "22290-140"

logradouros <- c(
  "r. gen.. glicério, 137",
  "cond pres j. k., qd 05 lt 02 1",
  "av d pedro I, 020"
)
padronizar_logradouros(logradouros)
#> [1] "RUA GENERAL GLICERIO, 137"                                    
#> [2] "CONDOMINIO PRESIDENTE JUSCELINO KUBITSCHEK, QUADRA 5 LOTE 2 1"
#> [3] "AVENIDA DOM PEDRO I, 20"

numeros <- c("0210", "001", "1", "", "S N", "S/N", "SN", "0180  0181")
padronizar_numeros(numeros)
#> [1] "210"     "1"       "1"       "S/N"     "S/N"     "S/N"     "S/N"    
#> [8] "180 181"
```

## Controle de verbosidade

O disparo de mensagens com informações sobre a execução das funções pode
ser controlado pela opção `enderecobr.verbose`, que recebe os valores
`"quiet"` ou `"verbose"`, como demonstrado a seguir:

``` r
campos <- correspondencia_logradouro(
  nome_do_logradouro = "logradouro",
  numero = "nroLogradouro"
)

# quieto, por padrão
res <- padronizar_logradouros_completos(enderecos, campos)

# verboso, se desejado
rlang::local_options("enderecobr.verbose" = "verbose")
res <- padronizar_logradouros_completos(enderecos, campos)
#> ✔ Padronizando nomes dos logradouros... [130ms]
#> ✔ Padronizando números... [111ms]
#> ✔ Trazendo números para o logradouro completo... [107ms]
```

## Nota <a href="https://www.ipea.gov.br"><img src="man/figures/ipea_logo.png" alt="Ipea" align="right" width="300"/></a>

**enderecobr** é desenvolvido por uma equipe de pesquisadores do
Instituto de Pesquisa Econômica Aplicada (Ipea).
