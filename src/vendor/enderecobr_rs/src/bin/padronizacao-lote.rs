use std::sync::Arc;

use clap::Parser;
use enderecobr_rs::{
    padronizar_bairros, padronizar_cep_leniente, padronizar_complementos,
    padronizar_estados_para_nome, padronizar_logradouros, padronizar_municipios,
    padronizar_numeros, padronizar_tipo_logradouro,
};
use polars::prelude::{
    col, sync_on_close::SyncOnCloseType, Column, DataType, Field, IntoColumn, LazyFrame,
    ParquetCompression, ParquetWriteOptions, PlPath, ScanArgsParquet, Schema, SinkOptions,
    StatisticsOptions, StringChunked,
};

#[derive(Debug, Clone)]
enum TipoCampo {
    Logradouro,
    TipoLogradouro,
    Numero,
    Complemento,
    Localidade,
    Municipio,
    Estado,
    Cep,
}

#[derive(Debug, Clone)]
struct EspecificacaoCampo {
    tipo: TipoCampo,
    origem: String,
    destino: String,
}

fn identificar_campo(tipo_campo: &str) -> Result<TipoCampo, String> {
    match tipo_campo.to_lowercase().as_str() {
        "logradouro" | "logr" => Ok(TipoCampo::Logradouro),
        "tipo_logradouro" | "tipo_logr" => Ok(TipoCampo::TipoLogradouro),
        "numero" | "num" => Ok(TipoCampo::Numero),
        "complemento" | "comp" => Ok(TipoCampo::Complemento),
        "bairro" | "localidade" | "loc" => Ok(TipoCampo::Localidade),
        "estado" | "uf" => Ok(TipoCampo::Estado),
        "municipio" | "mun" => Ok(TipoCampo::Municipio),
        "cep" => Ok(TipoCampo::Cep),
        _ => Err(format!("Tipo desconhecido: {}", tipo_campo)),
    }
}

fn parsear(s: &str) -> Result<EspecificacaoCampo, String> {
    let parts: Vec<_> = s.split(':').collect();
    if parts.len() != 3 {
        return Err("Formato esperado: tipo:src:dst".into());
    }

    Ok(EspecificacaoCampo {
        tipo: identificar_campo(parts[0]).unwrap(),
        origem: parts[1].to_string(),
        destino: parts[2].to_string(),
    })
}

fn obter_padronizador(tipo: &TipoCampo) -> fn(&str) -> String {
    match tipo {
        TipoCampo::Logradouro => padronizar_logradouros,
        TipoCampo::TipoLogradouro => padronizar_tipo_logradouro,
        TipoCampo::Numero => padronizar_numeros,
        TipoCampo::Complemento => padronizar_complementos,
        TipoCampo::Localidade => padronizar_bairros,
        TipoCampo::Municipio => padronizar_municipios,
        TipoCampo::Estado => |x| padronizar_estados_para_nome(x).to_string(),
        TipoCampo::Cep => padronizar_cep_leniente,
    }
}

/// Utilitário que serve para processar um arquivo parquet com as funções do enderecobr_rs.
#[derive(Debug, Parser)]
#[clap(author, version)]
struct Args {
    /// Caminho do arquivo PARQUET de entrada.
    arquivo_entrada: String,

    /// Caminho do arquivo PARQUET de saída.
    #[arg(short('o'), long, default_value = "./resultado.parquet")]
    arquivo_saida: String,

    /// Se deve manter todos campos
    #[arg(short('M'), long, default_value = "false")]
    manter_todos: bool,

    /// Campos que devem ser mantidos
    #[arg(short('m'), long, num_args = 1..,)]
    manter: Vec<String>,

    /// Limite de linhas a serem processadas. Usado para execuções de teste.
    #[arg(short('n'), long)]
    limite: Option<u32>,

    /// Especificação dos campos a serem processados.
    #[arg(
        short('c'),
        long = "campos",
        value_name = "TIPO_CAMPO:CAMPO_ORIGEM:CAMPO_DESTINO",
        num_args = 1..,
        value_parser = parsear
    )]
    campos: Vec<EspecificacaoCampo>,
}

fn processar_campo(df: LazyFrame, campo: &EspecificacaoCampo, schema: &Arc<Schema>) -> LazyFrame {
    let padronizador = obter_padronizador(&campo.tipo);
    let field = Field::new(campo.destino.as_str().into(), DataType::String);

    // Verifica se o campo é float para forçar um typecast antes
    // para int e então fazer o cast final para string
    let mut _df = match schema.get(&campo.origem) {
        Some(DataType::Float32) | Some(DataType::Float64) => {
            df.with_column(col(&campo.origem).cast(DataType::Int32))
        }
        _ => df,
    };

    _df.with_column(
        col(&campo.origem)
            .cast(DataType::String)
            .map(
                move |coluna: Column| {
                    let iterador = coluna
                        .str()
                        .unwrap()
                        .iter()
                        .map(|opt| opt.map(padronizador));
                    let nova_coluna = StringChunked::from_iter(iterador).into_column();
                    Ok(nova_coluna)
                },
                move |_, _| Ok(field.clone()),
            )
            .alias(&campo.destino),
    )
}

fn main() {
    let args = Args::parse();
    // println!("{:#?}", args);

    let mut df = LazyFrame::scan_parquet(
        PlPath::new(&args.arquivo_entrada),
        ScanArgsParquet {
            low_memory: true,
            parallel: polars::prelude::ParallelStrategy::RowGroups,
            use_statistics: true,
            rechunk: true,
            ..Default::default()
        },
    )
    .unwrap()
    .with_new_streaming(true);

    if let Some(limite) = args.limite {
        df = df.limit(limite);
    }

    let schema = df.collect_schema().unwrap();
    for campo in &args.campos {
        df = processar_campo(df, campo, &schema);
    }

    if !args.manter_todos {
        let colunas_finais: Vec<_> = args
            .campos
            .iter()
            // Colunas criadas pela execução atual
            .map(|c| c.destino.as_str())
            // Colunas que foram solicitadas para serem mantidas.
            .chain(args.manter.iter().map(|c| c.as_str()))
            .map(col)
            .collect();

        df = df.select(colunas_finais);
    }

    let resultado = df
        .sink_parquet(
            polars::prelude::SinkTarget::Path(PlPath::new(&args.arquivo_saida)),
            ParquetWriteOptions {
                compression: ParquetCompression::Zstd(None),
                statistics: StatisticsOptions {
                    min_value: true,
                    max_value: true,
                    distinct_count: true,
                    null_count: true,
                },
                row_group_size: Some(10_000),
                data_page_size: Some(1024 * 1024),
                ..Default::default()
            },
            None,
            SinkOptions {
                sync_on_close: SyncOnCloseType::All,
                maintain_order: false,
                ..Default::default()
            },
        )
        .unwrap()
        .collect_with_engine(polars::prelude::Engine::Streaming);

    match resultado {
        Ok(_) => println!(
            "Arquivo \"{}\" foi processado com sucesso e salvo em \"{}\".",
            args.arquivo_entrada, args.arquivo_saida
        ),
        Err(err) => println!("{}", err),
    }
}
