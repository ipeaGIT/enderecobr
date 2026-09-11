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

## Geração dos wrappers (`R/extendr-wrappers.R`)

O arquivo `R/extendr-wrappers.R` é versionado e **não** é regenerado na
instalação do pacote. O `Makevars(.win)` só compila e executa o binário
`document` (`src/rust/document.rs`) quando a variável `ROXYGEN_PKG` está
definida, ou seja, durante `devtools::document()`. Esse binário linka com a
`libR`, que não existe em builds do R sem `--enable-R-shlib` (caso das
máquinas Fedora do CRAN, ver [issue
#70](https://github.com/ipea/enderecobr/issues/70)) — por isso a etapa
nunca pode rodar em `R CMD INSTALL`.

Se o `devtools::document()` falhar por falta da `libR` na sua máquina, a
alternativa é `rextendr::register_extendr()` (usa a DLL já compilada) ou
editar o arquivo à mão. Não adotar o `document.c` do rextendr de
desenvolvimento: ele depende do símbolo `write__make_<pkg>_wrappers`, que só
existe no extendr do git, não no `extendr-api` 0.9.0 do crates.io.
