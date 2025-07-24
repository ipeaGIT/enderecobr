import re
from typing import Any, List, Optional, Sequence
import numpy as np

try:
    import pandas as pd
except ImportError:  # se pandas indisponível
    pd = None  # type: ignore


# ---------------------------------------------------------------------------
# Helpers mínimos (reuse / substitua se já tiver no projeto)
# ---------------------------------------------------------------------------

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

def _mask_na(vals: Sequence[Any]) -> np.ndarray:
    """
    Marca NA/None/NaN/pandas NA/"" como faltantes (vamos convertê-los a NA no final).
    """
    out = []
    for v in vals:
        if v is None:
            out.append(True); continue
        if isinstance(v, float) and np.isnan(v):
            out.append(True); continue
        if pd is not None and pd.isna(v):
            out.append(True); continue
        if isinstance(v, str) and v == "":
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


# ---------------------------------------------------------------------------
# Cascata de regex (ordem importa — replica mapeamento do R)
# Observação: Converti os padrões `r"{...}"` (estilo raw string do R) em regex Python.
# ---------------------------------------------------------------------------
_TIPO_PATTERNS: List[tuple[str, str]] = [
    # --- pontuação / limpeza básica ---
    (r"\.\.+", "."),                      # pontos repetidos
    (r"(\d+)\.(\d{3})", r"\1\2"),         # separador de milhar
    (r"\.([^ ])", r". \1"),               # espaço após ponto
    (r" [-\.] ", " "),                    # " - " ou " . " -> espaço
    (r"\.$", ""),                         # ponto final
    (r"\"", "'"),                         # aspas duplas -> simples

    # --- valores non-sense ---
    (r"^-+$", ""),                        # só hífens
    (r"^([^\d])\1{1,}$", ""),             # char não-numérico repetido
    (r"^\d+$", ""),                       # só números (não é tipo)
    # ordenação (ex.: 3A RUA, 15O BECO)
    (r"\b\d+[AO]\s?", ""),                # remove ordinal no começo

    # --- tipos de logradouro principais ---
    (r"\bR(A|U)?\b\.?", "RUA"),
    (r"\b(ROD|RDV)\b\.?", "RODOVIA"),
    (r"\bAV(E|N|D|DA|I)?\b\.?", "AVENIDA"),
    (r"\bESTR?\b\.?", "ESTRADA"),  # ESTANCIA é raro; preferimos ESTRADA
    (r"\b(PCA?|PR(A|C))\b\.?", "PRACA"),
    # (?<!BECO) impede re-substituir BECO já correto
    (r"(?<!BECO)\bBE?CO?\b\.?", "BECO"),
    (r"\b(T(RA?)?V|TRA)\b\.?", "TRAVESSA"),
    (r"\bP((A?R)?Q|QU?E)\b\.?", "PARQUE"),
    # evitar "RODOVIA AL ..." (estado AL) virar ALAMEDA:
    (r"(?<!RODOVIA )\bAL(A|M)?\b\.?", "ALAMEDA"),
    (r"\bLOT\b\.?", "LOTEAMENTO"),
    (r"\bVI?L\b\.?", "VILA"),
    (r"\bLAD\b\.?", "LADEIRA"),
    (r"\bDIS(TR?)?\b\.?", "DISTRITO"),
    (r"\bNUC\b\.?", "NUCLEO"),
    (r"\bL(AR|RG|GO)\b\.?", "LARGO"),
    (r"\bAER(OP)?\b\.?", "AEROPORTO"),
    (r"\bFAZ(EN?)?\b\.?", "FAZENDA"),
    (r"\bCOND\b\.?", "CONDOMINIO"),
    (r"\bSIT\b\.?", "SITIO"),
    (r"\bRES(ID)?\b\.?", "RESIDENCIAL"),
    (r"\bQ(U(AD?)?|D(RA?)?)\b\.?", "QUADRA"),
    (r"\bCHAC\b\.?", "CHACARA"),  # CHAPADAO conflita → usamos CHAC
    (r"\bCPO\b\.?", "CAMPO"),
    (r"\bCOL\b\.?", "COLONIA"),
    (r"\bC(ONJ|J)\b\.?", "CONJUNTO"),
    (r"\bJ(D(I?M)?|A?RD|AR(DIN)?)\b\.?", "JARDIM"),
    (r"\bFAV\b\.?", "FAVELA"),
    (r"\bVIE\b\.?", "VIELA"),
    (r"\bSET\b\.?", "SETOR"),
    (r"\bILH\b\.?", "ILHA"),
    (r"\bVER\b\.?", "VEREDA"),
    (r"\bACA\b\.?", "ACAMPAMENTO"),
    (r"\bACE\b\.?", "ACESSO"),
    (r"\bADR\b\.?", "ADRO"),
    (r"\bALT\b\.?", "ALTO"),
    (r"\bARE\b\.?", "AREA"),
    (r"\bART\b\.?", "ARTERIA"),
    (r"\bATA\b\.?", "ATALHO"),
    (r"\bBAI\b\.?", "BAIXA"),
    (r"\bBLO\b\.?", "BLOCO"),
    (r"\bBOS\b\.?", "BOSQUE"),
    (r"\bBOU\b\.?", "BOULEVARD"),
    (r"\bBUR\b\.?", "BURACO"),
    (r"\bCAI\b\.?", "CAIS"),
    (r"\bCAL\b\.?", "CALCADA"),
    (r"\bELE\b\.?", "ELEVADA"),
    (r"\bESP\b\.?", "ESPLANADA"),
    (r"\bFEI\b\.?", "FEIRA"),
    (r"\bFER\b\.?", "FERROVIA"),
    (r"\bFON\b\.?", "FONTE"),
    (r"\bFOR\b\.?", "FORTE"),
    (r"\bGAL\b\.?", "GALERIA"),
    (r"\bGRA\b\.?", "GRANJA"),
    (r"\bMOD\b\.?", "MODULO"),
    (r"\bMON\b\.?", "MONTE"),
    (r"\bMOR\b\.?", "MORRO"),
    (r"\bPAT\b\.?", "PATIO"),
    (r"\bPOR\b\.?", "PORTO"),
    (r"\bREC\b\.?", "RECANTO"),
    (r"\bRET\b\.?", "RETA"),
    (r"\bROT\b\.?", "ROTULA"),
    (r"\bSER\b\.?", "SERVIDAO"),
    (r"\bSUB\b\.?", "SUBIDA"),
    (r"\bTER\b\.?", "TERMINAL"),
    (r"\bTRI\b\.?", "TRINCHEIRA"),
    (r"\bTUN\b\.?", "TUNEL"),
    (r"\bUNI\b\.?", "UNIDADE"),
    (r"\bVAL\b\.?", "VALA"),
    (r"\bVAR\b\.?", "VARIANTE"),
    (r"\bZIG\b\.?", "ZIGUE-ZAGUE"),

    # literal OUTROS -> vazio
    (r"\bOUTROS\b", ""),
]


