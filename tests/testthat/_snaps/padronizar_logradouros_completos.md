# da erro quando nome do logradouro nao eh especificado

    Code
      tester(campos_do_logradouro = correspondencia_logradouro(tipo_de_logradouro = "tipo",
        numero = "numero"))
    Condition <erro_endpad_nome_do_logradouro_ausente>
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
        tipo_de_logradouro = "tipo", nome_do_logradouro = "logradouro"),
      checar_tipos = TRUE)
    Message
      i Padronizando nomes dos logradouros...
      v Padronizando nomes dos logradouros... [xxx ms]
      
      i Padronizando tipos de logradouro...
      v Padronizando tipos de logradouro... [xxx ms]
      
      i Verificando duplicatas entre o tipo e o nome do logradouro...
      v Verificando duplicatas entre o tipo e o nome do logradouro... [xxx ms]
      
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
      

