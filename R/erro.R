erro_endbr <- function(message, call, .envir = parent.frame()) {
  chamada_erro <- sys.call(-1)
  funcao_atribuida <- as.name(chamada_erro[[1]])

  classes_erro <- c(
    paste0("erro_endbr_", sub("^erro_", "", funcao_atribuida)),
    "erro_endbr"
  )

  cli::cli_abort(
    message,
    class = classes_erro,
    call = call,
    .envir = .envir
  )
}
