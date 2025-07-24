import re
from typing import Any, List, Optional, Sequence, Dict

import numpy as np

try:
    import pandas as pd
except ImportError:  # fallback se pandas não estiver instalado
    pd = None  # type: ignore


# =============================================================================
# Utilidades internas
# =============================================================================

def _is_scalar(x: Any) -> bool:
    """Retorna True se `x` deve ser tratado como escalar."""
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
    """Coerção leve -> lista Python."""
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
    # strings e outros escalares
    return [x]


def _mask_na(vals: Sequence[Any]) -> np.ndarray:
    """
    Máscara booleana de missings (None, NaN, pandas NA) **ou string vazia**,
    exatamente como o comportamento do código R (que marcava `ceps == "" | is.na(ceps)`).
    """
    out = []
    for v in vals:
        if v is None:
            out.append(True)
            continue
        if isinstance(v, float) and np.isnan(v):
            out.append(True)
            continue
        if pd is not None and pd.isna(v):
            out.append(True)
            continue
        if isinstance(v, str) and v == "":
            out.append(True)
            continue
        out.append(False)
    return np.array(out, dtype=bool)


def _all_numeric(vals: Sequence[Any]) -> bool:
    """
    True se TODOS os valores não-missing forem numéricos (int/float).
    (Equivale ao caso em que `check_numeric()` em R passaria para o vetor completo.)
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


# -----------------------------------------------------------------------------
# Formatação de índices em português (estilo cli::cli_vec)
# -----------------------------------------------------------------------------
def _format_indices_pt(indices: Sequence[int], max_show: int = 5) -> str:
    """
    Formata índices (1-based) em português no estilo aproximado do cli::cli_vec do R.

    Exemplos:
    [1]         -> "1"
    [1,2]       -> "1 e 2"
    [1,2,3]     -> "1, 2 e 3"
    [1..6]      -> "1, 2, 3, 4, 5 ... (+1)"
    """
    if not indices:
        return ""
    idx1b = [i + 1 for i in indices]  # 1-based
    if len(idx1b) <= max_show:
        if len(idx1b) == 1:
            return f"{idx1b[0]}"
        *head, last = idx1b
        return f"{', '.join(map(str, head))} e {last}"
    head = idx1b[:max_show]
    rest = len(idx1b) - max_show
    return f"{', '.join(map(str, head))} ... (+{rest})"


# =============================================================================
# Exceção customizada
# =============================================================================

class PadronizarCEPError(ValueError):
    """Erro customizado para padronização de CEPs."""


# =============================================================================
# Checks (equivalentes a checa_se_letra_presente / checa_se_digitos_demais)
# =============================================================================

_LETRA_RE = re.compile(r"[A-Za-z]", flags=re.ASCII)

def _check_letters(raw_vals: Sequence[Optional[str]]) -> None:
    """Levanta erro se qualquer elemento tiver letras (A-Z)."""
    mask_bad = []
    for s in raw_vals:
        if s is None:
            mask_bad.append(False)
            continue
        if isinstance(s, float) and np.isnan(s):
            mask_bad.append(False)
            continue
        if pd is not None and pd.isna(s):
            mask_bad.append(False)
            continue
        s = str(s)
        mask_bad.append(bool(_LETRA_RE.search(s)))
    bad_idx = [i for i, b in enumerate(mask_bad) if b]
    if bad_idx:
        lista = _format_indices_pt(bad_idx)
        raise PadronizarCEPError(
            "CEP não deve conter letras. "
            f"O(s) elemento(s) com índice {lista} possui(em) letras."
        )


def _check_too_many_digits(std_vals: Sequence[Optional[str]]) -> None:
    """Levanta erro se qualquer CEP padronizado tiver mais que 9 caracteres (8 dígitos + hífen)."""
    mask_bad = []
    for s in std_vals:
        if s is None:
            mask_bad.append(False)
            continue
        mask_bad.append(len(s) > 9)
    bad_idx = [i for i, b in enumerate(mask_bad) if b]
    if bad_idx:
        lista = _format_indices_pt(bad_idx)
        raise PadronizarCEPError(
            "CEP não deve conter mais que 8 dígitos. "
            f"O(s) elemento(s) com índice {lista} possui(em) mais que 8 dígitos após padronização."
        )


# =============================================================================
# Função principal
# =============================================================================

def padronizar_ceps(ceps: Any):
    """
    Padronizar CEPs (Código de Endereçamento Postal) brasileiros.

    Esta função reproduz, com fidelidade semântica, a função R `padronizar_ceps()`
    (enderecobr). Opera de forma vetorial em qualquer sequência de CEPs (strings ou números)
    e retorna objeto do *mesmo tipo* quando possível.

    Parâmetros
    ----------
    ceps : sequência-like de str ou números, ou escalar.
        Os CEPs a padronizar.

    Retorno
    -------
    Mesmo tipo do input quando possível:
        * pandas.Series  -> pandas.Series
        * pandas.Index   -> pandas.Index
        * numpy.ndarray  -> numpy.ndarray[object]
        * tuple          -> tuple
        * list/other     -> list
        * escalar        -> escalar (str ou None)

    Regras de padronização
    ----------------------
    1. Conversão para caractere se input for numérico (inteiro/float).
    2. Adição de zeros à esquerda para atingir 8 dígitos.
    3. Remoção de espaços, pontos e vírgulas.
    4. Inserção de hífen após o 5º dígito: ``xxxxx-xxx``.
    5. Inputs vazios (``""``) ou NA permanecem como NA (``None``).
    6. Validações:
       - Nenhuma letra permitida.
       - Não mais que 8 dígitos (comprimento total > 9 caracteres dispara erro).

    Exemplos
    --------
    >>> padronizar_ceps(["22290-140", "22.290-140", "22290 140", "22290140"])
    ['22290-140', '22290-140', '22290-140', '22290-140']

    >>> padronizar_ceps([22290140, 1000000, None])
    ['22290-140', '01000-000', None]
    """
    orig = ceps
    orig_is_scalar = isinstance(ceps, str) or _is_scalar(ceps)

    # Coagir para lista Python
    vals = _coerce_to_python_list(ceps)

    # Máscara de missings / vazios (antes de qualquer transformação)
    na_mask = _mask_na(vals)

    # Input todo numérico?
    numeric_input = _all_numeric(vals)

    # Checagem de letras (apenas se input NÃO for numeric_input)
    if not numeric_input:
        raw_strs = []
        for v in vals:
            if v is None or (isinstance(v, float) and np.isnan(v)) or (pd is not None and pd.isna(v)):  # type: ignore[attr-defined]
                raw_strs.append(None)
            else:
                raw_strs.append(str(v))
        _check_letters(raw_strs)

    # Deduplicar (ganho de desempenho)
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

    # Padronizar únicos
    std_uniq: List[Optional[str]] = [None] * len(uniq_vals)
    for i, v in enumerate(uniq_vals):
        # Missing/vazio -> None
        if (
            v is None
            or (isinstance(v, float) and np.isnan(v))
            or (pd is not None and pd.isna(v))  # type: ignore[attr-defined]
            or (isinstance(v, str) and v == "")
        ):
            std_uniq[i] = None
            continue

        if numeric_input:
            # Tratar como inteiro (floats serão truncados)
            try:
                int_v = int(v)
            except Exception:
                # fallback: converte string e pega parte inteira antes de ponto
                int_v = int(str(v).split('.')[0])
            s = f"{int_v:08d}"
        else:
            s = str(v)

        # Remover espaços, pontos, vírgulas
        s = re.sub(r"[.,\s]", "", s)

        # Zeros à esquerda
        if len(s) < 8:
            s = s.zfill(8)

        # Inserir hífen após 5º dígito. Mantemos sobras (se houver) p/ flag posterior.
        if len(s) >= 8:
            m = re.match(r"^(\d{5})(\d{3})(.*)$", s)
            if m:
                s = f"{m.group(1)}-{m.group(2)}{m.group(3)}"

        std_uniq[i] = s

    # Mapear de volta
    std_vals: List[Optional[str]] = []
    for v in vals:
        std_vals.append(std_uniq[unique_map[_key(v)]])

    # Restaurar missings/vazios detectados no início
    for j, is_na in enumerate(na_mask):
        if is_na:
            std_vals[j] = None

    # Checar se algo ficou com dígitos demais
    _check_too_many_digits(std_vals)

    # Reconstruir tipo original
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
