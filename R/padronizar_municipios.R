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
#' caracteres não ASCII, correção de erros ortográficos frequentes e atualização
#' de nomes conforme listagem de municípios do IBGE de 2022.
#'
#' @examples
#' municipios <- c(
#'   "3304557", "003304557", " 3304557 ", "RIO DE JANEIRO", "rio de janeiro",
#'   "SÃO PAULO",
#'   "", NA
#' )
#' padronizar_municipios(municipios)
#'
#' municipios <- c(3304557, NA)
#' padronizar_municipios(municipios)
#'
#' municipios <- c("PARATI", "AUGUSTO SEVERO", "SAO VALERIO DA NATIVIDADE")
#' padronizar_municipios(municipios)
#'
#' @export
padronizar_municipios <- function(municipios) {
  checkmate::assert(
    checkmate::check_character(municipios),
    checkmate::check_numeric(municipios),
    combine = "or"
  )

  municipios_dedup <- unique(municipios)

  # alguns municipios podem vir vazios e devem permanecer vazios ao final.
  # identificamos o indice dos municipios vazios para "reesvazia-los" ao final,
  # ja que a sequencia de operacoes abaixo acabaria atribuindo um valor a eles

  indice_municipio_vazio <- which(municipios == "" | is.na(municipios))

  if (is.numeric(municipios_dedup)) {
    municipios_padrao_dedup <- formatC(municipios_dedup, format = "d")
  } else {
    municipios_padrao_dedup <- stringr::str_squish(municipios_dedup)
    municipios_padrao_dedup <- toupper(municipios_padrao_dedup)
    municipios_padrao_dedup <- stringr::str_replace_all(
      municipios_padrao_dedup,
      c("\\b0+(\\d+)\\b" = "\\1")
    )
  }

  # em uma primeira etapa, fazemos uma busca dos nomes completos dos municipios
  # a partir de seus códigos numericos. esses codigos aparecem tanto em sua
  # versao com 7 quanto com 6 digitos, logo usamos as duas opcoes na busca. apos
  # essa etapa, se ainda houver algum registro de valor diferente dos nomes
  # completos padroes, fazemos uma serie de manipulacoes de string que tomam um
  # pouco mais de tempo

  vetor_busca_com_cod7 <- vetor_busca_com_cod6 <- codigos_municipios$nome_muni
  names(vetor_busca_com_cod7) <- codigos_municipios$codigo_muni
  names(vetor_busca_com_cod6) <- substr(codigos_municipios$codigo_muni, 1, 6)

  result_busca_com_cod7 <- vetor_busca_com_cod7[municipios_padrao_dedup]
  result_busca_com_cod6 <- vetor_busca_com_cod6[municipios_padrao_dedup]

  result_busca_com_cod <- ifelse(
    is.na(result_busca_com_cod7),
    result_busca_com_cod6,
    result_busca_com_cod7
  )

  municipios_padrao_dedup <- ifelse(
    is.na(result_busca_com_cod),
    municipios_padrao_dedup,
    result_busca_com_cod
  )
  names(municipios_padrao_dedup) <- NULL

  municipio_nao_padrao <- !(
    municipios_padrao_dedup %in% c(codigos_municipios$nome_muni, "", NA)
  )

  if (any(municipio_nao_padrao)) {
    municipios_padrao_dedup[municipio_nao_padrao] <- manipular_nome_muni(
      municipios_padrao_dedup[municipio_nao_padrao]
    )
  }

  names(municipios_padrao_dedup) <- municipios_dedup
  municipios_padrao <- municipios_padrao_dedup[as.character(municipios)]
  names(municipios_padrao) <- NULL

  municipios_padrao[indice_municipio_vazio] <- ""

  return(municipios_padrao)
}

manipular_nome_muni <- function(muni) {
  muni <- stringi::stri_trans_general(muni, "Latin-ASCII")

  muni <- stringr::str_replace_all(
    muni,
    c(
      "^MOJI MIRIM$" = "MOGI MIRIM",
      "^GRAO PARA$" = "GRAO-PARA",
      "^BIRITIBA-MIRIM$" = "BIRITIBA MIRIM",
      "^SAO LUIS DO PARAITINGA$" = "SAO LUIZ DO PARAITINGA",
      "^TRAJANO DE MORAIS$" = "TRAJANO DE MORAES",
      "^PARATI$" = "PARATY",
      "^LAGOA DO ITAENGA$" = "LAGOA DE ITAENGA",
      "^ELDORADO DOS CARAJAS$" = "ELDORADO DO CARAJAS",
      "^SANTANA DO LIVRAMENTO$" = "SANT'ANA DO LIVRAMENTO",
      "^BELEM DE SAO FRANCISCO$" = "BELEM DO SAO FRANCISCO",
      "^SANTO ANTONIO DO LEVERGER$" = "SANTO ANTONIO DE LEVERGER",
      "^POXOREO$" = "POXOREU",
      "^SAO THOME DAS LETRAS$" = "SAO TOME DAS LETRAS",
      "^OLHO-D'AGUA DO BORGES$" = "OLHO D'AGUA DO BORGES",
      "^ITAPAGE$" = "ITAPAJE",
      "^MUQUEM DE SAO FRANCISCO$" = "MUQUEM DO SAO FRANCISCO",
      "^DONA EUSEBIA$" = "DONA EUZEBIA",
      "^PASSA-VINTE$" = "PASSA VINTE",
      "^AMPARO DE SAO FRANCISCO$" = "AMPARO DO SAO FRANCISCO",
      "^BRASOPOLIS$" = "BRAZOPOLIS",
      "^SERIDO$" = "SAO VICENTE DO SERIDO",
      "^IGUARACI$" = "IGUARACY",
      "^AUGUSTO SEVERO$" = "CAMPO GRANDE",
      "^FLORINIA$" = "FLORINEA",
      "^FORTALEZA DO TABOCAO$" = "TABOCAO",
      "^SAO VALERIO DA NATIVIDADE$" = "SAO VALERIO"
    )
  )

  return(muni)
}
