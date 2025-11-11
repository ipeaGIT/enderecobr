#' Padronizar bairros
#'
#' Padroniza um vetor de caracteres representando bairros de municípios
#' brasileiros. Veja a seção *Detalhes* para mais informações sobre a
#' padronização.
#'
#' @param bairros Um vetor de caracteres. Os bairros a serem padronizados.
#'
#' @return Um vetor de caracteres com os bairros padronizados.
#'
#' @section Detalhes:
#' Operações realizadas durante a padronização:
#'
#' - remoção de espaços em branco antes e depois das strings e remoção de
#' espaços em excesso entre palavras;
#' - conversão de caracteres para caixa alta;
#' - remoção de acentos e caracteres não ASCII;
#' - adição de espaços após abreviações sinalizadas por pontos;
#' - expansão de abreviações frequentemente utilizadas através de diversas
#' [expressões regulares
#' (regexes)](https://en.wikipedia.org/wiki/Regular_expression);
#' - correção de alguns pequenos erros ortográficos.
#'
#' @examples
#' bairros <- c("PRQ IND", "NSA SEN DE FATIMA", "ILHA DO GOV")
#' padronizar_bairros(bairros)
#'
#' @export
padronizar_bairros <- function(bairros) {
  checkmate::assert_character(bairros)
  padronizar_bairros_rs(bairros)
}
