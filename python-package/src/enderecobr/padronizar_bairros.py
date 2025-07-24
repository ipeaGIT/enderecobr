"""
Standardize Brazilian neighborhood (bairro) names.

This module provides :func:`padronizar_bairros`, a faithful Python port of the
R function you supplied. It normalizes strings representing Brazilian
neighborhood names by trimming whitespace, uppercasing, stripping accents,
expanding common abbreviations, fixing punctuation, and correcting a number of
frequent typos/data-entry artifacts.

The goal is **behavioral parity** with the original R version. Differences are
documented below.

Parameters
----------
bairros : sequence-like of str (or pandas.Series / numpy.ndarray / scalar)
    The neighborhood names to standardize.

Returns
-------
Same type as input when possible (Series -> Series, ndarray -> ndarray, list->list),
otherwise a Python list of strings. Missing values become ``None``.

Major Processing Steps
----------------------
1. Input validation.
2. Deduplicate for efficiency (operate on unique values, then map back).
3. Whitespace squash (trim + collapse internal runs).
4. Uppercase.
5. Latin-ASCII transliteration (strip accents).
6. Regex substitution cascade (over 100 targeted cleanups; order matters).
7. Map back; empty strings -> None.

Example
-------
>>> bairros = ["PRQ IND", "NSA SEN DE FATIMA", "ILHA DO GOV"]
>>> padronizar_bairros(bairros)
['PARQUE INDUSTRIAL', 'NOSSA SENHORA DE FATIMA', 'ILHA DO GOVERNADOR']

Notes on Fidelity vs. R
-----------------------
* R used ``stringr::str_replace_all`` with a named vector; order of application
  was the order in which the vector was given. We replicate that by iterating a
  Python list in sequence.
* In R you used raw-string literals like r"{...}"; here they are plain Python
  raw strings (r"...") with the delimiters removed.
* Backreferences (e.g. ``\\1`` in R) are written using Python's ``\\g<1>`` form.
* All operations assume inputs are Unicode; everything is uppercased and then
  converted to ASCII before regex replacements so patterns are ASCII-only.
* After all replacements, strings that become empty are returned as ``None``.

If you observe any differences from the R output, please give me a reproducible
example and I'll patch.

"""

from __future__ import annotations

from typing import Iterable, Sequence, Mapping, Dict, List, Tuple, Union, Optional, Any
import re
import unicodedata

import pandas as pd  # type: ignore
import numpy as np   # type: ignore


def _ascii_transliterate(x: str) -> str:
    """Convert Unicode text to closest ASCII approximation (strip accents)."""
    if not isinstance(x, str):
        x = str(x)
    return unicodedata.normalize("NFKD", x).encode("ascii", "ignore").decode("ascii")


def _squish(x: str) -> str:
    """Trim leading/trailing whitespace and collapse internal whitespace."""
    return re.sub(r"\s+", " ", x.strip())


# ---------------------------------------------------------------------------
# Regex replacement cascade
# ---------------------------------------------------------------------------
# IMPORTANT: Order matters. These are applied in sequence top-to-bottom,
# mirroring the R pattern vector you provided.
# ---------------------------------------------------------------------------

