use arrow::array::{Array, StringArray};
use parquet::arrow::arrow_reader::ParquetRecordBatchReaderBuilder;
use std::fs::File;
use std::path::Path;

/// Erro customizado para validação de CEP
#[derive(Debug)]
enum CepError {
    ContemLetras(Vec<usize>),
    MuitosDigitos(Vec<usize>),
}

impl std::fmt::Display for CepError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            CepError::ContemLetras(indices) => {
                write!(f, "CEP não deve conter letras. Elementos com índices {:?} possuem letras.", indices)
            }
            CepError::MuitosDigitos(indices) => {
                write!(f, "CEP não deve conter mais que 8 dígitos. Elementos com índices {:?} possuem mais que 8 dígitos após padronização.", indices)
            }
        }
    }
}

impl std::error::Error for CepError {}

/// Padroniza um único CEP
///
/// Operações realizadas:
/// - Remove espaços, pontos e vírgulas
/// - Adiciona zeros à esquerda se necessário
/// - Adiciona hífen separando radical (5 primeiros) do sufixo (3 últimos)
fn padronizar_cep(cep: &str) -> Result<String, Box<dyn std::error::Error>> {
    // Se vazio ou apenas espaços, retorna erro
    if cep.trim().is_empty() {
        return Ok(String::new());
    }
    
    // Verifica se contém letras
    if cep.chars().any(|c| c.is_alphabetic()) {
        return Err(Box::new(CepError::ContemLetras(vec![0])));
    }
    
    // Remove pontos, vírgulas e espaços
    let limpo = cep
        .chars()
        .filter(|c| c.is_numeric() || *c == '-')
        .collect::<String>();
    
    // Remove hífen temporariamente para contar dígitos
    let apenas_numeros = limpo.replace("-", "");
    
    // Verifica se tem mais de 8 dígitos
    if apenas_numeros.len() > 8 {
        return Err(Box::new(CepError::MuitosDigitos(vec![0])));
    }
    
    // Adiciona zeros à esquerda se necessário
    let padded = format!("{:0>8}", apenas_numeros);
    
    // Adiciona hífen no formato XXXXX-XXX
    let formatado = format!("{}-{}", &padded[..5], &padded[5..]);
    
    Ok(formatado)
}

/// Padroniza um vetor de CEPs
fn padronizar_ceps(ceps: Vec<Option<String>>) -> Vec<Option<String>> {
    let mut resultados = Vec::with_capacity(ceps.len());
    let mut indices_com_letras = Vec::new();
    let mut indices_muitos_digitos = Vec::new();
    
    // Primeira passagem: processar e coletar erros
    for (idx, cep_opt) in ceps.iter().enumerate() {
        match cep_opt {
            None => resultados.push(None),
            Some(cep) => {
                match padronizar_cep(cep) {
                    Ok(padronizado) => {
                        if padronizado.is_empty() {
                            resultados.push(None);
                        } else {
                            resultados.push(Some(padronizado));
                        }
                    },
                    Err(e) => {
                        // Coletar índices dos erros
                        if let Some(cep_err) = e.downcast_ref::<CepError>() {
                            match cep_err {
                                CepError::ContemLetras(_) => indices_com_letras.push(idx),
                                CepError::MuitosDigitos(_) => indices_muitos_digitos.push(idx),
                            }
                        }
                        resultados.push(None);
                    }
                }
            }
        }
    }
    
    // Reportar erros se houver
    if !indices_com_letras.is_empty() {
        eprintln!("⚠️  CEPs com letras nos índices: {:?}", indices_com_letras);
    }
    if !indices_muitos_digitos.is_empty() {
        eprintln!("⚠️  CEPs com mais de 8 dígitos nos índices: {:?}", indices_muitos_digitos);
    }
    
    resultados
}

