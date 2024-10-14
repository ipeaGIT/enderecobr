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

      # sinalizacao
      r"{"}" = "'", # existem ocorrencias em que aspas duplas sao usadas para se referir a um logradouro/quadra com nome relativamente ambiguo - e.g. RUA \"A\", 26. isso pode causar um problema quando lido com o data.table: https://github.com/Rdatatable/data.table/issues/4779. por enquanto, substituindo por aspas simples. depois a gente pode ver o que fazer com as aspas simples rs.

      # valores non-sense
      r"{^(0|-)+$}" = "", # - --+ 0 00+
      r"{^([^\dIX])\1{1,}$}" = "", # qualquer valor não numérico ou romano repetido 2+ vezes
      r"{^(\d)\1{3,}$}" = "", # assumindo que qualquer numero que apareca 4 ou mais vezes repetido eh um erro de digitacao
      r"{^I{4,}$}" = "", # IIII+
      r"{^X{3,}$}" = "", # XXX+

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
      "\\bLOT(EAME?)?\\b\\.?(?!$)" = "LOTEAMENTO",
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
      "\\bCONS\\b\\.?(?!$)" = "CONSELHEIRO", # CONS COMUN => CONSELHO COMUNITARIO, provavelmente
      "\\bPROL\\b\\.?(?!$)" = "PROLONGAMENTO",

      # titulos
      "\\bSTO\\b\\.?" = "SANTO",
      "\\bSTOS\\b\\.?" = "SANTOS",
      "\\bSTA\\b\\.?" = "SANTA",
      "\\bSRA\\b\\.?" = "SENHORA",
      "\\b(N(OS|SS?A?)?\\.? S(RA|ENHORA)|(NOSSA|NSA\\.?) (S(RA?)?|SEN(H(OR)?)?))\\b\\.?" = "NOSSA SENHORA",
      r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( DE?)?|NOSSA SENHORA|NS) (FAT.*|LO?UR.*|SANTANA|GUADALUPE|NAZ.*|COP*)\b}" = "NOSSA SENHORA DE \\7",
      r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(A|E)?)?|NOSSA SENHORA|NS) (GRACA|VITORIA|PENHA|CONCEICAO|PAZ|GUIA|AJUDA|CANDELARIA|PURIFICACAO|SAUDE|PIEDADE|ABADIA|GLORIA|SALETE|APRESENTACAO)\b}" = "NOSSA SENHORA DA \\8",
      r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(A|E)?)?|NOSSA SENHORA D(A|E)|NS) (APA.*|AUX.*|MEDIANEIRA|CONSOLADORA)\b}" = "NOSSA SENHORA \\9",
      r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSA SENHORA|NS) (NAVEGANTES)\b}" = "NOSSA SENHORA DOS \\8",
      r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( DO?)?|NOSSA SENHORA|NS) (CARMO|LIVRAMENTO|RETIRO|SION|ROSARIO|PILAR|ROCIO|CAMINHO|DESTERRO|BOM CONSELHO|AMPARO|PERP.*|P.* S.*)\b}" = "NOSSA SENHORA DO \\7",
      r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(AS?)?)?|NOSSA SENHORA|NS) (GRACAS|DORES)\b}" = "NOSSA SENHORA DAS \\8",
      r"{\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR( D(OS)?)?) (BON\w*)\b}" = "SENHOR DO BONFIM",
      r"{\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR( D(OS?)?)?) (BOM ?F\w*)\b}" = "SENHOR DO BONFIM",
      r"{\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR) (PASS\w*|MONT\w*)\b}" = "SENHOR DOS \\5",
      r"{\bS(R|ENH?)\.? (BOM J\w*)\b}" = "SENHOR BOM JESUS",
      r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSO SENHOR|NS) (BONF\w*|BOM ?F\w*)\b}" = "NOSSO SENHOR DO BONFIM",
      r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSO SENHOR|NS) (PASS\w*|MONT\w*)\b}" = "NOSSO SENHOR DOS \\8",
      "\\bESP?\\.? SANTO" = "ESPIRITO SANTO",
      "\\bDIV\\.? ESPIRITO SANTO\\b" = "DIVINO ESPIRITO SANTO",
      "\\bS\\.? (PAULO|VICENTE|FRANCISCO|DOMINGOS?|CRISTOVAO)\\b" = "SAO \\1",

      "\\bALMTE\\b\\.?" = "ALMIRANTE",
      "\\bMAL\\b\\.?(?!$)" = "MARECHAL",
      "\\bSGTO?\\b\\.?" = "SARGENTO",
      "\\bCEL\\b\\.?" = "CORONEL",
      "\\bBRIG\\b\\.?" = "BRIGADEIRO",
      "\\bTEN\\b\\.?" = "TENENTE",
      "\\bBRIGADEIRO (F\\.?|FARIA) (L|LIMA)\\b\\.?" = "BRIGADEIRO FARIA LIMA",

      # consertar esse presidente
      "\\bPRES(ID)?\\b\\.?(?!$)" = "PRESIDENTE",
      "\\bGOV\\b\\.?" = "GOVERNADOR", # pode acabar com GOV. - e.g. ilha do gov.
      "\\bPREF\\b\\.?(?!$)" = "PREFEITO",
      "\\bDEP\\b\\.?(?!$)" = "DEPUTADO",

      "\\bDR\\b\\.?" = "DOUTOR",
      "\\bDRA\\b\\.?" = "DOUTORA",
      "\\bPROF\\b\\.?" = "PROFESSOR",
      "\\bPROFA\\b\\.?" = "PROFESSORA",
      "\\bPE\\b\\.(?!$)" = "PADRE",

      "\\bD\\b\\.? (PEDRO|JOAO|HENRIQUE)" = "DOM \\1",
      "\\bI(NF)?\\.? DOM\\b" = "INFANTE DOM",

      # datas

      r"{\b(\d+) DE? JAN(?!EIRO)\b}" = "\\1 DE JANEIRO",
      r"{\b(\d+) DE? FEV(?!EREIRO)\b}" = "\\1 DE FEVEREIRO",
      r"{\b(\d+) DE? MAR(?!CO)\b}" = "\\1 DE MARCO",
      r"{\b(\d+) DE? ABR(?!IL)\b}" = "\\1 DE ABRIL",
      r"{\b(\d+) DE? MAI(?!O)\b}" = "\\1 DE MAIO",
      r"{\b(\d+) DE? JUN(?!HO)\b}" = "\\1 DE JUNHO",
      r"{\b(\d+) DE? JUL(?!HO)\b}" = "\\1 DE JULHO",
      r"{\b(\d+) DE? AGO(?!STO)\b}" = "\\1 DE AGOSTO",
      r"{\b(\d+) DE? SET(?!EMBRO)\b}" = "\\1 DE SETEMBRO",
      r"{\b(\d+) DE? OUT(?!UBRO)\b}" = "\\1 DE OUTUBRO",
      r"{\b(\d+) DE? NOV(?!EMBRO)\b}" = "\\1 DE NOVEMBRO",
      r"{\b(\d+) DE? DEZ(?!EMBRO)\b}" = "\\1 DE DEZEMBRO"
    )
  )

  names(bairros_padrao_dedup) <- bairros_dedup
  bairros_padrao <- bairros_padrao_dedup[bairros]
  names(bairros_padrao) <- NULL

  bairros_padrao[bairros_padrao == ""] <- NA_character_

  return(bairros_padrao)
}
