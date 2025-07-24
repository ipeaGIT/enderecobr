mensagem_progresso_endbr <- function(msg) {
  rlib_verboso <- (getOption("rlib_message_verbosity", "quiet") == "verbose")
  pacote_verboso <- (getOption("enderecobr.verbose", "quiet") == "verbose")

  if (rlib_verboso || pacote_verboso) {
    cli::cli_progress_step(msg, .envir = parent.frame())
  }
}
