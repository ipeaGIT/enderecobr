# Marca todos os targets como phony (nenhum cria arquivo)
.PHONY: $(MAKEFILE_LIST)

DIR_DATASETS = ./datasets
DIR_SNAPSHOT = ./datasets/dados/snapshot_test

# ==== Utilitários ====

build:
	cargo build --release

build-lto:
	cargo build --profile release-lto --all-features

doc:
	cargo doc --no-deps --lib --release --all-features

test:
	cargo test

coverage:
	cargo llvm-cov --show-missing-lines

# ==== Utilitários para os testes de Snapshot ====

# Esses targets chamam o `snapshot-download` antes de rodar os testes,
# que por sua vez baixa os arquivos quando eles não existem.
snapshot-test: snapshot-download
	cargo run --release -p snapshot -- $(DIR_SNAPSHOT)

snapshot-criar: snapshot-download
	cargo run --release -p snapshot -- -s $(DIR_SNAPSHOT)

# Esses targets só chamam um outro makefile do diretório de datasets
snapshot-upload:
	$(MAKE) -C $(DIR_DATASETS) hf-publicar-snapshot-test

snapshot-download:
	$(MAKE) -C $(DIR_DATASETS) snapshot-download

# Flag -B força a execução mesmo que os arquivos existam.
snapshot-download-force:
	$(MAKE) -C $(DIR_DATASETS) -B snapshot-download
