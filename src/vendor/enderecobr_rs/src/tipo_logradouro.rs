use std::sync::LazyLock;

use crate::Padronizador;

pub fn criar_padronizador_tipo_logradouro() -> Padronizador {
    let mut padronizador = Padronizador::default();
    padronizador
        // Substituição nova
        .adicionar(r"\s{2,}", " ")

        .adicionar(r"\.\.+", ".")         // remover pontos repetidos
        .adicionar(r"(\d+)\.(\d{3})", "$1$2") // pontos usados como separador de milhares

        .adicionar(r"\.([^ ])", ". $1") // garantir que haja espaco depois do ponto
        .adicionar(r" (-|\.) ", " ")
        .adicionar(r"\.$", "") // remocao de ponto final

        .adicionar(r"\.([^ ])", ". $1") // garantir que haja espaco depois do ponto

        // sinalizacao
        .adicionar("\"", "'") // existem ocorrencias em que aspas duplas sao usadas para se referir a um logradouro/quadra com nome relativamente ambiguo - e.g. RUA \"A\", 26. isso pode causar um problema quando lido com o data.table: https://github.com/Rdatatable/data.table/issues/4779. por enquanto, substituindo por aspas simples. depois a gente pode ver o que fazer com as aspas simples rs.

        // valores non-sense
        .adicionar(r"^-+$", "") // - --+ 0 00+
        // PS: A regex original era ^([^\d])\1{1,}$ que usa uma back-reference.
        // Ou seja, qualquer coisa que comece com algo que não seja um com um dígito e repete ele até o fim da string, pelo menos uma vez.
        // O motor do Rust não permite esse tipo de coisa. Troquei para os casos concretos.
        // FIXME: Precisa colocar pontuação também aqui ou retirar casos não permitidos.
        .adicionar(r"^(AA+|BB+|CC+|DD+|EE+|FF+|GG+|HH+|JJ+|KK+|LL+|MM+|NN+|OO+|PP+|QQ+|RR+|SS+|TT+|UU+|VV+|WW+|YY+|ZZ+|[*][*]+|__+|;;+|//+|,,+|::+|''+)$", "") // qualquer valor não numérico ou romano repetido 2+ vezes

        .adicionar(r"^\d+$", "") // tipos de logradouro não podem ser números

        // ordenacao de logradouros - e.g. 3A RUA, 15A TRAVESSA, 1A RODOVIA, 1O BECO, etc
        .adicionar(r"\b\d+(A|O) ?", "")

        // tipos de logradouro
        // problema visto no cadunico 2011: muitos tipos são truncados em 3 letras.
        // existem ambiguidades com CAM (CAMINHO x CAMPO), CON (CONJUNTO x
        // CONDOMINIO), PAS (PASSARELA x PASSAGEM x PASSEIO), entre outros. nesses
        // casos, acho melhor não "tomar um lado" e manter inalterado

        .adicionar(r"\bR(A|U)?\b\.?", "RUA")
        .adicionar(r"\b(ROD|RDV)\b\.?", "RODOVIA")
        .adicionar(r"\bAV(E|N|D|DA|I)?\b\.?", "AVENIDA")
        .adicionar(r"\bESTR?\b\.?", "ESTRADA") // EST pode ser ESTANCIA, mas são poucos casos. no cadunico 2011 ESTRADA eram 139780 e ESTANCIA 158, 0.1%
        .adicionar(r"\b(PCA?|PR(A|C))\b\.?", "PRACA")
        // regexp original: \bBE?CO?\b(?<!BECO)\.?
        .adicionar_com_ignorar(r"\bBE?CO?\b\.?", "BECO", r"\bBE?CO?\bBECO\.?") // (?<!BECO) serve para remover os matches com a palavra BECO ja correta 
        .adicionar(r"\b(T(RA?)?V|TRA)\b\.?", "TRAVESSA")
        .adicionar(r"\bP((A?R)?Q|QU?E)\b\.?", "PARQUE")
        // Regexp original: (?<!RODOVIA )\bAL(A|M)?\b\.?
        .adicionar_com_ignorar(r"\bAL(A|M)?\b\.?", "ALAMEDA", r"RODOVIA \bAL(A|M)?\b\.?") // evitando um possivel caso de RODOVIA AL ..., que faria referencia a uma rodovia estadual de alagoas
        .adicionar(r"\bLOT\b\.?", "LOTEAMENTO")
        .adicionar(r"\bVI?L\b\.?", "VILA")
        .adicionar(r"\bLAD\b\.?", "LADEIRA")
        .adicionar(r"\bDIS(TR?)?\b\.?", "DISTRITO")
        .adicionar(r"\bNUC\b\.?", "NUCLEO")
        .adicionar(r"\bL(AR|RG|GO)\b\.?", "LARGO")
        .adicionar(r"\bAER(OP)?\b\.?", "AEROPORTO")
        .adicionar(r"\bFAZ(EN?)?\b\.?", "FAZENDA")
        .adicionar(r"\bCOND\b\.?", "CONDOMINIO")
        .adicionar(r"\bSIT\b\.?", "SITIO")
        .adicionar(r"\bRES(ID)?\b\.?", "RESIDENCIAL")
        .adicionar(r"\bQ(U(AD?)?|D(RA?)?)\b\.?", "QUADRA")
        .adicionar(r"\bCHAC\b\.?", "CHACARA") // CHA pode ser CHAPADAO
        .adicionar(r"\bCPO\b\.?", "CAMPO")
        .adicionar(r"\bCOL\b\.?", "COLONIA")
        .adicionar(r"\bC(ONJ|J)\b\.?", "CONJUNTO")
        .adicionar(r"\bJ(D(I?M)?|A?RD|AR(DIN)?)\b\.?", "JARDIM")
        .adicionar(r"\bFAV\b\.?", "FAVELA")
        .adicionar(r"\bNUC\b\.?", "NUCLEO")
        .adicionar(r"\bVIE\b\.?", "VIELA")
        .adicionar(r"\bSET\b\.?", "SETOR")
        .adicionar(r"\bILH\b\.?", "ILHA")
        .adicionar(r"\bVER\b\.?", "VEREDA")
        .adicionar(r"\bACA\b\.?", "ACAMPAMENTO")
        .adicionar(r"\bACE\b\.?", "ACESSO")
        .adicionar(r"\bADR\b\.?", "ADRO")
        .adicionar(r"\bALT\b\.?", "ALTO")
        .adicionar(r"\bARE\b\.?", "AREA")
        .adicionar(r"\bART\b\.?", "ARTERIA")
        .adicionar(r"\bATA\b\.?", "ATALHO")
        .adicionar(r"\bBAI\b\.?", "BAIXA")
        .adicionar(r"\bBLO\b\.?", "BLOCO")
        .adicionar(r"\bBOS\b\.?", "BOSQUE")
        .adicionar(r"\bBOU\b\.?", "BOULEVARD")
        .adicionar(r"\bBUR\b\.?", "BURACO")
        .adicionar(r"\bCAI\b\.?", "CAIS")
        .adicionar(r"\bCAL\b\.?", "CALCADA")
        .adicionar(r"\bELE\b\.?", "ELEVADA")
        .adicionar(r"\bESP\b\.?", "ESPLANADA")
        .adicionar(r"\bFEI\b\.?", "FEIRA")
        .adicionar(r"\bFER\b\.?", "FERROVIA")
        .adicionar(r"\bFON\b\.?", "FONTE")
        .adicionar(r"\bFOR\b\.?", "FORTE")
        .adicionar(r"\bGAL\b\.?", "GALERIA")
        .adicionar(r"\bGRA\b\.?", "GRANJA")
        .adicionar(r"\bMOD\b\.?", "MODULO")
        .adicionar(r"\bMON\b\.?", "MONTE")
        .adicionar(r"\bMOR\b\.?", "MORRO")
        .adicionar(r"\bPAT\b\.?", "PATIO")
        .adicionar(r"\bPOR\b\.?", "PORTO")
        .adicionar(r"\bREC\b\.?", "RECANTO")
        .adicionar(r"\bRET\b\.?", "RETA")
        .adicionar(r"\bROT\b\.?", "ROTULA")
        .adicionar(r"\bSER\b\.?", "SERVIDAO")
        .adicionar(r"\bSUB\b\.?", "SUBIDA")
        .adicionar(r"\bTER\b\.?", "TERMINAL")
        .adicionar(r"\bTRI\b\.?", "TRINCHEIRA")
        .adicionar(r"\bTUN\b\.?", "TUNEL")
        .adicionar(r"\bUNI\b\.?", "UNIDADE")
        .adicionar(r"\bVAL\b\.?", "VALA")
        .adicionar(r"\bVAR\b\.?", "VARIANTE")
        .adicionar(r"\bZIG\b\.?", "ZIGUE-ZAGUE")
        .adicionar("OUTROS", "");

    // EDF é usado pra sinalizar endereços típicos do DF no CadUnico (sigla de
    // Endereço do DF), não substituir por EDIFICIO
    //  * pelo menos é o que diz o manual do CadUnico, mas isso não aparece nenhuma vez, pelo visto

    padronizador.preparar();
    padronizador
}

