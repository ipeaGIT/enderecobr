#' Padronizar CEPs
#'
#' Padroniza um vetor de caracteres ou números representando CEPs. Veja a seção
#' *Detalhes* para mais informações sobre a padronização.
#'
#' @param ceps Um vetor de caracteres ou números. Os CEPs a serem padronizados.
#'
#' @return Um vetor de caracteres com os CEPs padronizados.
#'
#' @section Detalhes:
#' Operações realizadas durante a padronização:
#'
#' - conversão para caracter, se o input for numérico;
#' - adição de zeros à esquerda, se o input contiver menos de 8 dígitos;
#' - remoção de espaços em branco, pontos e vírgulas;
#' - adição de traço separando o radical (5 primeiros dígitos) do sufixo (3
#' últimos digitos).
#'
#' @examples
#' ceps <- c("22290-140", "22.290-140", "22290 140", "22290140")
#' padronizar_ceps(ceps)
#'
#' ceps <- c(22290140, 1000000, NA)
#' padronizar_ceps(ceps)
#'
#' @export
padronizar_ceps <- function(ceps) {
  checkmate::assert(
    checkmate::check_character(ceps),
    checkmate::check_numeric(ceps),
    combine = "or"
  )

  ceps_dedup <- unique(ceps)

  # alguns ceps podem vir vazios e devem permanecer vazios ao final. nesse caso,
  # a chamada da str_pad() abaixo faz com que esses ceps virem '00000000'. para
  # evitar que o resultado contenha esses valores, identificamos o indice dos
  # ceps vazios para "reesvazia-los" ao final

  indice_cep_vazio <- which(ceps == "" | is.na(ceps))

  if (is.numeric(ceps)) {
    ceps_padrao_dedup <- formatC(ceps_dedup, width = 8, format = "d", flag = 0)
  } else {
    checa_se_letra_presente(ceps)

    ceps_padrao_dedup <- ceps_dedup
  }

  ceps_padrao_dedup <- stringr::str_replace_all(
    ceps_padrao_dedup,
    c("\\.|,| " = "")
  )
  ceps_padrao_dedup <- stringr::str_pad(ceps_padrao_dedup, width = 8, pad = "0")
  ceps_padrao_dedup <- stringr::str_replace_all(
    ceps_padrao_dedup,
    c("(\\d{5})(\\d{3})" = "\\1-\\2")
  )

  names(ceps_padrao_dedup) <- ceps_dedup
  ceps_padrao <- ceps_padrao_dedup[as.character(ceps)]
  names(ceps_padrao) <- NULL

  ceps_padrao[indice_cep_vazio] <- NA_character_

  checa_se_digitos_demais(ceps_padrao)

  return(ceps_padrao)
}

# checks ------------------------------------------------------------------

checa_se_letra_presente <- function(ceps) {
  possui_letras <- stringr::str_detect(ceps, "[a-zA-Z]")

  if (any(possui_letras[!is.na(possui_letras)])) {
    erro_cep_com_letra(possui_letras)
  }
}

checa_se_digitos_demais <- function(ceps_padrao) {
  possui_digitos_demais <- nchar(ceps_padrao) > 9

  if (any(possui_digitos_demais[!is.na(possui_digitos_demais)])) {
    erro_cep_com_digitos_demais(possui_digitos_demais)
  }
}

# erros -------------------------------------------------------------------

erro_cep_com_letra <- function(possui_letras) {
  # a padronizar_ceps() pode tanto ser chamada individualmente ou como parte da
  # função padronizar_enderecos(). nesse caso, precisamos que o erro aponte pra
  # chamada da padronizar_enderecos(), já que o usuário não sabe que a
  # padronizar_ceps é chamada internamente. pra isso, verificamos as chamadas
  # feitas na stack e, caso seja feita pela função interna usada na
  # padronizar_enderecos(), mudamos o caller_env do erro

  n_caller_env <- 2

  chamada_upstream <- tryCatch(sys.call(-10), error = function(cnd) NULL)
  if (!is.null(chamada_upstream)) {
    funcao_upstream <- as.character(chamada_upstream[[1]])
    funcao_upstream <- setdiff(funcao_upstream, c("::", "enderecobr"))

    if (funcao_upstream == "padronizar_enderecos") n_caller_env <- 8
  }

  indice_com_letras <- which(possui_letras)
  indice_com_letras <- as.character(indice_com_letras)

  lista_indices <- cli::cli_vec(
    indice_com_letras,
    list("vec-trunc" = 5, "vec-last" = " e ", "vec-sep2" = " e ")
  )

  erro_endbr(
    c(
      "CEP n\u00e3o deve conter letras.",
      "i" = paste0(
        "O{?s} elemento{?s} com \u00edndice{?s} ",
        "{lista_indices} possu{?i/em} letras."
      )
    ),
    call = rlang::caller_env(n = n_caller_env),
    .envir = environment()
  )
}

erro_cep_com_digitos_demais <- function(possui_digitos_demais) {
  # a padronizar_ceps() pode tanto ser chamada individualmente ou como parte da
  # função padronizar_enderecos(). nesse caso, precisamos que o erro aponte pra
  # chamada da padronizar_enderecos(), já que o usuário não sabe que a
  # padronizar_ceps é chamada internamente. pra isso, verificamos as chamadas
  # feitas na stack e, caso seja feita pela função interna usada na
  # padronizar_enderecos(), mudamos o caller_env do erro

  n_caller_env <- 2

  chamada_upstream <- tryCatch(sys.call(-10), error = function(cnd) NULL)
  if (!is.null(chamada_upstream)) {
    funcao_upstream <- as.character(chamada_upstream[[1]])
    funcao_upstream <- setdiff(funcao_upstream, c("::", "enderecobr"))

    if (funcao_upstream == "padronizar_enderecos") n_caller_env <- 8
  }

  indice_muitos_digitos <- which(possui_digitos_demais)
  indice_muitos_digitos <- as.character(indice_muitos_digitos)

  lista_indices <- cli::cli_vec(
    indice_muitos_digitos,
    list("vec-trunc" = 5, "vec-last" = " e ", "vec-sep2" = " e ")
  )

  erro_endbr(
    c(
      "CEP n\u00e3o deve conter mais que 8 d\u00edgitos.",
      "i" = paste0(
        "O{?s} elemento{?s} com \u00edndice{?s} ",
        "{lista_indices} possu{?i/em} mais que 8 d\u00edgitos ",
        "ap\u00f3s padroniza\u00e7\u00e3o."
      )
    ),
    call = rlang::caller_env(n = n_caller_env),
    .envir = environment()
  )
}
