import re
from typing import Any, Dict, List, Optional, Sequence

import numpy as np

try:
    import pandas as pd
except ImportError:  # caso não tenha pandas
    pd = None  # type: ignore


# =============================================================================
# Mini tabela de códigos de municípios (DEMO!) -------------------------------
# SUBSTITUA por dataset completo IBGE 2022.
# Esperado: colunas ["codigo_muni", "nome_muni"].
# Recomendo deixar nome_muni já em UPPER ASCII para desempenho.
# =============================================================================
_CODIGOS_MUNICIPIOS_MINI = [
    ("3304557", "RIO DE JANEIRO"),
    ("3550308", "SAO PAULO"),
    ("2927408", "SALVADOR"),
    ("2304400", "FORTALEZA"),
    ("5300108", "BRASILIA"),
    ("2408003", "CAMPO GRANDE"),   # para ilustrar AUGUSTO SEVERO -> CAMPO GRANDE
    ("1722081", "SAO VALERIO"),
    ("3300308", "ARARUAMA"),
    ("3302700", "PARATY"),         # PARATI -> PARATY
]
if pd is not None:
    CODIGOS_MUNICIPIOS = pd.DataFrame(
        _CODIGOS_MUNICIPIOS_MINI, columns=["codigo_muni", "nome_muni"]
    )
else:
    CODIGOS_MUNICIPIOS = {
        "codigo_muni": [r[0] for r in _CODIGOS_MUNICIPIOS_MINI],
        "nome_muni":   [r[1] for r in _CODIGOS_MUNICIPIOS_MINI],
    }


# =============================================================================
# Helpers compartilhados ------------------------------------------------------
# (idênticos / compatíveis com os que usei nas outras traduções; sinta-se livre
#  para centralizá-los em um módulo utilitário e importar aqui.)
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
    Marca apenas NA/None/NaN/pandas NA (não marca "" como NA).
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
    Strings numéricas contam como texto (como no R).
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
# Construir dicionários de busca por código (7 e 6 dígitos)
# =============================================================================
def _build_muni_lookups(codigos_municipios=None):
    if codigos_municipios is None:
        codigos_municipios = CODIGOS_MUNICIPIOS

    if pd is not None and isinstance(codigos_municipios, pd.DataFrame):
        df = codigos_municipios.copy()
    else:
        df = pd.DataFrame(codigos_municipios) if pd is not None else None
        if df is None:
            raise RuntimeError("`codigos_municipios` indisponível em formato reconhecido.")

    # Strings
    df["codigo_muni"] = df["codigo_muni"].astype(str)
    df["cod6"] = df["codigo_muni"].str.slice(0, 6)
    df["nome_muni"] = df["nome_muni"].astype(str)

    by_cod7 = dict(zip(df["codigo_muni"], df["nome_muni"]))
    by_cod6 = dict(zip(df["cod6"], df["nome_muni"]))
    nomes_validos = set(df["nome_muni"].tolist())

    return by_cod7, by_cod6, nomes_validos


# =============================================================================
# manipular_nome_muni (correções ortográficas / renomes IBGE)
# =============================================================================
_MANIP_MUNI_PATTERNS: List[tuple[str, str]] = [
    (r"^MOJI MIRIM$", "MOGI MIRIM"),
    (r"^GRAO PARA$", "GRAO-PARA"),
    (r"^BIRITIBA-MIRIM$", "BIRITIBA MIRIM"),
    (r"^SAO LUIS DO PARAITINGA$", "SAO LUIZ DO PARAITINGA"),
    (r"^TRAJANO DE MORAIS$", "TRAJANO DE MORAES"),
    (r"^PARATI$", "PARATY"),
    (r"^LAGOA DO ITAENGA$", "LAGOA DE ITAENGA"),
    (r"^ELDORADO DOS CARAJAS$", "ELDORADO DO CARAJAS"),
    (r"^SANTANA DO LIVRAMENTO$", "SANT'ANA DO LIVRAMENTO"),
    (r"^BELEM DE SAO FRANCISCO$", "BELEM DO SAO FRANCISCO"),
    (r"^SANTO ANTONIO DO LEVERGER$", "SANTO ANTONIO DE LEVERGER"),
    (r"^POXOREO$", "POXOREU"),
    (r"^SAO THOME DAS LETRAS$", "SAO TOME DAS LETRAS"),
    (r"^OLHO-D'AGUA DO BORGES$", "OLHO D'AGUA DO BORGES"),
    (r"^ITAPAGE$", "ITAPAJE"),
    (r"^MUQUEM DE SAO FRANCISCO$", "MUQUEM DO SAO FRANCISCO"),
    (r"^DONA EUSEBIA$", "DONA EUZEBIA"),
    (r"^PASSA-VINTE$", "PASSA VINTE"),
    (r"^AMPARO DE SAO FRANCISCO$", "AMPARO DO SAO FRANCISCO"),
    (r"^BRASOPOLIS$", "BRAZOPOLIS"),
    (r"^SERIDO$", "SAO VICENTE DO SERIDO"),
    (r"^IGUARACI$", "IGUARACY"),
    (r"^AUGUSTO SEVERO$", "CAMPO GRANDE"),
    (r"^FLORINIA$", "FLORINEA"),
    (r"^FORTALEZA DO TABOCAO$", "TABOCAO"),
    (r"^SAO VALERIO DA NATIVIDADE$", "SAO VALERIO"),
]