// Em Rust, a constant é criada durante a compilação, então só posso chamar funções muito restritas
// quando uso `const`. Nesse caso,  como tenho uma construção complexa da struct `Padronizador`,
// tenho que usar static com inicialização Lazy (o LazyLock aqui previne condições de corrida).
static PADRONIZADOR: LazyLock<Padronizador> = LazyLock::new(criar_padronizador_tipo_logradouro);

/// Padroniza uma string representando complementos de logradouros.
///
/// # Exemplo
/// ```
/// use enderecobr_rs::padronizar_tipo_logradouro;
/// assert_eq!(padronizar_tipo_logradouro("R"), "RUA");
/// assert_eq!(padronizar_tipo_logradouro("AVE"), "AVENIDA");
/// assert_eq!(padronizar_tipo_logradouro("QDRA"), "QUADRA");
/// ```
///
/// # Detalhes
/// Operações realizadas durante a padronização:
/// - remoção de espaços em branco antes e depois das strings e remoção de espaços em excesso entre palavras;
/// - conversão de caracteres para caixa alta;
/// - remoção de acentos e caracteres não ASCII;
/// - adição de espaços após abreviações sinalizadas por pontos;
/// - expansão de abreviações frequentemente utilizadas através de diversas expressões regulares (regexes);
/// - correção de alguns pequenos erros ortográficos.
///
/// Note que existe uma etapa de compilação das expressões regulares utilizadas,
/// logo a primeira execução desta função pode demorar um pouco a mais.
///
pub fn padronizar_tipo_logradouro(valor: &str) -> String {
    // Forma de obter a variável lazy
    let padronizador = &*PADRONIZADOR;
    padronizador.padronizar(valor)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn padroniza_corretamente() {
        let casos = [
            (" RUA ", "RUA"),
            ("rua", "RUA"),
            ("RUÁ", "RUA"),
            ("RUA..", "RUA"),
            ("..RUA", ". RUA"),
            ("1.000", ""),
            ("ROD.UM", "RODOVIA UM"),
            ("RUA - UM", "RUA UM"),
            ("RUA . UM", "RUA UM"),
            ("RUA.", "RUA"),
            ("\"", "'"),
            ("AA", ""),
            ("AAAAAA", ""),
            ("1", ""),
            ("1111", ""),
            ("-", ""),
            ("--", ""),
            ("1A", ""),
            ("1O", ""),
            ("10A", ""),
            ("11A RUA", "RUA"),
            ("1O BECO", "BECO"),
            ("R", "RUA"),
            ("R.", "RUA"),
            ("RA", "RUA"),
            ("RA.", "RUA"),
            ("RU", "RUA"),
            ("RU.", "RUA"),
            ("ROD", "RODOVIA"),
            ("ROD.", "RODOVIA"),
            ("RDV", "RODOVIA"),
            ("RDV.", "RODOVIA"),
            ("AV", "AVENIDA"),
            ("AV.", "AVENIDA"),
            ("AVE", "AVENIDA"),
            ("AVE.", "AVENIDA"),
            ("AVN", "AVENIDA"),
            ("AVN.", "AVENIDA"),
            ("AVD", "AVENIDA"),
            ("AVD.", "AVENIDA"),
            ("AVDA", "AVENIDA"),
            ("AVDA.", "AVENIDA"),
            ("AVI", "AVENIDA"),
            ("AVI.", "AVENIDA"),
            ("EST", "ESTRADA"),
            ("EST.", "ESTRADA"),
            ("ESTR", "ESTRADA"),
            ("ESTR.", "ESTRADA"),
            ("PC", "PRACA"),
            ("PC.", "PRACA"),
            ("PCA", "PRACA"),
            ("PCA.", "PRACA"),
            ("PRA", "PRACA"),
            ("PRA.", "PRACA"),
            ("PRC", "PRACA"),
            ("PRC.", "PRACA"),
            ("BC", "BECO"),
            ("BC.", "BECO"),
            ("BEC", "BECO"),
            ("BEC.", "BECO"),
            ("BCO", "BECO"),
            ("BCO.", "BECO"),
            ("TV", "TRAVESSA"),
            ("TV.", "TRAVESSA"),
            ("TRV", "TRAVESSA"),
            ("TRV.", "TRAVESSA"),
            ("TRAV", "TRAVESSA"),
            ("TRAV.", "TRAVESSA"),
            ("TRA", "TRAVESSA"),
            ("TRA.", "TRAVESSA"),
            ("PQ", "PARQUE"),
            ("PQ.", "PARQUE"),
            ("PRQ", "PARQUE"),
            ("PRQ.", "PARQUE"),
            ("PARQ", "PARQUE"),
            ("PARQ.", "PARQUE"),
            ("PQE", "PARQUE"),
            ("PQE.", "PARQUE"),
            ("PQUE", "PARQUE"),
            ("PQUE.", "PARQUE"),
            ("AL", "ALAMEDA"),
            ("AL.", "ALAMEDA"),
            ("ALA", "ALAMEDA"),
            ("ALA.", "ALAMEDA"),
            ("ALM", "ALAMEDA"),
            ("ALM.", "ALAMEDA"),
            ("RODOVIA AL", "RODOVIA AL"),
            ("LOT", "LOTEAMENTO"),
            ("LOT.", "LOTEAMENTO"),
            ("VL", "VILA"),
            ("VL.", "VILA"),
            ("VIL", "VILA"),
            ("VIL.", "VILA"),
            ("LAD", "LADEIRA"),
            ("LAD.", "LADEIRA"),
            ("DIS", "DISTRITO"),
            ("DIS.", "DISTRITO"),
            ("DIST", "DISTRITO"),
            ("DIST.", "DISTRITO"),
            ("DISTR", "DISTRITO"),
            ("DISTR.", "DISTRITO"),
            ("LAR", "LARGO"),
            ("LAR.", "LARGO"),
            ("LRG", "LARGO"),
            ("LRG.", "LARGO"),
            ("LGO", "LARGO"),
            ("LGO.", "LARGO"),
            ("AER", "AEROPORTO"),
            ("AER.", "AEROPORTO"),
            ("AEROP", "AEROPORTO"),
            ("AEROP.", "AEROPORTO"),
            ("FAZ", "FAZENDA"),
            ("FAZ.", "FAZENDA"),
            ("FAZE", "FAZENDA"),
            ("FAZE.", "FAZENDA"),
            ("FAZEN", "FAZENDA"),
            ("FAZEN.", "FAZENDA"),
            ("COND", "CONDOMINIO"),
            ("COND.", "CONDOMINIO"),
            ("SIT", "SITIO"),
            ("SIT.", "SITIO"),
            ("RES", "RESIDENCIAL"),
            ("RES.", "RESIDENCIAL"),
            ("RESID", "RESIDENCIAL"),
            ("RESID.", "RESIDENCIAL"),
            ("QU", "QUADRA"),
            ("QU.", "QUADRA"),
            ("QUA", "QUADRA"),
            ("QUA.", "QUADRA"),
            ("QUAD", "QUADRA"),
            ("QUAD.", "QUADRA"),
            ("QD", "QUADRA"),
            ("QD.", "QUADRA"),
            ("QDR", "QUADRA"),
            ("QDR.", "QUADRA"),
            ("QDRA", "QUADRA"),
            ("QDRA.", "QUADRA"),
            ("CHAC", "CHACARA"),
            ("CHAC.", "CHACARA"),
            ("CPO", "CAMPO"),
            ("CPO.", "CAMPO"),
            ("COL", "COLONIA"),
            ("COL.", "COLONIA"),
            ("CONJ", "CONJUNTO"),
            ("CONJ.", "CONJUNTO"),
            ("CJ", "CONJUNTO"),
            ("CJ.", "CONJUNTO"),
            ("JD", "JARDIM"),
            ("JD.", "JARDIM"),
            ("JDM", "JARDIM"),
            ("JDM.", "JARDIM"),
            ("JDIM", "JARDIM"),
            ("JDIM.", "JARDIM"),
            ("JRD", "JARDIM"),
            ("JRD.", "JARDIM"),
            ("JARD", "JARDIM"),
            ("JARD.", "JARDIM"),
            ("JAR", "JARDIM"),
            ("JAR.", "JARDIM"),
            ("JARDIN", "JARDIM"),
            ("JARDIN.", "JARDIM"),
            ("FAV", "FAVELA"),
            ("FAV.", "FAVELA"),
            ("NUC", "NUCLEO"),
            ("NUC.", "NUCLEO"),
            ("VIE", "VIELA"),
            ("VIE.", "VIELA"),
            ("SET", "SETOR"),
            ("SET.", "SETOR"),
            ("ILH", "ILHA"),
            ("ILH.", "ILHA"),
            ("VER", "VEREDA"),
            ("VER.", "VEREDA"),
            ("ACA", "ACAMPAMENTO"),
            ("ACA.", "ACAMPAMENTO"),
            ("ACE", "ACESSO"),
            ("ACE.", "ACESSO"),
            ("ADR", "ADRO"),
            ("ADR.", "ADRO"),
            ("ALT", "ALTO"),
            ("ALT.", "ALTO"),
            ("ARE", "AREA"),
            ("ARE.", "AREA"),
            ("ART", "ARTERIA"),
            ("ART.", "ARTERIA"),
            ("ATA", "ATALHO"),
            ("ATA.", "ATALHO"),
            ("BAI", "BAIXA"),
            ("BAI.", "BAIXA"),
            ("BLO", "BLOCO"),
            ("BLO.", "BLOCO"),
            ("BOS", "BOSQUE"),
            ("BOS.", "BOSQUE"),
            ("BOU", "BOULEVARD"),
            ("BOU.", "BOULEVARD"),
            ("BUR", "BURACO"),
            ("BUR.", "BURACO"),
            ("CAI", "CAIS"),
            ("CAI.", "CAIS"),
            ("CAL", "CALCADA"),
            ("CAL.", "CALCADA"),
            ("ELE", "ELEVADA"),
            ("ELE.", "ELEVADA"),
            ("ESP", "ESPLANADA"),
            ("ESP.", "ESPLANADA"),
            ("FEI", "FEIRA"),
            ("FEI.", "FEIRA"),
            ("FER", "FERROVIA"),
            ("FER.", "FERROVIA"),
            ("FON", "FONTE"),
            ("FON.", "FONTE"),
            ("FOR", "FORTE"),
            ("FOR.", "FORTE"),
            ("GAL", "GALERIA"),
            ("GAL.", "GALERIA"),
            ("GRA", "GRANJA"),
            ("GRA.", "GRANJA"),
            ("MOD", "MODULO"),
            ("MOD.", "MODULO"),
            ("MON", "MONTE"),
            ("MON.", "MONTE"),
            ("MOR", "MORRO"),
            ("MOR.", "MORRO"),
            ("PAT", "PATIO"),
            ("PAT.", "PATIO"),
            ("POR", "PORTO"),
            ("POR.", "PORTO"),
            ("REC", "RECANTO"),
            ("REC.", "RECANTO"),
            ("RET", "RETA"),
            ("RET.", "RETA"),
            ("ROT", "ROTULA"),
            ("ROT.", "ROTULA"),
            ("SER", "SERVIDAO"),
            ("SER.", "SERVIDAO"),
            ("SUB", "SUBIDA"),
            ("SUB.", "SUBIDA"),
            ("TER", "TERMINAL"),
            ("TER.", "TERMINAL"),
            ("TRI", "TRINCHEIRA"),
            ("TRI.", "TRINCHEIRA"),
            ("TUN", "TUNEL"),
            ("TUN.", "TUNEL"),
            ("UNI", "UNIDADE"),
            ("UNI.", "UNIDADE"),
            ("VAL", "VALA"),
            ("VAL.", "VALA"),
            ("VAR", "VARIANTE"),
            ("VAR.", "VARIANTE"),
            ("ZIG", "ZIGUE-ZAGUE"),
            ("ZIG.", "ZIGUE-ZAGUE"),
            ("OUTROS", ""),
        ];

        for (input, expected) in casos.iter() {
            assert_eq!(&padronizar_tipo_logradouro(input), expected);
        }
    }
}
