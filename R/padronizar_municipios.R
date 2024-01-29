#' Padronizar municípios
#'
#' Padroniza um vetor de caracteres ou números representando municípios
#' brasileiros. Veja a seção *Detalhes* para mais informações sobre a
#' padronização.
#'
#' @param municipios Um vetor de caracteres ou números. Os municípios a serem
#'   padronizados.
#'
#' @return Um vetor de caracteres com os municípios padronizados.
#'
#' @section Detalhes:
#' Operações realizadas durante a padronização:
#'
#' 1. conversão para caracter, se o input for numérico;
#' 2. remoção de espaços em branco antes e depois dos valores e remoção de
#' espaços em excesso entre palavras;
#' 3. conversão de caracteres para caixa alta;
#' 4. remoção de zeros à esquerda;
#' 5. busca, a partir do código numérico, do nome completo de cada município;
#' 6. caso a busca não tenha encontrado determinado valor, remoção de acentos e
#' caracteres não ASCII - esta etapa, de manipulação de strings, pode ser
#' incrementada para adequação futura a bases de dados com as quais as etapas
#' anteriores não resultem em valores padronizados.
#'
#' @examples
#' municipios <- c(
#'   "3304557", "003304557", " 3304557 ", "RIO DE JANEIRO", "rio de janeiro",
#'   "SÃO PAULO",
#'   "", NA
#' )
#' padronizar_municipios(municipios)
#'
#' municipios <- c(21, NA)
#' padronizar_municipios(municipios)
#'
#' @export
padronizar_municipios <- function(municipios) {
  checkmate::assert(
    checkmate::check_character(municipios),
    checkmate::check_numeric(municipios),
    combine = "or"
  )

  # alguns municipios podem vir vazios e devem permanecer vazios ao final.
  # identificamos o indice dos municipios vazios para "reesvazia-los" ao final,
  # ja que a sequencia de operacoes abaixo acabaria atribuindo um valor a eles

  indice_municipio_vazio <- which(municipios == "" | is.na(municipios))

  if (is.numeric(municipios)) {
    municipios_padrao <- formatC(municipios, format = "d")
  } else {
    municipios_padrao <- stringr::str_squish(municipios)
    municipios_padrao <- toupper(municipios_padrao)
    municipios_padrao <- stringr::str_replace_all(
      municipios_padrao,
      c("\\b0+(\\d+)\\b" = "\\1")
    )
  }

  # em uma primeira etapa, fazemos uma busca dos nomes completos dos municipios
  # a partir de seus códigos numericos. apos essa etapa, se ainda houver algum
  # registro de valor diferente dos nomes completos padroes, fazemos uma serie
  # de manipulacoes de string que tomam um pouco mais de tempo

  vetor_busca_com_cod <- codigos_municipios$nome_muni
  names(vetor_busca_com_cod) <- codigos_municipios$codigo_muni
  result_busca_com_cod <- vetor_busca_com_cod[municipios_padrao]

  municipios_padrao <- ifelse(
    is.na(result_busca_com_cod),
    municipios_padrao,
    result_busca_com_cod
  )
  names(municipios_padrao) <- NULL

  municipios_padrao[indice_municipio_vazio] <- ""

  municipio_nao_padrao <- !(
    municipios_padrao %in% c(codigos_municipios$nome_muni, "")
  )

  if (any(municipio_nao_padrao)) {
    municipios_padrao[municipio_nao_padrao] <- manipular_nome_muni(
      municipios_padrao[municipio_nao_padrao]
    )
  }

  return(municipios_padrao)
}

manipular_nome_muni <- function(muni) {
  muni <- stringi::stri_trans_general(muni, "Latin-ASCII")

  return(muni)
}
