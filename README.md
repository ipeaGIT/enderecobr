
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

A `padronizar_estados()` aceita vetores de strings e números. Caso
numérico, o vetor deve conter o [código do
IBGE](https://www.ibge.gov.br/explica/codigos-dos-municipios.php) de
cada estado. Caso seja composto de strings, o vetor pode conter a sigla
do estado, seu código ou seu nome por extenso. Neste caso, a função
ainda aplica diversas manipulações para chegar a um valor padronizado,
como a conversão de caracteres para caixa alta, remoção de acentos e
caracteres não ASCII e remoção de espaços em branco antes e depois dos
valores e de espaços em excesso entre palavras. O código abaixo
apresenta exemplos de aplicação da função com vetores numéricos e de
strings.

``` r
library(enderecopadrao)

estados <- c("21", " 21", "MA", " MA ", "ma", "MARANHÃO")
padronizar_estados(estados)
#> [1] "MARANHAO" "MARANHAO" "MARANHAO" "MARANHAO" "MARANHAO" "MARANHAO"

estados <- c(21, 32)
padronizar_estados(estados)
#> [1] "MARANHAO"       "ESPIRITO SANTO"
```

A função de padronização de campos de município,
`padronizar_municipios()`, funciona de forma muito semelhante, aceitando
também valores numéricos representando os códigos dos municípios e
strings. As mesmas manipulações de remoção de espaços, conversão para
caixa alta são aplicadas e conversão para caracteres são aplicadas
(assim como nos demais tratamentos de vetores de strings que serão
apresentados a seguir), mas a função também verifica erros ortográficos
frequentemente observados nos nomes dos municípios (e.g. Moji Mirim -\>
Mogi Mirim, Parati -\> Paraty).

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

A `padronizar_bairros()` trabalha exclusivamente com vetores de strings.
Como os nomes de bairros são muito mais variados e, consequentemente,
menos rigidamente controlados do que os de estados e municípios, a
função se atém a corrigir erros ortográficos e a expandir abreviações
frequentemente utilizadas através de diversas [expressões regulares
(regexes)](https://en.wikipedia.org/wiki/Regular_expression). O exemplo
abaixo mostra algumas das muitas abreviações usualmente empregadas no
preenchimento de endereços.

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

A `padronizar_ceps()` é outro exemplo de função que trabalha com strings
e números. Caso o input seja numérico, a função verifica se os valores
possuem comprimentos compatíveis com um CEP, adicionando zeros à
esquerda se necessário (é muito comum que leitores de CSV, por exemplo,
erroneamente leiam valores de CEP como números e excluam zeros à
esquerda por considerá-los redundantes). Caso o input seja formado por
strings, a função remove frequentemente são usados para separar partes
do CEP (e.g. pontos, vírgulas, espaços em branco) e verifica se o hífen
separando os cinco primeiros dígitos dos três últimos está presente,
adicionando-o caso contrário. A função ainda produz erros se recebe como
input valores que não podem ser corretamente convertidos em CEPs, como
no caso de strings contendo caracteres não numéricos e de strings com
caracteres em excesso.

``` r
ceps <- c("22290-140", "22.290-140", "22290 140", "22290140")
padronizar_ceps(ceps)
#> [1] "22290-140" "22290-140" "22290-140" "22290-140"

ceps <- c(22290140, 1000000)
padronizar_ceps(ceps)
#> [1] "22290-140" "01000-000"

padronizar_ceps("2229014a")
#> Error in `padronizar_ceps()`:
#> ! CEP não deve conter letras.
#> ℹ O elemento com índice 1 possui letras.

padronizar_ceps("022290140")
#> Error in `padronizar_ceps()`:
#> ! CEP não deve conter mais que 8 dígitos.
#> ℹ O elemento com índice 1 possui mais que 8 dígitos após padronização.
```

A tarefa de padronizar logradouros é a mais complexa dentre as
apresentadas até aqui, uma vez que o campo de logradouro é o que
apresenta maior variabilidade de input. A `padronizar_logradouros()`,
portanto, assim como a função de padronização de bairros, se limita a
expandir abreviações frequentemente utilizadas e a corrigir alguns
poucos erros de digitação, fora o tratamento usual dado a strings, como
conversão para caixa alta, remoção de espaços em excesso e antes e
depois das strings, etc.

``` r
logradouros <- c(
  "r. gen.. glicério, 137",
  "cond pres j. k., qd 05 lt 02 1",
  "av d pedro I, 020"
)
padronizar_logradouros(logradouros)
#> [1] "RUA GENERAL GLICERIO, 137"                                    
#> [2] "CONDOMINIO PRESIDENTE JUSCELINO KUBITSCHEK, QUADRA 5 LOTE 2 1"
#> [3] "AVENIDA DOM PEDRO I, 20"
```

Por fim, a `padronizar_numeros()` tem como objetivo padronizar o número
do logradouro, caso este esteja em um campo separado do logradouro
propriamente dito. A função aceita vetores de números e strings e
retorna um vetor de strings. Os tratamentos incluem a remoção de zeros à
esquerda, remoção de espaços em branco em excesso e a substituição de
valores em branco e de variações de SN (sem número) por “S/N”.

``` r
numeros <- c("0210", "001", "1", "", "S N", "S/N", "SN", "0180  0181")
padronizar_numeros(numeros)
#> [1] "210"     "1"       "1"       "S/N"     "S/N"     "S/N"     "S/N"    
#> [8] "180 181"

numeros <- c(210, 1, 10000, NA)
padronizar_numeros(numeros)
#> [1] "210"   "1"     "10000" "S/N"
```
