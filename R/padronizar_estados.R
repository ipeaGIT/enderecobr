#' Padronizar estados
#'
#' Padroniza um vetor de estados. Veja a seção *Detalhes* para mais informações
#' sobre a padronização.
#'
#' @param estados Um vetor de caracteres ou números. Os estados a serem
#'   padronizados.
#'
#' @return Um vetor de caracteres com os estados padronizados.
#'
#' @section Detalhes:
#' TODO: revisar isso aqui
#' Operações realizadas durante a padronização:
#'
#' 1. conversão para caracter, se o input for numérico;
#' 2. remoção de espaços em branco antes e depois dos números e de espaços em
#' branco em excesso entre números;
#' 3. remoção de zeros à esquerda;
#' 4. substituição de números vazios e de variações de SN (SN, S N, S.N., S./N.,
#' etc) por S/N.
#'
#' @examples
#' numeros <- c("0210", "001", "1", "", "S N", "S/N", "SN", "0180  0181")
#' padronizar_numeros(numeros)
#'
#' numeros <- c(210, 1, 10000, NA)
#' padronizar_numeros(numeros)
#'
#' @export
padronizar_estados <- function(estados) {
  checkmate::assert(
    checkmate::check_character(estados),
    checkmate::check_numeric(estados),
    combine = "or"
  )

  # alguns estados podem vir vazios e devem permanecer vazios ao final.
  #
  # FIXME: esse texto continua relevante?
  # nesse caso,
  # a chamada da str_pad() abaixo faz com que esses ceps virem '00000000'. para
  # evitar que o resultado contenha esses valores, identificamos o indice dos
  # ceps vazios para "reesvazia-los" ao final

  indice_estado_vazio <- which(estados == "" | is.na(estados))

  estados_padrao <- if (is.numeric(estados)) {
    formatC(estados, format = "d")
  } else {
    estados
  }

  # FIXME: provavelmente dá pra fazer isso aqui só condicionalmente, depois da busca com os vetores
  estados_padrao <- stringr::str_squish(estados_padrao)
  estados_padrao <- toupper(estados_padrao)
  estados_padrao <- stringi::stri_trans_general(estados_padrao, "Latin-ASCII")

  vetor_busca_com_cod <- vetor_busca_com_abrev <- codigos_estados$nome_estado
  names(vetor_busca_com_cod) <- codigos_estados$codigo_estado
  names(vetor_busca_com_abrev) <- codigos_estados$abrev_estado

  result_busca_com_cod <- vetor_busca_com_cod[estados_padrao]
  result_busca_com_abrev <- vetor_busca_com_abrev[estados_padrao]

  estados_padrao <- ifelse(
    is.na(result_busca_com_cod),
    result_busca_com_abrev,
    result_busca_com_cod
  )
  names(estados_padrao) <- NULL

  estados_padrao[indice_estado_vazio] <- ""

  return(estados_padrao)
}
