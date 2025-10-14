use extendr_api::prelude::*;
use regex::{Regex, RegexSet};
use unidecode::unidecode;

#[derive(Debug)]
struct ParSubstituicao {
    regexp: Regex,
    substituicao: String,
}

impl ParSubstituicao {
    fn new(regex: &str, substituicao: &str) -> Self {
        ParSubstituicao {
            regexp: Regex::new(regex).unwrap(),
            substituicao: substituicao.to_uppercase().to_string(),
        }
    }
}

#[derive(Default)]
struct Padronizador {
    substituicoes: Vec<ParSubstituicao>,
    grupo_regex: RegexSet,
}

impl Padronizador {
    fn adicionar(&mut self, regex: &str, substituicao: &str) -> &mut Self {
        self.substituicoes
            .push(ParSubstituicao::new(regex, substituicao));
        self
    }

    fn preparar(&mut self) {
        let regexes: Vec<&str> = self
            .substituicoes
            .iter()
            .map(|par| par.regexp.as_str())
            .collect();

        self.grupo_regex = RegexSet::new(regexes).unwrap();
    }
    fn padronizar(&self, valor: &str) -> String {
        let mut preproc = unidecode(valor.to_uppercase().trim());
        let mut ultimo_idx: Option<usize> = None;

        while self.grupo_regex.is_match(preproc.as_str()) {
            let idx_substituicao = self
                .grupo_regex
                .matches(preproc.as_str())
                .iter()
                .find(|idx| ultimo_idx.is_none_or(|ultimo| *idx > ultimo));

            if idx_substituicao.is_none() {
                break;
            }

            ultimo_idx = Some(idx_substituicao.unwrap());
            let par =
                self.substituicoes.get(idx_substituicao.unwrap()).unwrap();

            preproc = par
                .regexp
                .replace_all(preproc.as_str(), par.substituicao.as_str())
                .to_string();
        }

        preproc.to_string()
    }
}

/// Return string `"Hello world!"` to R.
/// @export
#[extendr]
fn hello_world() -> &'static str {
    "Hello world!"
}

