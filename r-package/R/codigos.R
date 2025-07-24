#' Códigos e nomes dos estados brasileiros (2022)
#'
#' Tabela com a relação entre os códigos e nomes dos estados brasileiros. Os
#' códigos foram convertidos para caracteres; os nomes foram convertidos para
#' caracteres ASCII em caixa alta.
#'
#' @format
#' Um data frame com 27 linhas e 3 colunas:
#' - `codigo_estado` - código do estado;
#' - `nome_estado` - nome do estado;
#' - `abrev_estado` - abreviação do nome do estado.
#'
#' @source <https://www.ibge.gov.br/explica/codigos-dos-municipios.php>
#'
#' @seealso [codigos_municipios]
#'
#' @name codigos_estados
#' @export
"codigos_estados"

#' Códigos e nomes dos municípios brasileiros (2022)
#'
#' Tabela com a relação entre os códigos e nomes dos municípios brasileiros. Os
#' códigos foram convertidos para caracteres; os nomes foram convertidos para
#' caracteres ASCII em caixa alta.
#'
#' @format
#' Um data frame com 5570 linhas e 3 colunas:
#' - `codigo_estado` - código do estado em que o município está localizado;
#' - `codigo_muni` - código do município;
#' - `nome_muni` - nome do município.
#'
#' @source <https://www.ibge.gov.br/explica/codigos-dos-municipios.php>
#'
#' @seealso [codigos_estados]
#'
#' @name codigos_municipios
#' @export
"codigos_municipios"
