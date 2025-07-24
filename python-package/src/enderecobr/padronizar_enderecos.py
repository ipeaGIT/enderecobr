from .padronizar_logradouros import padronizar_logradouros
from .padronizar_tipos_de_logradouro import padronizar_tipos_de_logradouro
from .padronizar_logradouros_completos import padronizar_logradouros_completos
from .padronizar_numeros import padronizar_numeros
from .padronizar_complementos import padronizar_complementos
from .padronizar_bairros import padronizar_bairros
from .padronizar_municipios import padronizar_municipios
from .padronizar_estados import padronizar_estados
from .padronizar_ceps import padronizar_ceps

import warnings
from typing import Dict, Any, List, Callable, Optional

import pandas as pd



# --------------------------------------------------------------------------- #
# Utilidades / validações                                                     #
# --------------------------------------------------------------------------- #

class EnderecoPadronizacaoError(ValueError):
    """Erro de validação de argumentos na padronização de endereços."""


def _check_choice(arg: str, nome: str, choices: List[str]) -> None:
    if arg not in choices:
        raise EnderecoPadronizacaoError(
            f'Valor inválido para "{nome}": {arg!r}. Opções válidas: {choices}.'
        )


def _checa_campos_do_endereco(
    campos: Dict[str, str],
    df: pd.DataFrame,
) -> None:
    """
    • Confere tipos; nomes únicos; campos permitidos; se colunas existem no DF.
    • Avisa (warning) se já existirem colunas "<campo>_padr" que serão sobrescritas.
    """
    if not isinstance(campos, dict) or not all(isinstance(k, str) for k in campos):
        raise EnderecoPadronizacaoError(
            "`campos_do_endereco` deve ser um dicionário str -> str."
        )

    campos_permitidos = {
        "tipo_de_logradouro",
        "logradouro",
        "numero",
        "complemento",
        "cep",
        "bairro",
        "municipio",
        "estado",
    }
    nomes = list(campos.keys())

    duplicados = {n for n in nomes if nomes.count(n) > 1}
    if duplicados:
        raise EnderecoPadronizacaoError(f"Nomes duplicados em campos_do_endereco: {duplicados}")

    não_permitidos = set(nomes) - campos_permitidos
    if não_permitidos:
        raise EnderecoPadronizacaoError(f"Campos não reconhecidos: {não_permitidos}")

    faltando = [v for v in campos.values() if v not in df.columns]
    if faltando:
        raise EnderecoPadronizacaoError(f"Colunas ausentes no dataframe: {faltando}")

    # aviso sobre sobrescrever "<campo>_padr"
    ja_existe = [f"{c}_padr" for c in nomes if f"{c}_padr" in df.columns]
    if ja_existe:
        warnings.warn(
            f"As colunas {', '.join(ja_existe)} já existem no dataframe e serão sobrescritas.",
            stacklevel=2,
        )


# --------------------------------------------------------------------------- #
# Auxiliar para combinar tipo/nome/número em um único logradouro completo     #
# --------------------------------------------------------------------------- #

def _int_padronizar_com_log_completo(
    df: pd.DataFrame,
    campos: Dict[str, str],
    campos_do_logradouro: List[str],
    checar_tipos: bool,
):
    """
    • Seleciona colunas listadas (se existirem) → chama padronizar_logradouros_completos().
    • Adiciona coluna 'logradouro_completo_padr' ao dataframe.
    """
    presentes = {c: col for c, col in campos.items() if c in campos_do_logradouro}
    if not presentes:
        return df  # nada a fazer

    # Renomear conforme esperado por padronizar_logradouros_completos
    # (tipo_de_logradouro → tipo, logradouro → nome_do_logradouro, numero → numero etc.)
    renomeia = {
        "tipo_de_logradouro": "tipo",
        "logradouro": "nome_do_logradouro",
        "numero": "numero",
    }
    args = {renomeia[k]: df[col] for k, col in presentes.items()}

    df["logradouro_completo_padr"] = padronizar_logradouros_completos(
        **args, checar_tipos=checar_tipos
    )
    return df


# --------------------------------------------------------------------------- #
# Tabela de relacionamento campo  ↔  função padronizadora                     #
# --------------------------------------------------------------------------- #

