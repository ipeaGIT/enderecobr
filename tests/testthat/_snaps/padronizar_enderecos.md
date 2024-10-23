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

# erro de nome do nome de log ausente eh atribuido a pad enderecos

    Code
      tester(ends, correspondencia_campos(tipo_de_logradouro = "tipo", numero = "numero"),
      combinar_logradouro = TRUE)
    Condition <erro_endpad_nome_do_logradouro_ausente>
      Error in `padronizar_enderecos()`:
      ! Não é possível fazer uma padronização de logradouro completo sem o nome do logradouro.
      i Por favor informe uma coluna com a informação de nome do logradouro.

# erros relacionados ao cep sao atribuidos a pad enderecos

    Code
      tester(ends, correspondencia_campos(cep = "cep"))
    Condition <erro_endpad_cep_com_digitos_demais>
      Error in `padronizar_enderecos()`:
      ! CEP não deve conter mais que 8 dígitos.
      i O elemento com índice 1 possui mais que 8 dígitos após padronização.

---

    Code
      tester(ends, correspondencia_campos(cep = "cep"))
    Condition <erro_endpad_cep_com_letra>
      Error in `padronizar_enderecos()`:
      ! CEP não deve conter letras.
      i O elemento com índice 1 possui letras.

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
      

---

    Code
      res <- tester(combinar_logradouro = TRUE, checar_tipos = TRUE)
    Message
      i Padronizando nomes dos logradouros...
      v Padronizando nomes dos logradouros... [xxx ms]
      
      i Padronizando números...
      v Padronizando números... [xxx ms]
      
      i Trazendo números para o logradouro completo...
      v Trazendo números para o logradouro completo... [xxx ms]
      
      i Padronizando tipos de logradouro...
      v Padronizando tipos de logradouro... [xxx ms]
      
      i Verificando duplicatas entre o tipo e o nome do logradouro...
      v Verificando duplicatas entre o tipo e o nome do logradouro... [xxx ms]
      
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
      

