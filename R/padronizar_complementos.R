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

      # localidades
      r"{\bAPT0\b}" = "APTO",
      r"{\bAP(T(O|\u00BA)?|ART)?\.?(\d)}" = "APARTAMENTO \\3", # \u00BA = º, usado pro check não reclamar da presença de caracteres não-ascii
      r"{(\d)AP(T(O|\u00BA)?|ART(AMENTO)?)?\b\.?}" = "\\1 APARTAMENTO",
      r"{\bAP(T(O|\u00BA)?|ART)?\b\.?}" = "APARTAMENTO",
      r"{\bAPARTAMENTO\b: ?}" = "APARTAMENTO ",

      r"{\bBLC?\.?(\d)}" = "BLOCO \\1",
      r"{(\d)BLC?\b\.?}" = "\\1 BLOCO",
      r"{\bBLC?\b\.?}" = "BLOCO",
      r"{\bBLOCO\b: ?}" = "BLOCO ",

      # lidar com Q07L02C51

      r"{\bQD(RA?)?\.?(\d)}" = "QUADRA \\1", # QDA pode ser QUADRA A. da tipo 1%~ das observacoes, pelo que vi aqui. vale a pena errar nesses 1% e transformar?
      r"{(\d)QD(RA?)?\b\.?}" = "\\1 QUADRA",
      r"{\bQD(RA?)?\b\.?}" = "QUADRA",
      r"{\bQUADRA\b: ?}" = "QUADRA ",
      r"{\bQ\.? ?(\d)}" = "QUADRA \\1",

      r"{\bLTE?\.?(\d)}" = "LOTE \\1",
      r"{(\d)LTE?\b\.?}" = "\\1 LOTE",
      r"{\bLTE?\b\.?}" = "LOTE",
      r"{\bLOTE\b: ?}" = "LOTE ",

      r"{\bCS\.?(\d)}" = "CASA \\1", # CSA?     o que quer dizer FDS? talvez FUNDOS
      r"{(\d)CS\b\.?}" = "\\1 CASA",
      r"{\bCS\b\.?}" = "CASA",
      r"{\bCASA\b: ?}" = "CASA ",

      r"{\bC(ON)?J\.?(\d)}" = "CONJUNTO \\2",
      r"{(\d)C(ON)?J\b\.?}" = "\\1 CONJUNTO",
      r"{\bC(ON)?J\b\.?}" = "CONJUNTO",
      r"{\bC(ON)?J\b: ?}" = "CONJUNTO ",

      r"{\bC(O?N)?D\.?(\d)}" = "CONDOMINIO \\2", # "LOTE 4 RUA 06 COND263"? "COND3 T7 APARTAMENTO 13"? "BLOCO 07 APARTAMENTO 204 CD2"?
      r"{(\d)C(O?N)?D\b\.?}" = "\\1 CONDOMINIO",
      r"{\bC(O?N)?D\b\.?}" = "CONDOMINIO",
      r"{\bC(O?N)?D\b: ?}" = "CONDOMINIO ",

      r"{\bAND\.?(\d)}" = "ANDAR \\1",
      r"{(\d)AND\b\.?}" = "\\1 ANDAR",
      r"{\bAND\b\.?}" = "ANDAR",
      r"{\bAND\b: ?}" = "ANDAR ",

      # abreviacoes
      r"{\bS\.? ?N\b\.?}" = "S/N",
      r"{\bPROX\b\.?}" = "PROXIMO",
      # r"{\bESQ\b\.?}" = "ESQUINA" # tem uns casos que ESQ = ESQUERDA, não ESQUINA - e.g. "LD ESQ", "A ESQ ENT XIQUITIM", "ULTIMA CASA LADO ESQ"
      r"{\bLOTEAM\b\.?}" = "LOTEAMENTO",
      r"{\bCX\.? ?P(T|(OST(AL)?))?\b\.?}" = "CAIXA POSTAL",
      r"{\bEDI?F?\b\.?}" = "EDIFICIO",
      r"{\bN(O|\u00BA)?\. (\d)}" = "NUMERO \\2"
    )
  )

  names(complementos_padrao_dedup) <- complementos_dedup
  complementos_padrao <- complementos_padrao_dedup[complementos]
  names(complementos_padrao) <- NULL

  complementos_padrao[indice_complemento_vazio] <- NA_character_

  return(complementos_padrao)
}
