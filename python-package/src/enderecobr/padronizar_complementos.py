import re
from typing import Any, List, Optional, Sequence, Dict

import numpy as np

try:
    import pandas as pd
except ImportError:
    pd = None  # type: ignore


# =============================================================================
# Helpers genéricos -----------------------------------------------------------
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
    Mascara True para NA/None/NaN/pandas NA ou string vazia "".
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
# Cascata principal de regex (ordem importa!) ---------------------------------
# =============================================================================
# Observação: Ajustei apenas os padrões que no R dependiam de lookbehind
# variável (incompatível com Python). Esses casos são resolvidos depois,
# em `_apply_special_context_rules()`.
#
# Onde o R usava grupos numerados altos (\\4, \\5...) dentro de padrões com
# alternâncias complexas, simplifiquei o padrão e a substituição para capturar
# explicitamente o fragmento desejado; sem alterar o resultado prático.


_PATTERN_REPLACEMENTS: List[tuple[str, str]] = [
    # --- PONTUAÇÃO / LIMPEZA ---
    (r"\.\.+", "."),                      # remover pontos repetidos
    (r"(\d+)\.(\d{3})", r"\1\2"),         # separador de milhares
    (r"\.([^ ])", r". \1"),               # garantir espaço após ponto
    (r" (-|\.) ", " "),                   # espaço em torno de - ou .
    (r"\.$", ""),                         # ponto final
    (r"\"", "'"),                         # aspas duplas -> simples
    (r"\bQD\s*(\d+)\b", r"QUADRA \1"),    # capturar QD 20, QD   003 etc antes das regras mais complexas

    # --- NON-SENSE ---
    (r"^(0|-)+$", ""),                    # só 0s / hífens
    (r"^([^\dIX])\1{1,}$", ""),           # repetição de char não num / não I/X
    (r"^(\d)\1{3,}$", ""),                # número repetido 4+ vezes
    (r"^I{4,}$", ""),                     # IIII+
    (r"^X{3,}$", ""),                     # XXX+

    # --- QUADRA / LOTE / CASA permutações ---
    (r"\bQD?-?(\d+)-?LT?-?(\d+)-?CS?-?(\d+)\b", r"QUADRA \1 LOTE \2 CASA \3"),
    (r"\bQD?-?(\d+)-?CS?-?(\d+)-?LT?-?(\d+)\b", r"QUADRA \1 LOTE \3 CASA \2"),
    (r"\bCS?-?(\d+)-?LT?-?(\d+)-?QD?-?(\d+)\b", r"QUADRA \3 LOTE \2 CASA \1"),
    (r"\bCS?-?(\d+)-?QD?-?(\d+)-?LT?-?(\d+)\b", r"QUADRA \2 LOTE \3 CASA \1"),
    (r"\bLT?-?(\d+)-?QD?-?(\d+)-?CS?-?(\d+)\b", r"QUADRA \2 LOTE \1 CASA \3"),
    (r"\bLT?-?(\d+)-?CS?-?(\d+)-?QD?-?(\d+)\b", r"QUADRA \3 LOTE \1 CASA \2"),

    (r"\bFDS-?QD?-?(\d+)-?LT?-?(\d+)\b", r"QUADRA \1 LOTE \2 FUNDOS"),
    (r"\bQD?-?(\d+)-?LT?-?(\d+)\b", r"QUADRA \1 LOTE \2"),
    (r"\bFDS-?LT?-?(\d+)-?QD?-?(\d+)\b", r"QUADRA \2 LOTE \1 FUNDOS"),
    (r"\bLT?-?(\d+)-?QD?-?(\d+)\b", r"QUADRA \2 LOTE \1"),

    (r"\bQD?-?(\d+)-?CS?-?(\d+)\b", r"QUADRA \1 CASA \2"),

    (r"\bLT?-?(\d+)-?C-?(\d+)\b", r"LOTE \1 CASA \2"),
    (r"\bC-?(\d+)-?LT?-?(\d+)\b", r"LOTE \2 CASA \1"),

    (r"\bQD?-?(\d+)-?BL?-?(\d+)-?AP(?:TO?)?-?(\d+)\b", r"QUADRA \1 BLOCO \2 APARTAMENTO \3"),
    (r"\bLT?-?(\d+)-?BL?-?(\d+)-?AP(?:TO?)?-?(\d+)\b", r"LOTE \1 BLOCO \2 APARTAMENTO \3"),

    (r"\bB(?:LOCO|L)?-?(\d+)-?C(?:ASA|S)?-?(\d+)\b", r"BLOCO \1 CASA \2"),

    (r"\bB(?:LOCO|L)?-?(\d+[A-Z]?)-?AP(?:ARTAMENTO|TO?)?-?(\d+[A-Z]?)\b", r"BLOCO \1 APARTAMENTO \2"),
    (r"\bAP(?:ARTAMENTO|TO?)?-?(\d+[A-Z]?)-?B(?:LOCO|L)?-?(\d+[A-Z]?)\b", r"BLOCO \2 APARTAMENTO \1"),

    # --- APARTAMENTO ---
    (r"\bAPR?T0\b", "APTO"),
    (r"\bAP(?:R?T(?:O|º)?|AR?T(?:O|AMENTO)?)?\.?(\d+)", r"APARTAMENTO \1"),
    (r"(\d+)AP(?:R?T(?:O|º)?|AR?T(?:O|AMENTO)?)?\b\.?", r"\1 APARTAMENTO"),
    (r"\bAP(?:R?T(?:O|º)?|AR?TO?)?\b\.?", "APARTAMENTO"),
    (r"\bAPARTAMENTO\b: ?", "APARTAMENTO "),
    (r"\bAPARTAMENTO-(\d+)", r"APARTAMENTO \1"),
    (r" ?-APARTAMENTO", " APARTAMENTO"),

    # --- BLOCO ---
    (r"\b(BLO CO|BLOC0|BLOO(?:CO)?|BLOQ)\b", "BLOCO"),
    (r"\b(BLOCO|BL(?:OC|Q|C?O?)?)\.?(\d+)", r"BLOCO \2"),
    (r"(\d)(BLOCO|BL(?:OC|Q|C?O?)?)\b\.?", r"\1 BLOCO"),
    (r"\bBL(?:OC|Q|C?O?)?\b\.?", "BLOCO"),
    (r"\bBLOCO\b: ?", "BLOCO "),
    (r"\bBLOCO-(\d+)", r"BLOCO \1"),
    (r" ?-BLOCO", " BLOCO"),
    (r"\b(BLOCO|BL(?:Q|C?O?)?)\.?-?([A-Z]\d?|[A-Z])\b", r"BLOCO \2"),

    # --- QUADRA ---
    (r"QU ADRA", "QUADRA"),
    (r"\bQ(?:U(?:ADRA)?|D(?:RA?)?)\.?(\d+)", r"QUADRA \1"),
    (r"(\d+)Q(?:U(?:ADRA)?|D(?:RA?)?)\b\.?", r"\1 QUADRA"),
    (r"\bQD(?:RA?)?\b\.?", "QUADRA"),
    (r"\bQU\b\.? ", "QUADRA "),
    (r"\bQUADRA\b: ?", "QUADRA "),
    (r"\bQUADRA-(\d+)", r"QUADRA \1"),
    (r"\bQ\.? ?(\d+)", r"QUADRA \1"),
    (r"\bQ-(\d+)", r"QUADRA \1"),
    (r"\bQ-([A-Z])\b", r"QUADRA \1"),
    (r" ?-QUADRA", " QUADRA"),

    # --- LOTE / L ---
    (r"\b(LOTE|LTE?)\.?(\d+)", r"LOTE \2"),
    # (L digit) contexto tratado depois
    (r"(\d)(LTE?|LOTE)\b\.?", r"\1 LOTE"),
    (r"\bLTE?\b\.?", "LOTE"),
    (r"\bLOTE\b: ?", "LOTE "),
    (r"\bLOTE-(\d+)", r"LOTE \1"),
    # (L- digit) contexto tratado depois
    (r" ?-LOTE", " LOTE"),
    (r"\b(LOTES|LTS)\.?(\d+)", r"LOTES \2"),
    (r"(\d)(LTS|LOTES)\b\.?", r"\1 LOTES"),
    (r"\bLTS\b\.?", "LOTES"),
    (r"\bLOT\.? ([A-Z]{2,})", r"LOTEAMENTO \1"),

    # --- CASA ---
    (r"\b(CASA|CS)\.?(\d+)", r"CASA \2"),
    (r"(\d)(CASA|CS)\b\.?", r"\1 CASA"),
    (r"\bCS\b\.?", "CASA"),
    (r"\bCASA\b: ?", "CASA "),
    (r"\bCASA-(\d+)", r"CASA \1"),
    (r" ?-CASA", " CASA"),

    # --- CONJUNTO ---
    (r"\b(C(?:ON)?JT?|CONJUNTO)\.?(\d+)", r"CONJUNTO \2"),
    (r"(\d)(C(?:ON)?JT?|CONJUNTO)\b\.?", r"\1 CONJUNTO"),
    (r"\bC(?:ON)?JT?\b\.?", "CONJUNTO"),
    (r"\bCONJUNTO\b: ?", "CONJUNTO "),
    (r"\bCONJUNTO-(\d+)", r"CONJUNTO \1"),
    (r" ?-CONJUNTO", " CONJUNTO"),

    # --- CONDOMINIO ---
    (r"\b(CONDOMINIO|C(?:O?N)?D)\.?(\d+)", r"CONDOMINIO \2"),
    (r"(\d)(CONDOMINIO|C(?:O?N)?D)\b\.?", r"\1 CONDOMINIO"),
    (r"\bC(?:O?N)?D\b\.?", "CONDOMINIO"),
    (r"\bCONDOMINIO\b: ?", "CONDOMINIO "),
    (r"\bCONDOMINIO-(\d+)", r"CONDOMINIO \1"),
    (r" ?-CONDOMINIO", " CONDOMINIO"),

    # --- ANDAR ---
    (r"\bAND(?:AR)?\.?(\d+)", r"ANDAR \1"),
    (r"(\dO?)AND(?:AR)?\b\.?", r"\1 ANDAR"),
    (r"\bAND\b\.?", "ANDAR"),
    (r"\bANDAR\b: ?", "ANDAR "),
    (r"\bANDAR-(\d+)", r"ANDAR \1"),
    (r" ?-ANDAR", " ANDAR"),

    # --- COBERTURA ---
    (r"\bCOB(?:ERTURA)?\.?(\d+)", r"COBERTURA \1"),
    (r"(\d)COB(?:ERTURA)?\b\.?", r"\1 COBERTURA"),
    (r"\bCOB\b\.?", "COBERTURA"),
    (r"\bCOBERTURA\b: ?", "COBERTURA "),
    (r"\bCOBERTURA-(\d+)", r"COBERTURA \1"),
    (r" ?-COBERTURA", " COBERTURA"),

    # --- FUNDOS ---
    (r"\b(FDS|FUNDOS)\.?(\d+)", r"FUNDOS \2"),
    (r"(\d)(FDS|FUNDOS)\b\.?", r"\1 FUNDOS"),
    (r"\bFDS\b\.?", "FUNDOS"),
    (r"-FUNDOS", " FUNDOS"),

    # --- TIPOS DE LOGRADOURO ---
    (r"\bAV\b\.?", "AVENIDA"),
    (r"\bAVENIDA\b[:\-] ?", "AVENIDA "),
    (r"\bROD\b\.?", "RODOVIA"),
    (r"\b(BR|RO|AC|AM|RR|PA|AP|TO|MA|PI|CE|RN|PB|PE|AL|SE|BA|MG|ES|RJ|SP|PR|SC|RS|MS|MT|GO|DF) ?(\d{3})\b KM", r"\1-\2 KM"),
    (r"\bRODOVIA (BR|RO|AC|AM|RR|PA|AP|TO|MA|PI|CE|RN|PB|PE|AL|SE|BA|MG|ES|RJ|SP|PR|SC|RS|MS|MT|GO|DF) ?(\d{3})\b", r"\1-\2"),
    (r"^(BR|RO|AC|AM|RR|PA|AP|TO|MA|PI|CE|RN|PB|PE|AL|SE|BA|MG|ES|RJ|SP|PR|SC|RS|MS|MT|GO|DF) ?(\d{3})$", r"\1-\2"),
    (r"\bESTR\b\.?", "ESTRADA"),

    # --- ABREVIAÇÕES GERAIS ---
    (r"\bS\.? ?N\b\.?", "S/N"),
    (r"\bPRO?X\b\.?", "PROXIMO"),
    (r"\bLOTEAM?\b\.?", "LOTEAMENTO"),
    (r"\bCX\.? ?P(?:T|OST(?:AL)?)?\b\.?", "CAIXA POSTAL"),
    (r"\bC\.? ?P(?:T|OST(?:AL)?)?\b\.?", "CAIXA POSTAL"),
    (r"\bEDI?F?\b\.?", "EDIFICIO"),
    (r"\bN(?:O|º)?\.?(?: O|º)? (\d+)", r"NUMERO \1"),
    (r"\b(PX|PROXI)\b\.?", "PROXIMO"),
    (r"\bLJ\b\.?", "LOJA"),
    (r"\bLJS\b\.?", "LOJAS"),
    (r"\bSLS\b\.?", "SALAS"),
    (r"\bFAZ(?:EN)?\b\.?", "FAZENDA"),
    (r"\bPCA\b\.?", "PRACA"),
    (r"\bP(?:A?R)?Q\b\.?", "PARQUE"),
    (r"\bL(?:RG|GO)\b\.?", "LARGO"),
    (r"\bSIT\b\.?", "SITIO"),
    (r"\bCHAC\b\.?", "CHACARA"),
    (r"\bT(?:RA?)?V\b\.?", "TRAVESSA"),
    (r"\bJAR DIM\b", "JARDIM"),
    (r"\bJ(?:D(?:I?M)?|A?RD|AR(?:DIN)?)\b\.?", "JARDIM"),
    (r"\bVL\b\.?", "VILA"),
    (r"\bNUC\b\.?", "NUCLEO"),
    (r"\bNUCLEO H(?:AB)?\b\.?", "NUCLEO HABITACIONAL"),
    (r"\bNUCLEO COL\b\.?", "NUCLEO COLONIAL"),
    (r"\bASSENT\b\.?", "ASSENTAMENTO"),

    # --- NOMES RELIGIOSOS / TÍTULOS (simplificados) ---
    (r"\bN(?:O?S)?\.? S(?:R|EN(?:H(?:OR)?)?)?\.?(?: DE?)?\b", "NOSSA SENHORA"),
    (r"\bSTA\b\.?", "SANTA"),
    (r"\bSTO\b\.?", "SANTO"),
    (r"\bSRA\b\.?", "SENHORA"),
    (r"\bSR\b\.?", "SENHOR"),
    (r"\bS\.? (JOSE|JOAO)\b", r"SAO \1"),
    (r"\bPROF\b\.?", "PROFESSOR"),
    (r"\bMONS\b\.?", "MONSENHOR"),
    (r"\bPRES(?:ID)?\b\.?", "PRESIDENTE"),
    (r"\bGOV\b\.?", "GOVERNADOR"),
    (r"\bVISC\b\.?", "VISCONDE"),

    # ordinais
    (r"\b(\d+)\. (O|º)\b", r"\1O"),
    (r"\b(\d+)(O|º)\b\.", r"\1O"),

    # --- DATAS ---
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
# Regras especiais de contexto (substituíam lookbehinds variáveis no R) -------
# =============================================================================
def _apply_special_context_rules(s: str) -> str:
    """
    Regras que no R usavam lookbehind variável:

    1. (?<!RUA |S/)L\.? (\d+)  ->  LOTE \1
       (Não transformar L 5 quando parte de "RUA L 5" ou "S/L 5".)

    2. \b(NUCLEO RES|(?<!S/)N\.? RES(IDENCIAL)?)\b  -> NUCLEO RESIDENCIAL
       (Se houver prefixo "S/", não mexer.)

    3. \b(NUCLEO RUR|(?<!S/)N\.? RURAL)\b  -> NUCLEO RURAL
       (Mesma lógica.)

    Implementado via callbacks avaliando o contexto textual.
    """
    # --- Regra 1: L <num> ---
    pat_L = re.compile(r"\bL\.?\s*(\d+)")
    def repl_L(m):
        start = m.start()
        prefix = s[max(0, start-5):start]  # olha até 5 chars antes
        if prefix.endswith("RUA ") or prefix.endswith("S/"):
            return m.group(0)  # preserva
        return f"LOTE {m.group(1)}"
    s = pat_L.sub(repl_L, s)

    # --- Regra 2: N RES... ---
    # Primeiro, normalizar variantes explícitas "NUCLEO RES" para NUCLEO RESIDENCIAL
    s = re.sub(r"\bNUCLEO RES\b", "NUCLEO RESIDENCIAL", s)
    pat_NRES = re.compile(r"\bN\.?\s*RES(?:IDENCIAL)?\b")
    def repl_NRES(m):
        start = m.start()
        if s[max(0, start-2):start].endswith("S/"):
            return m.group(0)
        return "NUCLEO RESIDENCIAL"
    s = pat_NRES.sub(repl_NRES, s)

    # --- Regra 3: N RURAL ---
    s = re.sub(r"\bNUCLEO RUR\b", "NUCLEO RURAL", s)
    pat_NRUR = re.compile(r"\bN\.?\s*RURAL\b")
    def repl_NRUR(m):
        start = m.start()
        if s[max(0, start-2):start].endswith("S/"):
            return m.group(0)
        return "NUCLEO RURAL"
    s = pat_NRUR.sub(repl_NRUR, s)

    return s


# =============================================================================
# Função principal ------------------------------------------------------------
# =============================================================================

def padronizar_complementos(complementos: Any):
    """
    Padronizar complementos de logradouro (vetorial).

    Parâmetros
    ----------
    complementos : sequência-like de str (ou escalar).

    Retorno
    -------
    Mesmo tipo do input quando possível (Series->Series, ndarray->ndarray, etc.).
    """
    orig = complementos
    orig_is_scalar = isinstance(complementos, str) or _is_scalar(complementos)

    vals = _coerce_to_python_list(complementos)
    na_mask = _mask_na(vals)

    # Deduplicar
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
        if (
            v is None
            or (isinstance(v, float) and np.isnan(v))
            or (pd is not None and pd.isna(v))  # type: ignore[attr-defined]
            or (isinstance(v, str) and v == "")
        ):
            std_uniq[i] = None
            continue

        s = str(v)

        # 1) squash espaços
        s = re.sub(r"\s+", " ", s).strip()

        # 2) caixa alta
        s = s.upper()

        # 3) Latin-ASCII
        s = _strip_accents_ascii(s)

        # 4) cascata regex
        for pat, repl in _PATTERN_REPLACEMENTS:
            s = re.sub(pat, repl, s)

        # 5) regras contextuais (substituíam lookbehinds variáveis do R)
        s = _apply_special_context_rules(s)

        std_uniq[i] = s

    # Mapear de volta
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


# =============================================================================
# Exemplo rápido --------------------------------------------------------------
# =============================================================================
if __name__ == "__main__":
    complementos = ["", "QD1 LT2 CS3", "APTO. 405",
                    "RUA L 5", "S/L 99", "n res 10", "n rural", "bl 2 apt 7"]
    print(padronizar_complementos(complementos))
    # Esperado (aprox):
    # [None,
    #  'QUADRA 1 LOTE 2 CASA 3',
    #  'APARTAMENTO 405',
    #  'RUA L 5',              # L preservado por vir após 'RUA '
    #  'S/L 99',               # idem prefixo S/
    #  'NUCLEO RESIDENCIAL 10',
    #  'NUCLEO RURAL',
    #  'BLOCO 2 APARTAMENTO 7']
