import re
import warnings
from typing import Any, List, Optional, Sequence

import numpy as np

try:
    import pandas as pd
except ImportError:  # caso não tenha pandas
    pd = None  # type: ignore


# =============================================================================
# Helpers básicos (reuse dos que já enviei; mantenha apenas uma versão no seu projeto)
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
    Mascara apenas NA/None/NaN/pandas NA (não marca "" como NA).
    Usada para "reesvaziar" ao final quando input tinha NA.
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
    """
    True se todos os valores não-missing forem numéricos (int/float).
    (R testava `is.numeric(numeros)`; aqui inferimos.)
    """
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
# Warning auxiliar (tradução do warning_conversao_invalida)
# =============================================================================

def _warning_conversao_invalida():
    warnings.warn(
        "Alguns números não puderam ser convertidos para integer; NAs introduzidos no resultado.",
        stacklevel=2,
    )


# =============================================================================
# Regex de limpeza (ordem importa)
# =============================================================================
# Nota: (?<!\.) lookbehind de largura fixa (1 char) é suportado em Python.
_NUM_PATTERNS: List[tuple[str, str]] = [
    # remover zeros à esquerda (quando não precedidos por ponto decimal)
    (r"(?<!\.)\b0+(\d+)\b", r"\1"),
    # remover separador de milhar: 1.234 -> 1234
    (r"(\d+)\.(\d{3})", r"\1\2"),
    # variações de S/N
    (r"S\.?( |\/)?N(?:O|º)?\.?", "S/N"),
    (r"SEM NUMERO", "S/N"),
    (r"^(?:X|0|-)+$", "S/N"),
]


# =============================================================================
# Função principal
# =============================================================================

def padronizar_numeros(numeros: Any, formato: str = "character"):
    """
    Padroniza números de logradouro.

    Parâmetros
    ----------
    numeros : vetor-like (str ou num) ou escalar.
    formato : {"character","integer"}.

    Retorno
    -------
    Mesmo tipo do input quando possível.
    """
    if formato not in ("character", "integer"):
        raise ValueError('`formato` deve ser "character" ou "integer".')

    orig = numeros
    orig_is_scalar = isinstance(numeros, str) or _is_scalar(numeros)

    vals = _coerce_to_python_list(numeros)
    na_mask = _mask_na_only(vals)

    numeric_input = _all_numeric(vals)

    # ------------------------------------------------------------------ #
    # Caminho: input numérico                                            #
    # ------------------------------------------------------------------ #
    if numeric_input:
        # Converte para int (quebrando floats com decimais -> int truncado como no R?).
        # O R aceita numeric; formatC(format="d") faz trunc/floor. Aqui usamos int().
        coerced: List[Optional[int]] = []
        for v in vals:
            if (
                v is None
                or (isinstance(v, float) and np.isnan(v))
                or (pd is not None and pd.isna(v))  # type: ignore[attr-defined]
            ):
                coerced.append(None)
                continue
            try:
                iv = int(v)
            except Exception:
                # se não converte, marca NA
                iv = None
            coerced.append(iv)

        # 0 -> NA
        coerced = [None if (c == 0 or c is None) else c for c in coerced]

        if formato == "integer":
            # Retorna inteiros (NA preservado)
            out_vals: List[Optional[int]] = coerced
            # reconstruir tipo original
            if orig_is_scalar:
                return out_vals[0]
            if _is_pandas_series(orig):
                return pd.Series(out_vals, index=orig.index, name=getattr(orig, "name", None))
            if _is_pandas_index(orig):
                return pd.Index(out_vals, name=getattr(orig, "name", None))
            if _is_numpy_array(orig):
                return np.array(out_vals, dtype=object)
            if isinstance(orig, tuple):
                return tuple(out_vals)
            return out_vals

        # formato == "character"
        out_vals_str: List[str] = []
        for c in coerced:
            if c is None:
                out_vals_str.append("S/N")
            else:
                out_vals_str.append(f"{c:d}")

        # reconstruir
        if orig_is_scalar:
            return out_vals_str[0]
        if _is_pandas_series(orig):
            return pd.Series(out_vals_str, index=orig.index, name=getattr(orig, "name", None))
        if _is_pandas_index(orig):
            return pd.Index(out_vals_str, name=getattr(orig, "name", None))
        if _is_numpy_array(orig):
            return np.array(out_vals_str, dtype=object)
        if isinstance(orig, tuple):
            return tuple(out_vals_str)
        return out_vals_str

    # ------------------------------------------------------------------ #
    # Caminho: input textual                                             #
    # ------------------------------------------------------------------ #
    std_vals: List[Optional[str]] = []
    for v in vals:
        if (
            v is None
            or (isinstance(v, float) and np.isnan(v))
            or (pd is not None and pd.isna(v))  # type: ignore[attr-defined]
        ):
            std_vals.append(None)
            continue

        s = str(v)

        # squish
        s = re.sub(r"\s+", " ", s).strip()
        # upper
        s = s.upper()
        # Latin-ASCII
        s = _strip_accents_ascii(s)

        # cascata regex
        for pat, repl in _NUM_PATTERNS:
            s = re.sub(pat, repl, s)

        std_vals.append(s)

    # Pós: formato
    if formato == "character":
        out_vals: List[str] = []
        for s in std_vals:
            if s is None or s == "":
                out_vals.append("S/N")
            else:
                out_vals.append(s)
        # reconstruir tipo original
        if orig_is_scalar:
            return out_vals[0]
        if _is_pandas_series(orig):
            return pd.Series(out_vals, index=orig.index, name=getattr(orig, "name", None))
        if _is_pandas_index(orig):
            return pd.Index(out_vals, name=getattr(orig, "name", None))
        if _is_numpy_array(orig):
            return np.array(out_vals, dtype=object)
        if isinstance(orig, tuple):
            return tuple(out_vals)
        return out_vals

    # formato == "integer"
    # 1º: trocar "S/N" (qualquer capitalização já foi upper) por NA
    cleaned_nums: List[Optional[str]] = []
    for s in std_vals:
        if s is None or s == "":
            cleaned_nums.append(None)
        elif s == "S/N":
            cleaned_nums.append(None)
        else:
            cleaned_nums.append(s)

    # Tentar converter para int
    converted: List[Optional[int]] = []
    any_fail = False
    for s in cleaned_nums:
        if s is None:
            converted.append(None)
            continue
        try:
            iv = int(s)
        except Exception:
            any_fail = True
            converted.append(None)
        else:
            converted.append(iv)

    if any_fail:
        _warning_conversao_invalida()

    # reconstruir tipo original
    if orig_is_scalar:
        return converted[0]
    if _is_pandas_series(orig):
        return pd.Series(converted, index=orig.index, name=getattr(orig, "name", None))
    if _is_pandas_index(orig):
        return pd.Index(converted, name=getattr(orig, "name", None))
    if _is_numpy_array(orig):
        return np.array(converted, dtype=object)
    if isinstance(orig, tuple):
        return tuple(converted)
    return converted
