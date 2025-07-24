import re
from typing import Any, Dict, List, Optional, Sequence


import numpy as np

try:
    import pandas as pd
except ImportError:  # se pandas não disponível, seguimos com listas
    pd = None  # type: ignore



# =============================================================================
# Helpers básicos (iguais / compatíveis com os já usados nas outras funções)
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

def _mask_na(vals: Sequence[Any]) -> np.ndarray:
    """
    Marca NA/None/NaN/pandas NA/strings vazias "" como faltantes.
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
    """
    Remove acentos (Latin-ASCII). Usa unidecode se disponível; senão fallback unicodedata.
    """
    try:
        import unidecode
        return unidecode.unidecode(s)
    except Exception:
        import unicodedata
        return "".join(
            c for c in unicodedata.normalize("NFD", s)
            if unicodedata.category(c) != "Mn"
        )


# =============================================================================
# Cascata de regex (ordem importa!)
# =============================================================================
# Observações de port:
# • Convertemos os padrões `r"{...}"` do R para regex Python normais.
# • Usamos grupos não capturantes onde não há backreference.
# • Alguns padrões foram ligeiramente generalizados para robustez.
# • Títulos religiosos: normalizamos para formas canônicas (“NOSSA SENHORA DE …”)
#   quando conseguimos capturar o sufixo; caso contrário, reduzimos para
#   “NOSSA SENHORA”. Ajuste se quiser fidelidade literal.

_LOGR_PATTERNS: List[tuple[str, str]] = [
    # ---------------- Pontuação / limpeza ----------------
    (r"\.\.+", "."),                      # ponto repetido
    (r",,+", ","),                        # vírgula repetida
    (r"(\d)\.(\d{3})", r"\1\2"),          # separador de milhar em números
    (r"\.([^ ,])", r". \1"),              # espaço depois de ponto
    (r",([^ ])", r", \1"),                # espaço depois de vírgula
    (r" \.", "."),                        # sem espaço antes de ponto
    (r" ,", ","),                         # sem espaço antes de vírgula
    (r"\.$", ""),                         # remove ponto final
    (r"\"", "'"),                         # aspas duplas -> simples

    # ---------------- Valores non-sense ------------------
    (r"^(?:0|-)+$", ""),                  # só 0 / hífens
    (r"^([^\dIX])\1{1,}$", ""),           # char repetido 2+
    (r"^(\d)\1{3,}$", ""),                # dígito repetido 4+
    (r"^I{4,}$", ""),                     # IIII+
    (r"^X{3,}$", ""),                     # XXX+

    # ---------------- Tipos de logradouro (início da string) ---------------
    # RUA
    (r"^RU?\b(?:[.,])?", "RUA"),
    (r"^(?:RUA|RODOVIA|ROD[.,]?) (?:RUA|RU?)\b(?:[.,])?", "RUA"),
    (r"^RUA\b[-,\.]\s*", "RUA "),

    # RODOVIA
    (r"^(?:ROD|RDV)\b(?:[.,])?", "RODOVIA"),
    (r"^(?:RODOVIA|RUA) (?:RODOVIA|ROD|RDV)\b(?:[.,])?", "RODOVIA"),
    (r"^RODOVIA\b[-,\.]\s*", "RODOVIA "),

    # AVENIDA
    (r"^AV(?:E|N|D|DA|I)?\b(?:[.,])?", "AVENIDA"),
    (r"^(?:AVENIDA|RUA|RODOVIA) (?:AVENIDA|AV(?:E|N|D|DA|I)?)\b(?:[.,])?", "AVENIDA"),
    (r"^AVENIDA\b[-,\.]\s*", "AVENIDA "),

    # ESTRADA
    (r"^ESTR?|^ETR\b(?:[.,])?", "ESTRADA"),
    (r"^(?:ESTRADA|RUA|RODOVIA) (?:ESTRADA|ESTR?|ETR)\b(?:[.,])?", "ESTRADA"),
    (r"^ESTRADA\b[-,\.]\s*", "ESTRADA "),

    # PRACA
    (r"^PCA?|^PRC\b(?:[.,])?", "PRACA"),
    (r"^(?:PRACA|RUA|RODOVIA) (?:PRACA|PCA?|PRC)\b(?:[.,])?", "PRACA"),
    (r"^PRACA\b[-,\.]\s*", "PRACA "),

    # BECO
    (r"^BE?CO?\b(?:[.,])?", "BECO"),
    (r"^(?:BECO|RUA|RODOVIA) BE?CO?\b(?:[.,])?", "BECO"),
    (r"^BE?CO?\b[-,\.]\s*", "BECO "),

    # TRAVESSA
    (r"^(?:TV|TRV|TRAV?)\b(?:[.,])?", "TRAVESSA"),
    (r"^(?:TRAVESSA|RODOVIA) (?:TRAVESSA|TV|TRV|TRAV?)\b(?:[.,])?", "TRAVESSA"),
    (r"^TRAVESSA\b[-,\.]\s*", "TRAVESSA "),
    (r"^(?:TRAVESSA|RUA|RODOVIA) (?:TRAVESSA|TV|TRV|TRAV?)\b-\s*", "TRAVESSA "),

    # PARQUE
    (r"^P(?:A?R)?Q|^PQU?E\b(?:[.,])?", "PARQUE"),
    (r"^(?:PARQUE|RODOVIA) (?:PARQUE|P(?:A?R)?Q|PQU?E)\b(?:[.,])?", "PARQUE"),
    (r"^PARQUE\b[-,\.]\s*", "PARQUE "),
    (r"^(?:PARQUE|RUA|RODOVIA) (?:PARQUE|P(?:A?R)?Q|PQU?E)\b-\s*", "PARQUE "),

    # ALAMEDA
    (r"^ALA?\b(?:[.,])?", "ALAMEDA"),
    (r"^ALAMEDA (?:ALAMEDA|ALA?)\b(?:[.,])?", "ALAMEDA"),
    (r"^RODOVIA (?:ALAMEDA|ALA)\b(?:[.,])?", "ALAMEDA"),
    (r"^ALAMEDA\b[-,\.]\s*", "ALAMEDA "),
    (r"^(?:ALAMEDA|RUA) (?:ALAMEDA|ALA?)\b-\s*", "ALAMEDA "),
    (r"^RODOVIA (?:ALAMEDA|ALA)\b-\s*", "ALAMEDA "),

    # LOTEAMENTO
    (r"^LOT\b(?:[.,])?", "LOTEAMENTO"),
    (r"^(?:LOTEAMENTO|RUA|RODOVIA) LOT\b(?:[.,])?", "LOTEAMENTO"),
    (r"^LOTEAMENTO?\b[-,\.]\s*", "LOTEAMENTO "),

    # LOCALIDADE
    (r"^LOC\b(?:[.,])?", "LOCALIDADE"),
    (r"^(?:LOCALIDADE|RUA) LOC\b(?:[.,])?", "LOCALIDADE"),
    (r"^LOCALIDADE?\b[-,\.]\s*", "LOCALIDADE "),

    # VILA
    (r"^VL\b(?:[.,])?", "VILA"),
    (r"^VILA VILA\b(?:[.,])?", "VILA"),
    (r"^VILA?\b[-,\.]\s*", "VILA "),

    # LADEIRA
    (r"^LAD\b(?:[.,])?", "LADEIRA"),
    (r"^LADEIRA LADEIRA\b(?:[.,])?", "LADEIRA"),
    (r"^LADEIRA?\b[-,\.]\s*", "LADEIRA "),

    # DISTRITO
    (r"^DT\b(?:[.,])?", "DISTRITO"),
    (r"\bDISTR?\b\.?", "DISTRITO"),
    (r"^DISTRITO DISTRITO\b(?:[.,])?", "DISTRITO"),
    (r"^DISTRITO?\b[-,\.]\s*", "DISTRITO "),

    # NUCLEO
    (r"^NUC\b(?:[.,])?", "NUCLEO"),
    (r"^NUCLEO NUCLEO\b(?:[.,])?", "NUCLEO"),
    (r"^NUCLEO?\b[-,\.]\s*", "NUCLEO "),

    # LARGO
    (r"^L(?:RG|GO)\b(?:[.,])?", "LARGO"),
    (r"^LARGO L(?:RG|GO)\b(?:[.,])?", "LARGO"),
    (r"^LARGO?\b[-,\.]\s*", "LARGO "),

    # ---------------- Estabelecimentos ----------------------------------
    # AEROPORTO
    (r"^AER(?:OP)?\b(?:[.,])?", "AEROPORTO"),
    (r"^AEROPORTO (?:AEROPORTO|AER)\b(?:[.,])?", "AEROPORTO"),
    (r"^AEROPORTO INT(?:ERN?)?\b(?:[.,])?", "AEROPORTO INTERNACIONAL"),

    # CONDOMINIO
    (r"^COND\b(?:[.,])?", "CONDOMINIO"),
    (r"^(?:CONDOMINIO|RODOVIA) (?:CONDOMINIO|COND)\b(?:[.,])?", "CONDOMINIO"),

    # FAZENDA
    (r"^FAZ(?:EN?)?\b\.?", "FAZENDA"),
    (r"^(?:FAZENDA|RODOVIA) (?:FAZ(?:EN?)?|FAZENDA)\b(?:[.,])?", "FAZENDA"),
    (r"\bFAZ(?:EN?)?\b\.?", "FAZENDA"),

    # COLONIA
    (r"^COL\b\.?", "COLONIA"),
    (r"\bCOLONIA AGRI?C?\b\.?", "COLONIA AGRICOLA"),

    # ---------------- Títulos religiosos --------------------------------
    (r"\bSTA\b\.?", "SANTA"),
    (r"\bSTO\b\.?", "SANTO"),
    # Normalização ampla de Nossa Senhora / Nosso Senhor etc.
    (r"\bNS\b\.?", "NOSSA SENHORA"),
    (r"\bSRA\b\.?", "SENHORA"),
    (r"\bN(?:O?S)?\.? S(?:RA?|ENH?ORA?)\b\.?", "NOSSA SENHORA"),
    (r"\bNOSSA SENHORA D[AEOS]* ([A-ZÇÃÂÉÍÓÚ]+)\b", r"NOSSA SENHORA DE \1"),
    (r"\bNOSSA SENHORA ([A-ZÇÃÂÉÍÓÚ]+)\b", r"NOSSA SENHORA \1"),
    (r"\bS(?:R|ENH?)\.? (BON\w*|BOM ?F\w*)\b", "SENHOR DO BONFIM"),
    (r"\bS(?:R|ENH?)\.? (BOM J\w*)\b", "SENHOR BOM JESUS"),
    (r"\bNOSSO SENHOR (BONF\w*|BOM ?F\w*)\b", "NOSSO SENHOR DO BONFIM"),

    # ---------------- Patentes / títulos civis-militares ----------------
    (r"\bALM?TE\b\.?", "ALMIRANTE"),
    (r"\bMAL\b\.?", "MARECHAL"),
    (r"\b(?:GEN|GAL)\b\.?", "GENERAL"),
    (r"\b(?:SGT|SGTO?|SARG)\b\.?", "SARGENTO"),
    (r"\b(?:PRIMEIRO|PRIM|1)\.? SARGENTO\b", "PRIMEIRO-SARGENTO"),
    (r"\b(?:SEGUNDO|SEG|2)\.? SARGENTO\b", "SEGUNDO-SARGENTO"),
    (r"\b(?:TERCEIRO|TERC|3)\.? SARGENTO\b", "TERCEIRO-SARGENTO"),
    (r"\bCEL\b\.?", "CORONEL"),
    (r"\bBRIG\b\.?", "BRIGADEIRO"),
    (r"\bTEN\b\.?", "TENENTE"),
    (r"\bTENENTE CORONEL\b", "TENENTE-CORONEL"),
    (r"\bTENENTE BRIGADEIRO\b", "TENENTE-BRIGADEIRO"),
    (r"\bTENENTE AVIADOR\b", "TENENTE-AVIADOR"),
    (r"\bSUB TENENTE\b", "SUBTENENTE"),
    (r"\b(?:PRIMEIRO|PRIM\.?) TENENTE\b", "PRIMEIRO-TENENTE"),
    (r"\b(?:SEGUNDO|SEG\.?) TENENTE\b", "SEGUNDO-TENENTE"),
    (r"\bSOLD\b\.?", "SOLDADO"),
    (r"\bMAJ\b\.?", "MAJOR"),

    (r"\bPROF\b\.?", "PROFESSOR"),
    (r"\bPROFA\b\.?", "PROFESSORA"),
    (r"\bDR\b\.?", "DOUTOR"),
    (r"\bDRA\b\.?", "DOUTORA"),
    (r"\bENG\b\.?", "ENGENHEIRO"),
    (r"\bENGA\b\.?", "ENGENHEIRA"),
    (r"\bPD?E\b\.", "PADRE"),  # PE. → PADRE
    (r"\bMONS\b\.?", "MONSENHOR"),

    (r"\bPRES(?:ID)?\b\.?", "PRESIDENTE"),
    (r"\bGOV\b\.?", "GOVERNADOR"),
    (r"\bSEN\b\.?", "SENADOR"),
    (r"\bPREF\b\.?", "PREFEITO"),
    (r"\bDEP\b\.?", "DEPUTADO"),
    (r"\bVER\b\.?(?!$)", "VEREADOR"),
    (r"\bESPL?\.? (?:DOS )?MIN(?:IST(?:ERIOS?)?)?\b\.?", "ESPLANADA DOS MINISTERIOS"),
    (r"\bMIN\b\.?(?!$)", "MINISTRO"),

    # ---------------- Abreviações gerais --------------------------------
    (r"\bJAR DIM\b", "JARDIM"),
    (r"\bJ(?:D(?:I?M)?|A?RD|AR(?:DIN)?)\b\.?", "JARDIM"),
    (r"\bUNID\b\.?", "UNIDADE"),
    (r"\b(?:CJ|CONJ)\b\.?", "CONJUNTO"),
    (r"\bLT\b\.?", "LOTE"),
    (r"\bLTS\b\.?", "LOTES"),
    (r"\bQDA?\b\.?", "QUADRA"),
    (r"\bLJ\b\.?", "LOJA"),
    (r"\bLJS\b\.?", "LOJAS"),
    (r"\bAPTO?\b\.?", "APARTAMENTO"),
    (r"\bBL\b\.?", "BLOCO"),
    (r"\bSLS\b\.?", "SALAS"),
    (r"\bEDI?F\.? EMP\b\.?", "EDIFICIO EMPRESARIAL"),
    (r"\bEDI?F\b\.?", "EDIFICIO"),
    (r"\bCOND\b\.?", "CONDOMINIO"),
    (r"\bKM\b\.", "KM"),
    (r"\bS\.? ?N\b\.?", "S/N"),
    (r"(\d)\.(?: O)? A(?:ND(?:AR)?)?\b\.?", r"\1 ANDAR"),
    (r"(\d)\.(?: O)? ANDARES\b", r"\1 ANDARES"),
    (r"(\d)(?: O)? AND\b\.?", r"\1 ANDAR"),
    (r"\bCX\.? ?P(?:T|OST(?:AL)?)?\b\.?", "CAIXA POSTAL"),
    (r"\bC\.? ?P(?:T|OST(?:AL)?)?\b\.?", "CAIXA POSTAL"),

    # ---------------- Interseção nomes/títulos --------------------------
    (r"\bD\b\.? (PEDRO|JOAO|HENRIQUE)", r"DOM \1"),
    (r"\bI(?:NF)?\.? DOM\b", "INFANTE DOM"),
    (r"\bMAR\b\.? (CARMONA|JOFRE|HERMES|MALLET|DEODORO|MARCIANO|OTAVIO|FLORIANO|BARBACENA|FIUZA|MASCARENHAS|MASCARENHA|TITO|FONTENELLE|XAVIER|BITENCOURT|BITTENCOURT|CRAVEIRO|OLIMPO|CANDIDO|RONDON|HENRIQUE|MIGUEL|JUAREZ|FONTENELE|FONTENELLE|DEADORO|HASTIMPHILO|NIEMEYER|JOSE|LINO|MANOEL|HUMB?|HUMBERTO|ARTHUR|ANTONIO|NOBREGA|CASTELO|DEODORA)\b",
     r"MARECHAL \1"),

    # ---------------- Nomes específicos ---------------------------------
    (r"\b(?:GETULHO|JETULHO|JETULIO|GET|JET)\.? VARGAS\b", "GETULIO VARGAS"),
    (r"\bJ(?:U[A-Z]*)?\.? K(?:U[A-Z]*)?\b\.?", "JUSCELINO KUBITSCHEK"),

    # ---------------- Expressões hifenizadas ----------------------------
    (r"\bBEIRA-MAR\b", "BEIRA MAR"),

    # ---------------- Rodovias ------------------------------------------
    (r"\b(?:RODOVIA|BR\.?|RODOVIA BR\.?) CENTO D?E (?:DESESSEIS|DESESEIS|DEZESSEIS|DEZESEIS)\b",
     "RODOVIA BR-116"),
    (r"\b(?:RODOVIA|BR\.?|RODOVIA BR\.?) CENTO D?E H?UM\b", "RODOVIA BR-101"),
    (r"\bBR\.? ?(\d{3})", r"BR-\1"),
    (r"\b(RO|AC|AM|RR|PA|AP|TO|MA|PI|CE|RN|PB|PE|AL|SE|BA|MG|ES|RJ|SP|PR|SC|RS|MS|MT|GO|DF) ?(\d{3})",
     r"\1-\2"),

    # ---------------- Zero à esquerda (palavra interna) -----------------
    (r" (0)(\d+)", r" \2"),

    # ---------------- Correções específicas ------------------------------
    (r"\bTENENTE SHI\b", "TEN SHI"),
    (r"\bHO SHI MINISTRO\b", "HO SHI MIN"),

    # ---------------- Datas ----------------------------------------------
    (r"\b(\d+) DE? JAN(?!EIRO)\b", r"\1 DE JANEIRO"),
    (r"\b(\d+) DE? FEV(?!EREIRO)\b", r"\1 DE FEVEREIRO"),
    (r"\b(\d+) DE? MAR(?!CO)\b", r"\1 DE MARCO"),
    (r"\b(\d+) DE? ABR(?!IL)\b", r"\1 DE ABRIL"),
    (r"\b(\d+) DE? MAI(?!O)\b", r"\1 DE MAIO"),
    (r"\b(\d+) DE? JUN(?!HO)\b", r"\1 DE JUNHO"),
    (r"\b(\d+) DE? JUL(?!HO)\b", r"\1 DE JULHO"),
    (r"\b(\d+) DE? AGO(?!STO)\b", r"\1 DE AGOSTO"),
    (r"\b(\d+) DE? SET(?!EMBRO)\b", r"\1 DE SETEMBRO"),
    (r"\b(\d+) DE? OUT(?!UBRO)\b", r"\1 DE OUTUBRO"),
    (r"\b(\d+) DE? NOV(?!EMBRO)\b", r"\1 DE NOVEMBRO"),
    (r"\b(\d+) DE? DEZ(?!EMBRO)\b", r"\1 DE DEZEMBRO"),
]


# =============================================================================
# Função principal
# =============================================================================

def padronizar_logradouros(logradouros: Any):
    """
    Padroniza nomes de logradouros brasileiros.

    Etapas:
      1. Remover espaços extremos; comprimir espaços internos.
      2. Caixa alta.
      3. Remover acentos (Latin-ASCII).
      4. Cascata de regex (_LOGR_PATTERNS, em ordem).
      5. Strings vazias → None.
      6. Preservar tipo de entrada (Series→Series, ndarray→ndarray etc.).

    Parâmetros
    ----------
    logradouros : sequência-like de str (ou escalar).

    Retorno
    -------
    Mesmo tipo do input quando possível.
    """
    if logradouros is None:
        return None

    orig = logradouros
    orig_is_scalar = isinstance(logradouros, str) or _is_scalar(logradouros)

    vals = _coerce_to_python_list(logradouros)
    na_mask = _mask_na(vals)

    # Dedup
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

    unique_map: Dict[Any, int] = {}
    uniq_vals: List[Any] = []
    for v in vals:
        k = _key(v)
        if k not in unique_map:
            unique_map[k] = len(uniq_vals)
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
        for pat, repl in _LOGR_PATTERNS:
            s = re.sub(pat, repl, s)

        std_uniq[i] = s

    # Map back
    std_vals: List[Optional[str]] = []
    for v in vals:
        std_vals.append(std_uniq[unique_map[_key(v)]])

    # Restaurar NAs originais
    for j, is_na in enumerate(na_mask):
        if is_na:
            std_vals[j] = None

    # Strings vazias finais -> None
    for j, sv in enumerate(std_vals):
        if isinstance(sv, str) and sv == "":
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
