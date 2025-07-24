# enderecobr

**Padronizador de endereços brasileiros em Python**

O **enderecobr** é um pacote Python para padronizar endereços postais brasileiros de forma simples e consistente.  
Ele oferece:

- Carregamento automático de códigos de estados e municípios.  
- Funções para padronizar bairros, CEPs, complementos, nomes de logradouros, tipos de logradouro, números e municípios.  
- Função agregadora para padronização completa de um DataFrame ou lista de endereços.

## Instalação

```bash
pip install enderecobr

from enderecobr import padronizar_enderecos, correspondencia_campos
import pandas as pd

# Exemplo com pandas DataFrame
df = pd.DataFrame({
    "logradouro": ["r ns sra da piedade"],
    "nroLogradouro": [20],
    "complemento": ["qd 20"],
    "cep": [25220020],
    "bairro": ["jd botanico"],
    "codmun_dom": [3304557],
    "uf_dom": ["rj"]
})

campos = {
    "logradouro": "logradouro",
    "numero": "nroLogradouro",
    "complemento": "complemento",
    "cep": "cep",
    "bairro": "bairro",
    "municipio": "codmun_dom",
    "estado": "uf_dom"
}

resultado = padronizar_enderecos(df, campos_do_endereco=campos)
print(resultado)

# Exemplo usando apenas numpy
import numpy as np
from enderecobr import padronizar_estados

ufs = np.array(["21", " MA", "ma", "Maranhão"], dtype=object)
print(padronizar_estados(ufs))
# Saída esperada: ['MARANHAO', 'MARANHAO', 'MARANHAO', 'MARANHAO']
