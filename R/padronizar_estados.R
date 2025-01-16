#' Padronizar estados
#'
#' Padroniza um vetor de caracteres ou números representando estados
#' brasileiros. Veja a seção *Detalhes* para mais informações sobre a
#' padronização.
#'
#' @param estados Um vetor de caracteres ou números. Os estados a serem
#'   padronizados.
#' @param formato Uma string. Como o resultado padronizado deve ser formatado.
#'   Por padrão, `"por_extenso"`, fazendo com que a função retorne o nome dos
#'   estados por extenso. Se `"sigla"`, a função retorna a sigla dos estados.
#'
#' @return Um vetor de caracteres com os estados padronizados.
#'
#' @section Detalhes:
#' Operações realizadas durante a padronização:
#'
#' - conversão para caracter, se o input for numérico;
#' - remoção de espaços em branco antes e depois dos valores e remoção de
#' espaços em excesso entre palavras;
#' - conversão de caracteres para caixa alta;
#' - remoção de zeros à esquerda;
#' - busca, a partir do código numérico ou da abreviação da UF, do nome
#' completo de cada estado;
#' - caso a busca não tenha encontrado determinado valor, remoção de acentos e
#' caracteres não ASCII.
#'
#' @examples
#' estados <- c("21", "021", "MA", " 21", " MA ", "ma", "", NA)
#' padronizar_estados(estados)
#'
#' estados <- c(21, NA)
#' padronizar_estados(estados)
#' padronizar_estados(estados, formato = "sigla")
#'
#' @export
padronizar_estados <- function(estados, formato = "por_extenso") {
  checkmate::assert(
    checkmate::check_character(estados),
    checkmate::check_numeric(estados),
    combine = "or"
  )
  checkmate::assert(
    checkmate::check_string(formato),
    checkmate::check_names(formato, subset.of = c("por_extenso", "sigla")),
    combine = "and"
  )

  estados_dedup <- unique(estados)

  # alguns estados podem vir vazios e devem permanecer vazios ao final.
  # identificamos o indice dos estados vazios para "reesvazia-los" ao final, ja
  # que a sequencia de operacoes abaixo acabaria atribuindo um valor a eles

  indice_estado_vazio <- which(is.na(estados))

  if (is.numeric(estados_dedup)) {
    estados_padrao_dedup <- formatC(estados_dedup, format = "d")
  } else {
    estados_padrao_dedup <- stringr::str_squish(estados_dedup)
    estados_padrao_dedup <- toupper(estados_padrao_dedup)
    estados_padrao_dedup <- stringi::stri_trans_general(
      estados_padrao_dedup,
      "Latin-ASCII"
    )
    estados_padrao_dedup <- re2::re2_replace_all(
      estados_padrao_dedup,
      "\\b0+(\\d+)\\b", "\\1"
    )
  }

  variavel_buscada <- ifelse(
    formato == "por_extenso",
    "nome_estado",
    "abrev_estado"
  )

  vetor_busca_com_cod <- codigos_estados[[variavel_buscada]]
  vetor_busca_com_abrev <- vetor_busca_com_nome <- vetor_busca_com_cod

  names(vetor_busca_com_cod) <- codigos_estados$codigo_estado
  names(vetor_busca_com_abrev) <- codigos_estados$abrev_estado
  names(vetor_busca_com_nome) <- codigos_estados$nome_estado

  result_busca_com_cod <- vetor_busca_com_cod[estados_padrao_dedup]
  result_busca_com_abrev <- vetor_busca_com_abrev[estados_padrao_dedup]
  result_busca_com_nome <- vetor_busca_com_nome[estados_padrao_dedup]

  estados_padrao_dedup <- ifelse(
    is.na(result_busca_com_cod),
    result_busca_com_abrev,
    result_busca_com_cod
  )
  estados_padrao_dedup <- ifelse(
    is.na(estados_padrao_dedup),
    result_busca_com_nome,
    estados_padrao_dedup
  )

  names(estados_padrao_dedup) <- NULL

  estados_padrao_dedup <- ifelse(
    is.na(estados_padrao_dedup),
    estados_dedup,
    estados_padrao_dedup
  )

  names(estados_padrao_dedup) <- estados_dedup
  estados_padrao <- estados_padrao_dedup[as.character(estados)]
  names(estados_padrao) <- NULL

  estados_padrao[indice_estado_vazio] <- NA_character_

  return(estados_padrao)
}
