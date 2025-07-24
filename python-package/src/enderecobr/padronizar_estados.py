import re
from typing import Any, Dict, List, Optional, Sequence

import numpy as np

try:
    import pandas as pd
except ImportError:  # se pandas indisponível, seguimos com listas
    pd = None  # type: ignore


# =============================================================================
# Tabela de códigos de estados (equivalente a `codigos_estados` no R)
# =============================================================================
# Fonte: códigos IBGE de Unidade da Federação (2 dígitos)
# Todos em caixa alta e sem acento (para comparações pós-normalização).
_CODIGOS_ESTADOS_DATA = [
    # codigo, sigla, nome
    (11, "RO", "RONDONIA"),
    (12, "AC", "ACRE"),
    (13, "AM", "AMAZONAS"),
    (14, "RR", "RORAIMA"),
    (15, "PA", "PARA"),
    (16, "AP", "AMAPA"),
    (17, "TO", "TOCANTINS"),
    (21, "MA", "MARANHAO"),
    (22, "PI", "PIAUI"),
    (23, "CE", "CEARA"),
    (24, "RN", "RIO GRANDE DO NORTE"),
    (25, "PB", "PARAIBA"),
    (26, "PE", "PERNAMBUCO"),
    (27, "AL", "ALAGOAS"),
    (28, "SE", "SERGIPE"),
    (29, "BA", "BAHIA"),
    (31, "MG", "MINAS GERAIS"),
    (32, "ES", "ESPIRITO SANTO"),
    (33, "RJ", "RIO DE JANEIRO"),
    (35, "SP", "SAO PAULO"),
    (41, "PR", "PARANA"),
    (42, "SC", "SANTA CATARINA"),
    (43, "RS", "RIO GRANDE DO SUL"),
    (50, "MS", "MATO GROSSO DO SUL"),
    (51, "MT", "MATO GROSSO"),
    (52, "GO", "GOIAS"),
    (53, "DF", "DISTRITO FEDERAL"),
]

if pd is not None:
    CODIGOS_ESTADOS = pd.DataFrame(
        _CODIGOS_ESTADOS_DATA,
        columns=["codigo_estado", "abrev_estado", "nome_estado"],
    )
else:
    # dicionário simples se pandas não disponível
    CODIGOS_ESTADOS = {
        "codigo_estado": [r[0] for r in _CODIGOS_ESTADOS_DATA],
        "abrev_estado":  [r[1] for r in _CODIGOS_ESTADOS_DATA],
        "nome_estado":   [r[2] for r in _CODIGOS_ESTADOS_DATA],
    }


# =============================================================================
# Helpers compartilhados (compatíveis com os usados nas outras funções) ------
# =============================================================================

def _is_scalar(x: Any) -> bool:
    if isinstance(x, (str, bytes)):
        return True
    return not isinstance(x, (list, tuple, set, np.ndarray)) and (
        pd is None or not isinstance(x, (pd.Series, pd.Index, pd.DataFrame))  # type: ignore[attr-defined]
    )

def _is_pandas_series(x: Any) -> bool:
    return (pd is not None) and isinstance(x, pd.Series)

def _is_pandas_index(x: Any) -> bool:
    return (pd is not None) and isinstance(x, pd.Index)

def _is_numpy_array(x: Any) -> bool:
    return isinstance(x, np.ndarray)

def _coerce_to_python_list(x: Any) -> List[Any]:
    if _is_pandas_series(x) or _is_pandas_index(x):
        return list(x.tolist())
    if _is_numpy_array(x):
        return x.tolist()
    if isinstance(x, list):
        return list(x)
    if isinstance(x, tuple):
        return list(x)
    if isinstance(x, set):
        return list(x)
    return [x]

def _mask_na_only(vals: Sequence[Any]) -> np.ndarray:
    """
    Máscara *apenas* para NAs (None/NaN/pandas NA).
    **Importante:** strings vazias NÃO são marcadas como NA,
    replicando o comportamento do código R (que usou `is.na()`).
    """
    out = []
    for v in vals:
        if v is None:
            out.append(True); continue
        if isinstance(v, float) and np.isnan(v):
            out.append(True); continue
        if pd is not None and pd.isna(v):
            out.append(True); continue
        out.append(False)
    return np.array(out, dtype=bool)

def _strip_accents_ascii(s: str) -> str:
    try:
        import unidecode
        return unidecode.unidecode(s)
    except Exception:
        import unicodedata
        return "".join(
            c for c in unicodedata.normalize("NFD", s)
            if unicodedata.category(c) != "Mn"
        )

def _all_numeric(vals: Sequence[Any]) -> bool:
    for v in vals:
        if v is None:
            continue
        if isinstance(v, float) and np.isnan(v):
            continue
        if pd is not None and pd.isna(v):
            continue
        if isinstance(v, (int, np.integer, float, np.floating)):
            continue
        return False
    return True


