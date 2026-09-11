use enderecobr_rs::separar_endereco;
use polars::{
    error::{PolarsError, PolarsResult},
    frame::DataFrame,
    prelude::{
        col, sync_on_close::SyncOnCloseType, Column, DataType, Field, IntoColumn, LazyFrame,
        ParquetCompression, ParquetWriteOptions, PlPath, PlSmallStr, ScanArgsParquet, SinkOptions,
        StatisticsOptions,
    },
};

fn expandir_endereco(col: Column) -> Result<Column, PolarsError> {
    let enderecos_chunk = col.str().unwrap();

    let mut logr_vec = Vec::with_capacity(enderecos_chunk.len());
    let mut num_vec = Vec::with_capacity(enderecos_chunk.len());
    let mut comp_vec = Vec::with_capacity(enderecos_chunk.len());
    let mut loc_vec = Vec::with_capacity(enderecos_chunk.len());

    for opt in enderecos_chunk {
        if let Some(endereco_str) = opt {
            let endereco = separar_endereco(endereco_str).endereco_padronizado();

            logr_vec.push(endereco.logradouro);
            num_vec.push(endereco.numero);
            comp_vec.push(endereco.complemento);
            loc_vec.push(endereco.localidade);
        } else {
            logr_vec.push(None);
            num_vec.push(None);
            comp_vec.push(None);
            loc_vec.push(None);
        }
    }

    let df = DataFrame::new(vec![
        Column::new(PlSmallStr::from_str("logradouro"), logr_vec),
        Column::new(PlSmallStr::from_str("numero"), num_vec),
        Column::new(PlSmallStr::from_str("complemento"), comp_vec),
        Column::new(PlSmallStr::from_str("localidade"), loc_vec),
    ])
    .unwrap();

    PolarsResult::Ok(
        df.into_struct(PlSmallStr::from_str("endereco_processado"))
            .into_column(),
    )
}

fn main() {
    let mut args = std::env::args();
    let arquivo = args.next_back().unwrap();
    let path = PlPath::new(&arquivo);

    let _df = LazyFrame::scan_parquet(
        path,
        ScanArgsParquet {
            low_memory: false,
            parallel: polars::prelude::ParallelStrategy::RowGroups,
            use_statistics: true,
            rechunk: true,
            ..Default::default()
        },
    )
    .unwrap()
    .with_new_streaming(true)
    .select([col("DscEndereco")])
    // .limit(10000)
    .with_column(
        col("DscEndereco")
            .map(expandir_endereco, |_, _| {
                Ok(Field::new(
                    "endereco_processado".into(),
                    DataType::Struct(vec![
                        Field::new("logradouro".into(), DataType::String),
                        Field::new("numero".into(), DataType::String),
                        Field::new("complemento".into(), DataType::String),
                        Field::new("localidade".into(), DataType::String),
                    ]),
                ))
            })
            .alias("endereco_processado"),
    )
    .with_columns(vec![
        col("endereco_processado")
            .struct_()
            .field_by_name("logradouro")
            .alias("logradouro"),
        col("endereco_processado")
            .struct_()
            .field_by_name("numero")
            .alias("numero"),
        col("endereco_processado")
            .struct_()
            .field_by_name("complemento")
            .alias("complemento"),
        col("endereco_processado")
            .struct_()
            .field_by_name("localidade")
            .alias("localidade"),
    ])
    .drop(col("endereco_processado").into_selector().unwrap())
    .sink_parquet(
        polars::prelude::SinkTarget::Path(PlPath::new("./aaaa2.parquet")),
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

    if let Some(err) = _df.err() {
        println!("{}", err);
    };
}
