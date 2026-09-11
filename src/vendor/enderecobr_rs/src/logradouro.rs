use std::sync::LazyLock;

use crate::{dado_faltante::zerar_dado_faltante, Padronizador};

pub fn criar_padronizador_logradouros() -> Padronizador {
    let mut padronizador = Padronizador::default();
    padronizador
        // Substituição nova
        .adicionar(r"\s{2,}", " ")

        // Pontuação
        .adicionar(r"\.\.+", ".") // ponto repetido
        .adicionar(r",,+", ",")   // virgula repetida
        .adicionar(r"(\d)\.(\d{3})", "$1$2") // remoção de separador de milhar
        .adicionar(r"\.([^ ,])", ". $1") // garantir que haja um espaço depois dos pontos
        .adicionar(r",([^ ])", ", $1") // garantir que haja um espaço depois das virgulas
        .adicionar(r" \.", ".") // garantir que não haja um espaço antes dos pontos
        .adicionar(r" ," , ",") // garantir que não haja um espaço antes dos pontos
        .adicionar(r"\.$", "") // remoção de ponto final
        .adicionar(r"\\", "/") // Contra-barra \ => Barra /

        // Sinalização
        .adicionar("\"", "'") // existem ocorrencias em que aspas duplas sao usadas para se referir a um logradouro/quadra com nome relativamente ambiguo - e.g. RUA \"A\", 26. isso pode causar um problema quando lido com o data.table: https://github.com/Rdatatable/data.table/issues/4779. por enquanto, substituindo por aspas simples. Depois a gente pode ver o que fazer com as aspas simples rs.

        // Valores non-sense
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

        // Logradouro começa com OUTROS: Caso de erro comum
        .adicionar(r"^OUTROS\s", "")

        // tipos de logradouro
        .adicionar(r"^RU?\b(\.|,)?", "RUA") // R. AZUL -> RUA AZUL
        .adicionar(r"^(RUA|RODOVIA|ROD(\.|,)?) (RUA|RU?)\b(\.|,)?", "RUA") // RUA R. AZUL -> RUA AZUL
        .adicionar(r"^RUA\b(-|,|\.) *", "RUA ") // R-AZUL -> RUA AZUL

        .adicionar(r"^(ROD|RDV)\b(\.|,)?", "RODOVIA")
        .adicionar(r"^(RODOVIA|RUA) (RODOVIA|ROD|RDV)\b(\.|,)?", "RODOVIA")
        .adicionar(r"^RODOVIA\b(-|,|\.) *", "RODOVIA ")

        // outros pra rodovia: "RO", "RO D", "ROV"

        .adicionar(r"^AV(E|N|D|DA|I)?\b(\.|,)?", "AVENIDA")
        .adicionar(r"^(AVENIDA|RUA|RODOVIA) (AVENIDA|AV(E|N|D|DA|I)?)\b(\.|,)?", "AVENIDA")
        .adicionar(r"^AVENIDA\b(-|,|\.) *", "AVENIDA ")

        // EST pode ser estancia ou estrada. será que deveríamos assumir que é estrada mesmo?
        .adicionar(r"^(ESTR?|ETR)\b(\.|,)?", "ESTRADA")
        .adicionar(r"^(ESTRADA|RUA|RODOVIA) (ESTRADA|ESTR?|ETR)\b(\.|,)?", "ESTRADA")
        .adicionar(r"^ESTRADA\b(-|,|\.) *", "ESTRADA ")

        .adicionar(r"^(PCA?|PRC)\b(\.|,)?", "PRACA")
        .adicionar(r"^(PRACA|RUA|RODOVIA) (PRACA|PCA?|PRC)\b(\.|,)?", "PRACA")
        .adicionar(r"^PRACA\b(-|,|\.) *", "PRACA ")

        .adicionar(r"^BE?CO?\b(\.|,)?", "BECO")
        .adicionar(r"^(BECO|RUA|RODOVIA) BE?CO?\b(\.|,)?", "BECO")
        .adicionar(r"^BE?CO?\b(-|,|\.) *", "BECO ")

        .adicionar(r"^(TV|TR|TRV|TRVS|TRAV?)\b(\.|,)?", "TRAVESSA") // tem varios casos de TR tambem, mas varios desses sao abreviacao de TRECHO, entao eh dificil fazer uma generalizacao
        .adicionar(r"^(TRAVESSA|RODOVIA) (TRAVESSA|TV|TRV|TRAV?)\b(\.|,)?", "TRAVESSA") // nao botei RUA nas opcoes iniciais porque tem varios ruas que realmente sao RUA TRAVESSA ...
        .adicionar(r"^TRAVESSA\b(-|,|\.) *", "TRAVESSA ")
        .adicionar(r"^(TRAVESSA|RUA|RODOVIA) (TRAVESSA|TV|TRV|TRAV?)\b- *", "TRAVESSA ") // aqui ja acho que faz sentido botar o RUA porque so da match com padroes como RUA TRAVESSA-1

        .adicionar(r"^P((A?R)?Q|QU?E)\b(\.|,)?", "PARQUE")
        .adicionar(r"^(PARQUE|RODOVIA) (PARQUE|P((A?R)?Q|QU?E))\b(\.|,)?", "PARQUE") // mesmo caso de travessa
        .adicionar(r"^PARQUE\b(-|,|\.) *", "PARQUE ")
        .adicionar(r"^(PARQUE|RUA|RODOVIA) (PARQUE|P((A?R)?Q|QU?E))\b- *", "PARQUE ") // mesmo caso de travessa

        .adicionar(r"^ALA?\b(\.|,)?", "ALAMEDA")
        .adicionar(r"^ALAMEDA (ALAMEDA|ALA?)\b(\.|,)?", "ALAMEDA") // mesmo caso de travessa
        .adicionar(r"^RODOVIA (ALAMEDA|ALA)\b(\.|,)?", "ALAMEDA") // RODOVIA precisa ser separado porque nesse caso nao podemos mudar RODOVIA AL pra ALAMEDA, ja que pode ser uma rodovia estadual de alagoas
        .adicionar(r"^ALAMEDA\b(-|,|\.) *", "ALAMEDA ")
        .adicionar(r"^(ALAMEDA|RUA) (ALAMEDA|ALA?)\b- *", "ALAMEDA ") // mesmo caso de travessa
        .adicionar(r"^RODOVIA (ALAMEDA|ALA)\b- *", "ALAMEDA ") // mesmo caso acima

        .adicionar(r"^LOT\b(\.|,)?", "LOTEAMENTO")
        .adicionar(r"^(LOTEAMENTO|RUA|RODOVIA) LOT\b(\.|,)?", "LOTEAMENTO")
        .adicionar(r"^LOTEAMENTO?\b(-|,|\.) *", "LOTEAMENTO ")

        .adicionar(r"^LOC\b(\.|,)?", "LOCALIDADE")
        .adicionar(r"^(LOCALIDADE|RUA) LOC\b(\.|,)?", "LOCALIDADE")
        .adicionar(r"^LOCALIDADE?\b(-|,|\.) *", "LOCALIDADE ")

        .adicionar(r"^VL\b(\.|,)?", "VILA")
        .adicionar(r"^VILA VILA\b(\.|,)?", "VILA")
        .adicionar(r"^VILA?\b(-|,|\.) *", "VILA ")

        .adicionar(r"^LAD\b(\.|,)?", "LADEIRA")
        .adicionar(r"^LADEIRA LADEIRA\b(\.|,)?", "LADEIRA")
        .adicionar(r"^LADEIRA?\b(-|,|\.) *", "LADEIRA ")

        .adicionar(r"^SER\b(\.|,)?", "SERRA")
        .adicionar(r"^(MR|MRR|MO|MOR)\b(\.|,)?", "MORRO")
        .adicionar(r"^(LD|LAD|LDR)\b(\.|,)?", "LADEIRA")
        .adicionar(r"^(CPO)\b(\.|,)?", "CAMPO")
        .adicionar(r"^(FV|FAV)\b(\.|,)?", "FAVELA")
        .adicionar(r"^(CAN)\b(\.|,)?", "CANAL")
        .adicionar(r"^(CB|CAB)\b(\.|,)?", "CABO")
        .adicionar(r"^(VIAD|VDT)\b(\.|,)?", "VIADUTO")
        .adicionar(r"^(PTE|PNT)\b(\.|,)?", "PONTE")
        .adicionar(r"^(ESC)\b(\.|,)?", "ESCOLA")
        .adicionar(r"^(TUN)\b(\.|,)?", "TUNEL")

        .adicionar(r"^DT\b(\.|,)?", "DISTRITO")
        .adicionar(r"\bDISTR?\b\.?", "DISTRITO")
        .adicionar(r"^DISTRITO DISTRITO\b(\.|,)?", "DISTRITO")
        .adicionar(r"^DISTRITO?\b(-|,|\.) *", "DISTRITO ")

        .adicionar(r"^NUC\b(\.|,)?", "NUCLEO")
        .adicionar(r"^NUCLEO NUCLEO\b(\.|,)?", "NUCLEO")
        .adicionar(r"^NUCLEO?\b(-|,|\.) *", "NUCLEO ")

        .adicionar(r"^L(RG|GO)\b(\.|,)?", "LARGO")
        .adicionar(r"^LARGO L(RG|GO)\b(\.|,)?", "LARGO")
        .adicionar(r"^LARGO?\b(-|,|\.) *", "LARGO ")

        .adicionar(r"\b(LN)\.?\b", "LINHA")
        .adicionar(r"\b(GL|GB)\.?\b", "GLEBA")

        // estabelecimentos
        .adicionar(r"^AER(OP)?\b(\.|,)?", "AEROPORTO") // sera que vale? tem uns casos estranhos aqui, e.g. "AER GUANANDY, 1", "AER WASHINGTON LUIZ, 3318"
        .adicionar(r"^AEROPORTO (AEROPORTO|AER)\b(\.|,)?", "AEROPORTO")
        .adicionar(r"^AEROPORTO INT(ERN?)?\b(\.|,)?", "AEROPORTO INTERNACIONAL")

        .adicionar(r"^COND\b(\.|,)?", "CONDOMINIO")
        .adicionar(r"^(CONDOMINIO|RODOVIA) (CONDOMINIO|COND)\b(\.|,)?", "CONDOMINIO")

        .adicionar(r"^FAZ(EN?)?\b\.?", "FAZENDA")
        .adicionar(r"^(FAZENDA|RODOVIA) (FAZ(EN?)?|FAZENDA)\b(\.|,)?", "FAZENDA")
        .adicionar(r"\bFAZ(EN?)?\b\.?", "FAZENDA")

        .adicionar(r"^COL\b\.?", "COLONIA")
        .adicionar(r"\bCOLONIA AGRI?C?\b\.?", "COLONIA AGRICOLA")

        // títulos
        .adicionar(r"\bSTA\b\.?", "SANTA")
        .adicionar(r"\bSTO\b\.?", "SANTO")
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

        .adicionar(r"\bALM?TE\b\.?", "ALMIRANTE")
        .adicionar(r"\bMAL\b\.?", "MARECHAL")
        .adicionar(r"\b(GEN|GAL)\b\.?", "GENERAL")
        .adicionar(r"\b(SGTO?|SARG)\b\.?", "SARGENTO")
        .adicionar(r"\b(PRIMEIRO|PRIM|1)\.? SARGENTO\b", "PRIMEIRO-SARGENTO")
        .adicionar(r"\b(SEGUNDO|SEG|2)\.? SARGENTO\b", "SEGUNDO-SARGENTO")
        .adicionar(r"\b(TERCEIRO|TERC|3)\.? SARGENTO\b", "TERCEIRO-SARGENTO")
        .adicionar(r"\bCEL\b\.?", "CORONEL")
        .adicionar(r"\bBRIG\b\.?", "BRIGADEIRO")
        .adicionar(r"\bTEN\b\.?", "TENENTE")
        .adicionar(r"\bTENENTE CORONEL\b", "TENENTE-CORONEL")
        .adicionar(r"\bTENENTE BRIGADEIRO\b", "TENENTE-BRIGADEIRO")
        .adicionar(r"\bTENENTE AVIADOR\b", "TENENTE-AVIADOR")
        .adicionar(r"\bSUB TENENTE\b", "SUBTENENTE")
        .adicionar(r"\b(PRIMEIRO|PRIM\.?) TENENTE\b", "PRIMEIRO-TENENTE")
        .adicionar(r"\b(SEGUNDO|SEG\.?) TENENTE\b", "SEGUNDO-TENENTE")
        .adicionar(r"\bSOLD\b\.?", "SOLDADO")
        .adicionar(r"\bMAJ\b\.?", "MAJOR")

        .adicionar(r"\bPROF\b\.?", "PROFESSOR")
        .adicionar(r"\bPROFA\b\.?", "PROFESSORA")
        .adicionar(r"\bDR\b\.?", "DOUTOR")
        .adicionar(r"\bDRA\b\.?", "DOUTORA")
        .adicionar(r"\bENG\b\.?", "ENGENHEIRO")
        .adicionar(r"\bENGA\b\.?", "ENGENHEIRA")
        .adicionar(r"\bPD?E\b\.", "PADRE") // PE pode ser só pe mesmo, então forcando o PE. (com ponto) pra ser PADRE
        .adicionar(r"\bMONS\b\.?", "MONSENHOR")

        // Erros de digitação comuns para presidente. => Sem testes
        .adicionar(r"\b(PREISI|PREZI|PRSI|PERSI|PESI)DENTE\b", "PRESIDENTE")

        .adicionar(r"\bPRES(ID)?\b\.?", "PRESIDENTE")
        .adicionar(r"\bGOV\b\.?", "GOVERNADOR")
        .adicionar(r"\bSEN\b\.?", "SENADOR")
        .adicionar(r"\bPREF\b\.?", "PREFEITO")
        .adicionar(r"\bDEP\b\.?", "DEPUTADO")
        // PS: Regex original tinha um look-ahead (?!$) que o motor do Rust não permite.
        // Troquei ele por um espaço em branco para garantir que não é no fim da string.
        .adicionar(r"\bVER\b\.?(.)", "VEREADOR$1")
        .adicionar(r"\bESPL?\.? (DOS )?MIN(IST(ERIOS?)?)?\b\.?", "ESPLANADA DOS MINISTERIOS")
        // PS: Regex original tinha um look-ahead (?!$) que o motor do Rust não permite.
        // Troquei ele por um espaço em branco para garantir que não é no fim da string.
        .adicionar(r"\bMIN\b\.?(.)", "MINISTRO$1")

        // Abreviações
        .adicionar(r"\bJAR DIM\b", "JARDIM")
        .adicionar(r"\bJ(D(I?M)?|A?RD|AR(DIN)?)\b\.?", "JARDIM")
        .adicionar(r"\bUNID\b\.?", "UNIDADE")
        .adicionar(r"\b(CJ|CONJ)\b\.?", "CONJUNTO")
        .adicionar(r"\bLT\b\.?", "LOTE")
        .adicionar(r"\bLTS\b\.?", "LOTES")
        .adicionar(r"\bQDA?\b\.?", "QUADRA")
        .adicionar(r"\bLJ\b\.?", "LOJA")
        .adicionar(r"\bLJS\b\.?", "LOJAS")
        .adicionar(r"\bAPTO?\b\.?", "APARTAMENTO")
        .adicionar(r"\bBL\b\.?", "BLOCO")
        .adicionar(r"\bSLS\b\.?", "SALAS")
        .adicionar(r"\bEDI?F\.? EMP\b\.?", "EDIFICIO EMPRESARIAL")
        .adicionar(r"\bEDI?F\b\.?", "EDIFICIO")
        .adicionar(r"\bCOND\b\.?", "CONDOMINIO") // apareceu antes mas como tipo de logradouro
        .adicionar(r"\bKM\b\.", "KM")
        .adicionar(r"\bS\.? ?N\b\.?", "S/N")
        .adicionar(r"(\d)\.( O)? A(ND(AR)?)?\b\.?", "$1 ANDAR")
        .adicionar(r"(\d)\.( O)? ANDARES\b", "$1 ANDARES")
        .adicionar(r"(\d)( O)? AND\b\.?", "$1 ANDAR")
        .adicionar(r"\bCX\.? ?P(T|(OST(AL)?))?\b\.?", "CAIXA POSTAL")
        .adicionar(r"\bC\.? ?P(T|(OST(AL)?))?\b\.?", "CAIXA POSTAL")
        // SL pode ser sobreloja ou sala

        // interseção entre nomes e títulos
        //   - D. pode ser muita coisa (e.g. dom vs dona), então não da pra
        //   simplesmente assumir que vai ser um valor especifico, so no contexto
        //   - MAR pode ser realmente só mar ou uma abreviação pra marechal
        .adicionar(r"\bD\b\.? (PEDRO|JOAO|HENRIQUE)", "DOM $1")
        .adicionar(r"\bI(NF)?\.? DOM\b", "INFANTE DOM")
        .adicionar(r"\bMAR\b\.? ((CARMONA|JOFRE|HERMES|MALLET|DEODORO|MARCIANO|OTAVIO|FLORIANO|BARBACENA|FIUZA|MASCARENHAS|MASCARENHA|TITO|FONTENELLE|XAVIER|BITENCOURT|BITTENCOURT|CRAVEIRO|OLIMPO|CANDIDO|RONDON|HENRIQUE|MIGUEL|JUAREZ|FONTENELE|FONTENELLE|DEADORO|HASTIMPHILO|NIEMEYER|JOSE|LINO|MANOEL|HUMB?|HUMBERTO|ARTHUR|ANTONIO|NOBREGA|CASTELO|DEODORA)\b)", "MARECHAL $1")

        // nomes
        .adicionar(r"\b(GETULHO|JETULHO|JETULIO|JETULHO|GET|JET)\.? VARGAS\b", "GETULIO VARGAS")
        .adicionar(r"\b(J(U[A-Z]*)?)\.? (K(U[A-Z]*)?)\b\.?", "JUSCELINO KUBITSCHEK")

        // expressões hifenizadas ou não
        //   - beira-mar deveria ter pelo novo acordo ortográfico, mas a grafia da
        //   grande maioria das ruas (se não todas, não tenho certeza) eh beira
        //   mar, sem hífen
        .adicionar(r"\bBEIRA-MAR\b", "BEIRA MAR")

        // rodovias
        .adicionar(r"\b(RD|RODOVIA|BR\.?|RODOVIA BR\.?) CENTO D?E (DESESSEIS|DESESEIS|DEZESSEIS|DEZESEIS)\b", "RODOVIA BR-116")
        .adicionar(r"\b(RODOVIA|BR\.?|RODOVIA BR\.?) CENTO D?E H?UM\b", "RODOVIA BR-101")
        // será que essas duas de baixo valem?
        .adicionar(r"\bBR\.? ?(\d{3})", "BR-$1")
        // essa aqui é complicada... AL, AP, SE, entre outras, são siglas que podem aparecer sem serem rodovias
        .adicionar(r"\b(RO|AC|AM|RR|PA|AP|TO|MA|PI|CE|RN|PB|PE|AL|SE|BA|MG|ES|RJ|SP|PR|SC|RS|MS|MT|GO|DF) ?(\d{3})", "$1-$2")

        // 0 à esquerda
        .adicionar(r"(^| )0+(\d+)\b", "$1$2")

        // correções de problemas ocasionados pelos filtros acima
        .adicionar(r"\bTENENTE SHI\b", "TEN SHI")
        .adicionar(r"\bHO SHI MINISTRO\b", "HO SHI MIN")

        // Unifica a grafia, mesmo que o nome oficial realmente seja diferente.
        .adicionar(r"\bCAMPOS? H?ELI(Z|S)I?E?(O|U)(S|Z)?\b", "CAMPOS ELISIOS")

        // datas

        // PS: Mudei todos os JAN(?!EIRO) para JAN(EIRO)?
        // PS: Mudei todos os DE? para ( DE)?
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

    // ALM é um caso complicado, pode ser alameda ou almirante. Inclusive no mesmo endereço podem aparecer os dois rs

    padronizador.preparar();
    padronizador
}