def manipular_nome_muni(muni: Sequence[str]) -> List[str]:
    """
    Recebe uma sequência de nomes (caixa alta) e aplica:
      • Remoção de acentos (Latin-ASCII)
      • Correções ortográficas / mudanças de nome (lista acima)
    Retorna lista de strings.
    """
    # Remover acentos
    muni_ascii = [_strip_accents_ascii(str(x)) for x in muni]

    # Aplicar substituições
    out = []
    for s in muni_ascii:
        for pat, repl in _MANIP_MUNI_PATTERNS:
            s = re.sub(pat, repl, s)
        out.append(s)
    return out


# =============================================================================
# Função principal padronizar_municipios --------------------------------------
# =============================================================================
def padronizar_municipios(municipios: Any, codigos_municipios=None):
    """
    Padroniza códigos / nomes de municípios brasileiros.

    Parâmetros
    ----------
    municipios : vetor-like (str ou num) ou escalar.
    codigos_municipios : DataFrame (opcional; padrão = global CODIGOS_MUNICIPIOS).
        Deve ter colunas ["codigo_muni", "nome_muni"].

    Retorno
    -------
    Mesmo tipo do input quando possível (Series→Series etc.).
    """
    if codigos_municipios is None:
        codigos_municipios = CODIGOS_MUNICIPIOS

    orig = municipios
    orig_is_scalar = isinstance(municipios, str) or _is_scalar(municipios)

    vals = _coerce_to_python_list(municipios)
    na_mask = _mask_na_only(vals)  # índice_municipio_vazio (NA apenas; "" não conta)

    # Dedup
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
        if (
            v is None
            or (isinstance(v, float) and np.isnan(v))
            or (pd is not None and pd.isna(v))  # type: ignore[attr-defined]
        ):
            std_uniq[i] = None
            continue

        if numeric_input:
            # sem zeros à esquerda
            try:
                iv = int(v)
            except Exception:
                iv = int(float(v))
            s = f"{iv:d}"
        else:
            s = str(v)
            s = " ".join(s.split()).strip()      # squish
            s = s.upper()
            # remover zeros à esquerda quando token inteiro numérico
            s = re.sub(r"\b0+(\d+)\b", r"\1", s)

        std_uniq[i] = s

    # Lookups
    by_cod7, by_cod6, nomes_validos = _build_muni_lookups(codigos_municipios)

    # Fase 1: mapear códigos
    mapped: List[Optional[str]] = []
    for s in std_uniq:
        if s is None:
            mapped.append(None); continue
        out = by_cod7.get(s)
        if out is None:
            out = by_cod6.get(s)
        # se achou -> padroniza; senão mantém s (por enquanto)
        if out is None:
            mapped.append(s)
        else:
            mapped.append(out)

    # Identificar quais não são nomes válidos (nem vazio)
    municipio_nao_padrao = [
        (m is not None) and (m not in nomes_validos) and (m != "")
        for m in mapped
    ]

    if any(municipio_nao_padrao):
        # aplicar manipular_nome_muni aos problemáticos
        idxs = [i for i, flag in enumerate(municipio_nao_padrao) if flag]
        to_fix = [mapped[i] for i in idxs]  # strings
        fixed = manipular_nome_muni(to_fix)
        for pos, val in zip(idxs, fixed):
            mapped[pos] = val

    # Map back à ordem original
    dedup_to_val = {i: mapped[i] for i in range(len(mapped))}
    std_vals: List[Optional[str]] = []
    for v in vals:
        std_vals.append(dedup_to_val[unique_map[_key(v)]])

    # Reesvaziar NAs originais
    for j, is_na in enumerate(na_mask):
        if is_na:
            std_vals[j] = None

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
