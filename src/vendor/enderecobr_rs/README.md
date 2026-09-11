# enderecobr_rs <img align="right" src="./assets/logo.svg" alt="" width="180">

| ***Rust*** | ***Python*** | ***R*** |
|-----|-----|-----|
| [![crates.io Latest Release](https://img.shields.io/crates/v/enderecobr_rs.svg)](https://crates.io/crates/enderecobr_rs) <br /> [![docs.rs Rust](https://docs.rs/enderecobr_rs/badge.svg)](https://docs.rs/enderecobr_rs/) <br /> [![codecov](https://codecov.io/gh/ipea/enderecobr_rs/graph/badge.svg?token=ckgU5oGbxf)](https://codecov.io/gh/ipea/enderecobr_rs) <br /> [![CI](https://github.com/ipea/enderecobr_rs/workflows/CI/badge.svg)](https://github.com/ipea/enderecobr_rs/actions) <br /> ![Crates.io Downloads (latest version)](https://img.shields.io/crates/dv/enderecobr_rs) | [![PyPi Latest Release](https://img.shields.io/pypi/v/enderecobr.svg)](https://pypi.org/project/enderecobr) <br /> [![Downloads](https://static.pepy.tech/badge/enderecobr)](https://pepy.tech/project/enderecobr) <br /> [![readthedocs Python](https://app.readthedocs.org/projects/enderecobr-py/badge)](https://enderecobr-py.readthedocs.io) | [![R-repo](https://img.shields.io/badge/github-repo-blue?logo=github)](https://github.com/ipea/enderecobr) <br /> [![CRAN status](https://www.r-pkg.org/badges/version/enderecobr)](https://CRAN.R-project.org/package=enderecobr) <br /> [![CRAN/METACRAN Total downloads](https://cranlogs.r-pkg.org/badges/grand-total/enderecobr?color=blue)](https://CRAN.R-project.org/package=enderecobr) |







[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)

**enderecobr_rs** é uma biblioteca em Rust que disponibiliza diversas funções para padronizar endereços brasileiros,
corrigindo erros comuns, expandindo abreviações etc, afim de facilitar processamentos posteriores. Ela usa 
majoritariamente expressões regulares nas padronizações, com exceção do módulo experimental de separação 
de endereços, que utiliza um modelo probabilístico de [Conditional Random Field](https://en.wikipedia.org/wiki/Conditional_random_field) já embutido na bilioteca.

Obs. Esta biblioteca é uma adaptação e expansão para Rust da versão original em R 
do [enderecobr](https://github.com/ipea/enderecobr) visando ganho de eficiência e 
expandir a implementação do pacote **endereçobr** em diferentes linguagens usando a 
versão em Rust como base.


## Bindings

Este é o repositório do enderecobr em Rust e em Python. A versão em Python é feita no subdiretório 
`bindings/python` deste projeto. O repositório da versão em R se mantém em [enderecobr](https://github.com/ipea/enderecobr), 
utilizando internamente as funções desta lib. Algumas funções ou classes/structs da implementação em 
Rust podem não estar expostas em outras linguagens. Vide [documentação](https://docs.rs/enderecobr_rs) 
do Rust para identificar tais situações. Para solicitar esse tipo de mudança ou bindings em outras 
linguagens de programação, por favor abrir uma Issue ou Pull request neste repositório.

## Documentação:

- [R](https://ipea.github.io/enderecobr/)
- [Rust](https://docs.rs/enderecobr_rs/)
- [Python](https://enderecobr-py.readthedocs.io)

## Instalação

A última versão pode ser baixada do crates com o comando:

```bash
cargo add enderecobr_rs
```

Ou adicionando em no seu `Cargo.toml`:

```toml
[dependencies]
enderecobr_rs = { version = "0.0.3" }
```

## Exemplo de uso

### Rust:

```rust
use enderecobr_rs::{padronizar_complementos, padronizar_logradouros};
assert_eq!(padronizar_logradouros("r. gen.. glicério"), "RUA GENERAL GLICERIO");
assert_eq!(padronizar_complementos("QD1 LT2 CS3"), "QUADRA 1 LOTE 2 CASA 3");
```

### Python:

```python
import enderecobr
assert enderecobr.padronizar_logradouros("r. gen.. glicério") == "RUA GENERAL GLICERIO"
assert enderecobr.padronizar_logradouros("QD1 LT2 CS3") == "QUADRA 1 LOTE 2 CASA 3"
```

## Nota <a href="https://www.ipea.gov.br"><img src="./assets/ipea_logo.png" alt="Ipea" align="right" width="300"/></a>

**enderecobr** é desenvolvido por uma equipe de pesquisadores do Instituto de Pesquisa Econômica Aplicada (Ipea).
