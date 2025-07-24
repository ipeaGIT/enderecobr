warning_endbr <- function(message, call, .envir) {
  chamada_warning <- sys.call(-1)
  funcao_atribuida <- as.name(chamada_warning[[1]])

  classes_warning <- c(
    paste0("warning_endbr_", sub("^warning_", "", funcao_atribuida)),
    "warning_endbr"
  )

  cli::cli_warn(message, class = classes_warning, call = call, .envir = .envir)
}
