use regex::{Regex, RegexSet};
use unidecode::unidecode;

#[derive(Debug)]
struct PadraoSub {
    padrao: Regex,
    sub: String,
}

impl PadraoSub {
    fn new(padrao: &str, sub: &str) -> Self {
        Self {
            padrao: Regex::new(padrao).unwrap(),
            sub: sub.to_string(),
        }
    }
}

#[derive(Default)]
pub struct PadronizadorDani {
    substituicoes: Vec<PadraoSub>,
    grupo_padroes: RegexSet,
}

impl PadronizadorDani {
    fn adicionar_sub(&mut self, padrao: &str, sub: &str) -> &mut Self {
        self.substituicoes.push(PadraoSub::new(padrao, sub));
        self
    }

    fn criar_grupo_padroes(&mut self) {
        let vetor_padroes: Vec<&str> = self
            .substituicoes
            .iter()
            .map(|par| par.padrao.as_str())
            .collect();

        self.grupo_padroes = RegexSet::new(vetor_padroes).unwrap();
    }

    pub fn padronizar(&self, texto: &str) -> String {
        let mut padronizado = unidecode(texto.to_uppercase().trim());

        let matches_padroes = self.grupo_padroes.matches(padronizado.as_str());

        for indice_match in matches_padroes.iter() {
            let padrao = &self.substituicoes[indice_match].padrao;
            let sub = &self.substituicoes[indice_match].sub;

            padronizado =
                padrao.replace_all(padronizado.as_str(), sub).to_string();
        }

        padronizado
    }
}