/// Return string `"Hello world!"` to R.
/// @export
#[extendr]
fn bairro_rs(bairros: Strings) -> Strings {
    let mut padronizador = Padronizador::default();

    padronizador
        // Substituição nova
        .adicionar(r"\s{2,}", " ")
        .adicionar(r"\.\.+", ".")         // remover pontos repetidos
        .adicionar(r"\.([^ ])", ". $1") // garantir que haja espaco depois do ponto
        // sinalizacao
        .adicionar("\"", "'") // existem ocorrencias em que aspas duplas sao usadas para se referir a um logradouro/quadra com nome relativamente ambiguo - e.g. RUA \"A\", 26. isso pode causar um problema quando lido com o data.table: https://github.com/Rdatatable/data.table/issues/4779. por enquanto, substituindo por aspas simples. depois a gente pode ver o que fazer com as aspas simples rs.
        // valores non-sense
        .adicionar(r"^(0|-)+$", "") // - --+ 0 00+
        // PS: A regex original era ^([^\dIX])\1{1,}$ que usa uma back-reference.
        // Ou seja, qualquer coisa que comece com algo que não seja um com um dígito, I ou X, e repete ele até o fim da string, pelo menos uma vez.
        // O motor do Rust não permite esse tipo de coisa. Troquei para os casos concretos.
        // FIXME: Precisa colocar pontuação também aqui ou retirar casos não permitidos.
        .adicionar(r"^(AA+|BB+|CC+|DD+|EE+|FF+|GG+|HH+|JJ+|KK+|LL+|MM+|NN+|OO+|PP+|QQ+|RR+|SS+|TT+|UU+|VV+|WW+|YY+|ZZ+)$", "") // qualquer valor não numérico ou romano repetido 2+ vezes
         // PS: A regex original era ^(\d)\1{3,}$ que usa uma back-reference.
        // Ou seja, começa com um dígito e repete ele até o fim da string, pelo menos 3 vezes.
        // O motor do Rust não permite esse tipo de coisa. Troquei para os casos concretos.
        .adicionar(r"^(1111+|2222+|3333+|4444+|5555+|6666+|7777+|8888+|9999+|0000+)$", "") // assumindo que qualquer numero que apareça 4 ou mais vezes repetido eh um erro de digitação
        .adicionar(r"^I{4,}$", "") // IIII+
        .adicionar(r"^X{3,}$", "") // XXX+
         // localidades
        .adicionar(r"\bRES(I?D)?\b\.?", "RESIDENCIAL")
        .adicionar(r"\bJAR DIM\b", "JARDIM")
        .adicionar(r"\bJ(D(I?M)?|A?RD|AR(DIN)?)\b\.?", "JARDIM")
        .adicionar(r"^JR\b\.?", "JARDIM")
        .adicionar(r"\b(PCA|PRC)\b\.?", "PRACA")
        .adicionar(r"\bP((A?R)?Q|QU?E)\b\.?", "PARQUE")
        .adicionar(r"\bP\.? RESIDENCIAL\b", "PARQUE RESIDENCIAL")
        .adicionar(r"^VL?\b\.?", "VILA") // melhor restringir ao comeco dos nomes, caso contrario pode ser algarismo romano ou nome abreviado
        .adicionar(r"\bCID\b\.?", "CIDADE")
        .adicionar(r"\bCIDADE UNI(V(ERS)?)?\b\.?", "CIDADE UNIVERSITARIA")
        .adicionar(r"\bC\.? UNIVERSITARIA\b", "CIDADE UNIVERSITARIA")
        .adicionar(r"\bCTO\b\.?", "CENTRO")
        .adicionar(r"\bDISTR?\b\.?", "DISTRITO")
        .adicionar(r"^DIS\b\.?", "DISTRITO")
        .adicionar(r"\bCHA?C\b\.?", "CHACARA")
        .adicionar(r"^CH\b\.?", "CHACARA")
        .adicionar(r"\bC(ON?)?J\b\.?", "CONJUNTO")
        .adicionar(r"^C\.? J\b\.?", "CONJUNTO")
        .adicionar(r"\bC(ONJUNTO)? (H(B|AB(IT)?)?)\b\.?", "CONJUNTO HABITACIONAL")
        .adicionar(r"\bSTR\b\.?", "SETOR") // ST pode ser setor, santo/santa ou sitio. talvez melhor manter só STR mesmo e fazer mudanças mais específicas com ST
        .adicionar(r"^SET\b\.?", "SETOR")
        .adicionar(r"\b(DAS|DE) IND(L|TRL|US(TR?)?)?\b\.?", "$1 INDUSTRIAS")
        .adicionar(r"\bIND(L|TRL|US(TR?)?)?\b\.?", "INDUSTRIAL")
        .adicionar(r"\bD\.? INDUSTRIAL\b", "DISTRITO INDUSTRIAL")
        .adicionar(r"\bS\.? INDUSTRIAL\b", "SETOR INDUSTRIAL")
        .adicionar(r"\b(P\.? INDUSTRIAL|PARQUE IN)\b\.?", "PARQUE INDUSTRIAL")
        .adicionar(r"\bLOT(EAME?)?\b\.?(.)", "LOTEAMENTO$2")
        .adicionar(r"^LT\b\.?", "LOTEAMENTO")
        .adicionar(r"\bZN\b\.?", "ZONA")
        .adicionar(r"^Z\b\.?", "ZONA")
        .adicionar(r"\bZONA R(UR?)?\b\.?", "ZONAL RURAL")
        .adicionar(r"^POV\b\.?", "POVOADO")
        .adicionar(r"\bNUCL?\b\.?", "NUCLEO")
        .adicionar(r"\b(NUCLEO|N\.?) H(AB)?\b\.?", "NUCLEO HABITACIONAL")
        .adicionar(r"\b(NUCLEO|N\.?) C(OL)?\b\.?", "NUCLEO COLONIAL")
        .adicionar(r"\bN\.? INDUSTRIAL\b", "NUCLEO INDUSTRIAL")
        .adicionar(r"\bN\.? RESIDENCIAL\b", "NUCLEO RESIDENCIAL")
        .adicionar(r"\bBALN?\b\.?", "BALNEARIO")
        .adicionar(r"\bFAZ(EN?)?\b\.?", "FAZENDA")
        .adicionar(r"\bBS?Q\b\.?", "BOSQUE")
        .adicionar(r"\bCACH\b\.?", "CACHOEIRA")
        .adicionar(r"\bTAB\b\.?", "TABULEIRO")
        .adicionar(r"\bCOND\b\.?", "CONDOMINIO")
        .adicionar(r"\bRECR?\.? (DOS? )?BAND.*\b\.?", "RECREIO DOS BANDEIRANTES")
        .adicionar(r"\bREC\b\.?", "RECANTO")
        .adicionar(r"^COR\b\.?", "CORREGO")
        .adicionar(r"\bENG\.? (D(A|E|O)|V(LH?|ELHO)?|NOVO|CACHOEIRINHA|GRANDE)\b", "ENGENHO $1")
        .adicionar(r"^TAG\b\.?", "TAGUATINGA")
        .adicionar(r"^ASS(ENT)?\b\.?", "ASSENTAMENTO")
        .adicionar(r"^SIT\b\.?", "SITIO")
        .adicionar(r"^CAM\b\.?", "CAMINHO")
        .adicionar(r"\bCERQ\b\.?", "CERQUEIRA")
        .adicionar(r"\bCONS\b\.?(.)", "CONSELHEIRO$1") // CONS COMUN => CONSELHO COMUNITARIO, provavelment)
        .adicionar(r"\bPROL\b\.?(.)", "PROLONGAMENTO$1")
         // titulos
        .adicionar(r"\bSTO\b\.?", "SANTO")
        .adicionar(r"\bSTOS\b\.?", "SANTOS")
        .adicionar(r"\bSTA\b\.?", "SANTA")
        .adicionar(r"\bSRA\b\.?", "SENHORA")
        .adicionar(r"\b(N(OS|SS?A?)?\.? S(RA|ENHORA)|(NOSSA|NSA\.?) (S(RA?)?|SEN(H(OR)?)?))\b\.?", "NOSSA SENHORA")
        .adicionar(r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( DE?)?|NOSSA SENHORA|NS) (FAT.*|LO?UR.*|SANTANA|GUADALUPE|NAZ.*|COP*)\b", "NOSSA SENHORA DE $7")
        .adicionar(r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(A|E)?)?|NOSSA SENHORA|NS) (GRACA|VITORIA|PENHA|CONCEICAO|PAZ|GUIA|AJUDA|CANDELARIA|PURIFICACAO|SAUDE|PIEDADE|ABADIA|GLORIA|SALETE|APRESENTACAO)\b", "NOSSA SENHORA DA $8")
        .adicionar(r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(A|E)?)?|NOSSA SENHORA D(A|E)|NS) (APA.*|AUX.*|MEDIANEIRA|CONSOLADORA)\b", "NOSSA SENHORA $9")
        .adicionar(r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSA SENHORA|NS) (NAVEGANTES)\b", "NOSSA SENHORA DOS $8")
        .adicionar(r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( DO?)?|NOSSA SENHORA|NS) (CARMO|LIVRAMENTO|RETIRO|SION|ROSARIO|PILAR|ROCIO|CAMINHO|DESTERRO|BOM CONSELHO|AMPARO|PERP.*|P.* S.*)\b", "NOSSA SENHORA DO $7")
        .adicionar(r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(AS?)?)?|NOSSA SENHORA|NS) (GRACAS|DORES)\b", "NOSSA SENHORA DAS $8")
        .adicionar(r"\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR( D(OS)?)?) (BON\w*)\b", "SENHOR DO BONFIM")
        .adicionar(r"\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR( D(OS?)?)?) (BOM ?F\w*)\b", "SENHOR DO BONFIM")
        .adicionar(r"\b(S(R|ENH?)\.?( D(OS?)?)?|SENHOR) (PASS\w*|MONT\w*)\b", "SENHOR DOS $5")
        .adicionar(r"\bS(R|ENH?)\.? (BOM J\w*)\b", "SENHOR BOM JESUS")
        .adicionar(r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSO SENHOR|NS) (BONF\w*|BOM ?F\w*)\b", "NOSSO SENHOR DO BONFIM")
        .adicionar(r"\b(N(O?S)?\.? S(R|EN(H(OR)?)?)?\.?( D(OS?)?)?|NOSSO SENHOR|NS) (PASS\w*|MONT\w*)\b", "NOSSO SENHOR DOS $8")
        .adicionar(r"\bESP?\.? SANTO", "ESPIRITO SANTO")
        .adicionar(r"\bDIV\.? ESPIRITO SANTO\b", "DIVINO ESPIRITO SANTO")
        .adicionar(r"\bS\.? (PAULO|VICENTE|FRANCISCO|DOMINGOS?|CRISTOVAO)\b", "SAO $1")
        .adicionar(r"\bALMTE\b\.?", "ALMIRANTE")
        .adicionar(r"\bMAL\b\.?(.)", "MARECHAL$1")
        .adicionar(r"\bSGTO?\b\.?", "SARGENTO")
        .adicionar(r"\bCEL\b\.?", "CORONEL")
        .adicionar(r"\bBRIG\b\.?", "BRIGADEIRO")
        .adicionar(r"\bTEN\b\.?", "TENENTE")
        .adicionar(r"\bBRIGADEIRO (F\.?|FARIA) (L|LIMA)\b\.?", "BRIGADEIRO FARIA LIMA")
         // consertar esse presidente
        .adicionar(r"\bPRES(ID)?\b\.?(.)", "PRESIDENTE$2")
        .adicionar(r"\bGOV\b\.?", "GOVERNADOR") // pode acabar com GOV. - e.g. ilha do gov
        .adicionar(r"\bPREF\b\.?(.)", "PREFEITO$1")
        .adicionar(r"\bDEP\b\.?(.)", "DEPUTADO$1")
          .adicionar(r"\bDR\b\.?", "DOUTOR")
        .adicionar(r"\bDRA\b\.?", "DOUTORA")
        .adicionar(r"\bPROF\b\.?", "PROFESSOR")
        .adicionar(r"\bPROFA\b\.?", "PROFESSORA")
        .adicionar(r"\bPE\b\.(.)", "PADRE$1")
        .adicionar(r"\bD\b\.? (PEDRO|JOAO|HENRIQUE)", "DOM $1")
        .adicionar(r"\bI(NF)?\.? DOM\b", "INFANTE DOM")
         // datas
        .adicionar(r"\b(\d+) DE? JAN(EIRO)?\b", "$1 DE JANEIRO")
        .adicionar(r"\b(\d+) DE? FEV(EREIRO)?\b", "$1 DE FEVEREIRO")
        .adicionar(r"\b(\d+) DE? MAR(CO)?\b", "$1 DE MARCO")
        .adicionar(r"\b(\d+) DE? ABR(IL)?\b", "$1 DE ABRIL")
        .adicionar(r"\b(\d+) DE? MAI(O)?\b", "$1 DE MAIO")
        .adicionar(r"\b(\d+) DE? JUN(HO)?\b", "$1 DE JUNHO")
        .adicionar(r"\b(\d+) DE? JUL(HO)?\b", "$1 DE JULHO")
        .adicionar(r"\b(\d+) DE? AGO(STO)?\b", "$1 DE AGOSTO")
        .adicionar(r"\b(\d+) DE? SET(EMBRO)?\b", "$1 DE SETEMBRO")
        .adicionar(r"\b(\d+) DE? OUT(UBRO)?\b", "$1 DE OUTUBRO")
        .adicionar(r"\b(\d+) DE? NOV(EMBRO)?\b", "$1 DE NOVEMBRO")
        .adicionar(r"\b(\d+) DE? DEZ(EMBRO)?\b", "$1 DE DEZEMBRO");

    padronizador.preparar();

    bairros
        .iter()
        .map(|x| padronizador.padronizar(x))
        .collect::<Strings>()
}

// Macro to generate exports.
// This ensures exported functions are registered with R.
// See corresponding C code in `entrypoint.c`.
extendr_module! {
    mod enderecobr;
    fn hello_world;
    fn bairro_rs;
}
