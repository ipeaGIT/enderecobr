# src/enderecobr/codigos.py

"""
Códigos e nomes dos estados e municípios brasileiros (2022)

Fonte:
  https://www.ibge.gov.br/explica/codigos-dos-municipios.php

Formato:
- Estados:
    - codigo_estado: código do estado (str)
    - nome_estado: nome do estado (ASCII maiúsculo)
    - abrev_estado: abreviação do nome do estado (str)

- Municípios:
    - codigo_estado: código do estado (str)
    - codigo_muni: código do município (str)
    - nome_muni: nome do município (ASCII maiúsculo)
"""

import pandas as pd
import importlib.resources as resources

# Estados
with resources.as_file(resources.files("enderecobr") / "data" / "codigos_brasil.xls") as xls_path:
    codigos_estados = pd.read_excel(
        xls_path,
        sheet_name="estados",
        dtype=str,
        engine="openpyxl"
    )

# Municípios
with resources.as_file(resources.files("enderecobr") / "data" / "codigos_brasil.xls") as xls_path:
    codigos_municipios = pd.read_excel(
        xls_path,
        sheet_name="municipios",
        dtype=str,
        engine="openpyxl"
    )


def carregar_codigos_estados():
    return codigos_estados.copy()


def carregar_codigos_municipios():
    return codigos_municipios.copy()
