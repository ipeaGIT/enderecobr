tester <- function(msg) mensagem_progresso_endbr(msg)

test_that("respeita a verbosidade definida", {
  rlang::local_options(rlib_message_verbosity = "verbose")
  rlang::local_options(enderecobr.verbose = "verbose")
  expect_message(mensagem_progresso_endbr("oi"))
  expect_message(cli::cli_progress_done())

  rlang::local_options(rlib_message_verbosity = "quiet")
  rlang::local_options(enderecobr.verbose = "quiet")
  expect_silent(mensagem_progresso_endbr("oi"))
  expect_silent(cli::cli_progress_done())

  rlang::local_options(rlib_message_verbosity = "quiet")
  rlang::local_options(enderecobr.verbose = "verbose")
  expect_message(mensagem_progresso_endbr("oi"))
  expect_message(cli::cli_progress_done())
})
