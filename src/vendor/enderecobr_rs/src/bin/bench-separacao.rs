use std::time::Instant;

use enderecobr_rs::separador_endereco::SeparadorEndereco;
use polars::{
    error::{PolarsError, PolarsResult},
    frame::DataFrame,
    prelude::{
        col, Column, DataType, Field, IntoColumn, LazyFrame, PlPath, PlSmallStr, ScanArgsParquet,
    },
};

struct Resultado {
    feats: u32,
    tagger: u32,
}

fn temporizar(separador: &SeparadorEndereco, texto: &str) -> Resultado {
    let mut tagger = separador.model.tagger().unwrap();
    let tokens = separador.extrator.tokenize(texto);

    let inicio_feats = Instant::now();
    let atributos = separador.tokens2attributes(&tokens);
    let duracao_feats = inicio_feats.elapsed();

    let inicio_tags = Instant::now();
    let _ = tagger.tag(&atributos).unwrap();
    let duracao_modelo = inicio_tags.elapsed();

    Resultado {
        feats: duracao_feats.subsec_micros(),
        tagger: duracao_modelo.subsec_micros(),
    }
}

fn expandir_endereco(col: Column, separador: &SeparadorEndereco) -> Result<Column, PolarsError> {
    let chunk = col.str().unwrap();

    let mut feats_vec = Vec::with_capacity(chunk.len());
    let mut tags_vec = Vec::with_capacity(chunk.len());

    for opt in chunk {
        if let Some(endereco_str) = opt {
            let res = temporizar(separador, endereco_str);

            feats_vec.push(res.feats);
            tags_vec.push(res.tagger);
        } else {
            feats_vec.push(0u32);
            tags_vec.push(0u32);
        }
    }

    let df = DataFrame::new(vec![
        Column::new(PlSmallStr::from_str("feats"), feats_vec),
        Column::new(PlSmallStr::from_str("tags"), tags_vec),
    ])
    .unwrap();

    PolarsResult::Ok(
        df.into_struct(PlSmallStr::from_str("tempos_endereco"))
            .into_column(),
    )
}

fn main() {
    let mut args = std::env::args();
    let arquivo = args.next_back().unwrap();
    let path = PlPath::new(&arquivo);

    let separador = SeparadorEndereco::new();

    let df = LazyFrame::scan_parquet(
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
    .limit(100000)
    .with_column(
        col("DscEndereco")
            .map(
                move |col_| expandir_endereco(col_, &separador),
                |_, _| {
                    Ok(Field::new(
                        "tempos_endereco".into(),
                        DataType::Struct(vec![
                            Field::new("feats".into(), DataType::UInt32),
                            Field::new("tags".into(), DataType::UInt32),
                        ]),
                    ))
                },
            )
            .alias("tempos_endereco"),
    )
    .with_columns(vec![
        col("tempos_endereco")
            .struct_()
            .field_by_name("tags")
            .alias("tags"),
        col("tempos_endereco")
            .struct_()
            .field_by_name("feats")
            .alias("feats"),
    ])
    .drop(col("tempos_endereco").into_selector().unwrap())
    .mean()
    .collect_with_engine(polars::prelude::Engine::Streaming);

    println!("{:?}", df);

    if let Some(err) = df.err() {
        println!("{}", err);
    };
}
