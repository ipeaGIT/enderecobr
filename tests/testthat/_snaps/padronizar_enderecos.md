# funciona mas da warning quando colunas com nome padrao ja existem

    Code
      res <- tester(ends, correspondencia_campos(logradouro = "logradouro_padr"))
    Condition <warning_endpad_coluna_existente>
      Warning in `padronizar_enderecos()`:
      A seguinte coluna foi encontrada no input e será sobrescrita no output: `logradouro_padr`.

---

    Code
      res <- tester(ends, correspondencia_campos(logradouro = "logradouro_padr",
        numero = "numero_padr"))
    Condition <warning_endpad_coluna_existente>
      Warning in `padronizar_enderecos()`:
      As seguintes colunas foram encontradas no input e serão sobrescritas no output: `logradouro_padr` e `numero_padr`.

---

    Code
      res <- tester(ends, correspondencia_campos(logradouro = "logradouro_padr",
        numero = "numero_padr", estado = "estado_padr"))
    Condition <warning_endpad_coluna_existente>
      Warning in `padronizar_enderecos()`:
      As seguintes colunas foram encontradas no input e serão sobrescritas no output: `logradouro_padr`, `numero_padr` e `estado_padr`.

# printa mensagens de progresso quando verboso

    Code
      res <- tester()
    Message
      i Padronizando tipos de logradouro...
      v Padronizando tipos de logradouro... [xxx ms]
      
      i Padronizando logradouros...
      v Padronizando logradouros... [xxx ms]
      
      i Padronizando números...
      v Padronizando números... [xxx ms]
      
      i Padronizando complementos...
      v Padronizando complementos... [xxx ms]
      
      i Padronizando CEPs...
      v Padronizando CEPs... [xxx ms]
      
      i Padronizando bairros...
      v Padronizando bairros... [xxx ms]
      
      i Padronizando municípios...
      v Padronizando municípios... [xxx ms]
      
      i Padronizando estados...
      v Padronizando estados... [xxx ms]
      

---

    Code
      res <- tester(combinar_logradouro = TRUE)
    Message
      i Padronizando nomes dos logradouros...
      v Padronizando nomes dos logradouros... [xxx ms]
      
      i Padronizando números...
      v Padronizando números... [xxx ms]
      
      i Trazendo números para o logradouro completo...
      v Trazendo números para o logradouro completo... [xxx ms]
      
      i Padronizando tipos de logradouro...
      v Padronizando tipos de logradouro... [xxx ms]
      
      i Trazendo tipos de logradouro para o logradouro completo...
      v Trazendo tipos de logradouro para o logradouro completo... [xxx ms]
      
      i Padronizando complementos...
      v Padronizando complementos... [xxx ms]
      
      i Padronizando CEPs...
      v Padronizando CEPs... [xxx ms]
      
      i Padronizando bairros...
      v Padronizando bairros... [xxx ms]
      
      i Padronizando municípios...
      v Padronizando municípios... [xxx ms]
      
      i Padronizando estados...
      v Padronizando estados... [xxx ms]
      