_RELACAO_CAMPOS: List[Dict[str, Any]] = [
    dict(nome_campo="tipo_de_logradouro", funcao="padronizar_tipos_de_logradouro"),
    dict(nome_campo="logradouro",         funcao="padronizar_logradouros"),
    dict(nome_campo="numero",             funcao="padronizar_numeros"),
    dict(nome_campo="complemento",        funcao="padronizar_complementos"),
    dict(nome_campo="cep",                funcao="padronizar_ceps"),
    dict(nome_campo="bairro",             funcao="padronizar_bairros"),
    dict(nome_campo="municipio",          funcao="padronizar_municipios"),
    dict(nome_campo="estado",             funcao="padronizar_estados"),
]


# --------------------------------------------------------------------------- #
# Função principal                                                            #
# --------------------------------------------------------------------------- #

def padronizar_enderecos(
    enderecos: pd.DataFrame,
    campos_do_endereco: Dict[str, str],
    *,
    formato_estados: str = "por_extenso",
    formato_numeros: str = "character",
    manter_cols_extras: bool = True,
    combinar_logradouro: bool = False,
    checar_tipos: bool = False,
) -> pd.DataFrame:
    """
    Padroniza simultaneamente múltiplos campos de endereço contidos em um DataFrame.

    Parâmetros
    ----------
    enderecos : pandas.DataFrame
        Tabela original.
    campos_do_endereco : dict
        Mapeamento 'campo lógico' → 'nome da coluna no DataFrame'.
        Exemplo:
            {
              "logradouro": "rua",
              "numero": "nro",
              "cep": "zip",
              "estado": "uf",
              ...
            }
    formato_estados : {"por_extenso", "sigla"}
        Retorno de estados.
    formato_numeros : {"character", "integer"}
        Retorno de números.
    manter_cols_extras : bool
        Se colunas não listadas devem permanecer no resultado.
    combinar_logradouro : bool
        Se deve combinar tipo + nome + número em `logradouro_completo_padr`.
    checar_tipos : bool
        (Só com `combinar_logradouro=True`). Verifica duplicidades
        tipo/nome (ex.: "RUA" + "RUA BOTAFOGO").

    Retorno
    -------
    pandas.DataFrame – cópia do input com novas colunas *_padr (padronizadas).
    """
    if not isinstance(enderecos, pd.DataFrame):
        raise EnderecoPadronizacaoError("`enderecos` precisa ser um pandas.DataFrame.")

    _check_choice(formato_estados, "formato_estados", ["por_extenso", "sigla"])
    _check_choice(formato_numeros, "formato_numeros", ["character", "integer"])
    _checa_campos_do_endereco(campos_do_endereco, enderecos)

    df = enderecos.copy()

    # Combina tipo/nome/número em logradouro completo, se solicitado
    if combinar_logradouro:
        df = _int_padronizar_com_log_completo(
            df,
            campos_do_endereco,
            campos_do_logradouro=["tipo_de_logradouro", "logradouro", "numero"],
            checar_tipos=checar_tipos,
        )

    # Mapeia nome_campo → função real + kwargs extras
    _dispatch: Dict[str, Callable] = {
        "padronizar_tipos_de_logradouro": padronizar_tipos_de_logradouro,
        "padronizar_logradouros":         padronizar_logradouros,
        "padronizar_numeros":             padronizar_numeros,
        "padronizar_complementos":        padronizar_complementos,
        "padronizar_ceps":                padronizar_ceps,
        "padronizar_bairros":             padronizar_bairros,
        "padronizar_municipios":          padronizar_municipios,
        "padronizar_estados":             padronizar_estados,
    }

    for item in _RELACAO_CAMPOS:
        campo = item["nome_campo"]
        if campo not in campos_do_endereco:
            continue  # usuário não pediu esse campo

        col_original = campos_do_endereco[campo]
        col_padron   = f"{campo}_padr"
        func         = _dispatch[item["funcao"]]

        # kwargs extras
        extras: Dict[str, Any] = {}
        if campo == "estado":
            extras["formato"] = formato_estados
        if campo == "numero":
            extras["formato"] = formato_numeros

        df[col_padron] = func(df[col_original], **extras)  # type: ignore[arg-type]

    # --------  lidar com colunas extras  -----------------------------------
    if not manter_cols_extras:
        cols_padronizadas = [f"{c}_padr" for c in campos_do_endereco]
        if combinar_logradouro:
            cols_padronizadas.append("logradouro_completo_padr")
        df = df[cols_padronizadas]
    else:
        # põe extras primeiro (estilo data.table::setcolorder)
        extras = [c for c in enderecos.columns if c not in campos_do_endereco.values()]
        df = df[extras + [c for c in df.columns if c not in extras]]

    return df
