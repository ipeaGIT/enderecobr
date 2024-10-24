mensagem_progresso_endpad <- function(msg) {
  rlib_verboso <- (getOption("rlib_message_verbosity", "quiet") == "verbose")
  pacote_verboso <- (getOption("enderecopadrao.verbose", "quiet") == "verbose")

  if (rlib_verboso || pacote_verboso) {
    cli::cli_progress_step(msg, .envir = parent.frame())
  }
}
