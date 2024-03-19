
# enderecopadrao

[![CRAN
status](https://www.r-pkg.org/badges/version/enderecopadrao)](https://CRAN.R-project.org/package=enderecopadrao)
[![B
status](https://github.com/ipeaGIT/enderecopadrao/workflows/check/badge.svg)](https://github.com/ipeaGIT/enderecopadrao/actions?query=workflow%3Acheck)
[![Codecov test
coverage](https://codecov.io/gh/ipeaGIT/enderecopadrao/branch/main/graph/badge.svg)](https://app.codecov.io/gh/ipeaGIT/enderecopadrao?branch=main)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html)

**enderecopadrao** é um pacote de R que permite padronizar endereços
brasileiros a partir de diferentes critérios. Os métodos de padronização
incluem apenas manipulações básicas de strings, não oferecendo suporte a
correspondências probabilísticas entre strings.

## Instalação

Versão em desenvolvimento:

``` r
# install.packages("remotes")
remotes::install_github("ipeaGIT/enderecopadrao")
```

## Utilização

O pacote atualmente fornece funções para padronizar diferentes campos de
um endereço. São elas:

- `padronizar_estados()`
- `padronizar_municipios()`
- `padronizar_bairros()`
- `padronizar_ceps()`
- `padronizar_logradouros()`
- `padronizar_numeros()`

Cada uma dessas funções recebe um vetor com valores não padronizados e
retorna um vetor de mesmo tamanho com os respectivos valores
padronizados.

A `padronizar_estados()` aceita vetores de caracteres e números. Caso
numérico, o vetor deve conter o [código do
IBGE](https://www.ibge.gov.br/explica/codigos-dos-municipios.php) de
cada estado. Caso seja composto de caracteres, o vetor pode conter a
sigla do estado, seu código ou seu nome por extenso. Neste caso, a
função ainda aplica diversas manipulações para chegar a um valor
padronizado, como a conversão de caracteres para caixa alta, remoção de
acentos e caracteres não ASCII e remoção de espaços em branco antes e
depois dos valores e de espaços em excesso entre palavras. O código
abaixo apresenta exemplos de aplicação da função com vetores numéricos e
de caracteres.

``` r
library(enderecopadrao)

estados <- c("21", " 21", "MA", " MA ", "ma", "MARANHÃO")
padronizar_estados(estados)
#> [1] "MARANHAO" "MARANHAO" "MARANHAO" "MARANHAO" "MARANHAO" "MARANHAO"

estados <- c(21, 32)
padronizar_estados(estados)
#> [1] "MARANHAO"       "ESPIRITO SANTO"
```

A `padronizar_municipios()` funciona de forma muito semelhante,
aceitando também valores numéricos representando os códigos dos
municípios e valores numéricos. As mesmas manipulações de remoção de
espaços, conversão para caixa alta são aplicadas e conversão para
caracteres são aplicadas (assim como nos demais tratamentos de vetores
de caracteres que serão apresentados a seguir), mas a função também
verifica erros ortográficos frequentemente observados nos nomes dos
municípios (e.g. Moji Mirim -\> Mogi Mirim, Parati -\> Paraty).

``` r
municipios <- c(
  "3304557", "003304557", " 3304557 ", "RIO DE JANEIRO", "rio de janeiro",
  "SÃO PAULO"
)
padronizar_municipios(municipios)
#> [1] "RIO DE JANEIRO" "RIO DE JANEIRO" "RIO DE JANEIRO" "RIO DE JANEIRO"
#> [5] "RIO DE JANEIRO" "SAO PAULO"

municipios <- 3304557
padronizar_municipios(municipios)
#> [1] "RIO DE JANEIRO"

municipios <- c("PARATI", "MOJI MIRIM")
padronizar_municipios(municipios)
#> [1] "PARATY"     "MOGI MIRIM"
```

A `padronizar_bairros()` trabalha exclusivamente com vetores de
caracteres. Como os nomes de bairros são muito mais variados e,
consequentemente, menos rigidamente controlados do que os de estados e
municípios, a função se atém a corrigir erros ortográficos e a expandir
abreviações frequentemente utilizadas através de diversas [expressões
regulares (regexes)](https://en.wikipedia.org/wiki/Regular_expression).
O exemplo abaixo mostra algumas das muitas abreviações usualmente
empregadas no preenchimento de endereços.

``` r
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
```
