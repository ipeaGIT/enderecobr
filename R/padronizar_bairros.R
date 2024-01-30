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
#' 1. remoção de espaços em branco antes e depois das strings e remoção de
#' espaços em excesso entre palavras;
#' 2. conversão de caracteres para caixa alta;
#' 3. remoção de acentos e caracteres não ASCII;
#' 4. adição de espaços após abreviações sinalizadas por pontos.
#'
#' @examples
#' bairros <- c("PRQ IND", "NSA SEN DE FATIMA", "ILHA DO GOV")
#' padronizar_bairros(bairros)
#'
#' @export
padronizar_bairros <- function(bairros) {
  checkmate::assert_character(bairros)

  # alguns bairros podem vir vazios e devem permanecer vazios ao final.
  # identificamos o indice dos bairros vazios para "reesvazia-los" ao final,
  # ja que a sequencia de operacoes abaixo acabaria atribuindo um valor a eles

  indice_bairro_vazio <- which(bairros == "" | is.na(bairros))

  bairros_padrao <- stringr::str_squish(bairros)
  bairros_padrao <- toupper(bairros_padrao)
  bairros_padrao <- stringi::stri_trans_general(bairros_padrao, "Latin-ASCII")

  bairros_padrao <- stringr::str_replace_all(
    bairros_padrao,
    c(
      # pontuacao
      "\\.\\.+" = ".",         # remover pontos repetidos
      "\\.([^ ])" = "\\. \\1", # garantir que haja espaco depois do ponto

      # localidades
      "\\bRES(I?D)?\\b\\.?" = "RESIDENCIAL",
      "\\bJ(DM?|A?RD)\\b\\.?" = "JARDIM",
      "\\b(PCA|PRC)\\b\\.?" = "PRACA",
      "\\bP(R?Q|QUE)\\b\\.?" = "PARQUE",
      "^VL?\\b\\.?" = "VILA", # melhor restringir ao comeco dos nomes, caso contrario pode ser algarismo romano ou nome abreviado
      "\\bCID\\b\\.?" = "CIDADE",
      "\\bCIDADE UNI(VERS)?\\b\\.?" = "CIDADE UNIVERSITARIA",
      "\\bCTO\\b\\.?" = "CENTRO",
      "\\bDISTR?\\b\\.?" = "DISTRITO",
      "^DIS\\b\\.?" = "DISTRITO",
      "\\bCHAC\\b\\.?" = "CHACARA",
      "^CH\\b\\.?" = "CHACARA",
      "\\bC(ON)?J\\b\\.?" = "CONJUNTO",
      "\\bCONJUNTO (H(B|AB(IT)?)?)\\b\\.?" = "CONJUNTO HABITACIONAL",
      "\\bSTR\\b\\.?" = "SETOR", # ST pode ser setor ou santo/santa, talvez melhor manter só STR mesmo e fazer mudanças mais específicas com ST
      "\\bIND(L|TRL|UST?)?\\b\\.?" = "INDUSTRIAL",
      "\\bLOT\\b\\.?[^$]" = "LOTEAMENTO",
      "^LT\\b\\.?" = "LOTEAMENTO",
      "\\bZN\\b\\.?" = "ZONA",
      "^Z\\b\\.?" = "ZONA",
      "^POV\\b\\.?" = "POVOADO",

      # titulos
      "\\bSTO\\b\\.?" = "SANTO",
      "\\bSTA\\b\\.?" = "SANTA",
      "\\bSRA\\b\\.?" = "SENHORA",
      "\\b(N(S|SA)?\\.? SENHORA|(NOSSA|NSA\\.?) (SR?|SEN))\\b\\.?" = "NOSSA SENHORA",

      "\\bALMTE\\b\\.?" = "ALMIRANTE",
      "\\bMAL\\b\\.?[^$]" = "MARECHAL",
      "\\bSGTO?\\b\\.?" = "SARGENTO",
      "\\bCEL\\b\\.?" = "CORONEL",
      "\\bBRIG\\b\\.?" = "BRIGADEIRO",
      "\\bTEN\\b\\.?" = "TENENTE",
      "\\bBRIGADEIRO (F\\.?|FARIA) (L|LIMA)\\b\\.?" = "BRIGADEIRO FARIA LIMA",

      "\\bPRES(ID)?\\b\\.?[^$]" = "PRESIDENTE",
      "\\bGOV\\b\\.?" = "GOVERNADOR", # pode acabar com GOV. - e.g. ilha do gov.
      "\\bPREF\\b\\.?[^$]" = "PREFEITO",
      "\\bDEP\\b\\.?[^$]" = "DEPUTADO"
    )
  )

  return(bairros_padrao)
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
