# enderecobr 0.4.1

## Correção de bugs

- Corrigido bug na `padronizar_enderecos()` (quando chamada via
`enderecobr::padronizar_enderecos()`) em que a função resultava num erro quando,
internamente, a `padronizar_numeros()` lançava um warning. Relacionado ao [issue
#38](https://github.com/ipeagit/enderecobr/issues/38).
- Corrigido bug na `padronizar_enderecos()` (quando chamada via
`enderecobr::padronizar_enderecos()`) em que a função resultava num erro quando,
internamente, a `padronizar_ceps()` identificava um CEP inválido.

# enderecobr 0.4.0

## Correção de bugs

- Corrigido bug na `padronizar_numeros()` em que zeros após o separador de
milhares eram suprimidos. Por exemplo, "1.028" virava "1.28". Relacionado ao
[issue #37](https://github.com/ipeaGIT/enderecobr/issues/37).
- Corrigido bug na `padronizar_numeros()` em que zeros de vetores numéricos não
eram adequadamente transformados em "S/N". Relacionado ao [issue
#38](https://github.com/ipeaGIT/enderecobr/issues/38).

## Novas funcionalidades

- Novo argumento na `padronizar_numeros()`, `formato`, responsável por controlar
como o resultado deve ser padronizado: se como um vetor de caracteres ou de
inteiros.
- Novo argumento na `padronizar_numeros()`, `formato_numeros`, que controla como
deve ser feita a padronização de números dentro dessa função.

# enderecobr 0.3.0

## Novas funcionalidades

- Novo argumento na `padronizar_estados()`, `formato`, responsável por controlar
como o resultado deve ser padronizado: se usando o nome por extenso de cada
estado ou sua sigla.
- Novo argumento na `padronizar_enderecos()`, `formato_estados`, que controla
como deve ser feita a padronização de estados dentro dessa função.

# enderecobr 0.2.1

## Notas

- Lucas Mation adicionado como autor do pacote.

# enderecobr 0.2.0

## Correção de bugs

- Ajuste na exportação dos dados dos códigos de estados e municípios, que
impedia que o pacote fosse usado sem ser explicitamente carregado com
`library(enderecopadrao)`.
- Ajuste na `padronizar_estados()`, evitando casos em que um valor padronizado
  poderia acabar sendo erroneamente atribuído a um estado de input (relacionado
  ao [issue #26](https://github.com/ipeaGIT/enderecobr/issues/26)).

## Novas funcionalidades

- Diversos ajustes nas padronizações.
- Novas funções: `padronizar_tipos_de_logradouro()` e
  `padronizar_logradouros_completos()`.
- Novos argumentos na `padronizar_enderecos()`: `manter_cols_extras`,
  `combinar_logradouro` e `checar_tipos`. A função agora mantém as
  colunas de input no resultado e retorna o output em colunas nomeadas no padrão
  `<campo>_padr`.
- A verbosidade das funções agora pode ser controlada pela opção
  `enderecobr.verbose`, que recebe os valores `"quiet"` ou `"verbose"`.

## Notas

- Primeira versão no CRAN.
- Mudança do nome do pacote, de `{enderecopadrao}` para `{enderecobr}`.
- Diversos ajustes na documentação.

# enderecopadrao 0.1.0

Primeira versão estável.
