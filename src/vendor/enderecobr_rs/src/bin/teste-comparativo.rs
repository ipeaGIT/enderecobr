use std::num::NonZero;

use clap::Parser;
use enderecobr_rs::obter_padronizador_por_tipo;
use polars::prelude::{
    col, Column, CsvWriterOptions, DataType, Field, IntoColumn, LazyFrame, PlPath, ScanArgsParquet,
    SinkOptions, SinkTarget, StringChunked,
};

/// Utilitário que serve para comparar o resultado desta lib com os valores de um
/// arquivo parquet. Salva apenas as diferenças num arquivo `.csv` especificado.
#[derive(Debug, Parser)]
#[clap(author, version)]
struct Args {
    /// Caminho do arquivo PARQUET de entrada.
    arquivo_entrada: String,

    /// Caminho do arquivo CSV de saída.
    #[arg(short('o'), long, default_value = "./diff.csv")]
    arquivo_saida: String,

    /// Tipo do padronizar a ser usado. Vide função `obter_padronizador_por_tipo`.
    #[arg(short('t'), long, default_value = "logradouro")]
    tipo_padronizador: String,

    /// Nome do campo a ser processado.
    #[arg(short('b'), long, default_value = "logradouro")]
    campo_bruto: String,

    /// Nome do campo a ser usado como valor de referência.
    #[arg(short('r'), long, default_value = "logradouro_padr")]
    campo_referencia: String,
}

fn main() {
    let args = Args::parse();

    let padronizador = obter_padronizador_por_tipo(&args.tipo_padronizador).unwrap();

    let res = LazyFrame::scan_parquet(
        PlPath::from_string(args.arquivo_entrada),
        ScanArgsParquet {
            low_memory: true,
            parallel: polars::prelude::ParallelStrategy::RowGroups,
            use_statistics: false,
            rechunk: true,
            ..Default::default()
        },
    )
    .unwrap()
    .with_new_streaming(true)
    .select([col(&args.campo_bruto), col(&args.campo_referencia)])
    .with_column(
        col(&args.campo_bruto)
            .map(
                move |campo: Column| {
                    let iterador = campo.str().unwrap().iter().map(|opt| opt.map(padronizador));
                    let col = StringChunked::from_iter(iterador).into_column();
                    Ok(col)
                },
                |_, _| Ok(Field::new("campo_processado".into(), DataType::String)),
            )
            .alias("campo_processado"),
    )
    .filter(
        col("campo_processado")
            .eq(col(&args.campo_referencia))
            .not(),
    )
    .unique(None, polars::frame::UniqueKeepStrategy::First)
    .sink_csv(
        SinkTarget::Path(PlPath::new(&args.arquivo_saida)),
        CsvWriterOptions {
            batch_size: NonZero::new(100).unwrap(),
            ..Default::default()
        },
        None,
        SinkOptions {
            ..Default::default()
        },
    )
    .unwrap()
    .collect_with_engine(polars::prelude::Engine::Streaming);

    if let Some(err) = res.err() {
        println!("{}", err);
    };
}