_PATTERN_REPLACEMENTS: List[Tuple[str, str]] = [
    # punctuation ------------------------------------------------------------
    (r"\.\.+", "."),                    # remove repeated periods
    (r"\.([^ ])", r". \\1"),             # ensure space after period

    # sinalizacao ------------------------------------------------------------
    (r"\"", "'"),  # replace double quote with single quote (see R comment)

    # valores non-sense ------------------------------------------------------
    (r"^(0|-)+$", ""),                  # strings like -, ---, 0, 00...
    (r"^([^\dIX])\1{1,}$", ""),         # repeated non-numeric / non-roman char
    (r"^(\d)\1{3,}$", ""),              # number repeated >=4 times
    (r"^I{4,}$", ""),                   # IIII+
    (r"^X{3,}$", ""),                   # XXX+

    # localidades ------------------------------------------------------------
    (r"\bP((A?R)?Q|QU?E)\b\.?", "PARQUE"),
    (r"\bIND(L|TRL|US(TR?)?)?\b\.?", "INDUSTRIAL"),
    (r"\bRES(I?D)?\b\.?", "RESIDENCIAL"),
    (r"\bJAR DIM\b", "JARDIM"),
    (r"\bJ(D(I?M)?|A?RD|AR(DIN)?)\b\.?", "JARDIM"),
    (r"^JR\b\.?", "JARDIM"),
    (r"\b(PCA|PRC)\b\.?", "PRACA"),
    (r"\bP((A?R)?Q|QU?E)\b\.?", "PARQUE"),
    (r"\bP\.? RESIDENCIAL\b", "PARQUE RESIDENCIAL"),
    (r"^VL?\b\.?", "VILA"),  # restrict to beginning; else could be roman numeral
    (r"\bCID\b\.?", "CIDADE"),
    (r"\bCIDADE UNI(V(ERS)?)?\b\.?", "CIDADE UNIVERSITARIA"),
    (r"\bC\.? UNIVERSITARIA\b", "CIDADE UNIVERSITARIA"),
    (r"\bCTO\b\.?", "CENTRO"),
    (r"\bDISTR?\b\.?", "DISTRITO"),
    (r"^DIS\b\.?", "DISTRITO"),
    (r"\bCHA?C\b\.?", "CHACARA"),
    (r"^CH\b\.?", "CHACARA"),
    (r"\bC(ON?)?J\b\.?", "CONJUNTO"),
    (r"^C\.? J\b\.?", "CONJUNTO"),
    (r"\bC(ONJUNTO)? (H(B|AB(IT)?)?)\b\.?", "CONJUNTO HABITACIONAL"),
    (r"\bSTR\b\.?", "SETOR"),  # ST ambiguous; only STR handled
    (r"^SET\b\.?", "SETOR"),
    (r"\b(DAS|DE) IND(L|TRL|US(TR?)?)?\b\.?", r"\\1 INDUSTRIAS"),
    (r"\bIND(L|TRL|US(TR?)?)?\b\.?", "INDUSTRIAL"),
    (r"\bD\.? INDUSTRIAL\b", "DISTRITO INDUSTRIAL"),
    (r"\bS\.? INDUSTRIAL\b", "SETOR INDUSTRIAL"),
    (r"\b(P\.? INDUSTRIAL|PARQUE IN)\b\.?", "PARQUE INDUSTRIAL"),
    (r"\bLOT(EAME?)?\b\.?(!?$)?", "LOTEAMENTO"),
    (r"^LT\b\.?", "LOTEAMENTO"),
    (r"\bZN\b\.?", "ZONA"),
    (r"^Z\b\.?", "ZONA"),
    (r"\bZONA R(UR?)?\b\.?", "ZONAL RURAL"),
    (r"^POV\b\.?", "POVOADO"),
    (r"\bNUCL?\b\.?", "NUCLEO"),
    (r"\b(NUCLEO|N\.?) H(AB)?\b\.?", "NUCLEO HABITACIONAL"),
    (r"\b(NUCLEO|N\.?) C(OL)?\b\.?", "NUCLEO COLONIAL"),
    (r"\bN\.? INDUSTRIAL\b", "NUCLEO INDUSTRIAL"),
    (r"\bN\.? RESIDENCIAL\b", "NUCLEO RESIDENCIAL"),
    (r"\bBALN?\b\.?", "BALNEARIO"),
    (r"\bFAZ(EN?)?\b\.?", "FAZENDA"),
    (r"\bBS?Q\b\.?", "BOSQUE"),
    (r"\bCACH\b\.?", "CACHOEIRA"),
    (r"\bTAB\b\.?", "TABULEIRO"),
    (r"\bCOND\b\.?", "CONDOMINIO"),
    (r"\bRECR?\.? (DOS? )?BAND.*\b\.?", "RECREIO DOS BANDEIRANTES"),
    (r"\bREC\b\.?", "RECANTO"),
    (r"^COR\b\.?", "CORREGO"),
    (r"\bENG\.? (D(A|E|O)|V(LH?|ELHO)?|NOVO|CACHOEIRINHA|GRANDE)\b", r"ENGENHO \\1"),
    (r"^TAG\b\.?", "TAGUATINGA"),
    (r"^ASS(ENT)?\b\.?", "ASSENTAMENTO"),
    (r"^SIT\b\.?", "SITIO"),
    (r"^CAM\b\.?", "CAMINHO"),
    (r"\bCERQ\b\.?", "CERQUEIRA"),
    (r"\bCONS\b\.?(!?$)?", "CONSELHEIRO"),
    (r"\bPROL\b\.?(!?$)?", "PROLONGAMENTO"),
    (r"\bRES(I?D)?\b\.?", "RESIDENCIAL"),

    # titulos ---------------------------------------------------------------
    (r"\bSTO\b\.?", "SANTO"),
    (r"\bSTOS\b\.?", "SANTOS"),
    (r"\bSTA\b\.?", "SANTA"),
    (r"\bSRA\b\.?", "SENHORA"),
    (r"\b(N(OS|SS?A?)?\.? S(RA|ENHORA)|(NOSSA|NSA\.?) (S(RA?)?|SEN(H(OR)?)?))\b\.?", "NOSSA SENHORA"),
    (r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( DE?)?|NOSSA SENHORA|NS) (FAT.*|LO?UR.*|SANTANA|GUADALUPE|NAZ.*|COP*)\b", r"NOSSA SENHORA DE \\g<7>"),
    (r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(A|E)?)?|NOSSA SENHORA|NS) (GRACA|VITORIA|PENHA|CONCEICAO|PAZ|GUIA|AJUDA|CANDELARIA|PURIFICACAO|SAUDE|PIEDADE|ABADIA|GLORIA|SALETE|APRESENTACAO)\b", r"NOSSA SENHORA DA \\g<8>"),
    (r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(A|E)?)?|NOSSA SENHORA D(A|E)|NS) (APA.*|AUX.*|MEDIANEIRA|CONSOLADORA)\b", r"NOSSA SENHORA \\g<9>"),
    (r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSA SENHORA|NS) (NAVEGANTES)\b", r"NOSSA SENHORA DOS \\g<8>"),
    (r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( DO?)?|NOSSA SENHORA|NS) (CARMO|LIVRAMENTO|RETIRO|SION|ROSARIO|PILAR|ROCIO|CAMINHO|DESTERRO|BOM CONSELHO|AMPARO|PERP.*|P.* S.*)\b", r"NOSSA SENHORA DO \\g<7>"),
    (r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(AS?)?)?|NOSSA SENHORA|NS) (GRACAS|DORES)\b", r"NOSSA SENHORA DAS \\g<8>"),
    (r"\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR( D(OS)?)?) (BON\w*)\b", "SENHOR DO BONFIM"),
    (r"\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR( D(OS?)?)?) (BOM ?F\w*)\b", "SENHOR DO BONFIM"),
    (r"\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR) (PASS\w*|MONT\w*)\b", r"SENHOR DOS \\g<5>"),
    (r"\bS(R|ENH?)\.? (BOM J\w*)\b", "SENHOR BOM JESUS"),
    (r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSO SENHOR|NS) (BONF\w*|BOM ?F\w*)\b", "NOSSO SENHOR DO BONFIM"),
    (r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSO SENHOR|NS) (PASS\w*|MONT\w*)\b", r"NOSSO SENHOR DOS \\g<8>"),
    (r"\bESP?\.? SANTO", "ESPIRITO SANTO"),
    (r"\bDIV\.? ESPIRITO SANTO\b", "DIVINO ESPIRITO SANTO"),
    (r"\bS\.? (PAULO|VICENTE|FRANCISCO|DOMINGOS?|CRISTOVAO)\b", r"SAO \\1"),

    (r"\bALMTE\b\.?", "ALMIRANTE"),
    (r"\bMAL\b\.?(!?$)?", "MARECHAL"),
    (r"\bSGTO?\b\.?", "SARGENTO"),
    (r"\bCEL\b\.?", "CORONEL"),
    (r"\bBRIG\b\.?", "BRIGADEIRO"),
    (r"\bTEN\b\.?", "TENENTE"),
    (r"\bBRIGADEIRO (F\.?|FARIA) (L|LIMA)\b\.?", "BRIGADEIRO FARIA LIMA"),

    # cargos ---------------------------------------------------------------
    (r"\bPRES(ID)?\b\.?(!?$)?", "PRESIDENTE"),
    (r"\bGOV\b\.?", "GOVERNADOR"),
    (r"\bPREF\b\.?(!?$)?", "PREFEITO"),
    (r"\bDEP\b\.?(!?$)?", "DEPUTADO"),

    # outros titulos -------------------------------------------------------
    (r"\bDR\b\.?", "DOUTOR"),
    (r"\bDRA\b\.?", "DOUTORA"),
    (r"\bPROF\b\.?", "PROFESSOR"),
    (r"\bPROFA\b\.?", "PROFESSORA"),
    (r"\bPE\b\.(?!$)", "PADRE"),

    (r"\bD\b\.? (PEDRO|JOAO|HENRIQUE)", r"DOM \\1"),
    (r"\bI(NF)?\.? DOM\b", "INFANTE DOM"),

    # datas ----------------------------------------------------------------
    (r"\b(\d+) DE? JAN(?!EIRO)\b", r"\\1 DE JANEIRO"),
    (r"\b(\d+) DE? FEV(?!EREIRO)\b", r"\\1 DE FEVEREIRO"),
    (r"\b(\d+) DE? MAR(?!CO)\b", r"\\1 DE MARCO"),
    (r"\b(\d+) DE? ABR(?!IL)\b", r"\\1 DE ABRIL"),
    (r"\b(\d+) DE? MAI(?!O)\b", r"\\1 DE MAIO"),
    (r"\b(\d+) DE? JUN(?!HO)\b", r"\\1 DE JUNHO"),
    (r"\b(\d+) DE? JUL(?!HO)\b", r"\\1 DE JULHO"),
    (r"\b(\d+) DE? AGO(?!STO)\b", r"\\1 DE AGOSTO"),
    (r"\b(\d+) DE? SET(?!EMBRO)\b", r"\\1 DE SETEMBRO"),
    (r"\b(\d+) DE? OUT(?!UBRO)\b", r"\\1 DE OUTUBRO"),
    (r"\b(\d+) DE? NOV(?!EMBRO)\b", r"\\1 DE NOVEMBRO"),
    (r"\b(\d+) DE? DEZ(?!EMBRO)\b", r"\\1 DE DEZEMBRO"),
]


