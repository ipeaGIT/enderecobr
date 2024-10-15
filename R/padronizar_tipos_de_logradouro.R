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
      r"{\.([^ ])}" = "\\. \\1", # garantir que haja espaco depois do ponto
      r"{ (-|\.) }" = " ",
      r"{\.$}" = "",           # remocao de ponto final

      # sinalizacao
      r"{"}" = "'", # existem ocorrencias em que aspas duplas sao usadas para se referir a um logradouro/quadra com nome relativamente ambiguo - e.g. RUA \"A\", 26. isso pode causar um problema quando lido com o data.table: https://github.com/Rdatatable/data.table/issues/4779. por enquanto, substituindo por aspas simples. depois a gente pode ver o que fazer com as aspas simples rs.

      # valores non-sense
      r"{^-+$}" = "", # - --+
      r"{^([^\d])\1{1,}$}" = "", # qualquer valor não numérico 2+ vezes
      r"{^\d+$}" = "", # tipos de logradouro não podem ser números

      # ordenacao de logradouros - e.g. 3A RUA, 15A TRAVESSA, 1A RODOVIA, 1O BECO, etc
      r"{\b\d+(A|O) ?}" = "",

      # tipos de logradouro
      # problema visto no cadunico 2011: muitos tipos são truncados em 3 letras.
      # existem ambiguidades com CAM (CAMINHO x CAMPO), CON (CONJUNTO x
      # CONDOMINIO), PAS (PASSARELA x PASSAGEM x PASSEIO), entre outros. nesses
      # casos, acho melhor não "tomar um lado" e manter inalterado

      r"{\bR(A|U)?\b\.?}" = "RUA",
      r"{\b(ROD|RDV)\b\.?}" = "RODOVIA",
      r"{\bAV(E|N|D|DA|I)?\b\.?}" = "AVENIDA",
      r"{\bESTR?\b\.?}" = "ESTRADA", # EST pode ser ESTANCIA, mas são poucos casos. no cadunico 2011 ESTRADA eram 139780 e ESTANCIA 158, 0.1%
      r"{\b(PCA?|PR(A|C))\b\.?}" = "PRACA",
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
      r"{\bCOND\b\.?}" = "CONDOMINIO",
      r"{\bSIT\b\.?}" = "SITIO",
      r"{\bRES(ID)?\b\.?}" = "RESIDENCIAL",
      r"{\bQ(U(AD?)?|D(RA?)?)\b\.?}" = "QUADRA",
      r"{\bCHAC\b\.?}" = "CHACARA", # CHA pode ser CHAPADAO
      r"{\bCPO\b\.?}" = "CAMPO",
      r"{\bCOL\b\.?}" = "COLONIA",
      r"{\bC(ONJ|J)\b\.?}" = "CONJUNTO",
      r"{\bJ(D(I?M)?|A?RD|AR(DIN)?)\b\.?}" = "JARDIM",
      r"{\bFAV\b\.?}" = "FAVELA",
      r"{\bNUC\b\.?}" = "NUCLEO",
      r"{\bVIE\b\.?}" = "VIELA",
      r"{\bSET\b\.?}" = "SETOR",
      r"{\bILH\b\.?}" = "ILHA",
      r"{\bVER\b\.?}" = "VEREDA",
      r"{\bACA\b\.?}" = "ACAMPAMENTO",
      r"{\bACE\b\.?}" = "ACESSO",
      r"{\bADR\b\.?}" = "ADRO",
      r"{\bALT\b\.?}" = "ALTO",
      r"{\bARE\b\.?}" = "AREA",
      r"{\bART\b\.?}" = "ARTERIA",
      r"{\bATA\b\.?}" = "ATALHO",
      r"{\bBAI\b\.?}" = "BAIXA",
      r"{\bBLO\b\.?}" = "BLOCO",
      r"{\bBOS\b\.?}" = "BOSQUE",
      r"{\bBOU\b\.?}" = "BOULEVARD",
      r"{\bBUR\b\.?}" = "BURACO",
      r"{\bCAI\b\.?}" = "CAIS",
      r"{\bCAL\b\.?}" = "CALCADA",
      r"{\bELE\b\.?}" = "ELEVADA",
      r"{\bESP\b\.?}" = "ESPLANADA",
      r"{\bFEI\b\.?}" = "FEIRA",
      r"{\bFER\b\.?}" = "FERROVIA",
      r"{\bFON\b\.?}" = "FONTE",
      r"{\bFOR\b\.?}" = "FORTE",
      r"{\bGAL\b\.?}" = "GALERIA",
      r"{\bGRA\b\.?}" = "GRANJA",
      r"{\bMOD\b\.?}" = "MODULO",
      r"{\bMON\b\.?}" = "MONTE",
      r"{\bMOR\b\.?}" = "MORRO",
      r"{\bPAT\b\.?}" = "PATIO",
      r"{\bPOR\b\.?}" = "PORTO",
      r"{\bREC\b\.?}" = "RECANTO",
      r"{\bRET\b\.?}" = "RETA",
      r"{\bROT\b\.?}" = "ROTULA",
      r"{\bSER\b\.?}" = "SERVIDAO",
      r"{\bSUB\b\.?}" = "SUBIDA",
      r"{\bTER\b\.?}" = "TERMINAL",
      r"{\bTRI\b\.?}" = "TRINCHEIRA",
      r"{\bTUN\b\.?}" = "TUNEL",
      r"{\bUNI\b\.?}" = "UNIDADE",
      r"{\bVAL\b\.?}" = "VALA",
      r"{\bVAR\b\.?}" = "VARIANTE",
      r"{\bZIG\b\.?}" = "ZIGUE-ZAGUE",

      "OUTROS" = ""

      # EDF é usado pra sinalizar endereços típicos do DF no CadUnico (sigla de
      # Endereço do DF), não substituir por EDIFICIO
      #   * pelo menos é o que diz o manual do CadUnico, mas isso não aparece
      #     nenhuma vez, pelo visto
    )
  )

  names(tipos_padrao_dedup) <- tipos_dedup
  tipos_padrao <- tipos_padrao_dedup[tipos]
  names(tipos_padrao) <- NULL

  tipos_padrao[tipos_padrao == ""] <- NA_character_

  return(tipos_padrao)
}
