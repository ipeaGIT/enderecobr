#' Padronizar complementos
#'
#' Padroniza um vetor de caracteres representando complementos de logradouros.
#' Veja a seção *Detalhes* para mais informações sobre a padronização.
#'
#' @param complementos Um vetor de caracteres. Os complementos a serem
#'   padronizados.
#'
#' @return Um vetor de caracteres com os complementos padronizados.
#'
#' @section Detalhes:
#' Operações realizadas durante a padronização:
#'
#' 1. remoção de espaços em branco antes e depois das strings e remoção de
#' espaços em excesso entre palavras;
#' 2. conversão de caracteres para caixa alta;
#' 3. remoção de acentos e caracteres não ASCII;
#' 4. adição de espaços após abreviações sinalizadas por pontos;
#' 5. substituição de abreviações pelos termos completos.
#'
#' @examples
#' complementos <- c("", "QD1 LT2 CS3", "APTO. 405")
#' padronizar_complementos(complementos)
#'
#' @export
padronizar_complementos <- function(complementos) {
  checkmate::assert_character(complementos)

  complementos_dedup <- unique(complementos)

  # alguns complementos podem vir vazios e devem permanecer vazios ao final.
  # identificamos o indice dos complementos vazios para "reesvazia-los" ao final,
  # ja que a sequencia de operacoes abaixo acabaria atribuindo um valor a eles

  indice_complemento_vazio <- which(is.na(complementos) | complementos == "")

  complementos_padrao_dedup <- stringr::str_squish(complementos_dedup)
  complementos_padrao_dedup <- toupper(complementos_padrao_dedup)
  complementos_padrao_dedup <- stringi::stri_trans_general(
    complementos_padrao_dedup,
    "Latin-ASCII"
  )

  complementos_padrao_dedup <- stringr::str_replace_all(
    complementos_padrao_dedup,
    c(
      # pontuacao
      r"{\.\.+}" = ".",          # remover pontos repetidos
      r"{(\d+)\.(\d{3})}" = "\\1\\2", # pontos usados como separador de milhares
      # r"{(\d+)\.(\d+)}" = "\\1,\\2", # pontos usados como separador de decimais (nao sei se esse vale, tem muitas poucas observacoes e ela sao meio ambiguas. no caso do cpf, por exemplo, tem so "BL 3.1 APTO 204", "KM 7.5", "2.2 BLOCO G" e "34.5KV" no primeiro milhao de observacoes)
      r"{\.([^ ])}" = "\\. \\1", # garantir que haja espaco depois do ponto
      r"{ - }" = " ",

      # "LT-04-BL-07-APTO-110" maravilha tb

      r"{\bQD?-?(\d+)-?LT?-?(\d+)-?C-?(\d+)\b}" = "QUADRA \\1 LOTE \\2 CASA \\3",
      r"{\bQD?-?(\d+)-?C-?(\d+)-?LT?-?(\d+)\b}" = "QUADRA \\1 LOTE \\3 CASA \\2",
      r"{\bC-?(\d+)-?LT?-?(\d+)-?QD?-?(\d+)\b}" = "QUADRA \\3 LOTE \\2 CASA \\1",
      r"{\bC-?(\d+)-?QD?-?(\d+)-?LT?-?(\d+)\b}" = "QUADRA \\2 LOTE \\3 CASA \\1",
      r"{\bLT?-?(\d+)-?QD?-?(\d+)-?C-?(\d+)\b}" = "QUADRA \\2 LOTE \\1 CASA \\3",
      r"{\bLT?-?(\d+)-?C-?(\d+)-?QD?-?(\d+)\b}" = "QUADRA \\3 LOTE \\1 CASA \\2",

      r"{\bFDS-?QD?-?(\d+)-?LT?-?(\d+)\b}" = "QUADRA \\1 LOTE \\2 FUNDOS",
      r"{\bQD?-?(\d+)-?LT?-?(\d+)\b}" = "QUADRA \\1 LOTE \\2",
      r"{\bFDS-?LT?-?(\d+)-?QD?-?(\d+)\b}" = "QUADRA \\2 LOTE \\1 FUNDOS",
      r"{\bLT?-?(\d+)-?QD?-?(\d+)\b}" = "QUADRA \\2 LOTE \\1",

      r"{\bQD?-?(\d+)-?C-?(\d+)\b}" = "QUADRA \\1 CASA \\2",

      r"{\bLT?-?(\d+)-?C-?(\d+)\b}" = "LOTE \\1 CASA \\2",
      r"{\bC-?(\d+)-?LT?-?(\d+)\b}" = "LOTE \\2 CASA \\1",

      r"{\bQD?-?(\d+)-?BL?-?(\d+)-?AP(TO?)?-?(\d+)\b}" = "QUADRA \\1 BLOCO \\2 APARTAMENTO \\4",

      r"{\bBL?-?(\d+)-?C-?(\d+)\b}" = "BLOCO \\1 CASA \\2",

      # APARTAMENTO33ABLOCO1, BLOCO1APARTAMENTO103, BLOCO38APT13
      r"{\bBL?-?(\d+)-?AP(TO?)?-?(\d+)\b}" = "BLOCO \\1 APARTAMENTO \\3",
      r"{\bAP(TO?)?-?(\d+)-?BL?-?(\d+)\b}" = "BLOCO \\3 APARTAMENTO \\2",

      # localidades
      # APRT
      r"{\bAPT0\b}" = "APTO",
      r"{\bAP(T(O|\u00BA)?|AR?T(AMENTO)?)?\.?(\d)}" = "APARTAMENTO \\4", # \u00BA = º, usado pro check não reclamar da presença de caracteres não-ascii
      r"{(\d)AP(T(O|\u00BA)?|AR?T(AMENTO)?)?\b\.?}" = "\\1 APARTAMENTO",
      r"{\bAP(T(O|\u00BA)?|AR?T)?\b\.?}" = "APARTAMENTO",
      r"{\bAPARTAMENTO\b: ?}" = "APARTAMENTO ",
      r"{\bAPARTAMENTO-(\d+)}" = "APARTAMENTO \\1",

      r"{\b(BLOCO|BLC?)\.?(\d+)}" = "BLOCO \\2",
      r"{(\d)(BLOCO|BLC?)\b\.?}" = "\\1 BLOCO",
      r"{\bBLC?\b\.?}" = "BLOCO",
      r"{\bBLOCO\b: ?}" = "BLOCO ",
      r"{\bBLOCO-(\d+)}" = "BLOCO \\1",

      # muita coisa pode ser quadra... Q A LOTE 2, Q I LOTE 45, QI, Q I, etc etc. tem que ver o que faz sentido
      r"{QU ADRA}" = "QUADRA",
      r"{\bQ(U(ADRA)?|D(RA?)?)\.?(\d)}" = "QUADRA \\4", # QDA pode ser QUADRA A. da tipo 1%~ das observacoes, pelo que vi aqui. vale a pena errar nesses 1% e transformar?
      r"{(\d+)Q(U(ADRA)?|D(RA?)?)\b\.?}" = "\\1 QUADRA",
      r"{\bQD(RA?)?\b\.?}" = "QUADRA",
      r"{\bQU\b\.? }" = "QUADRA ", # espaco no final pra evitar casos como "EDIFICIO RES M LUIZA QU" e "BLOCO 3A APARTAMENTO 201 E M QU"
      r"{\bQUADRA\b: ?}" = "QUADRA ",
      r"{\bQUADRA-(\d+)}" = "QUADRA \\1",
      r"{\bQ\.? ?(\d)}" = "QUADRA \\1",
      r"{\bQ-(\d+)}" = "QUADRA \\1",

      r"{\b(LOTE|LTE?)\.?(\d)}" = "LOTE \\2",
      r"{\b(?<!RUA |S\/)L\.? (\d)}" = "LOTE \\1", # o \\1 ta certo mesmo, os (?...) nao contam. transforma L 5 em LOTE 5, mas evita que RUA L 5 LOTE 45 vire RUA LOTE 5 LOTE 45 e que S/L 205 vire S/LOTE 205
      r"{(\d)(LTE?|LOTE)\b\.?}" = "\\1 LOTE",
      r"{\bLTE?\b\.?}" = "LOTE",
      r"{\bLOTE\b: ?}" = "LOTE ",
      r"{\bLOTE-(\d+)}" = "LOTE \\1",
      r"{\b(?<!(TV|TRAVESSA|QUADRA) )L-(\d+)}" = "LOTE \\2", # "L-21-NOVO HORIZONTE" ? "L-36" ?

      r"{\b(CASA|CS)\.?(\d)}" = "CASA \\2", # CSA?     o que quer dizer FDS? talvez FUNDOS
      r"{(\d)(CASA|CS)\b\.?}" = "\\1 CASA",
      r"{\bCS\b\.?}" = "CASA",
      r"{\bCASA\b: ?}" = "CASA ",
      r"{\bCASA-(\d+)}" = "CASA \\1",
      #r"{[^^]\b(?<!(APARTAMENTO|CONJUNTO|BLOCO|QUADRA) )C-(\d+)}" = "CASA \\1", # ESSE TEM MUITA VARIACAO, COMPLICADO #### Q-10 C-03 = Q-10 CASA 03, mas APARTAMENTO C-03 nao eh mexido, nem soh C-03 (pode ser soh C-03 mesmo)

      r"{\b(C(ON)?JT?|CONJUNTO)\.?(\d)}" = "CONJUNTO \\3",
      r"{(\d)(C(ON)?JT?|CONJUNTO)\b\.?}" = "\\1 CONJUNTO",
      r"{\bC(ON)?JT?\b\.?}" = "CONJUNTO",
      r"{\bCONJUNTO\b: ?}" = "CONJUNTO ",
      r"{\bCONJUNTO-(\d)}" = "CONJUNTO \\1",

      r"{\b(CONDOMINIO|C(O?N)?D)\.?(\d)}" = "CONDOMINIO \\3", # "LOTE 4 RUA 06 COND263"? "COND3 T7 APARTAMENTO 13"? "BLOCO 07 APARTAMENTO 204 CD2"?
      r"{(\d)(CONDOMINIO|C(O?N)?D)\b\.?}" = "\\1 CONDOMINIO",
      r"{\bC(O?N)?D\b\.?}" = "CONDOMINIO",
      r"{\bCONDOMINIO\b: ?}" = "CONDOMINIO ",
      r"{\bCONDOMINIO-(\d)}" = "CONDOMINIO \\1",

      r"{\bAND(AR)?\.?(\d)}" = "ANDAR \\2",
      r"{(\d)AND(AR)?\b\.?}" = "\\1 ANDAR",
      r"{\bAND\b\.?}" = "ANDAR",
      r"{\bANDAR\b: ?}" = "ANDAR ",
      r"{\bANDAR-(\d+)}" = "ANDAR \\1",

      r"{\bCOB(ERTURA)?\.?(\d)}" = "COBERTURA \\2",
      r"{(\d)COB(ERTURA)?\b\.?}" = "\\1 COBERTURA",
      r"{\bCOB\b\.?}" = "COBERTURA",
      r"{\bCOBERTURA\b: ?}" = "COBERTURA ",
      r"{\bCOBERTURA-(\d+)}" = "COBERTURA \\1",

      # abreviacoes
      r"{\bS\.? ?N\b\.?}" = "S/N",
      r"{\bPROX\b\.?}" = "PROXIMO",
      # r"{\bESQ\b\.?}" = "ESQUINA" # tem uns casos que ESQ = ESQUERDA, não ESQUINA - e.g. "LD ESQ", "A ESQ ENT XIQUITIM", "ULTIMA CASA LADO ESQ"
      r"{\bLOTEAM\b\.?}" = "LOTEAMENTO",
      r"{\bCX\.? ?P(T|(OST(AL)?))?\b\.?}" = "CAIXA POSTAL",
      r"{\bEDI?F?\b\.?}" = "EDIFICIO",
      r"{\bN(O|\u00BA)?\. (\d)}" = "NUMERO \\2",

      r"{\b(N(OS|SS?A?)?\.? S(RA|ENHORA)|(NOSSA|NSA\.?) (S(RA?)?|SEN(H(OR)?)?))\b\.?}" = "NOSSA SENHORA",
      r"{\b(NS?\.? S(R|ENH?)?\.?( DE?)?|NOSSA SENHORA) (FAT.*|LO?UR.*|SANTANA|GUADALUPE|NAZ.*|COP*)\b}" = "NOSSA SENHORA DE \\4",
      r"{\b(NS?\.? S(R|ENH?)?\.?( D(A|E)?)?|NOSSA SENHORA) (GRACA|VITORIA|PENHA|CONCEICAO|PAZ|GUIA|AJUDA|CANDELARIA|PURIFICACAO|SAUDE|PIEDADE|ABADIA|GLORIA|SALETE|APRESENTACAO)\b}" = "NOSSA SENHORA DA \\5",
      r"{\b(NS?\.? S(R|ENH?)?\.?( D(A|E)?)?|NOSSA SENHORA D(A|E)) (APA.*|AUX.*|MEDIANEIRA|CONSOLADORA)\b}" = "NOSSA SENHORA \\6",
      r"{\b(NS?\.? S(R|ENH?)?\.?( D(OS?)?)?|NOSSA SENHORA) (NAVEGANTES)\b}" = "NOSSA SENHORA DOS \\5",
      r"{\b(NS?\.? S(R|ENH?)?\.?( DO?)?|NOSSA SENHORA) (CARMO|LIVRAMENTO|RETIRO|SION|ROSARIO|PILAR|ROCIO|CAMINHO|DESTERRO|BOM CONSELHO|AMPARO|PERP.*|P.* S.*)\b}" = "NOSSA SENHORA DO \\4",
      r"{\b(NS?\.? S(R|ENH?)?\.?( D(AS?)?)?|NOSSA SENHORA) (GRACAS|DORES)\b}" = "NOSSA SENHORA DAS \\5",
      r"{\bNOSSO (SR?|SEN)\b\.?}" = "NOSSO SENHOR"
    )
  )

  names(complementos_padrao_dedup) <- complementos_dedup
  complementos_padrao <- complementos_padrao_dedup[complementos]
  names(complementos_padrao) <- NULL

  complementos_padrao[indice_complemento_vazio] <- NA_character_

  return(complementos_padrao)
}