def _apply_patterns(x: str) -> str:
    """Apply the ordered regex replacement cascade to *one* string."""
    out = x
    for pat, repl in _PATTERN_REPLACEMENTS:
        out = re.sub(pat, repl, out)
    return out


def _coerce_input(
    bairros: Any,
) -> Tuple[List[Optional[str]], str, Any]:
    """Coerce input to list of Python strings; record input type for back-conversion.

    Returns
    -------
    values : list of str | None
    kind   : one of {"series","ndarray","list","tuple","scalar"}
    meta   : object needed to reconstruct (index for Series; shape for ndarray; etc.)
    """
    # pandas Series ---------------------------------------------------------
    if isinstance(bairros, pd.Series):
        return bairros.astype("object").tolist(), "series", bairros.index

    # numpy array -----------------------------------------------------------
    if isinstance(bairros, np.ndarray):
        if bairros.ndim != 1:
            raise ValueError("bairros must be 1D")
        return bairros.astype("object").tolist(), "ndarray", bairros.shape

    # list / tuple ----------------------------------------------------------
    if isinstance(bairros, list):
        return list(bairros), "list", None
    if isinstance(bairros, tuple):
        return list(bairros), "tuple", len(bairros)

    # scalar ---------------------------------------------------------------
    if bairros is None or isinstance(bairros, str):
        return [bairros], "scalar", None

    # fallback --------------------------------------------------------------
    try:
        return list(bairros), "list", None
    except Exception as exc:  # pragma: no cover
        raise TypeError("bairros must be sequence-like of strings") from exc


