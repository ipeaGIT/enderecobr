## Workflow de atualização do crate `enderecobr_rs`

> TODO: detalhar melhor isso e talvez fazer um script para facilitar isso

```R
# Atualizar a versão no `cargo.toml`
# Apagar as pastas `vendor` (em src/ e src/rust, não sei porque tem duas)

extendr::vendor_pkgs() # Atualiza os pacotes "vendored"

devtools::document() # Recompila tudo
devtools::load_all() # Carrega o pacote

enderecobr::padronizar_logradouro("") # Teste rápido

devtools::test() # Roda testes unitários
testthat::snapshot_accept() # Opcionalmente, aceita os novos snapshots

devtools::check(remote = TRUE, manual = TRUE) # Testes finais

devtools::check(pkg = ".",  cran = FALSE, env_vars = c(NOT_CRAN = "true")) # Outro comando de testes

# Atualizar a versão no DESCRIPTION

devtools::submit_cran() # Subir no CRAN
```
