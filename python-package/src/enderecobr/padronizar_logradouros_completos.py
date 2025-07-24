import warnings
from typing import Dict, Any, List, Optional

import pandas as pd
import numpy as np


# ---------------------------------------------------------------------------
# Dependências: presume-se que estas funções já estejam definidas/importadas
# no seu módulo (traduções que fizemos anteriormente ou suas versões).
# Substitua os "stubs" abaixo pelas implementações reais se ainda não importou.
# ---------------------------------------------------------------------------

def padronizar_logradouros(x):        # stub -> substitua
    return x if isinstance(x, pd.Series) else list(x)

def padronizar_numeros(x, formato="character"):  # stub -> substitua
    return x if isinstance(x, pd.Series) else list(x)

def padronizar_tipos_de_logradouro(x):  # stub -> substitua
    return x if isinstance(x, pd.Series) else list(x)


# ---------------------------------------------------------------------------
# Erros customizados
# ---------------------------------------------------------------------------

class LogradouroCompletoError(ValueError):
    """Erro em padronizar_logradouros_completos()."""


# ---------------------------------------------------------------------------
# Checks equivalentes aos do R
# ---------------------------------------------------------------------------

def _checa_campos_do_logradouro(
    campos_do_logradouro: Dict[str, str],
    df: pd.DataFrame,
) -> None:
    """
    Verifica:
      • dict str->str
      • nomes únicos e dentro do conjunto permitido
      • colunas existem no DataFrame
    """
    if not isinstance(campos_do_logradouro, dict):
        raise LogradouroCompletoError("`campos_do_logradouro` deve ser dict {campo: coluna_df}.")
    if not all(isinstance(k, str) for k in campos_do_logradouro):
        raise LogradouroCompletoError("Todos os nomes em `campos_do_logradouro` devem ser strings.")
    if not all(isinstance(v, str) for v in campos_do_logradouro.values()):
        raise LogradouroCompletoError("Todos os valores em `campos_do_logradouro` devem ser nomes de colunas (str).")

    permitidos = {"tipo_de_logradouro", "nome_do_logradouro", "numero"}
    nomes = list(campos_do_logradouro.keys())

    dup = {n for n in nomes if nomes.count(n) > 1}
    if dup:
        raise LogradouroCompletoError(f"Nomes duplicados em campos_do_logradouro: {dup}.")

    nao_permit = set(nomes) - permitidos
    if nao_permit:
        raise LogradouroCompletoError(f"Campos não reconhecidos: {nao_permit}.")

    faltam = [v for v in campos_do_logradouro.values() if v not in df.columns]
    if faltam:
        raise LogradouroCompletoError(f"Colunas ausentes no DataFrame: {faltam}.")


def _checa_se_nome_ausente(campos_do_logradouro: Dict[str, str]) -> None:
    if "nome_do_logradouro" not in campos_do_logradouro:
        _erro_nome_do_logradouro_ausente()


def _erro_nome_do_logradouro_ausente() -> None:
    raise LogradouroCompletoError(
        "Não é possível padronizar logradouro completo sem o nome do logradouro. "
        "Informe `nome_do_logradouro` em `campos_do_logradouro`."
    )


