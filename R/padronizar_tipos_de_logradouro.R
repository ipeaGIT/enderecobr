#' Padronizar tipos de logradouro
#'
#' Padroniza um vetor de caracteres representando tipos de logradouro. Veja a
#' seção *Detalhes* para mais informações sobre a padronização.
#'
#' @param tipos Um vetor de caracteres. Os tipos de logradouro a serem
#'   padronizados.
#'
#' @return Um vetor de caracteres com os tipos de logradouro padronizados.
#'
#' @section Detalhes:
#' Operações realizadas durante a padronização:
#'
#' 1. remoção de espaços em branco antes e depois das strings e remoção de
#' espaços em excesso entre palavras;
#' 2. conversão de caracteres para caixa alta;
#' 3. remoção de acentos e caracteres não ASCII;
#' 4. adição de espaços após abreviações sinalizadas por pontos;
#' 5. substituição de abreviações pelos termos completos;
#' 6. remoção de valores inválidos (i.e. que não representam tipos de
#' logradouro).
#'
#' @examples
#' tipos <- c("R", "AVE", "QDRA")
#' padronizar_tipos_de_logradouro(tipos)
#'
#' @export
padronizar_tipos_de_logradouro <- function(tipos) {
  checkmate::assert_character(tipos)

  tipos_dedup <- unique(tipos)

  tipos_padrao_dedup <- stringr::str_squish(tipos_dedup)
  tipos_padrao_dedup <- toupper(tipos_padrao_dedup)
  tipos_padrao_dedup <- stringi::stri_trans_general(
    tipos_padrao_dedup,
    "Latin-ASCII"
  )

  tipos_padrao_dedup <- stringr::str_replace_all(
    tipos_padrao_dedup,
    c(
      # pontuacao
      r"{\.\.+}" = ".",          # remover pontos repetidos
      r"{(\d+)\.(\d{3})}" = "\\1\\2", # pontos usados como separador de milhares
      # r"{(\d+)\.(\d+)}" = "\\1,\\2", # pontos usados como separador de decimais (nao sei se esse vale, tem muitas poucas observacoes e ela sao meio ambiguas. no caso do cpf, por exemplo, tem so "BL 3.1 APTO 204", "KM 7.5", "2.2 BLOCO G" e "34.5KV" no primeiro milhao de observacoes)
      r"{\.([^ ])}" = "\\. \\1", # garantir que haja espaco depois do ponto
      r"{ (-|\.) }" = " ",
      r"{\.$}" = "",           # remocao de ponto final

      # sinalizacao
      r"{"}" = "'", # existem ocorrencias em que aspas duplas sao usadas para se referir a um logradouro/quadra com nome relativamente ambiguo - e.g. RUA \"A\", 26. isso pode causar um problema quando lido com o data.table: https://github.com/Rdatatable/data.table/issues/4779. por enquanto, substituindo por aspas simples. depois a gente pode ver o que fazer com as aspas simples rs.

      # valores non-sense
      r"{^([^\d])\1{1,}$}" = "",
      r"{^(\d)\1{3,}$}" = "", # assumindo que qualquer numero que apareca 4 ou mais vezes repetido eh um erro de digitacao
      r"{^(-)+$}" = "",

      r"{\bR(A|U)?\b\.?}" = "RUA",
      r"{\b(ROD|RDV)\b\.?}" = "RODOVIA",
      r"{\bAV(E|N|D|DA|I)?\b\.?}" = "AVENIDA",
      r"{\bESTR?\b\.?}" = "ESTRADA", # EST pode ser ESTANCIA, mas são poucos casos. no cadunico 2011 ESTRADA eram 139780 e ESTANCIA 158, 0.1%
      r"{\b(PCA?|PRC)\b\.?}" = "PRACA",
      r"{\bBE?CO?\b(?<!BECO)\.?}" = "BECO", # (?<!BECO) serve para remover os matches com a palavra BECO ja correta
      r"{\b(T(RA?)?V|TRA)\b\.?}" = "TRAVESSA",
      r"{\bP((A?R)?Q|QU?E)\b\.?}" = "PARQUE",
      r"{(?<!RODOVIA )\bAL(A|M)?\b\.?}" = "ALAMEDA", # evitando um possivel caso de RODOVIA AL ..., que faria referencia a uma rodovia estadual de alagoas
      r"{\bLOT\b\.?}" = "LOTEAMENTO",
      r"{\bVI?L\b\.?}" = "VILA",
      r"{\bLAD\b\.?}" = "LADEIRA",
      r"{\bDIS(TR?)?\b\.?}" = "DISTRITO",
      r"{\bNUC\b\.?}" = "NUCLEO",
      r"{\bL(AR|RG|GO)\b\.?}" = "LARGO",
      r"{\bAER(OP)?\b\.?}" = "AEROPORTO",
      r"{\bFAZ(EN?)?\b\.?}" = "FAZENDA",
      r"{\bCOND?\b\.?}" = "CONDOMINIO",
      r"{\bSIT\b\.?}" = "SITIO",
      r"{\bRES(ID)?\b\.?}" = "RESIDENCIAL",
      r"{\bQ(U(AD?)?|D(RA?)?)\b\.?}" = "QUADRA",
      r"{\bCHAC?\b\.?}" = "CHACARA",

      "OUTROS" = ""

      #,

      # EDF é usado pra sinalizar endereços típicos do DF no CadUnico (sigla de
      # Endereço do DF), não substituir por EDIFICIO

      # "^COL\\b\\.?" = "COLONIA",
      # "\\bCOLONIA AGRI?C?\\b\\.?" = "COLONIA AGRICOLA",
      #
      #
      #
      #
      #
      #
      #
      #
      #
      #
      #
      #
      #
      # # muita coisa pode ser quadra... Q A LOTE 2, Q I LOTE 45, QI, Q I, etc etc. tem que ver o que faz sentido
      # r"{QU ADRA}" = "QUADRA",
      # r"{\bQ(U(ADRA)?|D(RA?)?)\.?(\d)}" = "QUADRA \\4", # QDA pode ser QUADRA A. da tipo 1%~ das observacoes, pelo que vi aqui. vale a pena errar nesses 1% e transformar?
      # r"{(\d+)Q(U(ADRA)?|D(RA?)?)\b\.?}" = "\\1 QUADRA",
      # r"{\bQD(RA?)?\b\.?}" = "QUADRA",
      # r"{\bQU\b\.? }" = "QUADRA ", # espaco no final pra evitar casos como "EDIFICIO RES M LUIZA QU" e "BLOCO 3A APARTAMENTO 201 E M QU"
      # r"{\bQUADRA\b: ?}" = "QUADRA ",
      # r"{\bQUADRA-(\d+)}" = "QUADRA \\1",
      # r"{\bQ\.? ?(\d)}" = "QUADRA \\1",
      # r"{\bQ-(\d+)}" = "QUADRA \\1",
      # r"{\bQ-([A-Z])\b}" = "QUADRA \\1",
      # r"{ ?-QUADRA}" = " QUADRA",
      #
      # r"{\b(LOTE|LTE?)\.?(\d)}" = "LOTE \\2",
      # r"{\b(?<!RUA |S\/)L\.? (\d)}" = "LOTE \\1", # o \\1 ta certo mesmo, os (?...) nao contam. transforma L 5 em LOTE 5, mas evita que RUA L 5 LOTE 45 vire RUA LOTE 5 LOTE 45 e que S/L 205 vire S/LOTE 205
      # r"{(\d)(LTE?|LOTE)\b\.?}" = "\\1 LOTE",
      # r"{\bLTE?\b\.?}" = "LOTE",
      # r"{\bLOTE\b: ?}" = "LOTE ",
      # r"{\bLOTE-(\d+)}" = "LOTE \\1",
      # r"{\b(?<!(TV|TRAVESSA|QUADRA) )L-(\d+)}" = "LOTE \\2", # "L-21-NOVO HORIZONTE" ? "L-36" ?
      # r"{ ?-LOTE}" = " LOTE",
      # r"{\b(LOTES|LTS)\.?(\d)}" = "LOTES \\2",
      # r"{(\d)(LTS|LOTES)\b\.?}" = "\\1 LOTES",
      # r"{\bLTS\b\.?}" = "LOTES",
      # # r"{\bLOT\.? ?(\d)}" = "LOTE \\1", # LOT seguido de numero tende a ser LOTE, mas seguido de palavra tende a ser LOTEAMENTO? tem excecoes e.g. "LOT 28 AGOSTO", "LOT 1 DE MAIO", "LOT 2 IRMAS", "LOT 3 COQUEIROS"
      # r"{\bLOT\.? ([A-Z]{2,})}" = "LOTEAMENTO \\1",
      #
      # r"{\b(CASA|CS)\.?(\d)}" = "CASA \\2", # CSA?
      # r"{(\d)(CASA|CS)\b\.?}" = "\\1 CASA",
      # r"{\bCS\b\.?}" = "CASA",
      # r"{\bCASA\b: ?}" = "CASA ",
      # r"{\bCASA-(\d+)}" = "CASA \\1",
      # #r"{[^^]\b(?<!(APARTAMENTO|CONJUNTO|BLOCO|QUADRA) )C-(\d+)}" = "CASA \\1", # ESSE TEM MUITA VARIACAO, COMPLICADO #### Q-10 C-03 = Q-10 CASA 03, mas APARTAMENTO C-03 nao eh mexido, nem soh C-03 (pode ser soh C-03 mesmo)
      # r"{ ?-CASA}" = " CASA",
      #
      # r"{\b(C(ON)?JT?|CONJUNTO)\.?(\d)}" = "CONJUNTO \\3",
      # r"{(\d)(C(ON)?JT?|CONJUNTO)\b\.?}" = "\\1 CONJUNTO",
      # r"{\bC(ON)?JT?\b\.?}" = "CONJUNTO",
      # r"{\bCONJUNTO\b: ?}" = "CONJUNTO ",
      # r"{\bCONJUNTO-(\d)}" = "CONJUNTO \\1",
      # r"{ ?-CONJUNTO}" = " CONJUNTO",
      #
      # r"{\b(CONDOMINIO|C(O?N)?D)\.?(\d)}" = "CONDOMINIO \\3", # "LOTE 4 RUA 06 COND263"? "COND3 T7 APARTAMENTO 13"? "BLOCO 07 APARTAMENTO 204 CD2"?
      # r"{(\d)(CONDOMINIO|C(O?N)?D)\b\.?}" = "\\1 CONDOMINIO",
      # r"{\bC(O?N)?D\b\.?}" = "CONDOMINIO",
      # r"{\bCONDOMINIO\b: ?}" = "CONDOMINIO ",
      # r"{\bCONDOMINIO-(\d)}" = "CONDOMINIO \\1",
      # r"{ ?-CONDOMINIO}" = " CONDOMINIO",
      #
      # r"{\bAND(AR)?\.?(\d)}" = "ANDAR \\2",
      # r"{(\dO?)AND(AR)?\b\.?}" = "\\1 ANDAR",
      # r"{\bAND\b\.?}" = "ANDAR",
      # r"{\bANDAR\b: ?}" = "ANDAR ",
      # r"{\bANDAR-(\d+)}" = "ANDAR \\1",
      # r"{ ?-ANDAR}" = " ANDAR",
      #
      # r"{\bCOB(ERTURA)?\.?(\d)}" = "COBERTURA \\2",
      # r"{(\d)COB(ERTURA)?\b\.?}" = "\\1 COBERTURA",
      # r"{\bCOB\b\.?}" = "COBERTURA",
      # r"{\bCOBERTURA\b: ?}" = "COBERTURA ",
      # r"{\bCOBERTURA-(\d+)}" = "COBERTURA \\1",
      # r"{ ?-COBERTURA}" = " COBERTURA",
      #
      # r"{\b(FDS|FUNDOS)\.?(\d)}" = "FUNDOS \\2",
      # r"{(\d)(FDS|FUNDOS)\b\.?}" = "\\1 FUNDOS",
      # r"{\bFDS\b\.?}" = "FUNDOS",
      # r"{-FUNDOS}" = " FUNDOS",
      #
      # # tipos de logradouro
      #
      # r"{\bAV\b\.?}" = "AVENIDA", # "APARTAMENTO 401 EDIFICIO RES 5O AV"? "GUARABU AV"? "TRAVESSA AV JOAO XXIII"?
      # r"{\bAVENIDA\b(:|-) ?}" = "AVENIDA ",
      #
      # r"{\bROD\b\.?}" = "RODOVIA", # "FAZENDA FIRMESA ROD CRIO"
      # r"{\bRODOVIA (BR|RO|AC|AM|RR|PA|AP|TO|MA|PI|CE|RN|PB|PE|AL|SE|BA|MG|ES|RJ|SP|PR|SC|RS|MS|MT|GO|DF) ?(\d{3})\b}" = "\\1-\\2",
      # r"{\b(BR|RO|AC|AM|RR|PA|AP|TO|MA|PI|CE|RN|PB|PE|AL|SE|BA|MG|ES|RJ|SP|PR|SC|RS|MS|MT|GO|DF) ?(\d{3}) KM}" = "\\1-\\2 KM",
      # r"{^(BR|RO|AC|AM|RR|PA|AP|TO|MA|PI|CE|RN|PB|PE|AL|SE|BA|MG|ES|RJ|SP|PR|SC|RS|MS|MT|GO|DF) ?(\d{3})$}" = "\\1-\\2",
      #
      # r"{\bESTR\b\.?}" = "ESTRADA",
      #
      # # abreviacoes
      # r"{\bS\.? ?N\b\.?}" = "S/N",
      # r"{\bPRO?X\b\.?}" = "PROXIMO",
      # # r"{\bESQ\b\.?}" = "ESQUINA" # tem uns casos que ESQ = ESQUERDA, não ESQUINA - e.g. "LD ESQ", "A ESQ ENT XIQUITIM", "ULTIMA CASA LADO ESQ"
      # r"{\bLOTEAM?\b\.?}" = "LOTEAMENTO",
      # r"{\bCX\.? ?P(T|(OST(AL)?))?\b\.?}" = "CAIXA POSTAL",
      # r"{\bC\.? ?P(T|(OST(AL)?))?\b\.?}" = "CAIXA POSTAL", # separado pq nao tenho certeza. varios parecem ser caixa postal mesmo, mas tem bastante coisas como "A C CP 113". o que é esse A C/AC/etc que se repete antes?
      #
      # r"{\bEDI?F?\b\.?}" = "EDIFICIO",
      # r"{\bN((O|\u00BA)?\.|\. (O|\u00BA)) (\d)}" = "NUMERO \\4",
      # r"{\b(PX|PROXI)\b\.?}" = "PROXIMO", # vale tentar ajustar a preposição? tem varios "PX AO FINAL DA LINHA" mas tb tem "PX VIADUTO" e "PX A CX DAGUA"
      # r"{\bLJ\b\.?}" = "LOJA",
      # r"{\bLJS\b\.?}" = "LOJAS",
      # r"{\bSLS\b\.?}" = "SALAS",
      # r"{\bFAZ(EN?)?\b\.?}" = "FAZENDA",
      # r"{\bPCA\b\.?}" = "PRACA",
      # r"{\bP((A?R)?Q|QU?E)\b\.?}" = "PARQUE",
      # r"{\bL(RG|GO)\b\.?}" = "LARGO",
      # r"{\bSIT\b\.?}" = "SITIO",
      # r"{\bCHAC\b\.?}" = "CHACARA",
      # r"{\bT(RA?)?V\b\.?}" = "TRAVESSA", # "3º TRV"? "TRV WE 40"? "TV. WE 49"? "TV WE 07"? o que é esse WE?
      # r"{\bJ(D(I?M)?|A?RD)\b\.?}" = "JARDIM", # tendo a achar que JD tb eh jardim, mas tem uns mais estranhos e.g. "JD WALDES". sera que poderia ser abreviacao de um nome tb?
      # r"{\bVL\b\.?}" = "VILA",
      # r"{\bNUC\b\.?}" = "NUCLEO",
      # r"{\bNUCLEO H(AB)?\b\.?}" = "NUCLEO HABITACIONAL",
      # r"{\bNUCLEO COL\b\.?}" = "NUCLEO COLONIAL",
      # r"{\b(NUCLEO RES|(?<!S/)N\.? RES(IDENCIAL)?)\b\.?}" = "NUCLEO RESIDENCIAL",
      # r"{\b(NUCLEO RUR|(?<!S/)N\.? RURAL)\b\.?}" = "NUCLEO RURAL", # evita coisas como "S/N RURAL"
      # r"{\bASSENT\b\.?}" = "ASSENTAMENTO",
      #
      # r"{\b(N(OS|SS?A?)?\.? S(RA|ENHORA)|(NOSSA|NSA\.?) (S(RA?)?|SEN(H(OR)?)?))\b\.?}" = "NOSSA SENHORA",
      # r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( DE?)?|NOSSA SENHORA|NS) (FAT.*|LO?UR.*|SANTANA|GUADALUPE|NAZ.*|COP*)\b}" = "NOSSA SENHORA DE \\7",
      # r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(A|E)?)?|NOSSA SENHORA|NS) (GRACA|VITORIA|PENHA|CONCEICAO|PAZ|GUIA|AJUDA|CANDELARIA|PURIFICACAO|SAUDE|PIEDADE|ABADIA|GLORIA|SALETE|APRESENTACAO)\b}" = "NOSSA SENHORA DA \\8",
      # r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(A|E)?)?|NOSSA SENHORA D(A|E)|NS) (APA.*|AUX.*|MEDIANEIRA|CONSOLADORA)\b}" = "NOSSA SENHORA \\9",
      # r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSA SENHORA|NS) (NAVEGANTES)\b}" = "NOSSA SENHORA DOS \\8",
      # r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( DO?)?|NOSSA SENHORA|NS) (CARMO|LIVRAMENTO|RETIRO|SION|ROSARIO|PILAR|ROCIO|CAMINHO|DESTERRO|BOM CONSELHO|AMPARO|PERP.*|P.* S.*)\b}" = "NOSSA SENHORA DO \\7",
      # r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(AS?)?)?|NOSSA SENHORA|NS) (GRACAS|DORES)\b}" = "NOSSA SENHORA DAS \\8",
      # r"{\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR( D(OS)?)?) (BON\w*)\b}" = "SENHOR DO BONFIM",
      # r"{\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR( D(OS?)?)?) (BOM ?F\w*)\b}" = "SENHOR DO BONFIM",
      # r"{\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR) (PASS\w*|MONT\w*)\b}" = "SENHOR DOS \\5",
      # r"{\bS(R|ENH?)\.? (BOM J\w*)\b}" = "SENHOR BOM JESUS",
      # r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSO SENHOR|NS) (BONF\w*|BOM ?F\w*)\b}" = "NOSSO SENHOR DO BONFIM",
      # r"{\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSO SENHOR|NS) (PASS\w*|MONT\w*)\b}" = "NOSSO SENHOR DOS \\8",
      #
      # r"{\bSTA\b\.?}" = "SANTA",
      # r"{\bSTO\b\.?}" = "SANTO",
      # r"{\bSRA\b\.?}" = "SENHORA",
      # r"{\bSR\b\.?}" = "SENHOR", # "Q SR LOTE 1"?
      #
      # r"{\bS\.? (JOSE|JOAO)\b}" = "SAO \\1",
      #
      # r"{\bPROF\b\.?}" = "PROFESSOR",
      # # r"{\bDR\b\.?}" = "DOUTOR", # tem varios DR que nao parecem ser DOUTOR... e.g. "DR 16", "AREA DR", "1O DR DER DF"
      # r"{\bMONS\b\.?}" = "MONSENHOR",
      # r"{\bPRES(ID)?\b\.?}" = "PRESIDENTE",
      # r"{\bGOV\b\.?}" = "GOVERNADOR",
      # r"{\bVISC\b\.?}" = "VISCONDE",
      #
      # r"{\b(\d+)\. (O|\u00BA)\b}" = "\\1O", # o que fazer com "6O ANDAR"? transformar em "6 ANDAR"? de forma geral, o que fazer com numeros ordinais
      # r"{\b(\d+)(O|\u00BA)\b\.}" = "\\1O",
      #
      # # datas
      #
      # r"{\b(\d+) DE? JAN(?!EIRO)\b}" = "\\1 DE JANEIRO",
      # r"{\b(\d+) DE? FEV(?!EREIRO)\b}" = "\\1 DE FEVEREIRO",
      # r"{\b(\d+) DE? MAR(?!CO)\b}" = "\\1 DE MARCO",
      # r"{\b(\d+) DE? ABR(?!IL)\b}" = "\\1 DE ABRIL",
      # r"{\b(\d+) DE? MAI(?!O)\b}" = "\\1 DE MAIO",
      # r"{\b(\d+) DE? JUN(?!HO)\b}" = "\\1 DE JUNHO",
      # r"{\b(\d+) DE? JUL(?!HO)\b}" = "\\1 DE JULHO",
      # r"{\b(\d+) DE? AGO(?!STO)\b}" = "\\1 DE AGOSTO",
      # r"{\b(\d+) DE? SET(?!EMBRO)\b}" = "\\1 DE SETEMBRO",
      # r"{\b(\d+) DE? OUT(?!UBRO)\b}" = "\\1 DE OUTUBRO",
      # r"{\b(\d+) DE? NOV(?!EMBRO)\b}" = "\\1 DE NOVEMBRO",
      # r"{\b(\d+) DE? DEZ(?!EMBRO)\b}" = "\\1 DE DEZEMBRO"
    )
  )

  names(tipos_padrao_dedup) <- tipos_dedup
  tipos_padrao <- tipos_padrao_dedup[tipos]
  names(tipos_padrao) <- NULL

  tipos_padrao[tipos_padrao == ""] <- NA_character_

  return(tipos_padrao)
}
