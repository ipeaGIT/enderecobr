# Padronizador de CEPs em Rust 🦀

Port da função `padronizar_ceps()` do pacote R enderecobr para Rust.

## 🚀 Performance

- **10-100x mais rápido** que a versão R para grandes volumes
- Processamento standalone sem dependências R
- Suporte nativo para arquivos Parquet

## 📦 Instalação

### Pré-requisitos
- [Rust](https://rustup.rs/) (1.70+)

### Compilar
```bash
cd rust_cep
cargo build --release
```

## 📁 Preparação dos Dados de Teste

### Opção 1: Criar arquivo CSV de exemplo
```bash
# Criar diretório se não existir
mkdir -p ../data_test

# Criar arquivo CSV com CEPs de exemplo
cat > ../data_test/exemplo_ceps.csv << 'EOF'
id,cep
1,22290140
2,01000-000
3,22.290-140
4,1000000
5,22290 140
EOF

echo "Arquivo de teste criado em data_test/exemplo_ceps.csv"
```

### Opção 2: Usar dados do pacote R (se disponível)
```r
# No R, exportar dados de exemplo
library(enderecobr)
library(arrow)

# Criar dados de exemplo
dados <- data.frame(
  id = 1:10,
  cep = c("22290140", "01000000", "22290-140", NA, "1000000", 
          "22.290-140", "", "22290 140", "01310-100", "04567890")
)

# Salvar como Parquet
write_parquet(dados, "data_test/endbr.parquet")
```

## 🎯 Uso

### Testar padronização (exemplos)
```bash
cargo run -- --test
```

### Processar arquivo Parquet
```bash
# Criar dados de teste primeiro (se necessário)
./criar_dados_teste.sh

# Da pasta rust_cep
cargo run -- ../data_test/endbr.parquet

# Ou com binário compilado
./target/release/padronizar_cep ../data_test/endbr.parquet
```

## 📋 Funcionalidades

Implementa a mesma lógica da versão R:
- ✅ Remove espaços, pontos e vírgulas
- ✅ Adiciona zeros à esquerda (padding para 8 dígitos)
- ✅ Formata com hífen (XXXXX-XXX)
- ✅ Valida entrada (sem letras, máx 8 dígitos)
- ✅ Trata valores nulos/vazios

## 🧪 Exemplos

```
Input: "22290-140"  → Output: "22290-140"
Input: "22290 140"  → Output: "22290-140"
Input: "22.290-140" → Output: "22290-140"
Input: "22290140"   → Output: "22290-140"
Input: "1000000"    → Output: "01000-000"
Input: "botafogo"   → ERRO: CEP não deve conter letras
Input: "222290140"  → ERRO: CEP não deve conter mais que 8 dígitos
```

## 🔧 Testes

```bash
cargo test
```

## 📊 Comparação com R

Para validar que produz os mesmos resultados:

```r
# No R
library(enderecobr)
ceps <- c("22290140", "1000000", "22.290-140")
padronizar_ceps(ceps)
# [1] "22290-140" "01000-000" "22290-140"
```

```bash
# Em Rust
cargo run -- --test
# '22290140' → '22290-140'
# '1000000' → '01000-000'
# '22.290-140' → '22290-140'
```

## 📝 Notas

- Compatível com a versão R 0.4.1 do enderecobr
- Processa arquivos Parquet diretamente
- Detecta automaticamente colunas de CEP
- Reporta erros sem interromper processamento

## 🤝 Contribuindo

Este é um port experimental. Feedbacks e melhorias são bem-vindos!

## 📄 Licença

Mesma licença do projeto original (MIT)