# ---------------------------------------------------------------------------
# Lista de tipos possíveis (exportada no R; útil em padronizar_tipos_de_logradouro)
# ---------------------------------------------------------------------------
TIPOS_DE_LOGRADOURO_POSSIVEIS = [
    "AREA", "ACESSO", "ACAMPAMENTO", "ACESSO LOCAL", "ADRO", "AREA ESPECIAL",
    "AEROPORTO", "ALAMEDA", "AVENIDA MARGINAL DIREITA", "AVENIDA MARGINAL ESQUERDA",
    "ANEL VIARIO", "ANTIGA ESTRADA", "ARTERIA", "ALTO", "ATALHO", "AREA VERDE",
    "AVENIDA", "AVENIDA CONTORNO", "AVENIDA MARGINAL", "AVENIDA VELHA", "BALNEARIO",
    "BECO", "BURACO", "BELVEDERE", "BLOCO", "BALAO", "BLOCOS", "BULEVAR", "BOSQUE",
    "BOULEVARD", "BAIXA", "CAIS", "CALCADA", "CAMINHO", "CANAL", "CHACARA",
    "CHAPADAO", "CICLOVIA", "CIRCULAR", "CONJUNTO", "CONJUNTO MUTIRAO",
    "COMPLEXO VIARIO", "COLONIA", "COMUNIDADE", "CONDOMINIO", "CORREDOR", "CAMPO",
    "CORREGO", "CONTORNO", "DESCIDA", "DESVIO", "DISTRITO", "ENTRE BLOCO",
    "ESTRADA INTERMUNICIPAL", "ENSEADA", "ENTRADA PARTICULAR", "ENTRE QUADRA",
    "ESCADA", "ESCADARIA", "ESTRADA ESTADUAL", "ESTRADA VICINAL",
    "ESTRADA DE LIGACAO", "ESTRADA MUNICIPAL", "ESPLANADA", "ESTRADA DE SERVIDAO",
    "ESTRADA", "ESTRADA VELHA", "ESTRADA ANTIGA", "ESTACAO", "ESTADIO", "ESTANCIA",
    "ESTRADA PARTICULAR", "ESTACIONAMENTO", "EVANGELICA", "ELEVADA", "EIXO INDUSTRIAL",
    "FAVELA", "FAZENDA", "FERROVIA", "FONTE", "FEIRA", "FORTE", "GALERIA", "GRANJA",
    "NUCLEO HABITACIONAL", "ILHA", "INDETERMINADO", "ILHOTA", "JARDIM", "JARDINETE",
    "LADEIRA", "LAGOA", "LAGO", "LOTEAMENTO", "LARGO", "LOTE", "MERCADO", "MARINA",
    "MODULO", "PROJECAO", "MORRO", "MONTE", "NUCLEO", "NUCLEO RURAL", "OUTEIRO",
    "PARALELA", "PASSEIO", "PATIO", "PRACA", "PRACA DE ESPORTES", "PARADA",
    "PARADOURO", "PONTA", "PRAIA", "PROLONGAMENTO", "PARQUE MUNICIPAL", "PARQUE",
    "PARQUE RESIDENCIAL", "PARALELA", "PASSAGEM", "PASSAGEM DE PEDESTRE",
    "PASSAGEM SUBTERRANEA", "PONTE", "PORTO", "QUADRA", "QUINTA", "QUINTAS", "RUA",
    "RUA INTEGRACAO", "RUA DE LIGACAO", "RUA PARTICULAR", "RUA VELHA", "RAMAL",
    "RECREIO", "RECANTO", "RETIRO", "RESIDENCIAL", "RETA", "RUELA", "RAMPA",
    "RODO ANEL", "RODOVIA", "ROTULA", "RUA DE PEDESTRE", "MARGEM", "RETORNO",
    "SEGUNDA AVENIDA", "SITIO", "SERVIDAO", "SETOR", "SUBIDA", "TRINCHEIRA",
    "TERMINAL", "TRECHO", "TREVO", "TUNEL", "TRAVESSA", "TRAVESSA PARTICULAR",
    "TRAVESSA VELHA", "UNIDADE", "VIA", "VIA COLETORA", "VIA LOCAL", "VIA DE ACESSO",
    "VALA", "VIA COSTEIRA", "VIADUTO", "VIA EXPRESSA", "VEREDA", "VIA ELEVADO",
    "VILA", "VIELA", "VALE", "VIA LITORANEA", "VIA DE PEDESTRE", "VARIANTE",
    "ZIGUE-ZAGUE",
]


# ---------------------------------------------------------------------------
# Etapas internas (equivalentes às int_* do R) ------------------------------
# ---------------------------------------------------------------------------

def _int_padronizar_nome(df: pd.DataFrame, campos: Dict[str, str]) -> None:
    """
    Cria/atualiza coluna temporária `.tmp_log_padrao` com nome do logradouro
    padronizado (vetor).
    """
    col_nome = campos["nome_do_logradouro"]
    df["_tmp_log_padrao"] = padronizar_logradouros(df[col_nome])


def _int_padronizar_numero(df: pd.DataFrame, campos: Dict[str, str]) -> None:
    """
    Adiciona número padronizado e concatena a `_tmp_log_padrao`.
    """
    col_num = campos["numero"]
    df["_tmp_num_padrao"] = padronizar_numeros(df[col_num])

    # fcase do R:
    # if log NA -> número
    # else if número NA -> log
    # else paste(log, número)
    log = df["_tmp_log_padrao"]
    num = df["_tmp_num_padrao"]

    cond1 = log.isna()
    cond2 = num.isna()
    both = ~cond1 & ~cond2

    out = log.copy()
    out[cond1] = num[cond1]
    out[cond2 & ~cond1] = log[cond2 & ~cond1]
    out[both] = (log[both].astype(str) + " " + num[both].astype(str))

    df["_tmp_log_padrao"] = out
    df.drop(columns=["_tmp_num_padrao"], inplace=True)