/// Lê arquivo parquet e processa CEPs
fn processar_arquivo_parquet<P: AsRef<Path>>(path: P) -> Result<(), Box<dyn std::error::Error>> {
    println!("📖 Lendo arquivo parquet...");
    
    let file = File::open(&path)?;
    let builder = ParquetRecordBatchReaderBuilder::try_new(file)?;
    
    let schema = builder.schema();
    println!("📊 Schema do arquivo:");
    for field in schema.fields() {
        println!("   - {}: {:?}", field.name(), field.data_type());
    }
    
    // Tentar encontrar uma coluna que possa conter CEPs
    let cep_columns = ["cep", "CEP", "cep_dom", "postal_code", "zip_code"];
    let mut cep_column_name: Option<String> = None;
    
    for field in schema.fields() {
        for cep_col in &cep_columns {
            if field.name().to_lowercase().contains(&cep_col.to_lowercase()) {
                cep_column_name = Some(field.name().clone());
                println!("✅ Coluna de CEP encontrada: {}", field.name());
                break;
            }
        }
        if cep_column_name.is_some() {
            break;
        }
    }
    
    if cep_column_name.is_none() {
        println!("⚠️  Nenhuma coluna de CEP encontrada. Usando primeira coluna string/numérica.");
        // Pegar primeira coluna que seja string ou numérica
        for field in schema.fields() {
            match field.data_type() {
                arrow::datatypes::DataType::Utf8 | 
                arrow::datatypes::DataType::Int32 | 
                arrow::datatypes::DataType::Int64 |
                arrow::datatypes::DataType::Float32 |
                arrow::datatypes::DataType::Float64 => {
                    cep_column_name = Some(field.name().clone());
                    println!("📍 Usando coluna: {}", field.name());
                    break;
                },
                _ => continue,
            }
        }
    }
    
    let column_name = cep_column_name.ok_or("Nenhuma coluna adequada encontrada")?;
    
    // Ler os dados
    let mut total_processados = 0;
    let mut total_padronizados = 0;
    
    println!("\n🔄 Processando CEPs...");
    
    // Criar leitor de batches
    let mut reader = builder.build()?;
    
    while let Some(batch_result) = reader.next() {
        let batch = batch_result?;
        
        if let Some(column) = batch.column_by_name(&column_name) {
            let ceps_array: Vec<Option<String>> = match column.data_type() {
                arrow::datatypes::DataType::Utf8 => {
                    let string_array = column.as_any().downcast_ref::<StringArray>()
                        .ok_or("Erro ao converter coluna para StringArray")?;
                    
                    (0..string_array.len())
                        .map(|i| {
                            if string_array.is_null(i) {
                                None
                            } else {
                                Some(string_array.value(i).to_string())
                            }
                        })
                        .collect()
                },
                _ => {
                    // Tentar converter números para string
                    (0..column.len())
                        .map(|i| {
                            if column.is_null(i) {
                                None
                            } else {
                                Some(format!("{:?}", column))
                            }
                        })
                        .collect()
                }
            };
            
            total_processados += ceps_array.len();
            
            // Processar CEPs
            let padronizados = padronizar_ceps(ceps_array.clone());
            
            // Contar sucessos
            for resultado in &padronizados {
                if resultado.is_some() {
                    total_padronizados += 1;
                }
            }
            
            // Mostrar alguns exemplos (apenas do primeiro batch)
            if total_processados <= 1000 {
                println!("\n📝 Exemplos de padronização (primeiros 10):");
                for i in 0..10.min(ceps_array.len()) {
                    let original = ceps_array[i].as_deref().unwrap_or("NULL");
                    let padronizado = padronizados[i].as_deref().unwrap_or("NULL/ERRO");
                    println!("   {} → {}", original, padronizado);
                }
            }
        }
    }
    
    println!("\n✅ Processamento concluído!");
    println!("   Total de registros: {}", total_processados);
    println!("   CEPs padronizados com sucesso: {}", total_padronizados);
    if total_processados > 0 {
        println!("   Taxa de sucesso: {:.1}%", 
                 (total_padronizados as f64 / total_processados as f64) * 100.0);
    }
    
    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = std::env::args().collect();
    
    if args.len() < 2 {
        eprintln!("Uso: {} <arquivo.parquet>", args[0]);
        eprintln!("\nExemplo:");
        eprintln!("   cargo run -- ../data_test/endbr.parquet");
        eprintln!("\nPara testar com CEPs individuais:");
        eprintln!("   cargo run -- --test");
        eprintln!("\nNota: Se o arquivo não existir, veja o README.md para criar dados de teste");
        std::process::exit(1);
    }
    
    if args[1] == "--test" {
        // Modo teste: demonstrar padronização
        println!("🧪 Modo teste - Exemplos de padronização:\n");
        
        let testes = vec![
            "22290-140",
            "22290 140", 
            "22.290-140",
            "22290140",
            "1000000",
            " 1000000",
            "",
        ];
        
        for cep in testes {
            match padronizar_cep(cep) {
                Ok(resultado) => {
                    if resultado.is_empty() {
                        println!("'{}' → NULL", cep);
                    } else {
                        println!("'{}' → '{}'", cep, resultado);
                    }
                },
                Err(e) => println!("'{}' → ERRO: {}", cep, e),
            }
        }
        
        println!("\n✅ Testes com erros esperados:");
        let erros = vec!["botafogo", "222290-140", "12345678900"];
        for cep in erros {
            match padronizar_cep(cep) {
                Ok(_) => println!("'{}' → Deveria dar erro!", cep),
                Err(e) => println!("'{}' → {}", cep, e),
            }
        }
    } else {
        // Modo arquivo parquet
        let arquivo = &args[1];
        processar_arquivo_parquet(arquivo)?;
    }
    
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_padroniza_corretamente() {
        assert_eq!(padronizar_cep("22290-140").unwrap(), "22290-140");
        assert_eq!(padronizar_cep("22290 140").unwrap(), "22290-140");
        assert_eq!(padronizar_cep("22.290-140").unwrap(), "22290-140");
        assert_eq!(padronizar_cep("22290140").unwrap(), "22290-140");
        assert_eq!(padronizar_cep("1000000").unwrap(), "01000-000");
        assert_eq!(padronizar_cep(" 1000000").unwrap(), "01000-000");
    }
    
    #[test]
    fn test_erro_com_letras() {
        assert!(padronizar_cep("botafogo").is_err());
        assert!(padronizar_cep("22290a140").is_err());
    }
    
    #[test]
    fn test_erro_muitos_digitos() {
        assert!(padronizar_cep("222290140").is_err());
        assert!(padronizar_cep("12345678900").is_err());
    }
    
    #[test]
    fn test_cep_vazio() {
        assert_eq!(padronizar_cep("").unwrap(), "");
        assert_eq!(padronizar_cep("   ").unwrap(), "");
    }
}