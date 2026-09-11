use std::sync::LazyLock;

use crate::{dado_faltante::zerar_dado_faltante, Padronizador};

pub fn criar_padronizador_complemento() -> Padronizador {
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
        .adicionar(r"^(0|-)+$", "") // - --+ 0 00+
        // PS: A regex original era ^([^\dIX])\1{1,}$ que usa uma back-reference.
        // Ou seja, qualquer coisa que comece com algo que não seja um com um dígito, I ou X, e repete ele até o fim da string, pelo menos uma vez.
        // O motor do Rust não permite esse tipo de coisa. Troquei para os casos concretos.
        // FIXME: Precisa colocar pontuação também aqui ou retirar casos não permitidos.
        .adicionar(r"^(AA+|BB+|CC+|DD+|EE+|FF+|GG+|HH+|JJ+|KK+|LL+|MM+|NN+|OO+|PP+|QQ+|RR+|SS+|TT+|UU+|VV+|WW+|YY+|ZZ+|[*][*]+|__+|;;+|//+|,,+|::+|''+)$", "") // qualquer valor não numérico ou romano repetido 2+ vezes

        // PS: A regex original era ^(\d)\1{3,}$ que usa uma back-reference.
        // Ou seja, começa com um dígito e repete ele até o fim da string, pelo menos 3 vezes.
        // O motor do Rust não permite esse tipo de coisa. Troquei para os casos concretos.
        .adicionar(r"^(1111+|2222+|3333+|4444+|5555+|6666+|7777+|8888+|9999+|0000+)$", "") // assumindo que qualquer numero que apareça 4 ou mais vezes repetido eh um erro de digitação

        .adicionar(r"^I{4,}$", "") // IIII+
        .adicionar(r"^X{3,}$", "") // XXX+

        // Complemento começa com OUTROS: caso de erro comum
        .adicionar(r"^OUTROS\s", "")

        // Zeros à esquerda
        .adicionar(r"(^| )0+(\d+)( |$)", "$1$2$3")

        .adicionar(r"\bQD?-?(\d+)-?LT?-?(\d+)-?CS?-?(\d+)\b", "QUADRA $1 LOTE $2 CASA $3")
      .adicionar(r"\bQD?-?(\d+)-?CS?-?(\d+)-?LT?-?(\d+)\b", "QUADRA $1 LOTE $3 CASA $2")
      .adicionar(r"\bCS?-?(\d+)-?LT?-?(\d+)-?QD?-?(\d+)\b", "QUADRA $3 LOTE $2 CASA $1")
      .adicionar(r"\bCS?-?(\d+)-?QD?-?(\d+)-?LT?-?(\d+)\b", "QUADRA $2 LOTE $3 CASA $1")
      .adicionar(r"\bLT?-?(\d+)-?QD?-?(\d+)-?CS?-?(\d+)\b", "QUADRA $2 LOTE $1 CASA $3")
      .adicionar(r"\bLT?-?(\d+)-?CS?-?(\d+)-?QD?-?(\d+)\b", "QUADRA $3 LOTE $1 CASA $2")

      .adicionar(r"\bFDS-?QD?-?(\d+)-?LT?-?(\d+)\b", "QUADRA $1 LOTE $2 FUNDOS")
      .adicionar(r"\bQD?-?(\d+)-?LT?-?(\d+)\b", "QUADRA $1 LOTE $2")
      .adicionar(r"\bFDS-?LT?-?(\d+)-?QD?-?(\d+)\b", "QUADRA $2 LOTE $1 FUNDOS")
      .adicionar(r"\bLT?-?(\d+)-?QD?-?(\d+)\b", "QUADRA $2 LOTE $1")

      .adicionar(r"\bQD?-?(\d+)-?CS?-?(\d+)\b", "QUADRA $1 CASA $2")

      .adicionar(r"\bLT?-?(\d+)-?C-?(\d+)\b", "LOTE $1 CASA $2")
      .adicionar(r"\bC-?(\d+)-?LT?-?(\d+)\b", "LOTE $2 CASA $1")

      .adicionar(r"\bQD?-?(\d+)-?BL?-?(\d+)-?AP(TO?)?-?(\d+)\b", "QUADRA $1 BLOCO $2 APARTAMENTO $4")

      .adicionar(r"\bLT?-?(\d+)-?BL?-?(\d+)-?AP(TO?)?-?(\d+)\b", "LOTE $1 BLOCO $2 APARTAMENTO $4")

      .adicionar(r"\bB(LOCO|L)?-?(\d+)-?C(ASA|S)?-?(\d+)\b", "BLOCO $2 CASA $4")

      .adicionar(r"\bB(LOCO|L)?-?(\d+([A-Z]{1})?)-?AP(ARTAMENTO|TO?)?-?(\d+([A-Z]{1})?)\b", "BLOCO $2 APARTAMENTO $5")
      .adicionar(r"\bAP(ARTAMENTO|TO?)?-?(\d+([A-Z]{1})?)-?B(LOCO|L)?-?(\d+([A-Z]{1})?)\b", "BLOCO $5 APARTAMENTO $2")

        // localidades
      .adicionar(r"\bAPR?T0\b", "APTO")
      .adicionar(r"\bAP(R?T(O|\u00BA)?|AR?T(O|AMENTO)?)?\.?(\d)", "APARTAMENTO $4") // \u00BA = º, usado pro check não reclamar da presença de caracteres não-ascii
      .adicionar(r"(\d)AP(R?T(O|\u00BA)?|AR?T(O|AMENTO)?)?\b\.?", "$1 APARTAMENTO") // "FUJIKAWA APATO"
      .adicionar(r"\bAP(R?T(O|\u00BA)?|AR?TO?)?\b\.?", "APARTAMENTO")
      .adicionar(r"\bAPARTAMENTO\b: ?", "APARTAMENTO ")
      .adicionar(r"\bAPARTAMENTO-(\d+)", "APARTAMENTO $1")
      .adicionar(r" ?-APARTAMENTO", " APARTAMENTO")

      .adicionar(r"\b(BLO CO|BLOC0|BLOO(CO)?|BLOQ)\b", "BLOCO")
      .adicionar(r"\b(BLOCO|BL(OC|Q|C?O?)?)\.?(\d+)", "BLOCO $3")
      .adicionar(r"(\d)(BLOCO|BL(OC|Q|C?O?)?)\b\.?", "$1 BLOCO")
      .adicionar(r"\bBL(OC|Q|C?O?)?\b\.?", "BLOCO") // "BLO CASA 03"? "CASA 07 BLO"? soh truncado talvez; vi alguns BLQ que nao parecem BLOCO Q, mas sim BLOCO mesmo. e.g. "QUADRA 19 BLQ A", "BLQ 40 APARTAMENTO 504", "BLQ 01"
      .adicionar(r"\bBLOCO\b: ?", "BLOCO ")
      .adicionar(r"\bBLOCO-(\d+)", "BLOCO $1")
      .adicionar(r" ?-BLOCO", " BLOCO")
      .adicionar(r"\b(BLOCO|BL(Q|C?O?)?)\.?-?([A-Z]{1}(\d{1})?)\b", "BLOCO $2") // e.g. "APARTAMENTO 402 BLA", "BLOCO-C-42 APARTAMENTO 11", "C3 BLB1 APARTAMENTO 43"

      // muita coisa pode ser quadra... Q A LOTE 2, Q I LOTE 45, QI, Q I, etc etc. tem que ver o que faz sentido
      .adicionar(r"QU ADRA", "QUADRA")
      .adicionar(r"\bQ(U(ADRA)?|D(RA?)?)\.?(\d)", "QUADRA $4") // QDA pode ser QUADRA A. da tipo 1%~ das observacoes, pelo que vi aqui. vale a pena errar nesses 1% e transformar?
      .adicionar(r"(\d+)Q(U(ADRA)?|D(RA?)?)\b\.?", "$1 QUADRA")
      .adicionar(r"\bQD(RA?)?\b\.?", "QUADRA")
      .adicionar(r"\bQU\b\.? ", "QUADRA ") // espaco no final pra evitar casos como "EDIFICIO RES M LUIZA QU" e "BLOCO 3A APARTAMENTO 201 E M QU"
      .adicionar(r"\bQUADRA\b: ?", "QUADRA ")
      .adicionar(r"\bQUADRA-(\d+)", "QUADRA $1")
      .adicionar(r"\bQ\.? ?(\d)", "QUADRA $1")
      .adicionar(r"\bQ-(\d+)", "QUADRA $1")
      .adicionar(r"\bQ-([A-Z])\b", "QUADRA $1")
      .adicionar(r" ?-QUADRA", " QUADRA")

      .adicionar(r"\b(LOTE|LTE?)\.?(\d)", "LOTE $2")
        // FIXME: Regexp original: \b(?<!RUA |S\/)L\.? (\d)
      // Comentário original: o $1 ta certo mesmo, os (?...) nao contam. transforma L 5 em LOTE 5, mas evita que RUA L 5 LOTE 45 vire RUA LOTE 5 LOTE 45 e que S/L 205 vire S/LOTE 205
        .adicionar_com_ignorar(r"\bL\.? (\d)", "LOTE $1", r"\b(RUA |S\/)L\.? \d")
      .adicionar(r"(\d)(LTE?|LOTE)\b\.?", "$1 LOTE")
      .adicionar(r"\bLTE?\b\.?", "LOTE")
      .adicionar(r"\bLOTE\b: ?", "LOTE ")
      .adicionar(r"\bLOTE-(\d+)", "LOTE $1")
      .adicionar_com_ignorar(r"\bL-(\d+)", "LOTE $1", r"\b((TV|TRAVESSA|QUADRA) )L-(\d+)")
      // FIXME: .adicionar(r"\b(?<!(TV|TRAVESSA|QUADRA) )L-(\d+)", "LOTE $2") // "L-21-NOVO HORIZONTE" ? "L-36" ?
      .adicionar(r" ?-LOTE", " LOTE")
      .adicionar(r"\b(LOTES|LTS)\.?(\d)", "LOTES $2")
      .adicionar(r"(\d)(LTS|LOTES)\b\.?", "$1 LOTES")
      .adicionar(r"\bLTS\b\.?", "LOTES")
      // r"\bLOT\.? ?(\d)", "LOTE $1", # LOT seguido de numero tende a ser LOTE, mas seguido de palavra tende a ser LOTEAMENTO? tem excecoes e.g. "LOT 28 AGOSTO", "LOT 1 DE MAIO", "LOT 2 IRMAS", "LOT 3 COQUEIROS"
      .adicionar(r"\bLOT\.? ([A-Z]{2,})", "LOTEAMENTO $1")

      .adicionar(r"\b(CASA|CS)\.?(\d)", "CASA $2") // CSA?
      .adicionar(r"(\d)(CASA|CS)\b\.?", "$1 CASA")
      .adicionar(r"\bCS\b\.?", "CASA")
      .adicionar(r"\bCASA\b: ?", "CASA ")
      .adicionar(r"\bCASA-(\d+)", "CASA $1")
      //r"[^^]\b(?<!(APARTAMENTO|CONJUNTO|BLOCO|QUADRA) )C-(\d+)", "CASA $1", # ESSE TEM MUITA VARIACAO, COMPLICADO #### Q-10 C-03 = Q-10 CASA 03, mas APARTAMENTO C-03 nao eh mexido, nem soh C-03 (pode ser soh C-03 mesmo)
      .adicionar(r" ?-CASA", " CASA")

      .adicionar(r"\b(C(ON)?JT?|CONJUNTO)\.?(\d)", "CONJUNTO $3")
      .adicionar(r"(\d)(C(ON)?JT?|CONJUNTO)\b\.?", "$1 CONJUNTO")
      .adicionar(r"\bC(ON)?JT?\b\.?", "CONJUNTO")
      .adicionar(r"\bCONJUNTO\b: ?", "CONJUNTO ")
      .adicionar(r"\bCONJUNTO-(\d)", "CONJUNTO $1")
      .adicionar(r" ?-CONJUNTO", " CONJUNTO")

      .adicionar(r"\b(CONDOMINIO|C(O?N)?D)\.?(\d)", "CONDOMINIO $3") // "LOTE 4 RUA 06 COND263"? "COND3 T7 APARTAMENTO 13"? "BLOCO 07 APARTAMENTO 204 CD2"?
      .adicionar(r"(\d)(CONDOMINIO|C(O?N)?D)\b\.?", "$1 CONDOMINIO")
      .adicionar(r"\bC(O?N)?D\b\.?", "CONDOMINIO")
      .adicionar(r"\bCONDOMINIO\b: ?", "CONDOMINIO ")
      .adicionar(r"\bCONDOMINIO-(\d)", "CONDOMINIO $1")
      .adicionar(r" ?-CONDOMINIO", " CONDOMINIO")

      .adicionar(r"\bAND(AR)?\.?(\d)", "ANDAR $2")
      .adicionar(r"(\dO?)AND(AR)?\b\.?", "$1 ANDAR")
      .adicionar(r"\bAND\b\.?", "ANDAR")
      .adicionar(r"\bANDAR\b: ?", "ANDAR ")
      .adicionar(r"\bANDAR-(\d+)", "ANDAR $1")
      .adicionar(r" ?-ANDAR", " ANDAR")

      .adicionar(r"\bCOB(ERTURA)?\.?(\d)", "COBERTURA $2")
      .adicionar(r"(\d)COB(ERTURA)?\b\.?", "$1 COBERTURA")
      .adicionar(r"\bCOB\b\.?", "COBERTURA")
      .adicionar(r"\bCOBERTURA\b: ?", "COBERTURA ")
      .adicionar(r"\bCOBERTURA-(\d+)", "COBERTURA $1")
      .adicionar(r" ?-COBERTURA", " COBERTURA")

      .adicionar(r"\b(FDS|FUNDOS)\.?(\d)", "FUNDOS $2")
      .adicionar(r"(\d)(FDS|FUNDOS)\b\.?", "$1 FUNDOS")
      .adicionar(r"\bFDS\b\.?", "FUNDOS")
      .adicionar(r"-FUNDOS", " FUNDOS")


      .adicionar(r"\b(GL|GB)\b\.?", "GLEBA")
      .adicionar(r"\b(LN)\b\.?", "LINHA")

      // tipos de logradouro

      .adicionar(r"\bAV\b\.?", "AVENIDA") // "APARTAMENTO 401 EDIFICIO RES 5O AV"? "GUARABU AV"? "TRAVESSA AV JOAO XXIII"?
      .adicionar(r"\bAVENIDA\b(:|-) ?", "AVENIDA ")

      .adicionar(r"\bROD\b\.?", "RODOVIA") // "FAZENDA FIRMESA ROD CRIO"
      .adicionar(r"\bRODOVIA (BR|RO|AC|AM|RR|PA|AP|TO|MA|PI|CE|RN|PB|PE|AL|SE|BA|MG|ES|RJ|SP|PR|SC|RS|MS|MT|GO|DF) ?(\d{3})\b", "$1-$2")
      .adicionar(r"\b(BR|RO|AC|AM|RR|PA|AP|TO|MA|PI|CE|RN|PB|PE|AL|SE|BA|MG|ES|RJ|SP|PR|SC|RS|MS|MT|GO|DF) ?(\d{3}) KM", "$1-$2 KM")
      .adicionar(r"^(BR|RO|AC|AM|RR|PA|AP|TO|MA|PI|CE|RN|PB|PE|AL|SE|BA|MG|ES|RJ|SP|PR|SC|RS|MS|MT|GO|DF) ?(\d{3})$", "$1-$2")

      .adicionar(r"\bESTR\b\.?", "ESTRADA")

      // abreviacoes
      .adicionar(r"\bS\.? ?N\b\.?", "S/N")
      .adicionar(r"\bPRO?X\b\.?", "PROXIMO")
      // r"{\bESQ\b\.?}", "ESQUINA" # tem uns casos que ESQ = ESQUERDA, não ESQUINA - e.g. "LD ESQ", "A ESQ ENT XIQUITIM", "ULTIMA CASA LADO ESQ"
      .adicionar(r"\bLOTEAM?\b\.?", "LOTEAMENTO")
      .adicionar(r"\bCX\.? ?P(T|(OST(AL)?))?\b\.?", "CAIXA POSTAL")
      .adicionar(r"\bC\.? ?P(T|(OST(AL)?))?\b\.?", "CAIXA POSTAL") // separado pq nao tenho certeza. varios parecem ser caixa postal mesmo, mas tem bastante coisas como "A C CP 113". o que é esse A C/AC/etc que se repete antes?

      .adicionar(r"\bEDI?F?\b\.?", "EDIFICIO")
      .adicionar(r"\bN((O|\u00BA)?\.|\. (O|\u00BA)) (\d)", "NUMERO $4")
      .adicionar(r"\b(PX|PROXI)\b\.?", "PROXIMO") // vale tentar ajustar a preposição? tem varios "PX AO FINAL DA LINHA" mas tb tem "PX VIADUTO" e "PX A CX DAGUA"
      .adicionar(r"\bLJ\b\.?", "LOJA")
      .adicionar(r"\bLJS\b\.?", "LOJAS")
      .adicionar(r"\bSLS\b\.?", "SALAS")
      .adicionar(r"\bFAZ(EN?)?\b\.?", "FAZENDA")
      .adicionar(r"\bPCA\b\.?", "PRACA")
      .adicionar(r"\bP((A?R)?Q|QU?E)\b\.?", "PARQUE")
      .adicionar(r"\bL(RG|GO)\b\.?", "LARGO")
      .adicionar(r"\bSIT\b\.?", "SITIO")
      .adicionar(r"\bCHAC\b\.?", "CHACARA")
      .adicionar(r"\bT(RA?)?V\b\.?", "TRAVESSA") // "3º TRV"? "TRV WE 40"? "TV. WE 49"? "TV WE 07"? o que é esse WE?
      .adicionar(r"\bJAR DIM\b", "JARDIM")
      .adicionar(r"\bJ(D(I?M)?|A?RD|AR(DIN)?)\b\.?", "JARDIM") // tendo a achar que JD tb eh jardim, mas tem uns mais estranhos e.g. "JD WALDES". sera que poderia ser abreviacao de um nome tb?
      .adicionar(r"\bVL\b\.?", "VILA")
      .adicionar(r"\bNUC\b\.?", "NUCLEO")
      .adicionar(r"\bNUCLEO H(AB)?\b\.?", "NUCLEO HABITACIONAL")
      .adicionar(r"\bNUCLEO COL\b\.?", "NUCLEO COLONIAL")
      .adicionar_com_ignorar(r"\b(NUCLEO RES|N\.? RES(IDENCIAL)?)\b\.?", "NUCLEO RESIDENCIAL", r"\bS/N\.? RES(IDENCIAL)?")
      // FIXME: .adicionar(r"\b(NUCLEO RES|(?<!S/)N\.? RES(IDENCIAL)?)\b\.?", "NUCLEO RESIDENCIAL")
      .adicionar_com_ignorar(r"\b(NUCLEO RUR|N\.? RURAL)\b\.?", "NUCLEO RURAL", r"\b(S/N\.? RURAL)") // evita coisas como "S/N RURAL"
      // FIXME: .adicionar(r"\b(NUCLEO RUR|(?<!S/)N\.? RURAL)\b\.?", "NUCLEO RURAL") // evita coisas como "S/N RURAL"
      .adicionar(r"\bASSENT\b\.?", "ASSENTAMENTO")

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

      .adicionar(r"\bSTA\b\.?", "SANTA")
      .adicionar(r"\bSTO\b\.?", "SANTO")
      .adicionar(r"\bSRA\b\.?", "SENHORA")
      .adicionar(r"\bSR\b\.?", "SENHOR") // "Q SR LOTE 1"?

      .adicionar(r"\bS\.? (JOSE|JOAO)\b", "SAO $1")

      .adicionar(r"\bPROF\b\.?", "PROFESSOR")
      // r"{\bDR\b\.?}", "DOUTOR") // tem varios DR que nao parecem ser DOUTOR... e.g. "DR 16", "AREA DR", "1O DR DER DF"
      .adicionar(r"\bMONS\b\.?", "MONSENHOR")
      .adicionar(r"\bPRES(ID)?\b\.?", "PRESIDENTE")
      .adicionar(r"\bGOV\b\.?", "GOVERNADOR")
      .adicionar(r"\bVISC\b\.?", "VISCONDE")

      .adicionar(r"\b(\d+)\. (O|\u00BA)\b", "${1}O") // o que fazer com "6O ANDAR"? transformar em "6 ANDAR"? de forma geral, o que fazer com numeros ordinais
      .adicionar(r"\b(\d+)(O|\u00BA)\b\.", "${1}O")


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
    padronizador
}

// Em Rust, a constant é criada durante a compilação, então só posso chamar funções muito restritas
// quando uso `const`. Nesse caso,  como tenho uma construção complexa da struct `Padronizador`,
// tenho que usar static com inicialização Lazy (o LazyLock aqui previne condições de corrida).
static PADRONIZADOR: LazyLock<Padronizador> = LazyLock::new(criar_padronizador_complemento);

/// Padroniza uma string representando complementos de logradouros.
///
/// # Exemplo
/// ```
/// use enderecobr_rs::padronizar_complementos;
/// assert_eq!(padronizar_complementos("QD1 LT2 CS3"), "QUADRA 1 LOTE 2 CASA 3");
/// assert_eq!(padronizar_complementos("APTO. 405"), "APARTAMENTO 405");
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
pub fn padronizar_complementos(valor: &str) -> String {
    // Forma de obter a variável lazy
    let padronizador = &*PADRONIZADOR;
    padronizador
        .padronizar(&zerar_dado_faltante(valor))
        .to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn padroniza_corretamente() {
        assert_eq!(padronizar_complementos("qd 5 bl 7"), "QUADRA 5 BLOCO 7");
        assert_eq!(padronizar_complementos(""), "");
    }
}