def _int_padronizar_tipo(
    df: pd.DataFrame,
    campos: Dict[str, str],
    checar_tipos: bool,
) -> None:
    """
    Padroniza tipo e (opcionalmente) remove duplicidade com 1ª palavra do nome,
    então concatena ao logradouro.
    """
    col_tipo = campos["tipo_de_logradouro"]
    df["_tmp_tipo_padrao"] = padronizar_tipos_de_logradouro(df[col_tipo])

    if checar_tipos:
        # 1ª palavra do logradouro (já padronizado, com número possivelmente junto)
        prim = df["_tmp_log_padrao"].str.split(expand=False).str[0]
        same = prim == df["_tmp_tipo_padrao"]
        df.loc[same, "_tmp_tipo_padrao"] = pd.NA

    # fcase join
    tip = df["_tmp_tipo_padrao"]
    log = df["_tmp_log_padrao"]

    cond1 = tip.isna()
    cond2 = log.isna()
    both = ~cond1 & ~cond2

    out = log.copy()
    out[cond1] = log[cond1]           # nada a acrescentar
    out[cond2 & ~cond1] = tip[cond2 & ~cond1]
    out[both] = (tip[both].astype(str) + " " + log[both].astype(str))

    df["_tmp_log_padrao"] = out
    df.drop(columns=["_tmp_tipo_padrao"], inplace=True)


# ---------------------------------------------------------------------------
# Função principal -----------------------------------------------------------
# ---------------------------------------------------------------------------

def padronizar_logradouros_completos(
    enderecos: pd.DataFrame,
    campos_do_logradouro: Dict[str, str],
    *,
    manter_cols_extras: bool = True,
    checar_tipos: bool = False,
) -> pd.DataFrame:
    """
    Padroniza logradouro completo (tipo + nome + número) a partir de campos
    separados em `enderecos`.

    Parâmetros
    ----------
    enderecos : DataFrame
    campos_do_logradouro : dict
        { "nome_do_logradouro": <col>, "numero": <col>, "tipo_de_logradouro": <col>, ... }
        Apenas `nome_do_logradouro` é obrigatório; os outros são opcionais.
    manter_cols_extras : bool
        Se True (padrão), retorna DF original + coluna `logradouro_completo_padr`
        (sem remover nada).
        Se False, remove as colunas **não** listadas em `campos_do_logradouro`
        (imitando o código R; note que a docstring do R descreve comportamento
        ligeiramente diferente, mas aqui seguimos o código).
    checar_tipos : bool
        Se True, não repete o tipo quando ele já é a 1ª palavra do nome.

    Retorno
    -------
    pandas.DataFrame
    """
    if not isinstance(enderecos, pd.DataFrame):
        raise LogradouroCompletoError("`enderecos` precisa ser um pandas.DataFrame.")

    _checa_campos_do_logradouro(campos_do_logradouro, enderecos)
    _checa_se_nome_ausente(campos_do_logradouro)

    df = enderecos.copy()

    # fluxo: nome -> número -> tipo
    _int_padronizar_nome(df, campos_do_logradouro)

    if "numero" in campos_do_logradouro:
        _int_padronizar_numero(df, campos_do_logradouro)

    if "tipo_de_logradouro" in campos_do_logradouro:
        _int_padronizar_tipo(df, campos_do_logradouro, checar_tipos=checar_tipos)

    # renomeia coluna temporária
    df.rename(columns={"_tmp_log_padrao": "logradouro_completo_padr"}, inplace=True)

    if not manter_cols_extras:
        # Remove colunas que NÃO fazem parte do logradouro (código R faz isso)
        extras = [c for c in enderecos.columns if c not in campos_do_logradouro.values()]
        df = df.drop(columns=extras)

    return df


# ---------------------------------------------------------------------------
# Wrapper: retorna apenas a Série padronizada (útil dentro de padronizar_enderecos)
# ---------------------------------------------------------------------------

def _padronizar_logradouros_completos_vector(
    *,
    tipo=None,
    nome_do_logradouro=None,
    numero=None,
    checar_tipos=False,
) -> pd.Series:
    """
    Conveniência: aceita vetores/Series individuais, monta DF temporário,
    chama `padronizar_logradouros_completos()` e retorna a Série resultante.
    """
    data = {}
    campos = {}

    if nome_do_logradouro is None:
        _erro_nome_do_logradouro_ausente()

    data["__nome"] = nome_do_logradouro
    campos["nome_do_logradouro"] = "__nome"

    if numero is not None:
        data["__num"] = numero
        campos["numero"] = "__num"

    if tipo is not None:
        data["__tipo"] = tipo
        campos["tipo_de_logradouro"] = "__tipo"

    tmp_df = pd.DataFrame(data)
    out_df = padronizar_logradouros_completos(
        tmp_df,
        campos_do_logradouro=campos,
        manter_cols_extras=True,  # mantemos tudo; extração abaixo
        checar_tipos=checar_tipos,
    )
    return out_df["logradouro_completo_padr"]
