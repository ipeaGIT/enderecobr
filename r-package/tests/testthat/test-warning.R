funcao_pai <- function() warning_teste()

warning_teste <- function() {
  warning_endbr(c("teste", "*" = "informacao"), call = rlang::caller_env())
}

test_that("warning funciona corretamente", {
  expect_warning(funcao_pai(), class = "warning_endbr_teste")
  expect_warning(funcao_pai(), class = "warning_endbr")

  expect_snapshot(funcao_pai(), cnd_class = TRUE)
})
