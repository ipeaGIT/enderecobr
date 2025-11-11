use enderecobr_rs::{
    padronizar_bairros, padronizar_cep, padronizar_cep_numerico, padronizar_complementos,
    padronizar_estados_para_nome, padronizar_estados_para_sigla, padronizar_logradouros,
    padronizar_municipios, padronizar_numeros, padronizar_tipo_logradouro,
};
use extendr_api::prelude::*;
use extendr_api::ToVectorValue;
use std::collections::HashMap;

/// Função utilitária interna usada para fazer o tratamento em comum
/// dos dados vindos do R para os casos de string.
fn mapear_com_cache<F>(x: Strings, fun: F) -> Strings
where
    F: Fn(&str) -> String,
{
    let mut cache = HashMap::<&str, Rstr>::new();

    x.iter()
        .map(|xi| match xi.is_na() {
            true => Rstr::na(),
            false => {
                let chave = xi.as_str();
                if let Some(valor_cacheado) = cache.get(&chave) {
                    return valor_cacheado.clone();
                }
                let res_fun = fun(chave);
                let res_r = if res_fun.is_empty() {
                    Rstr::na()
                } else {
                    Rstr::from(res_fun)
                };
                cache.insert(chave, res_r.clone());
                res_r
            }
        })
        .collect::<Strings>()
}

#[extendr]
pub fn padronizar_bairros_rs(x: Strings) -> Strings {
    mapear_com_cache(x, padronizar_bairros)
}

#[extendr]
pub fn padronizar_complementos_rs(x: Strings) -> Strings {
    mapear_com_cache(x, padronizar_complementos)
}

#[extendr]
pub fn padronizar_logradouros_rs(x: Strings) -> Strings {
    mapear_com_cache(x, padronizar_logradouros)
}

#[extendr]
pub fn padronizar_tipos_de_logradouros_rs(x: Strings) -> Strings {
    mapear_com_cache(x, padronizar_tipo_logradouro)
}

#[extendr]
pub fn padronizar_municipios_rs(x: Strings) -> Strings {
    mapear_com_cache(x, padronizar_municipios)
}

#[extendr]
pub fn padronizar_ceps_rs(x: Strings) -> Strings {
    mapear_com_cache(x, |cep| match padronizar_cep(cep) {
        Ok(val) => val,
        Err(val) => format!("Erro: {}", val),
    })
}

#[extendr]
pub fn padronizar_ceps_numericos_rs(x: Integers) -> Strings {
    x.iter()
        .map(|xi| match xi.is_na() {
            true => Rstr::na(),
            false => match padronizar_cep_numerico(xi.to_integer()) {
                Ok(cep) => Rstr::from(cep),
                Err(err) => Rstr::from(format!("Erro: {}", err.to_string())),
            },
        })
        .collect::<Strings>()
}

#[extendr]
pub fn padronizar_numeros_rs(x: Strings) -> Strings {
    mapear_com_cache(x, padronizar_numeros)
}

// Por algum motivo, na documentação consta para usar #[extendr(default = "value)],
// porém ele só está aceitando o método supostamente depreciado #[default = "value"].
// https://github.com/extendr/extendr/pull/952/files

#[extendr]
pub fn padronizar_estados_rs(x: Strings, #[default = "'por_extenso'"] formato: Robj) -> Strings {
    if formato.as_str() == Some("sigla") {
        return mapear_com_cache(x, padronizar_estados_para_sigla);
    } else {
        return mapear_com_cache(x, padronizar_estados_para_nome);
    }
}

extendr_module! {
    mod enderecobr;
    fn padronizar_bairros_rs;
    fn padronizar_complementos_rs;
    fn padronizar_logradouros_rs;
    fn padronizar_tipos_de_logradouros_rs;
    fn padronizar_municipios_rs;
    fn padronizar_numeros_rs;
    fn padronizar_estados_rs;
    fn padronizar_ceps_rs;
    fn padronizar_ceps_numericos_rs;
}