pub fn padronizador_bairro() -> PadronizadorDani {
    let mut padronizador = PadronizadorDani::default();

    padronizador
        // Substituição nova
        .adicionar_sub(r"\s{2,}", " ")
        .adicionar_sub(r"\.\.+", ".")         // remover pontos repetidos
        .adicionar_sub(r"\.([^ ])", ". $1") // garantir que haja espaco depois do ponto
        // sinalizacao
        .adicionar_sub("\"", "'") // existem ocorrencias em que aspas duplas sao usadas para se referir a um logradouro/quadra com nome relativamente ambiguo - e.g. RUA \"A\", 26. isso pode causar um problema quando lido com o data.table: https://github.com/Rdatatable/data.table/issues/4779. por enquanto, substituindo por aspas simples. depois a gente pode ver o que fazer com as aspas simples rs.
        // valores non-sense
        .adicionar_sub(r"^(0|-)+$", "") // - --+ 0 00+
        // PS: A regex original era ^([^\dIX])\1{1,}$ que usa uma back-reference.
        // Ou seja, qualquer coisa que comece com algo que não seja um com um dígito, I ou X, e repete ele até o fim da string, pelo menos uma vez.
        // O motor do Rust não permite esse tipo de coisa. Troquei para os casos concretos.
        // FIXME: Precisa colocar pontuação também aqui ou retirar casos não permitidos.
        .adicionar_sub(r"^(AA+|BB+|CC+|DD+|EE+|FF+|GG+|HH+|JJ+|KK+|LL+|MM+|NN+|OO+|PP+|QQ+|RR+|SS+|TT+|UU+|VV+|WW+|YY+|ZZ+)$", "") // qualquer valor não numérico ou romano repetido 2+ vezes
         // PS: A regex original era ^(\d)\1{3,}$ que usa uma back-reference.
        // Ou seja, começa com um dígito e repete ele até o fim da string, pelo menos 3 vezes.
        // O motor do Rust não permite esse tipo de coisa. Troquei para os casos concretos.
        .adicionar_sub(r"^(1111+|2222+|3333+|4444+|5555+|6666+|7777+|8888+|9999+|0000+)$", "") // assumindo que qualquer numero que apareça 4 ou mais vezes repetido eh um erro de digitação
        .adicionar_sub(r"^I{4,}$", "") // IIII+
        .adicionar_sub(r"^X{3,}$", "") // XXX+
         // localidades
        .adicionar_sub(r"\bRES(I?D)?\b\.?", "RESIDENCIAL")
        .adicionar_sub(r"\bJAR DIM\b", "JARDIM")
        .adicionar_sub(r"\bJ(D(I?M)?|A?RD|AR(DIN)?)\b\.?", "JARDIM")
        .adicionar_sub(r"^JR\b\.?", "JARDIM")
        .adicionar_sub(r"\b(PCA|PRC)\b\.?", "PRACA")
        .adicionar_sub(r"\bP((A?R)?Q|QU?E)\b\.?", "PARQUE")
        .adicionar_sub(r"\bP\.? RESIDENCIAL\b", "PARQUE RESIDENCIAL")
        .adicionar_sub(r"^VL?\b\.?", "VILA") // melhor restringir ao comeco dos nomes, caso contrario pode ser algarismo romano ou nome abreviado
        .adicionar_sub(r"\bCID\b\.?", "CIDADE")
        .adicionar_sub(r"\bCIDADE UNI(V(ERS)?)?\b\.?", "CIDADE UNIVERSITARIA")
        .adicionar_sub(r"\bC\.? UNIVERSITARIA\b", "CIDADE UNIVERSITARIA")
        .adicionar_sub(r"\bCTO\b\.?", "CENTRO")
        .adicionar_sub(r"\bDISTR?\b\.?", "DISTRITO")
        .adicionar_sub(r"^DIS\b\.?", "DISTRITO")
        .adicionar_sub(r"\bCHA?C\b\.?", "CHACARA")
        .adicionar_sub(r"^CH\b\.?", "CHACARA")
        .adicionar_sub(r"\bC(ON?)?J\b\.?", "CONJUNTO")
        .adicionar_sub(r"^C\.? J\b\.?", "CONJUNTO")
        .adicionar_sub(r"\bC(ONJUNTO)? (H(B|AB(IT)?)?)\b\.?", "CONJUNTO HABITACIONAL")
        .adicionar_sub(r"\bSTR\b\.?", "SETOR") // ST pode ser setor, santo/santa ou sitio. talvez melhor manter só STR mesmo e fazer mudanças mais específicas com ST
        .adicionar_sub(r"^SET\b\.?", "SETOR")
        .adicionar_sub(r"\b(DAS|DE) IND(L|TRL|US(TR?)?)?\b\.?", "$1 INDUSTRIAS")
        .adicionar_sub(r"\bIND(L|TRL|US(TR?)?)?\b\.?", "INDUSTRIAL")
        .adicionar_sub(r"\bD\.? INDUSTRIAL\b", "DISTRITO INDUSTRIAL")
        .adicionar_sub(r"\bS\.? INDUSTRIAL\b", "SETOR INDUSTRIAL")
        .adicionar_sub(r"\b(P\.? INDUSTRIAL|PARQUE IN)\b\.?", "PARQUE INDUSTRIAL")
        .adicionar_sub(r"\bLOT(EAME?)?\b\.?(.)", "LOTEAMENTO$2")
        .adicionar_sub(r"^LT\b\.?", "LOTEAMENTO")
        .adicionar_sub(r"\bZN\b\.?", "ZONA")
        .adicionar_sub(r"^Z\b\.?", "ZONA")
        .adicionar_sub(r"\bZONA R(UR?)?\b\.?", "ZONAL RURAL")
        .adicionar_sub(r"^POV\b\.?", "POVOADO")
        .adicionar_sub(r"\bNUCL?\b\.?", "NUCLEO")
        .adicionar_sub(r"\b(NUCLEO|N\.?) H(AB)?\b\.?", "NUCLEO HABITACIONAL")
        .adicionar_sub(r"\b(NUCLEO|N\.?) C(OL)?\b\.?", "NUCLEO COLONIAL")
        .adicionar_sub(r"\bN\.? INDUSTRIAL\b", "NUCLEO INDUSTRIAL")
        .adicionar_sub(r"\bN\.? RESIDENCIAL\b", "NUCLEO RESIDENCIAL")
        .adicionar_sub(r"\bBALN?\b\.?", "BALNEARIO")
        .adicionar_sub(r"\bFAZ(EN?)?\b\.?", "FAZENDA")
        .adicionar_sub(r"\bBS?Q\b\.?", "BOSQUE")
        .adicionar_sub(r"\bCACH\b\.?", "CACHOEIRA")
        .adicionar_sub(r"\bTAB\b\.?", "TABULEIRO")
        .adicionar_sub(r"\bCOND\b\.?", "CONDOMINIO")
        .adicionar_sub(r"\bRECR?\.? (DOS? )?BAND.*\b\.?", "RECREIO DOS BANDEIRANTES")
        .adicionar_sub(r"\bREC\b\.?", "RECANTO")
        .adicionar_sub(r"^COR\b\.?", "CORREGO")
        .adicionar_sub(r"\bENG\.? (D(A|E|O)|V(LH?|ELHO)?|NOVO|CACHOEIRINHA|GRANDE)\b", "ENGENHO $1")
        .adicionar_sub(r"^TAG\b\.?", "TAGUATINGA")
        .adicionar_sub(r"^ASS(ENT)?\b\.?", "ASSENTAMENTO")
        .adicionar_sub(r"^SIT\b\.?", "SITIO")
        .adicionar_sub(r"^CAM\b\.?", "CAMINHO")
        .adicionar_sub(r"\bCERQ\b\.?", "CERQUEIRA")
        .adicionar_sub(r"\bCONS\b\.?(.)", "CONSELHEIRO$1") // CONS COMUN => CONSELHO COMUNITARIO, provavelment)
        .adicionar_sub(r"\bPROL\b\.?(.)", "PROLONGAMENTO$1")
         // titulos
        .adicionar_sub(r"\bSTO\b\.?", "SANTO")
        .adicionar_sub(r"\bSTOS\b\.?", "SANTOS")
        .adicionar_sub(r"\bSTA\b\.?", "SANTA")
        .adicionar_sub(r"\bSRA\b\.?", "SENHORA")
        .adicionar_sub(r"\b(N(OS|SS?A?)?\.? S(RA|ENHORA)|(NOSSA|NSA\.?) (S(RA?)?|SEN(H(OR)?)?))\b\.?", "NOSSA SENHORA")
        .adicionar_sub(r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( DE?)?|NOSSA SENHORA|NS) (FAT.*|LO?UR.*|SANTANA|GUADALUPE|NAZ.*|COP*)\b", "NOSSA SENHORA DE $7")
        .adicionar_sub(r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(A|E)?)?|NOSSA SENHORA|NS) (GRACA|VITORIA|PENHA|CONCEICAO|PAZ|GUIA|AJUDA|CANDELARIA|PURIFICACAO|SAUDE|PIEDADE|ABADIA|GLORIA|SALETE|APRESENTACAO)\b", "NOSSA SENHORA DA $8")
        .adicionar_sub(r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(A|E)?)?|NOSSA SENHORA D(A|E)|NS) (APA.*|AUX.*|MEDIANEIRA|CONSOLADORA)\b", "NOSSA SENHORA $9")
        .adicionar_sub(r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSA SENHORA|NS) (NAVEGANTES)\b", "NOSSA SENHORA DOS $8")
        .adicionar_sub(r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( DO?)?|NOSSA SENHORA|NS) (CARMO|LIVRAMENTO|RETIRO|SION|ROSARIO|PILAR|ROCIO|CAMINHO|DESTERRO|BOM CONSELHO|AMPARO|PERP.*|P.* S.*)\b", "NOSSA SENHORA DO $7")
        .adicionar_sub(r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(AS?)?)?|NOSSA SENHORA|NS) (GRACAS|DORES)\b", "NOSSA SENHORA DAS $8")
        .adicionar_sub(r"\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR( D(OS)?)?) (BON\w*)\b", "SENHOR DO BONFIM")
        .adicionar_sub(r"\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR( D(OS?)?)?) (BOM ?F\w*)\b", "SENHOR DO BONFIM")
        .adicionar_sub(r"\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR) (PASS\w*|MONT\w*)\b", "SENHOR DOS $5")
        .adicionar_sub(r"\bS(R|ENH?)\.? (BOM J\w*)\b", "SENHOR BOM JESUS")
        .adicionar_sub(r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSO SENHOR|NS) (BONF\w*|BOM ?F\w*)\b", "NOSSO SENHOR DO BONFIM")
        .adicionar_sub(r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSO SENHOR|NS) (PASS\w*|MONT\w*)\b", "NOSSO SENHOR DOS $8")
        .adicionar_sub(r"\bESP?\.? SANTO", "ESPIRITO SANTO")
        .adicionar_sub(r"\bDIV\.? ESPIRITO SANTO\b", "DIVINO ESPIRITO SANTO")
        .adicionar_sub(r"\bS\.? (PAULO|VICENTE|FRANCISCO|DOMINGOS?|CRISTOVAO)\b", "SAO $1")
        .adicionar_sub(r"\bALMTE\b\.?", "ALMIRANTE")
        .adicionar_sub(r"\bMAL\b\.?(.)", "MARECHAL$1")
        .adicionar_sub(r"\bSGTO?\b\.?", "SARGENTO")
        .adicionar_sub(r"\bCEL\b\.?", "CORONEL")
        .adicionar_sub(r"\bBRIG\b\.?", "BRIGADEIRO")
        .adicionar_sub(r"\bTEN\b\.?", "TENENTE")
        .adicionar_sub(r"\bBRIGADEIRO (F\.?|FARIA) (L|LIMA)\b\.?", "BRIGADEIRO FARIA LIMA")
         // consertar esse presidente
        .adicionar_sub(r"\bPRES(ID)?\b\.?(.)", "PRESIDENTE$2")
        .adicionar_sub(r"\bGOV\b\.?", "GOVERNADOR") // pode acabar com GOV. - e.g. ilha do gov
        .adicionar_sub(r"\bPREF\b\.?(.)", "PREFEITO$1")
        .adicionar_sub(r"\bDEP\b\.?(.)", "DEPUTADO$1")
          .adicionar_sub(r"\bDR\b\.?", "DOUTOR")
        .adicionar_sub(r"\bDRA\b\.?", "DOUTORA")
        .adicionar_sub(r"\bPROF\b\.?", "PROFESSOR")
        .adicionar_sub(r"\bPROFA\b\.?", "PROFESSORA")
        .adicionar_sub(r"\bPE\b\.(.)", "PADRE$1")
        .adicionar_sub(r"\bD\b\.? (PEDRO|JOAO|HENRIQUE)", "DOM $1")
        .adicionar_sub(r"\bI(NF)?\.? DOM\b", "INFANTE DOM")
         // datas
        .adicionar_sub(r"\b(\d+) DE? JAN(EIRO)?\b", "$1 DE JANEIRO")
        .adicionar_sub(r"\b(\d+) DE? FEV(EREIRO)?\b", "$1 DE FEVEREIRO")
        .adicionar_sub(r"\b(\d+) DE? MAR(CO)?\b", "$1 DE MARCO")
        .adicionar_sub(r"\b(\d+) DE? ABR(IL)?\b", "$1 DE ABRIL")
        .adicionar_sub(r"\b(\d+) DE? MAI(O)?\b", "$1 DE MAIO")
        .adicionar_sub(r"\b(\d+) DE? JUN(HO)?\b", "$1 DE JUNHO")
        .adicionar_sub(r"\b(\d+) DE? JUL(HO)?\b", "$1 DE JULHO")
        .adicionar_sub(r"\b(\d+) DE? AGO(STO)?\b", "$1 DE AGOSTO")
        .adicionar_sub(r"\b(\d+) DE? SET(EMBRO)?\b", "$1 DE SETEMBRO")
        .adicionar_sub(r"\b(\d+) DE? OUT(UBRO)?\b", "$1 DE OUTUBRO")
        .adicionar_sub(r"\b(\d+) DE? NOV(EMBRO)?\b", "$1 DE NOVEMBRO")
        .adicionar_sub(r"\b(\d+) DE? DEZ(EMBRO)?\b", "$1 DE DEZEMBRO");

    padronizador.criar_grupo_padroes();

    padronizador
}
