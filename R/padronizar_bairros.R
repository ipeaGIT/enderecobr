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

  bairros_dedup <- unique(bairros)

  # alguns bairros podem vir vazios e devem permanecer vazios ao final.
  # identificamos o indice dos bairros vazios para "reesvazia-los" ao final,
  # ja que a sequencia de operacoes abaixo acabaria atribuindo um valor a eles

  indice_bairro_vazio <- which(is.na(bairros) | bairros == "")

  bairros_padrao_dedup <- stringr::str_squish(bairros_dedup)
  bairros_padrao_dedup <- toupper(bairros_padrao_dedup)
  bairros_padrao_dedup <- stringi::stri_trans_general(
    bairros_padrao_dedup,
    "Latin-ASCII"
  )

  bairros_padrao_dedup <- stringr::str_replace_all(
    bairros_padrao_dedup,
    c(
      # pontuacao
      "\\.\\.+" = ".",         # remover pontos repetidos
      "\\.([^ ])" = "\\. \\1", # garantir que haja espaco depois do ponto

      # localidades
      "\\bRES(I?D)?\\b\\.?" = "RESIDENCIAL",
      "\\bJ(D(I?M)?|A?RD)\\b\\.?" = "JARDIM",
      "^JR\\b\\.?" = "JARDIM",
      "\\b(PCA|PRC)\\b\\.?" = "PRACA",
      "\\bP((A?R)?Q|QU?E)\\b\\.?" = "PARQUE",
      "\\bP\\.? RESIDENCIAL\\b" = "PARQUE RESIDENCIAL",
      "^VL?\\b\\.?" = "VILA", # melhor restringir ao comeco dos nomes, caso contrario pode ser algarismo romano ou nome abreviado
      "\\bCID\\b\\.?" = "CIDADE",
      "\\bCIDADE UNI(V(ERS)?)?\\b\\.?" = "CIDADE UNIVERSITARIA",
      "\\bC\\.? UNIVERSITARIA\\b" = "CIDADE UNIVERSITARIA",
      "\\bCTO\\b\\.?" = "CENTRO",
      "\\bDISTR?\\b\\.?" = "DISTRITO",
      "^DIS\\b\\.?" = "DISTRITO",
      "\\bCHA?C\\b\\.?" = "CHACARA",
      "^CH\\b\\.?" = "CHACARA",
      "\\bC(ON?)?J\\b\\.?" = "CONJUNTO",
      "^C\\.? J\\b\\.?" = "CONJUNTO",
      "\\bC(ONJUNTO)? (H(B|AB(IT)?)?)\\b\\.?" = "CONJUNTO HABITACIONAL",
      "\\bSTR\\b\\.?" = "SETOR", # ST pode ser setor, santo/santa ou sitio. talvez melhor manter só STR mesmo e fazer mudanças mais específicas com ST
      "^SET\\b\\.?" = "SETOR",
      "\\b(DAS|DE) IND(L|TRL|US(TR?)?)?\\b\\.?" = "\\1 INDUSTRIAS",
      "\\bIND(L|TRL|US(TR?)?)?\\b\\.?" = "INDUSTRIAL",
      "\\bD\\.? INDUSTRIAL\\b" = "DISTRITO INDUSTRIAL",
      "\\bS\\.? INDUSTRIAL\\b" = "SETOR INDUSTRIAL",
      "\\b(P\\.? INDUSTRIAL|PARQUE IN)\\b\\.?" = "PARQUE INDUSTRIAL",
      "\\bLOT(EAME?)?\\b\\.?[^$]" = "LOTEAMENTO",
      "^LT\\b\\.?" = "LOTEAMENTO",
      "\\bZN\\b\\.?" = "ZONA",
      "^Z\\b\\.?" = "ZONA",
      "\\bZONA R(UR?)?\\b\\.?" = "ZONAL RURAL",
      "^POV\\b\\.?" = "POVOADO",
      "\\bNUCL?\\b\\.?" = "NUCLEO",
      "\\b(NUCLEO|N\\.?) H(AB)?\\b\\.?" = "NUCLEO HABITACIONAL",
      "\\b(NUCLEO|N\\.?) C(OL)?\\b\\.?" = "NUCLEO COLONIAL",
      "\\bN\\.? INDUSTRIAL\\b" = "NUCLEO INDUSTRIAL",
      "\\bN\\.? RESIDENCIAL\\b" = "NUCLEO RESIDENCIAL",
      "\\bBALN?\\b\\.?" = "BALNEARIO",
      "\\bFAZ(EN?)?\\b\\.?" = "FAZENDA",
      "\\bBS?Q\\b\\.?" = "BOSQUE",
      "\\bCACH\\b\\.?" = "CACHOEIRA",
      "\\bTAB\\b\\.?" = "TABULEIRO",
      "\\bCOND\\b\\.?" = "CONDOMINIO",
      "\\bRECR?\\.? (DOS? )?BAND.*\\b\\.?" = "RECREIO DOS BANDEIRANTES",
      "\\bREC\\b\\.?" = "RECANTO",
      "^COR\\b\\.?" = "CORREGO",
      "\\bENG\\.? (D(A|E|O)|V(LH?|ELHO)?|NOVO|CACHOEIRINHA|GRANDE)\\b" = "ENGENHO \\1",
      "^TAG\\b\\.?" = "TAGUATINGA",
      "^ASS(ENT)?\\b\\.?" = "ASSENTAMENTO",
      "^SIT\\b\\.?" = "SITIO",
      "^CAM\\b\\.?" = "CAMINHO",
      "\\bCERQ\\b\\.?" = "CERQUEIRA",
      "\\bCONS\\b\\.?[^$]" = "CONSELHEIRO",
      "\\bPROL\\b\\.?[^$]" = "PROLONGAMENTO",

      # titulos
      "\\bSTO\\b\\.?" = "SANTO",
      "\\bSTOS\\b\\.?" = "SANTOS",
      "\\bSTA\\b\\.?" = "SANTA",
      "\\bSRA\\b\\.?" = "SENHORA",
      "\\b(N(OS|SS?A?)?\\.? S(RA|ENHORA)|(NOSSA|NSA\\.?) (S(RA?)?|SEN(H(OR)?)?))\\b\\.?" = "NOSSA SENHORA",
      "\\b(NS?\\.? S(R|ENH?)?\\.?( DE?)?|NOSSA SENHORA) (FAT.*|LO?UR.*|SANTANA|GUADALUPE|NAZ.*)\\b" = "NOSSA SENHORA DE \\4",
      "\\b(NS?\\.? S(R|ENH?)?\\.?( D(A|E)?)?|NOSSA SENHORA) (GRACA|VITORIA|PENHA|CONCEICAO|PAZ|GUIA|AJUDA|CANDELARIA|PURIFICACAO|SAUDE|PIEDADE|ABADIA|GLORIA|SALETE|APRESENTACAO)\\b" = "NOSSA SENHORA DA \\5",
      "\\b(NS?\\.? S(R|ENH?)?\\.?( D(A|E)?)?|NOSSA SENHORA D(A|E)) (APA.*|AUX.*|MEDIANEIRA|CONSOLADORA)\\b" = "NOSSA SENHORA \\6",
      "\\b(NS?\\.? S(R|ENH?)?\\.?( D(OS?)?)?|NOSSA SENHORA) (NAVEGANTES)\\b" = "NOSSA SENHORA DOS \\5",
      "\\b(NS?\\.? S(R|ENH?)?\\.?( DO?)?|NOSSA SENHORA) (CARMO|LIVRAMENTO|RETIRO|SION|ROSARIO|PILAR|ROCIO|CAMINHO|DESTERRO|BOM CONSELHO|AMPARO|PERP.*|P.* S.*)\\b" = "NOSSA SENHORA DO \\4",
      "\\b(NS?\\.? S(R|ENH?)?\\.?( D(AS?)?)?|NOSSA SENHORA) (GRACAS|DORES)\\b" = "NOSSA SENHORA DAS \\5",
      "\\bNOSSO (SR?|SEN)\\b\\.?" = "NOSSO SENHOR",
      "\\bESP?\\.? SANTO" = "ESPIRITO SANTO",
      "\\bDIV\\.? ESPIRITO SANTO\\b" = "DIVINO ESPIRITO SANTO",
      "\\bS\\.? (PAULO|VICENTE|FRANCISCO|DOMINGOS?|CRISTOVAO)\\b" = "SAO \\1",

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
      "\\bDEP\\b\\.?[^$]" = "DEPUTADO",

      "\\bDR\\b\\.?" = "DOUTOR",
      "\\bDRA\\b\\.?" = "DOUTORA",
      "\\bPROF\\b\\.?" = "PROFESSOR",
      "\\bPROFA\\b\\.?" = "PROFESSORA",
      "\\bPE\\b\\.[^$]" = "PADRE",

      "\\bD\\b\\.? (PEDRO|JOAO|HENRIQUE)" = "DOM \\1",
      "\\bI(NF)?\\.? DOM\\b" = "INFANTE DOM"
    )
  )

  names(bairros_padrao_dedup) <- bairros_dedup
  bairros_padrao <- bairros_padrao_dedup[bairros]
  names(bairros_padrao) <- NULL

  bairros_padrao[indice_bairro_vazio] <- ""

  return(bairros_padrao)
}
