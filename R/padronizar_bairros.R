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
#' bairros <- c("PRQ IND", "NSA SEN DE FATIMA", "ILHA DO GOV", "jd..botanico")
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

  bairros_padrao_dedup <- re2::re2_replace_all(
    bairros_padrao_dedup,

      # pontuacao
      "\\.\\.+", ".") |>         # remover pontos repetidos

      # sinalizacao
      re2::re2_replace_all(r"{"}", "'") |> # existem ocorrencias em que aspas duplas sao usadas para se referir a um logradouro/quadra com nome relativamente ambiguo - e.g. RUA \"A\", 26. isso pode causar um problema quando lido com o data.table: https://github.com/Rdatatable/data.table/issues/4779. por enquanto, substituindo por aspas simples. depois a gente pode ver o que fazer com as aspas simples rs.

      # valores non-sense
      re2::re2_replace_all(r"{^(0|-)+$}", "") |> # - --+ 0 00+
      re2::re2_replace_all(r"{^([^\dIX])\\1{1,}$}", "") |> # qualquer valor não numérico ou romano repetido 2+ vezes
      re2::re2_replace_all(r"{^(\d)\\1{3,}$}", "") |> # assumindo que qualquer numero que apareca 4 ou mais vezes repetido eh um erro de digitacao
      re2::re2_replace_all(r"{^I{4,}$}", "") |> # IIII+
      re2::re2_replace_all(r"{^X{3,}$}", "") |> # XXX+

      # localidades
      re2::re2_replace_all(r"{\bJAR DIM\b}", "JARDIM") |>
      re2::re2_replace_all("^JR\\b\\.?", "JARDIM") |>
      re2::re2_replace_all("\\b(PCA|PRC)\\b\\.?", "PRACA") |>
      re2::re2_replace_all("\\bP((A?R)?Q|QU?E)\\b\\.?", "PARQUE") |>
      re2::re2_replace_all("\\bP\\.? RESIDENCIAL\\b", "PARQUE RESIDENCIAL") |>
      re2::re2_replace_all("^VL?\\b\\.?", "VILA") |> # melhor restringir ao comeco dos nomes, caso contrario pode ser algarismo romano ou nome abreviado
      re2::re2_replace_all("\\bCID\\b\\.?", "CIDADE") |>
      re2::re2_replace_all("\\bCIDADE UNI(V(ERS)?)?\\b\\.?", "CIDADE UNIVERSITARIA") |>
      re2::re2_replace_all("\\bC\\.? UNIVERSITARIA\\b", "CIDADE UNIVERSITARIA") |>
      re2::re2_replace_all("\\bCTO\\b\\.?", "CENTRO") |>
      re2::re2_replace_all("\\bDISTR?\\b\\.?", "DISTRITO") |>
      re2::re2_replace_all("^DIS\\b\\.?", "DISTRITO") |>
      re2::re2_replace_all("\\bCHA?C\\b\\.?", "CHACARA") |>
      re2::re2_replace_all("^CH\\b\\.?", "CHACARA") |>
      re2::re2_replace_all("\\bC(ON?)?J\\b\\.?", "CONJUNTO") |>
      re2::re2_replace_all("^C\\.? J\\b\\.?", "CONJUNTO") |>
      re2::re2_replace_all("\\bC(ONJUNTO)? (H(B|AB(IT)?)?)\\b\\.?", "CONJUNTO HABITACIONAL") |>
      re2::re2_replace_all("\\bSTR\\b\\.?", "SETOR") |> # ST pode ser setor, santo/santa ou sitio. talvez melhor manter só STR mesmo e fazer mudanças mais específicas com ST
      re2::re2_replace_all("^SET\\b\\.?", "SETOR") |>
      re2::re2_replace_all("\\b(DAS|DE) IND(L|TRL|US(TR?)?)?\\b\\.?", "\\1 INDUSTRIAS") |>
      re2::re2_replace_all("\\bIND(L|TRL|US(TR?)?)?\\b\\.?", "INDUSTRIAL") |>
      re2::re2_replace_all("\\bD\\.? INDUSTRIAL\\b", "DISTRITO INDUSTRIAL") |>
      re2::re2_replace_all("\\bS\\.? INDUSTRIAL\\b", "SETOR INDUSTRIAL") |>
      re2::re2_replace_all("\\b(P\\.? INDUSTRIAL|PARQUE IN)\\b\\.?", "PARQUE INDUSTRIAL") |>
      re2::re2_replace_all("^LT\\b\\.?", "LOTEAMENTO") |>
      re2::re2_replace_all("\\bZN\\b\\.?", "ZONA") |>
      re2::re2_replace_all("^Z\\b\\.?", "ZONA") |>
      re2::re2_replace_all("\\bZONA R(UR?)?\\b\\.?", "ZONAL RURAL") |>
      re2::re2_replace_all("^POV\\b\\.?", "POVOADO") |>
      re2::re2_replace_all("\\bNUCL?\\b\\.?", "NUCLEO") |>
      re2::re2_replace_all("\\b(NUCLEO|N\\.?) H(AB)?\\b\\.?", "NUCLEO HABITACIONAL") |>
      re2::re2_replace_all("\\b(NUCLEO|N\\.?) C(OL)?\\b\\.?", "NUCLEO COLONIAL") |>
      re2::re2_replace_all("\\bN\\.? INDUSTRIAL\\b", "NUCLEO INDUSTRIAL") |>
      re2::re2_replace_all("\\bN\\.? RESIDENCIAL\\b", "NUCLEO RESIDENCIAL") |>
      re2::re2_replace_all("\\bBALN?\\b\\.?", "BALNEARIO") |>
      re2::re2_replace_all("\\bFAZ(EN?)?\\b\\.?", "FAZENDA") |>
      re2::re2_replace_all("\\bBS?Q\\b\\.?", "BOSQUE") |>
      re2::re2_replace_all("\\bCACH\\b\\.?", "CACHOEIRA") |>
      re2::re2_replace_all("\\bTAB\\b\\.?", "TABULEIRO") |>
      re2::re2_replace_all("\\bCOND\\b\\.?", "CONDOMINIO") |>
      re2::re2_replace_all("\\bRECR?\\.? (DOS? )?BAND.*\\b\\.?", "RECREIO DOS BANDEIRANTES") |>
      re2::re2_replace_all("\\bREC\\b\\.?", "RECANTO") |>
      re2::re2_replace_all("^COR\\b\\.?", "CORREGO") |>
      re2::re2_replace_all("\\bENG\\.? (D(A|E|O)|V(LH?|ELHO)?|NOVO|CACHOEIRINHA|GRANDE)\\b", "ENGENHO \\1") |>
      re2::re2_replace_all("^TAG\\b\\.?", "TAGUATINGA") |>
      re2::re2_replace_all("^ASS(ENT)?\\b\\.?", "ASSENTAMENTO") |>
      re2::re2_replace_all("^SIT\\b\\.?", "SITIO") |>
      re2::re2_replace_all("^CAM\\b\\.?", "CAMINHO") |>
      re2::re2_replace_all("\\bCERQ\\b\\.?", "CERQUEIRA") |>

      # titulos
      re2::re2_replace_all("\\bSTO\\b\\.?", "SANTO") |>
      re2::re2_replace_all("\\bSTOS\\b\\.?", "SANTOS") |>
      re2::re2_replace_all("\\bSTA\\b\\.?", "SANTA") |>
      re2::re2_replace_all("\\bSRA\\b\\.?", "SENHORA") |>
      re2::re2_replace_all("\\b(N(OS|SS?A?)?\\.? S(RA|ENHORA)|(NOSSA|NSA\\.?) (S(RA?)?|SEN(H(OR)?)?))\\b\\.?", "NOSSA SENHORA") |>
      re2::re2_replace_all(r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( DE?)?|NOSSA SENHORA|NS) (FAT.*|LO?UR.*|SANTANA|GUADALUPE|NAZ.*|COP*)\b}", "NOSSA SENHORA DE \\7") |>
      re2::re2_replace_all(r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(A|E)?)?|NOSSA SENHORA|NS) (GRACA|VITORIA|PENHA|CONCEICAO|PAZ|GUIA|AJUDA|CANDELARIA|PURIFICACAO|SAUDE|PIEDADE|ABADIA|GLORIA|SALETE|APRESENTACAO)\b}", "NOSSA SENHORA DA \\8") |>
      re2::re2_replace_all(r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(A|E)?)?|NOSSA SENHORA D(A|E)|NS) (APA.*|AUX.*|MEDIANEIRA|CONSOLADORA)\b}", "NOSSA SENHORA \\9") |>
      re2::re2_replace_all(r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSA SENHORA|NS) (NAVEGANTES)\b}", "NOSSA SENHORA DOS \\8") |>
      re2::re2_replace_all(r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( DO?)?|NOSSA SENHORA|NS) (CARMO|LIVRAMENTO|RETIRO|SION|ROSARIO|PILAR|ROCIO|CAMINHO|DESTERRO|BOM CONSELHO|AMPARO|PERP.*|P.* S.*)\b}", "NOSSA SENHORA DO \\7") |>
      re2::re2_replace_all(r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(AS?)?)?|NOSSA SENHORA|NS) (GRACAS|DORES)\b}", "NOSSA SENHORA DAS \\8") |>
      re2::re2_replace_all(r"{\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR( D(OS)?)?) (BON\w*)\b}", "SENHOR DO BONFIM") |>
      re2::re2_replace_all(r"{\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR( D(OS?)?)?) (BOM ?F\w*)\b}", "SENHOR DO BONFIM") |>
      re2::re2_replace_all(r"{\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR) (PASS\w*|MONT\w*)\b}", "SENHOR DOS \\5") |>
      re2::re2_replace_all(r"{\bS(R|ENH?)\.? (BOM J\w*)\b}", "SENHOR BOM JESUS") |>
      re2::re2_replace_all(r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSO SENHOR|NS) (BONF\w*|BOM ?F\w*)\b}", "NOSSO SENHOR DO BONFIM") |>
      re2::re2_replace_all(r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSO SENHOR|NS) (PASS\w*|MONT\w*)\b}", "NOSSO SENHOR DOS \\8") |>
      re2::re2_replace_all("\\bESP?\\.? SANTO", "ESPIRITO SANTO") |>
      re2::re2_replace_all("\\bDIV\\.? ESPIRITO SANTO\\b", "DIVINO ESPIRITO SANTO") |>
      re2::re2_replace_all("\\bS\\.? (PAULO|VICENTE|FRANCISCO|DOMINGOS?|CRISTOVAO)\\b", "SAO \\1") |>

      re2::re2_replace_all("\\bALMTE\\b\\.?", "ALMIRANTE") |>
      re2::re2_replace_all("\\bSGTO?\\b\\.?", "SARGENTO") |>
      re2::re2_replace_all("\\bCEL\\b\\.?", "CORONEL") |>
      re2::re2_replace_all("\\bBRIG\\b\\.?", "BRIGADEIRO") |>
      re2::re2_replace_all("\\bTEN\\b\\.?", "TENENTE") |>
      re2::re2_replace_all("\\bBRIGADEIRO (F\\.?|FARIA) (L|LIMA)\\b\\.?", "BRIGADEIRO FARIA LIMA") |>

      # consertar esse presidente
      re2::re2_replace_all("\\bGOV\\b\\.?", "GOVERNADOR") |> # pode acabar com GOV. - e.g. ilha do gov.

      re2::re2_replace_all("\\bDR\\b\\.?", "DOUTOR") |>
      re2::re2_replace_all("\\bDRA\\b\\.?", "DOUTORA") |>
      re2::re2_replace_all("\\bPROF\\b\\.?", "PROFESSOR") |>
      re2::re2_replace_all("\\bPROFA\\b\\.?", "PROFESSORA") |>

      re2::re2_replace_all("\\bD\\b\\.? (PEDRO|JOAO|HENRIQUE)", "DOM \\1") |>
      re2::re2_replace_all("\\bI(NF)?\\.? DOM\\b", "INFANTE DOM")




  bairros_padrao_dedup <- stringr::str_replace_all(
        bairros_padrao_dedup,
        c(

      "\\.([^ ])" = "\\. \\1", # garantir que haja espaco depois do ponto

      "\\bRES(I?D)?\\b\\.?" = "RESIDENCIAL",
      r"{\bJ(D(I?M)?|A?RD|AR(DIN)?)\b\.?}" = "JARDIM",

      # titulos / invalid perl operator: (?!
      "\\bMAL\\b\\.?(?!$)" = "MARECHAL",
      "\\bPRES(ID)?\\b\\.?(?!$)" = "PRESIDENTE",
      "\\bPREF\\b\\.?(?!$)" = "PREFEITO",
      "\\bDEP\\b\\.?(?!$)" = "DEPUTADO",
      "\\bPE\\b\\.(?!$)" = "PADRE",
      "\\bLOT(EAME?)?\\b\\.?(?!$)" = "LOTEAMENTO",
      "\\bCONS\\b\\.?(?!$)" = "CONSELHEIRO", # CONS COMUN => CONSELHO COMUNITARIO, provavelmente
      "\\bPROL\\b\\.?(?!$)" = "PROLONGAMENTO",

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