# ---------------------------------------------------------------------------
# Função principal
# ---------------------------------------------------------------------------
def padronizar_tipos_de_logradouro(tipos: Any):
    """
    Padroniza abreviações de tipo de logradouro.

    Parâmetros
    ----------
    tipos : vetor-like de str (ou escalar).

    Retorno
    -------
    Mesmo tipo do input quando possível (Series→Series etc.); valores vazios → None.
    """
    if tipos is None:
        return None

    orig = tipos
    orig_is_scalar = isinstance(tipos, str) or _is_scalar(tipos)

    vals = _coerce_to_python_list(tipos)
    na_mask = _mask_na(vals)

    # Dedup p/ eficiência (como no R)
    def _key(v):
        if v is None:
            return ("__NA__",)
        if isinstance(v, float) and np.isnan(v):
            return ("__NA__",)
        if pd is not None and pd.isna(v):  # type: ignore[attr-defined]
            return ("__NA__",)
        if isinstance(v, str) and v == "":
            return ("__NA__",)
        return ("VAL", str(v))

    uniq_map = {}
    uniq_vals = []
    for v in vals:
        k = _key(v)
        if k not in uniq_map:
            uniq_map[k] = len(uniq_vals)
            uniq_vals.append(v)

    std_uniq: List[Optional[str]] = [None] * len(uniq_vals)
    for i, v in enumerate(uniq_vals):
        if (
            v is None
            or (isinstance(v, float) and np.isnan(v))
            or (pd is not None and pd.isna(v))  # type: ignore[attr-defined]
            or (isinstance(v, str) and v == "")
        ):
            std_uniq[i] = None
            continue

        s = str(v)

        # 1) squish
        s = re.sub(r"\s+", " ", s).strip()
        # 2) upper
        s = s.upper()
        # 3) Latin-ASCII
        s = _strip_accents_ascii(s)

        # 4) cascata regex
        for pat, repl in _TIPO_PATTERNS:
            s = re.sub(pat, repl, s)

        std_uniq[i] = s

    # Mapear de volta à ordem original
    std_vals: List[Optional[str]] = []
    for v in vals:
        std_vals.append(std_uniq[uniq_map[_key(v)]])

    # Restaurar NAs originais
    for j, is_na in enumerate(na_mask):
        if is_na:
            std_vals[j] = None

    # Strings vazias finais -> NA
    for j, s in enumerate(std_vals):
        if isinstance(s, str) and s == "":
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