// Em Rust, a constant é criada durante a compilação, então só posso chamar funções muito restritas
// quando uso `const`. Nesse caso,  como tenho uma construção complexa da struct `Padronizador`,
// tenho que usar static com inicialização Lazy (o LazyLock aqui previne condições de corrida).
static PADRONIZADOR: LazyLock<Padronizador> = LazyLock::new(criar_padronizador_logradouros);

/// Padroniza uma string representando logradouros de municípios brasileiros.
///
/// # Exemplo
/// ```
/// use enderecobr_rs::padronizar_logradouros;
/// assert_eq!(padronizar_logradouros("r. gen.. glicério"), "RUA GENERAL GLICERIO");
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
pub fn padronizar_logradouros(valor: &str) -> String {
    // Forma de obter a variável lazy
    let padronizador = &*PADRONIZADOR;
    padronizador.padronizar(&zerar_dado_faltante(valor))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn padroniza_corretamente() {
        // Comentário original:
        // complicado fazer um teste pra cada uma das regexs usadas. testando só um basiquinho da manipulação,
        // depois pensamos melhor se vale a pena fazer um teste pra cada regex ou não
        assert_eq!(
            padronizar_logradouros("r. gen.. glicério"),
            "RUA GENERAL GLICERIO"
        );
        assert_eq!(padronizar_logradouros(""), "");
    }
}
