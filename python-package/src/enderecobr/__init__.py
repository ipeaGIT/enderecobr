"""
enderecobr — Padronizador de endereços brasileiros em Python.

Este pacote fornece funções para carregar mapeamentos de códigos de estados e municípios,
assim como diversas funções para padronizar componentes de endereços (bairros, CEPs,
complementos, estados, logradouros, municípios, números e tipos de logradouro) e uma função
agregadora para padronização completa de endereços.
"""

# Função principal do pacote
from .padronizar_enderecos import padronizar_enderecos

from .version import __version__
from .codigos import carregar_codigos_estados, carregar_codigos_municipios
from .padronizar_bairros import padronizar_bairros
from .padronizar_ceps import padronizar_ceps
from .padronizar_complementos import padronizar_complementos
from .padronizar_estados import padronizar_estados
from .padronizar_logradouros import padronizar_logradouros
from .padronizar_logradouros_completos import padronizar_logradouros_completos
from .padronizar_municipios import padronizar_municipios
from .padronizar_numeros import padronizar_numeros
from .padronizar_tipos_de_logradouro import padronizar_tipos_de_logradouro
#from .padronizar_enderecos import padronizar_enderecos

__all__ = [
    "__version__",
    "carregar_codigos_estados",
    "carregar_codigos_municipios",
    "padronizar_bairros",
    "padronizar_ceps",
    "padronizar_complementos",
    "padronizar_estados",
    "padronizar_logradouros",
    "padronizar_logradouros_completos",
    "padronizar_municipios",
    "padronizar_numeros",
    "padronizar_tipos_de_logradouro",
    "padronizar_enderecos",
]
