# da erro quando apenas um campo eh especificado

    Code
      tester(campos_do_logradouro = correspondencia_logradouro(numero = "numero"))
    Condition <erro_endpad_erro_apenas_um_campo_presente>
      Error in `padronizar_logradouros_completos()`:
      ! Apenas um campo foi passado para padronização. Por favor utilize a função correspondente:
      * Tipo de logradouro: `padronizar_tipos_de_logradouro()`
      * Nome do logradouro: `padronizar_logradouros()`
      * Número: `padronizar_numeros()`

# da erro quando nome do logradouro nao eh especificado

    Code
      tester(campos_do_logradouro = correspondencia_logradouro(tipo_de_logradouro = "tipo",
        numero = "numero"))
    Condition <erro_endpad_erro_nome_do_logradouro_ausente>
      Error in `padronizar_logradouros_completos()`:
      ! Não é possível fazer uma padronização de logradouro completo sem o nome do logradouro.
      i Por favor informe uma coluna com a informação de nome do logradouro.

# printa mensagens de progresso quando verboso

    Code
      res <- tester()
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
      

---

    Code
      res <- tester(campos_do_logradouro = correspondencia_logradouro(
        tipo_de_logradouro = "tipo", nome_do_logradouro = "logradouro"))
    Message
      i Padronizando nomes dos logradouros...
      v Padronizando nomes dos logradouros... [xxx ms]
      
      i Padronizando tipos de logradouro...
      v Padronizando tipos de logradouro... [xxx ms]
      
      i Trazendo tipos de logradouro para o logradouro completo...
      v Trazendo tipos de logradouro para o logradouro completo... [xxx ms]
      

---

    Code
      res <- tester(campos_do_logradouro = correspondencia_logradouro(
        nome_do_logradouro = "logradouro", numero = "numero"))
    Message
      i Padronizando nomes dos logradouros...
      v Padronizando nomes dos logradouros... [xxx ms]
      
      i Padronizando números...
      v Padronizando números... [xxx ms]
      
      i Trazendo números para o logradouro completo...
      v Trazendo números para o logradouro completo... [xxx ms]
      

