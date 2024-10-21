funcao_pai <- function() erro_teste()

erro_teste <- function() {
  erro_endpad(c("teste", "*" = "informacao"), call = rlang::caller_env())
}

test_that("erro funciona corretamente", {
  expect_error(funcao_pai(), class = "erro_endpad_teste")
  expect_error(funcao_pai(), class = "erro_endpad")

  expect_snapshot(funcao_pai(), error = TRUE, cnd_class = TRUE)
})
