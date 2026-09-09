## Test environments

- Local Windows Server 2022 installation (R 4.5.2)
- GitHub Actions:
  - windows-latest (release)
  - windows-11-arm (release)
  - macOS-latest (release)
  - Ubuntu 24.04 (devel, release, oldrel)
- win-builder (devel, release, oldrel)
- Rhub:
  - linux (devel)
  - macos-arm64 (devel)
  - windows (devel)

── R CMD check results ────────────────────────────────────────────── enderecobr 0.6.0 ────
Duration: 3m 10s

0 errors ✔ | 0 warnings ✔ | 0 notes ✔



# enderecobr 0.6.0

## Notas

- Atualização do pacote para utilizar a nova crate v0.2.0 do 
[enderecobr_rs](https://github.com/ipea/enderecobr_rs).
- A compilação do pacote requer Rust >= 1.81.0, conforme o requisito do
  `enderecobr_rs` v0.2.0.
- Corrigida a compilação do gerador de wrappers no Windows com Rtools e evitada
  a recompilação desnecessária das dependências Rust nessa etapa.
- Repositório migrado de `ipeaGIT/enderecobr` para `ipea/enderecobr` ([issue
  #67](https://github.com/ipea/enderecobr/issues/67)).
- Mudança de mantenedo do pacote, que passou do Daniel Herszenhut para o Rafel H. M. Pereira.