def _reconstruct(
    values: List[Optional[str]],
    kind: str,
    meta: Any,
):
    """Reconstruct output container matching the input type."""
    if kind == "series":
        return pd.Series(values, index=meta, dtype="object")
    if kind == "ndarray":
        arr = np.empty(meta, dtype=object)
        arr[:] = values
        return arr
    if kind == "tuple":
        return tuple(values)
    if kind == "scalar":
        return values[0]
    return values  # list


def padronizar_bairros(bairros: Any, *, as_list: bool = False):
    """Standardize a vector of Brazilian neighborhood names.

    Parameters
    ----------
    bairros : sequence-like of str
        Input neighborhood names. ``None`` / ``NaN`` allowed.
    as_list : bool, default False
        Force return as Python list regardless of input type.

    Returns
    -------
    See module docstring.
    """
    vals, kind, meta = _coerce_input(bairros)

    # Track positions of missing
    def _is_missing(v: Any) -> bool:
        if v is None:
            return True
        try:
            return bool(pd.isna(v))
        except Exception:  # pragma: no cover
            return False

    missing_mask = [_is_missing(v) for v in vals]

    # Convert to string (preserve None)
    work = ["" if m else str(v) for v, m in zip(vals, missing_mask)]

    # Deduplicate for efficiency ------------------------------------------------
    uniq = {}
    for v in work:
        if v not in uniq:
            vv = _squish(v)
            vv = vv.upper()
            vv = _ascii_transliterate(vv)
            vv = _apply_patterns(vv)
            vv = _squish(vv)  # clean up spaces introduced by replacements
            uniq[v] = vv

    # Map back
    out = [uniq[v] for v in work]

    # Empty to None
    out_final = [None if (missing_mask[i] or out[i] == "") else out[i] for i in range(len(out))]

    if as_list:
        return out_final
    return _reconstruct(out_final, kind, meta)


# English alias --------------------------------------------------------------
def standardize_neighborhoods(bairros: Any, **kwargs):
    """English alias for :func:`padronizar_bairros`. See that docstring."""
    return padronizar_bairros(bairros, **kwargs)


__all__ = ["padronizar_bairros", "standardize_neighborhoods"]
