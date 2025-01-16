#' Padronizar logradouros
#'
#' Padroniza um vetor de caracteres representando logradouros de municípios
#' brasileiros. Veja a seção *Detalhes* para mais informações sobre a
#' padronização.
#'
#' @param logradouros Um vetor de caracteres. Os logradouros a serem
#'   padronizados.
#'
#' @return Um vetor de caracteres com os logradouros padronizados.
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
#' logradouros <- c("r. gen.. glicério")
#' padronizar_logradouros(logradouros)
#'
#' @export
padronizar_logradouros <- function(logradouros) {
  checkmate::assert_character(logradouros)

  logradouros_dedup <- unique(logradouros)

  logradouros_padrao_dedup <- stringr::str_squish(logradouros_dedup)
  logradouros_padrao_dedup <- toupper(logradouros_padrao_dedup)
  logradouros_padrao_dedup <- stringi::stri_trans_general(
    logradouros_padrao_dedup,
    "Latin-ASCII"
  )

  logradouros_padrao_dedup <- re2::re2_replace_all(
    logradouros_padrao_dedup,

    # pontuacao
    "\\.\\.+", ".") |>               # ponto repetido
    re2::re2_replace_all(",,+", ",") |>                   # virgula repetida
    re2::re2_replace_all(r"{(\d)\.(\d{3})}", "\\1\\2") |> # remocao de separador de milhar
    re2::re2_replace_all("\\.([^ ,])", "\\. \\1") |>      # garantir que haja um espaco depois dos pontos
    re2::re2_replace_all(",([^ ])", ", \\1") |>           # garantir que haja um espaco depois das virgulas
    re2::re2_replace_all(" ,", ",") |>                    # garantir que não haja um espaco antes dos pontos
    re2::re2_replace_all(r"{\.$}", "") |>                 # remocao de ponto final

    # sinalizacao
    re2::re2_replace_all(r"{"}", "'") |> # existem ocorrencias em que aspas duplas sao usadas para se referir a um logradouro/quadra com nome relativamente ambiguo - e.g. RUA \"A\", 26. isso pode causar um problema quando lido com o data.table: https://github.com/Rdatatable/data.table/issues/4779. por enquanto, substituindo por aspas simples. depois a gente pode ver o que fazer com as aspas simples rs.

    # valores non-sense
    re2::re2_replace_all(r"{^(0|-)+$}", "") |> # - --+ 0 00+
    re2::re2_replace_all(r"{^([^\dIX])\\1{1,}$}", "") |> # qualquer valor não numérico ou romano repetido 2+ vezes
    re2::re2_replace_all(r"{^(\d)\\1{3,}$}", "") |> # assumindo que qualquer numero que apareca 4 ou mais vezes repetido eh um erro de digitacao
    re2::re2_replace_all(r"{^I{4,}$}", "") |> # IIII+
    re2::re2_replace_all(r"{^X{3,}$}", "") |> # XXX+

    # tipos de logradouro
    re2::re2_replace_all("^RU?\\b(\\.|,)?", "RUA") |>                                 # R. AZUL -> RUA AZUL
    re2::re2_replace_all("^(RUA|RODOVIA|ROD(\\.|,)?) (RUA|RU?)\\b(\\.|,)?", "RUA") |> # RUA R. AZUL -> RUA AZUL
    re2::re2_replace_all("^RUA\\b(-|,|\\.) *", "RUA ") |>                             # R-AZUL -> RUA AZUL

    re2::re2_replace_all("^(ROD|RDV)\\b(\\.|,)?", "RODOVIA") |>
    re2::re2_replace_all("^(RODOVIA|RUA) (RODOVIA|ROD|RDV)\\b(\\.|,)?", "RODOVIA") |>
    re2::re2_replace_all("^RODOVIA\\b(-|,|\\.) *", "RODOVIA ") |>

    # outros pra rodovia: "RO", "RO D", "ROV"

    re2::re2_replace_all("^AV(E|N|D|DA|I)?\\b(\\.|,)?", "AVENIDA") |>
    re2::re2_replace_all("^(AVENIDA|RUA|RODOVIA) (AVENIDA|AV(E|N|D|DA|I)?)\\b(\\.|,)?", "AVENIDA") |>
    re2::re2_replace_all("^AVENIDA\\b(-|,|\\.) *", "AVENIDA ") |>

    # EST pode ser estancia ou estrada. será que deveríamos assumir que é estrada mesmo?
    re2::re2_replace_all("^(ESTR?|ETR)\\b(\\.|,)?", "ESTRADA") |>
    re2::re2_replace_all("^(ESTRADA|RUA|RODOVIA) (ESTRADA|ESTR?|ETR)\\b(\\.|,)?", "ESTRADA") |>
    re2::re2_replace_all("^ESTRADA\\b(-|,|\\.) *", "ESTRADA ") |>

    re2::re2_replace_all("^(PCA?|PRC)\\b(\\.|,)?", "PRACA") |>
    re2::re2_replace_all("^(PRACA|RUA|RODOVIA) (PRACA|PCA?|PRC)\\b(\\.|,)?", "PRACA") |>
    re2::re2_replace_all("^PRACA\\b(-|,|\\.) *", "PRACA ") |>

    re2::re2_replace_all("^BE?CO?\\b(\\.|,)?", "BECO") |>
    re2::re2_replace_all("^(BECO|RUA|RODOVIA) BE?CO?\\b(\\.|,)?", "BECO") |>
    re2::re2_replace_all("^BE?CO?\\b(-|,|\\.) *", "BECO ") |>

    re2::re2_replace_all("^(TV|TRV|TRAV?)\\b(\\.|,)?", "TRAVESSA") |> # tem varios casos de TR tambem, mas varios desses sao abreviacao de TRECHO, entao eh dificil fazer uma generalizacao
    re2::re2_replace_all("^(TRAVESSA|RODOVIA) (TRAVESSA|TV|TRV|TRAV?)\\b(\\.|,)?", "TRAVESSA") |> # nao botei RUA nas opcoes iniciais porque tem varios ruas que realmente sao RUA TRAVESSA ...
    re2::re2_replace_all("^TRAVESSA\\b(-|,|\\.) *", "TRAVESSA ") |>
    re2::re2_replace_all("^(TRAVESSA|RUA|RODOVIA) (TRAVESSA|TV|TRV|TRAV?)\\b- *", "TRAVESSA ") |> # aqui ja acho que faz sentido botar o RUA porque so da match com padroes como RUA TRAVESSA-1

    re2::re2_replace_all("^P((A?R)?Q|QU?E)\\b(\\.|,)?", "PARQUE") |>
    re2::re2_replace_all("^(PARQUE|RODOVIA) (PARQUE|P((A?R)?Q|QU?E))\\b(\\.|,)?", "PARQUE") |> # mesmo caso de travessa
    re2::re2_replace_all("^PARQUE\\b(-|,|\\.) *", "PARQUE ") |>
    re2::re2_replace_all("^(PARQUE|RUA|RODOVIA) (PARQUE|P((A?R)?Q|QU?E))\\b- *", "PARQUE ") |> # mesmo caso de travessa

    re2::re2_replace_all("^ALA?\\b(\\.|,)?", "ALAMEDA") |>
    re2::re2_replace_all("^ALAMEDA (ALAMEDA|ALA?)\\b(\\.|,)?", "ALAMEDA") |> # mesmo caso de travessa
    re2::re2_replace_all("^RODOVIA (ALAMEDA|ALA)\\b(\\.|,)?", "ALAMEDA") |> # RODOVIA precisa ser separado porque nesse caso nao podemos mudar RODOVIA AL pra ALAMEDA, ja que pode ser uma rodovia estadual de alagoas
    re2::re2_replace_all("^ALAMEDA\\b(-|,|\\.) *", "ALAMEDA ") |>
    re2::re2_replace_all("^(ALAMEDA|RUA) (ALAMEDA|ALA?)\\b- *", "ALAMEDA ") |> # mesmo caso de travessa
    re2::re2_replace_all("^RODOVIA (ALAMEDA|ALA)\\b- *", "ALAMEDA ") |> # mesmo caso acima

    re2::re2_replace_all("^LOT\\b(\\.|,)?", "LOTEAMENTO") |>
    re2::re2_replace_all("^(LOTEAMENTO|RUA|RODOVIA) LOT\\b(\\.|,)?", "LOTEAMENTO") |>
    re2::re2_replace_all("^LOTEAMENTO?\\b(-|,|\\.) *", "LOTEAMENTO ") |>

    re2::re2_replace_all("^LOC\\b(\\.|,)?", "LOCALIDADE") |>
    re2::re2_replace_all("^(LOCALIDADE|RUA) LOC\\b(\\.|,)?", "LOCALIDADE") |>
    re2::re2_replace_all("^LOCALIDADE?\\b(-|,|\\.) *", "LOCALIDADE ") |>

    re2::re2_replace_all("^VL\\b(\\.|,)?", "VILA") |>
    re2::re2_replace_all("^VILA VILA\\b(\\.|,)?", "VILA") |>
    re2::re2_replace_all("^VILA?\\b(-|,|\\.) *", "VILA ") |>

    re2::re2_replace_all("^LAD\\b(\\.|,)?", "LADEIRA") |>
    re2::re2_replace_all("^LADEIRA LADEIRA\\b(\\.|,)?", "LADEIRA") |>
    re2::re2_replace_all("^LADEIRA?\\b(-|,|\\.) *", "LADEIRA ") |>

    re2::re2_replace_all("^DT\\b(\\.|,)?", "DISTRITO") |>
    re2::re2_replace_all("\\bDISTR?\\b\\.?", "DISTRITO") |>
    re2::re2_replace_all("^DISTRITO DISTRITO\\b(\\.|,)?", "DISTRITO") |>
    re2::re2_replace_all("^DISTRITO?\\b(-|,|\\.) *", "DISTRITO ") |>

    re2::re2_replace_all("^NUC\\b(\\.|,)?", "NUCLEO") |>
    re2::re2_replace_all("^NUCLEO NUCLEO\\b(\\.|,)?", "NUCLEO") |>
    re2::re2_replace_all("^NUCLEO?\\b(-|,|\\.) *", "NUCLEO ") |>

    re2::re2_replace_all("^L(RG|GO)\\b(\\.|,)?", "LARGO") |>
    re2::re2_replace_all("^LARGO L(RG|GO)\\b(\\.|,)?", "LARGO") |>
    re2::re2_replace_all("^LARGO?\\b(-|,|\\.) *", "LARGO ") |>

    # estabelecimentos
    re2::re2_replace_all("^AER(OP)?\\b(\\.|,)?", "AEROPORTO") |> # sera que vale? tem uns casos estranhos aqui, e.g. "AER GUANANDY, 1", "AER WASHINGTON LUIZ, 3318"
    re2::re2_replace_all("^AEROPORTO (AEROPORTO|AER)\\b(\\.|,)?", "AEROPORTO") |>
    re2::re2_replace_all("^AEROPORTO INT(ERN?)?\\b(\\.|,)?", "AEROPORTO INTERNACIONAL") |>

    re2::re2_replace_all("^COND\\b(\\.|,)?", "CONDOMINIO") |>
    re2::re2_replace_all("^(CONDOMINIO|RODOVIA) (CONDOMINIO|COND)\\b(\\.|,)?", "CONDOMINIO") |>

    re2::re2_replace_all("^FAZ(EN?)?\\b\\.?", "FAZENDA") |>
    re2::re2_replace_all("^(FAZENDA|RODOVIA) (FAZ(EN?)?|FAZENDA)\\b(\\.|,)?", "FAZENDA") |>
    re2::re2_replace_all(r"{\bFAZ(EN?)?\b\.?}", "FAZENDA") |>

    re2::re2_replace_all("^COL\\b\\.?", "COLONIA") |>
    re2::re2_replace_all("\\bCOLONIA AGRI?C?\\b\\.?", "COLONIA AGRICOLA") |>

    # títulos
    re2::re2_replace_all("\\bSTA\\b\\.?", "SANTA") |>
    re2::re2_replace_all("\\bSTO\\b\\.?", "SANTO") |>
    re2::re2_replace_all(r"{\b(N(OS|SS?A?)?\.? S(RA|ENHORA)|(NOSSA|NSA\.?) (S(RA?)?|SEN(H(OR)?)?))\b\.?}", "NOSSA SENHORA") |>
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

    re2::re2_replace_all("\\bALM?TE\\b\\.?", "ALMIRANTE") |>
    re2::re2_replace_all("\\bMAL\\b\\.?", "MARECHAL") |>
    re2::re2_replace_all("\\b(GEN|GAL)\\b\\.?", "GENERAL") |>
    re2::re2_replace_all("\\b(SGTO?|SARG)\\b\\.?", "SARGENTO") |>
    re2::re2_replace_all("\\b(PRIMEIRO|PRIM|1)\\.? SARGENTO\\b", "PRIMEIRO-SARGENTO") |>
    re2::re2_replace_all("\\b(SEGUNDO|SEG|2)\\.? SARGENTO\\b", "SEGUNDO-SARGENTO") |>
    re2::re2_replace_all("\\b(TERCEIRO|TERC|3)\\.? SARGENTO\\b", "TERCEIRO-SARGENTO") |>
    re2::re2_replace_all("\\bCEL\\b\\.?", "CORONEL") |>
    re2::re2_replace_all("\\bBRIG\\b\\.?", "BRIGADEIRO") |>
    re2::re2_replace_all("\\bTEN\\b\\.?", "TENENTE") |>
    re2::re2_replace_all("\\bTENENTE CORONEL\\b", "TENENTE-CORONEL") |>
    re2::re2_replace_all("\\bTENENTE BRIGADEIRO\\b", "TENENTE-BRIGADEIRO") |>
    re2::re2_replace_all("\\bTENENTE AVIADOR\\b", "TENENTE-AVIADOR") |>
    re2::re2_replace_all("\\bSUB TENENTE\\b", "SUBTENENTE") |>
    re2::re2_replace_all("\\b(PRIMEIRO|PRIM\\.?) TENENTE\\b", "PRIMEIRO-TENENTE") |>
    re2::re2_replace_all("\\b(SEGUNDO|SEG\\.?) TENENTE\\b", "SEGUNDO-TENENTE") |>
    re2::re2_replace_all("\\bSOLD\\b\\.?", "SOLDADO") |>
    re2::re2_replace_all("\\bMAJ\\b\\.?", "MAJOR") |>

    re2::re2_replace_all("\\bPROF\\b\\.?", "PROFESSOR") |>
    re2::re2_replace_all("\\bPROFA\\b\\.?", "PROFESSORA") |>
    re2::re2_replace_all("\\bDR\\b\\.?", "DOUTOR") |>
    re2::re2_replace_all("\\bDRA\\b\\.?", "DOUTORA") |>
    re2::re2_replace_all("\\bENG\\b\\.?", "ENGENHEIRO") |>
    re2::re2_replace_all("\\bENGA\\b\\.?", "ENGENHEIRA") |>
    re2::re2_replace_all("\\bPD?E\\b\\.", "PADRE") |> # PE pode ser só pe mesmo, entao forcando o PE. (com ponto) pra ser PADRE
    re2::re2_replace_all("\\bMONS\\b\\.?", "MONSENHOR") |>

    re2::re2_replace_all("\\bPRES(ID)?\\b\\.?", "PRESIDENTE") |>
    re2::re2_replace_all("\\bGOV\\b\\.?", "GOVERNADOR") |>
    re2::re2_replace_all("\\bSEN\\b\\.?", "SENADOR") |>
    re2::re2_replace_all("\\bPREF\\b\\.?", "PREFEITO") |>
    re2::re2_replace_all("\\bDEP\\b\\.?", "DEPUTADO") |>
    re2::re2_replace_all("\\bESPL?\\.? (DOS )?MIN(IST(ERIOS?)?)?\\b\\.?", "ESPLANADA DOS MINISTERIOS") |>

    # abreviacoes
    re2::re2_replace_all(r"{\bJAR DIM\b}", "JARDIM") |>
    re2::re2_replace_all(r"{\bJ(D(I?M)?|A?RD|AR(DIN)?)\b\.?}", "JARDIM") |>
    re2::re2_replace_all("\\bUNID\\b\\.?", "UNIDADE") |>
    re2::re2_replace_all("\\b(CJ|CONJ)\\b\\.?", "CONJUNTO") |>
    re2::re2_replace_all("\\bLT\\b\\.?", "LOTE") |>
    re2::re2_replace_all("\\bLTS\\b\\.?", "LOTES") |>
    re2::re2_replace_all("\\bQDA?\\b\\.?", "QUADRA") |>
    re2::re2_replace_all("\\bLJ\\b\\.?", "LOJA") |>
    re2::re2_replace_all("\\bLJS\\b\\.?", "LOJAS") |>
    re2::re2_replace_all("\\bAPTO?\\b\\.?", "APARTAMENTO") |>
    re2::re2_replace_all("\\bBL\\b\\.?", "BLOCO") |>
    re2::re2_replace_all("\\bSLS\\b\\.?", "SALAS") |>
    re2::re2_replace_all("\\bEDI?F\\.? EMP\\b\\.?", "EDIFICIO EMPRESARIAL") |>
    re2::re2_replace_all("\\bEDI?F\\b\\.?", "EDIFICIO") |>
    re2::re2_replace_all("\\bCOND\\b\\.?", "CONDOMINIO") |> # apareceu antes mas como tipo de logradour)
    re2::re2_replace_all("\\bKM\\b\\.", "KM") |>
    re2::re2_replace_all("\\bS\\.? ?N\\b\\.?", "S/N") |>
    re2::re2_replace_all(r"{(\d)\.( O)? A(ND(AR)?)?\b\.?}", "\\1 ANDAR") |>
    re2::re2_replace_all(r"{(\d)\.( O)? ANDARES\b}", "\\1 ANDARES") |>
    re2::re2_replace_all(r"{(\d)( O)? AND\b\.?}", "\\1 ANDAR") |>
    re2::re2_replace_all(r"{\bCX\.? ?P(T|(OST(AL)?))?\b\.?}", "CAIXA POSTAL") |>
    re2::re2_replace_all(r"{\bC\.? ?P(T|(OST(AL)?))?\b\.?}", "CAIXA POSTAL") |>
    # SL pode ser sobreloja ou sala

    # intersecao entre nomes e titulos
    #   - D. pode ser muita coisa (e.g. dom vs dona), entao nao da pra
    #   simplesmente assumir que vai ser um valor especifico, so no contexto
    #   - MAR pode ser realmente só mar ou uma abreviação pra marechal
    re2::re2_replace_all("\\bD\\b\\.? (PEDRO|JOAO|HENRIQUE)", "DOM \\1") |>
    re2::re2_replace_all("\\bI(NF)?\\.? DOM\\b", "INFANTE DOM") |>
    re2::re2_replace_all("\\bMAR\\b\\.? ((CARMONA|JOFRE|HERMES|MALLET|DEODORO|MARCIANO|OTAVIO|FLORIANO|BARBACENA|FIUZA|MASCARENHAS|MASCARENHA|TITO|FONTENELLE|XAVIER|BITENCOURT|BITTENCOURT|CRAVEIRO|OLIMPO|CANDIDO|RONDON|HENRIQUE|MIGUEL|JUAREZ|FONTENELE|FONTENELLE|DEADORO|HASTIMPHILO|NIEMEYER|JOSE|LINO|MANOEL|HUMB?|HUMBERTO|ARTHUR|ANTONIO|NOBREGA|CASTELO|DEODORA)\\b)", "MARECHAL \\1") |>

    # nomes
    re2::re2_replace_all("\\b(GETULHO|JETULHO|JETULIO|JETULHO|GET|JET)\\.? VARGAS\\b", "GETULIO VARGAS") |>
    re2::re2_replace_all("\\b(J(U[A-Z]*)?)\\.? (K(U[A-Z]*)?)\\b\\.?", "JUSCELINO KUBITSCHEK") |>

    # expressoes hifenizadas ou nao
    #   - beira-mar deveria ter pelo novo acordo ortografico, mas a grafia da
    #   grande maioria das ruas (se nao todas, nao tenho certeza) eh beira
    #   mar, sem hifen
    re2::re2_replace_all("\\bBEIRA-MAR\\b", "BEIRA MAR") |>

    # rodovias
    re2::re2_replace_all("\\b(RODOVIA|BR\\.?|RODOVIA BR\\.?) CENTO D?E (DESESSEIS|DESESEIS|DEZESSEIS|DEZESEIS)\\b", "RODOVIA BR-116") |>
    re2::re2_replace_all("\\b(RODOVIA|BR\\.?|RODOVIA BR\\.?) CENTO D?E H?UM\\b", "RODOVIA BR-101") |>
    # será que essas duas de baixo valem?
    re2::re2_replace_all("\\bBR\\.? ?(\\d{3})", "BR-\\1") |>
    # essa aqui é complicada... AL, AP, SE, entre outras, são siglas que podem aparecer sem serem rodovias
    re2::re2_replace_all("\\b(RO|AC|AM|RR|PA|AP|TO|MA|PI|CE|RN|PB|PE|AL|SE|BA|MG|ES|RJ|SP|PR|SC|RS|MS|MT|GO|DF) ?(\\d{3})", "\\1-\\2") |>

    # 0 à esquerda
    re2::re2_replace_all(" (0)(\\d+)", " \\2") |>

    # correcoes de problemas ocasionados pelos filtros acima
    re2::re2_replace_all("\\bTENENTE SHI\\b", "TEN SHI") |>
    re2::re2_replace_all("\\bHO SHI MINISTRO\\b", "HO SHI MIN")


  logradouros_padrao_dedup <- stringr::str_replace_all(
    logradouros_padrao_dedup,
    c(
      " \\." = "\\.",                # garantir que não haja um espaco antes dos pontos
      r"{^([^\dIX])\1{1,}$}" = "", # qualquer valor não numérico ou romano repetido 2+ vezes

      # titulos / invalid perl operator: (?!
      "\\bVER\\b\\.?(?!$)" = "VEREADOR",
      "\\bMIN\\b\\.?(?!$)" = "MINISTRO",
      "\\bMAL\\b\\.?(?!$)" = "MARECHAL",
      "\\bPRES(ID)?\\b\\.?(?!$)" = "PRESIDENTE",
      "\\bPREF\\b\\.?(?!$)" = "PREFEITO",
      "\\bDEP\\b\\.?(?!$)" = "DEPUTADO",
      "\\bPE\\b\\.(?!$)" = "PADRE",
      "\\bCONS\\b\\.?(?!$)" = "CONSELHEIRO", # CONS COMUN => CONSELHO COMUNITARIO, provavelmente

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

      # ALM é um caso complicado, pode ser alameda ou almirante. inclusive no mesmo endereço podem aparecer os dois rs
    )
  )

  names(logradouros_padrao_dedup) <- logradouros_dedup
  logradouros_padrao <- logradouros_padrao_dedup[logradouros]
  names(logradouros_padrao) <- NULL

  logradouros_padrao[logradouros_padrao == ""] <- NA_character_

  return(logradouros_padrao)
}
