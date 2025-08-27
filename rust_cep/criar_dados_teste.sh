#!/bin/bash
# Script para criar dados de teste para o padronizador de CEPs em Rust
# Autor: Marcelo Bragatte (ITpS - Instituto Todos pela Saúde)

echo "🔧 Criando dados de teste para o padronizador de CEPs..."

# Criar diretório se não existir
mkdir -p ../data_test

# Criar arquivo CSV de exemplo
cat > ../data_test/exemplo_ceps.csv << 'EOF'
id,logradouro,numero,bairro,cep,municipio,uf
1,Rua General Glicério,137,Centro,22290140,Rio de Janeiro,RJ
2,Av Dom Pedro I,20,Botafogo,01000-000,São Paulo,SP
3,Rua NS Sra da Piedade,20,Jd Botânico,22.290-140,Rio de Janeiro,RJ
4,Av Brasil,1000,Centro,1000000,Brasília,DF
5,Rua das Flores,S/N,Vila Nova,22290 140,Rio de Janeiro,RJ
6,,,,,Rio de Janeiro,RJ
7,Praça da Sé,100,Centro,01310-100,São Paulo,SP
8,Rua Amazonas,500,Savassi,30180001,Belo Horizonte,MG
9,Av Paulista,1578,Bela Vista,01310100,São Paulo,SP
10,Rua do Comércio,123,Centro,40010000,Salvador,BA
EOF

echo "✅ Arquivo CSV criado: ../data_test/exemplo_ceps.csv"

# Verificar se Python está instalado para criar Parquet
if command -v python3 &> /dev/null; then
    echo "📦 Tentando criar arquivo Parquet..."
    python3 << 'PYTHON_SCRIPT'
import sys
try:
    import pandas as pd
    import pyarrow.parquet as pq
    
    # Ler CSV
    df = pd.read_csv('../data_test/exemplo_ceps.csv')
    
    # Salvar como Parquet
    df.to_parquet('../data_test/exemplo.parquet', index=False)
    print("✅ Arquivo Parquet criado: ../data_test/exemplo.parquet")
except ImportError:
    print("⚠️  pandas ou pyarrow não instalados. Use o CSV ou instale:")
    print("   pip install pandas pyarrow")
except Exception as e:
    print(f"❌ Erro ao criar Parquet: {e}")
PYTHON_SCRIPT
else
    echo "⚠️  Python não encontrado. Arquivo Parquet não foi criado."
    echo "   Use o arquivo CSV ou instale Python para criar Parquet."
fi

echo ""
echo "📊 Para testar com os dados criados:"
echo "   cargo run -- ../data_test/exemplo_ceps.csv    # Se suportar CSV"
echo "   cargo run -- ../data_test/exemplo.parquet     # Se criou Parquet"
echo "   cargo run -- --test                           # Testes built-in"