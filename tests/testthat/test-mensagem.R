tester <- function(msg) mensagem_progresso_endpad(msg)

test_that("respeita a verbosidade definida", {
  rlang::local_options(rlib_message_verbosity = "verbose")
  rlang::local_options(endereco_padrao.verbose = "verbose")
  expect_message(mensagem_progresso_endpad("oi"))
  expect_message(cli::cli_progress_done())

  rlang::local_options(rlib_message_verbosity = "quiet")
  rlang::local_options(endereco_padrao.verbose = "quiet")
  expect_silent(mensagem_progresso_endpad("oi"))
  expect_silent(cli::cli_progress_done())

  rlang::local_options(rlib_message_verbosity = "quiet")
  rlang::local_options(endereco_padrao.verbose = "verbose")
  expect_message(mensagem_progresso_endpad("oi"))
  expect_message(cli::cli_progress_done())
})
