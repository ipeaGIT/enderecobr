
# python -m venv .venv
# "C:\Users\pedro\AppData\Local\R\cache\R\reticulate\uv\cache\archive-v0\tHzS6zc4tjxgOU7XJNM-m\Scripts\python.exe" -m pip install -e .


import pandas as pd
import enderecobr


# Simulando o dataframe de entrada
enderecos = pd.DataFrame({
    "logradouro": ["r ns sra da piedade"],
    "nroLogradouro": [20],
    "complemento": ["qd 20"],
    "cep": [25220020],
    "bairro": ["jd botanico"],
    "codmun_dom": [3304557],
    "uf_dom": ["rj"]
})

# Definindo correspondência de campos (equivalente ao correspondencia_campos)
campos = {
    "logradouro": "logradouro",
    "numero": "nroLogradouro",
    "complemento": "complemento",
    "cep": "cep",
    "bairro": "bairro",
    "municipio": "codmun_dom",
    "estado": "uf_dom"
}

# Aplicando a função principal de padronização
res = padronizar_enderecos(enderecos, campos_do_endereco=campos)

# Exibindo o resultado
print(res)

# logradouro_padr ficou diferente: r ns sra da piedade em vez de RUA NOSSA SENHORA DA PIEDADE
# complemento_padr ficou diferente: QD 20 em vez de QUADRA 20


## Testes individuais
estados = ["21", " 21", "MA", " MA ", "ma", "MARANHÃO"]
print(padronizar_estados(estados))

municipios = [
    "3304557", "003304557", " 3304557 ", "RIO DE JANEIRO", "rio de janeiro",
    "SÃO PAULO"
]
print(padronizar_municipios(municipios))

bairros = [
    "PRQ IND",
    "NSA SEN DE FATIMA",
    "ILHA DO GOV",
    "VL OLIMPICA",
    "NUC RES"
]
print(padronizar_bairros(bairros))

ceps = ["22290-140", "22.290-140", "22290 140", "22290140"]
print(padronizar_ceps(ceps))

logradouros = [
    "r. gen.. glicério, 137",
    "cond pres j. k., qd 05 lt 02 1",
    "av d pedro I, 020"
]
print(padronizar_logradouros(logradouros))

numeros = ["0210", "001", "1", "", "S N", "S/N", "SN", "0180  0181"]
print(padronizar_numeros(numeros))


## Verbosidade (controle)
# quieto, por padrão
campos = {"nome_do_logradouro": "logradouro", "numero": "nroLogradouro"}
res = padronizar_logradouros_completos(enderecos, campos)

# modo verboso
import contextlib
with contextlib.redirect_stdout(None):  # substituir com opção se houver controle via config
    import sys
    sys.modules['config'].enderecobr_verbose = "verbose"  # se existir um config.py com isso
res = padronizar_logradouros_completos(enderecos, campos)
