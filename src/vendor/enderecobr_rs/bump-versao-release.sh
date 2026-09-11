#!/usr/bin/env bash
set -euo pipefail

# Checagem se o argumento existe
if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <versão>" >&2
  exit 1
fi

VERSION="$1"

# Verificação do formato do argumento como versionamento semântico
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Erro: versão inválida: $VERSION" >&2
  echo "Esperado: MAJOR.MINOR.PATCH (ex.: 0.4.3)" >&2
  exit 1
fi

# Substituições inplace das versões nos arquivos chave
# Considera só a primeira ocorrencia do "version = " nos arquivos
sed -i -E "0,/^version = .*/s/^version = \".*\"/version = \"$VERSION\"/" Cargo.toml
sed -i -E "0,/^version = .*/s/^version = \".*\"/version = \"$VERSION\"/" bindings/python/pyproject.toml
sed -i -E "0,/^version = .*/s/^version = \".*\"/version = \"$VERSION\"/" bindings/python/Cargo.toml

# Faz o bump de versão nos arquivos de lock
cargo check
cargo check --manifest-path bindings/python/Cargo.toml
uv sync --directory bindings/python

# Faz o git commit desses caras todos (.toml e .lock)
git add Cargo.toml Cargo.lock bindings/python/pyproject.toml bindings/python/Cargo.toml bindings/python/Cargo.lock bindings/python/Cargo.toml bindings/python/uv.lock
git commit -m "chore: release v$VERSION"

# Cria a tag para a release
# PS: Esse comando dá erro quando a tag já existe. Remova ela com `git tag -d v0.x.x`
git tag "v$VERSION"
