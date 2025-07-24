#!/usr/bin/env python3
"""
data/extracao_tabelas_de_codigos.py

– Lê o arquivo .xls já baixado em data (range A7:M5577)
– Gera:
     • codigos_municipios: ['codigo_estado','codigo_muni','nome_muni']
     • codigos_estados:    ['codigo_estado','nome_estado','abrev_estado']
– Salva ambos em um único .xls com duas abas: 'estados' e 'municipios'
"""

import os
import pandas as pd
from unidecode import unidecode
from geobr import read_state
import xlwt



def extrair_codigos_locais(
    arquivo_xls: str = "src/data/RELATORIO_DTB_BRASIL_MUNICIPIO.xls"
) -> tuple[pd.DataFrame, pd.DataFrame]:
    # 1. Ler o XLS a partir da linha 7 (header=6)
    df = pd.read_excel(
        arquivo_xls
    )

    # 2. Selecionar e renomear colunas
    codigos = (
        df
        .rename(columns={
            "UF": "codigo_estado",
            "Nome_UF": "nome_estado",
            "Código Município Completo": "codigo_muni",
            "Nome_Município": "nome_muni"
        })
        [["codigo_estado", "nome_estado", "codigo_muni", "nome_muni"]]
    )

    # 3. Normalizar texto para UPPER ASCII
    codigos["nome_estado"] = (
        codigos["nome_estado"]
        .astype(str)
        .str.upper()
        .map(unidecode)
    )
    codigos["nome_muni"] = (
        codigos["nome_muni"]
        .astype(str)
        .str.upper()
        .map(unidecode)
    )

    # 4. Gerar codigos_municipios (drop nome_estado)
    codigos_municipios = codigos.drop(columns=["nome_estado"]).copy()

    # 5. Gerar codigos_estados (únicos)
    codigos_estados = (
        codigos[["codigo_estado", "nome_estado"]]
        .drop_duplicates()
        .copy()
    )

    # 6. Obter abreviações de estados via geobr (ano 2010)
    abrev_estados = read_state(year=2010)
    abrev_estados = (
        abrev_estados.drop(columns="geometry")
             [["code_state", "abbrev_state"]]
    )
    codigos_estados["codigo_estado"] = codigos_estados["codigo_estado"].astype(str)
    abrev_estados["code_state"]      = abrev_estados["code_state"].astype(str)
    
    codigos_estados = codigos_estados.merge(
        abrev_estados,
        how="left",
        left_on="codigo_estado",
        right_on="code_state"
    ).drop(columns="code_state").rename(columns={"abbrev_state": "abrev_estado"})

    return codigos_estados, codigos_municipios


def main():
    # Executa extração usando o arquivo local
    estados, municipios = extrair_codigos_locais()



    # Salva em um único arquivo .xls com duas planilhas
    arquivo_saida = "src/data/codigos_brasil.xls"
    with pd.ExcelWriter(arquivo_saida, engine="openpyxl") as writer:
        estados.to_excel(writer, sheet_name="estados", index=False)
        municipios.to_excel(writer, sheet_name="municipios", index=False)

    print(f"Gerado: {arquivo_saida} com abas 'estados' e 'municipios'")


if __name__ == "__main__":
    main()