# =============================================================================
# Construção dos dicionários de busca ----------------------------------------
# =============================================================================
def _build_lookup(formato: str):
    """
    Cria 3 dicionários:
      • por código (string sem zero à esquerda)
      • por sigla
      • por nome por extenso

    E retorna também a lista de valores alvo, de acordo com formato:
      - "por_extenso" → nome_estado
      - "sigla"       → abrev_estado
    """
    if pd is not None and isinstance(CODIGOS_ESTADOS, pd.DataFrame):
        df = CODIGOS_ESTADOS.copy()
    else:
        df = pd.DataFrame(CODIGOS_ESTADOS) if pd is not None else None
        if df is None:
            raise RuntimeError("CODIGOS_ESTADOS indisponível em formato reconhecido.")

    # normalizar colunas -> string sem acento (já está) / uppercase
    df["codigo_estado_str"] = df["codigo_estado"].astype(str)
    df["abrev_estado_str"] = df["abrev_estado"].astype(str).str.upper()
    df["nome_estado_str"]  = df["nome_estado"].astype(str).str.upper()

    # alvo
    if formato == "por_extenso":
        target = df["nome_estado_str"].tolist()
    else:
        target = df["abrev_estado_str"].tolist()

    by_cod   = dict(zip(df["codigo_estado_str"], target))
    by_abrev = dict(zip(df["abrev_estado_str"], target))
    by_nome  = dict(zip(df["nome_estado_str"], target))

    return by_cod, by_abrev, by_nome


# =============================================================================
# Função principal ------------------------------------------------------------
# =============================================================================

def padronizar_estados(estados: Any, formato: str = "por_extenso"):
    """
    Padronizar códigos / siglas / nomes de estados brasileiros.

    Parâmetros
    ----------
    estados : vetor-like (str ou num) ou escalar.
    formato : {"por_extenso", "sigla"}.
        Formato do resultado.

    Retorno
    -------
    Mesmo tipo do input quando possível (Series→Series etc.).
    """
    if formato not in ("por_extenso", "sigla"):
        raise ValueError('`formato` deve ser "por_extenso" ou "sigla".')

    orig = estados
    orig_is_scalar = isinstance(estados, str) or _is_scalar(estados)

    vals = _coerce_to_python_list(estados)

    # Mascara de NAs (apenas NA, *não* string vazia)
    na_mask = _mask_na_only(vals)

    # Dedup p/ eficiência
    def _key(v):
        if v is None:
            return ("__NA__",)
        if isinstance(v, float) and np.isnan(v):
            return ("__NA__",)
        if pd is not None and pd.isna(v):  # type: ignore[attr-defined]
            return ("__NA__",)
        return ("VAL", str(v))

    unique_map: Dict[Any, int] = {}
    uniq_vals: List[Any] = []
    for v in vals:
        k = _key(v)
        if k not in unique_map:
            unique_map[k] = len(uniq_vals)
            uniq_vals.append(v)

    numeric_input = _all_numeric(uniq_vals)

    # Pré-processamento deduplicado
    std_uniq: List[Optional[str]] = [None] * len(uniq_vals)
    for i, v in enumerate(uniq_vals):
        # NA → None
        if (
            v is None
            or (isinstance(v, float) and np.isnan(v))
            or (pd is not None and pd.isna(v))  # type: ignore[attr-defined]
        ):
            std_uniq[i] = None
            continue

        if numeric_input:
            # formato "d" (sem zeros à esquerda)
            try:
                iv = int(v)
            except Exception:
                iv = int(float(v))
            s = f"{iv:d}"
        else:
            # string path
            s = str(v)
            # str_squish
            s = " ".join(s.split()).strip()
            # upper
            s = s.upper()
            # Latin-ASCII
            s = _strip_accents_ascii(s)
            # remove zeros à esquerda *como palavra isolada* (ex.: "021" -> "21")
            s = re.sub(r"\b0+(\d+)\b", r"\1", s)

        std_uniq[i] = s

    # ---- lookup ----------------------------------------------------------
    by_cod, by_abrev, by_nome = _build_lookup(formato)

    # Mapear cada valor deduplicado -> estado padronizado (ou None se não achou)
    mapped: List[Optional[str]] = []
    for s in std_uniq:
        if s is None:
            mapped.append(None); continue

        # tenta por código
        out = by_cod.get(s)
        if out is None:
            # tenta por abrev (já uppercase)
            out = by_abrev.get(s)
        if out is None:
            # tenta por nome
            out = by_nome.get(s)
        if out is None:
            # fallback: devolve o próprio valor normalizado
            out = s
        mapped.append(out)

    # Mapear de volta à ordem original
    dedup_to_val = {i: mapped[i] for i in range(len(mapped))}
    std_vals: List[Optional[str]] = []
    for v in vals:
        std_vals.append(dedup_to_val[unique_map[_key(v)]])

    # Reesvaziar estados NA originais (índice_estado_vazio no R)
    for j, is_na in enumerate(na_mask):
        if is_na:
            std_vals[j] = None

    # Recriar tipo original
    if orig_is_scalar:
        return std_vals[0]
    if _is_pandas_series(orig):
        return pd.Series(std_vals, index=orig.index, name=getattr(orig, "name", None))
    if _is_pandas_index(orig):
        return pd.Index(std_vals, name=getattr(orig, "name", None))
    if _is_numpy_array(orig):
        return np.array(std_vals, dtype=object)
    if isinstance(orig, tuple):
        return tuple(std_vals)
    return std_vals
