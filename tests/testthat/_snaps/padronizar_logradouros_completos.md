# da erro quando nome do logradouro nao eh especificado

    Code
      tester(campos_do_logradouro = correspondencia_logradouro(tipo_de_logradouro = "tipo",
        numero = "numero"))
    Condition <erro_endbr_nome_do_logradouro_ausente>
      Error in `padronizar_logradouros_completos()`:
      ! Não é possível fazer uma padronização de logradouro completo sem o nome do logradouro.
      i Por favor informe uma coluna com a informação de nome do logradouro.

# printa mensagens de progresso quando verboso

    Code
      res <- tester()
    Message
      i Padronizando nomes dos logradouros...[K
      v Padronizando nomes dos logradouros... [xxx ms][K
      
      i Padronizando números...[K
      v Padronizando números... [xxx ms][K
      
      i Trazendo números para o logradouro completo...[K
      v Trazendo números para o logradouro completo... [xxx ms][K
      
      i Padronizando tipos de logradouro...[K
      v Padronizando tipos de logradouro... [xxx ms][K
      
      i Trazendo tipos de logradouro para o logradouro completo...[K
      v Trazendo tipos de logradouro para o logradouro completo... [xxx ms][K
      

---

    Code
      res <- tester(campos_do_logradouro = correspondencia_logradouro(
        tipo_de_logradouro = "tipo", nome_do_logradouro = "logradouro"))
    Message
      i Padronizando nomes dos logradouros...[K
      v Padronizando nomes dos logradouros... [xxx ms][K
      
      i Padronizando tipos de logradouro...[K
      v Padronizando tipos de logradouro... [xxx ms][K
      
      i Trazendo tipos de logradouro para o logradouro completo...[K
      v Trazendo tipos de logradouro para o logradouro completo... [xxx ms][K
      

---

    Code
      res <- tester(campos_do_logradouro = correspondencia_logradouro(
        tipo_de_logradouro = "tipo", nome_do_logradouro = "logradouro"),
      checar_tipos = TRUE)
    Message
      i Padronizando nomes dos logradouros...[K
      v Padronizando nomes dos logradouros... [xxx ms][K
      
      i Padronizando tipos de logradouro...[K
      v Padronizando tipos de logradouro... [xxx ms][K
      
      i Verificando duplicatas entre o tipo e o nome do logradouro...[K
      v Verificando duplicatas entre o tipo e o nome do logradouro... [xxx ms][K
      
      i Trazendo tipos de logradouro para o logradouro completo...[K
      v Trazendo tipos de logradouro para o logradouro completo... [xxx ms][K
      

---

    Code
      res <- tester(campos_do_logradouro = correspondencia_logradouro(
        nome_do_logradouro = "logradouro", numero = "numero"))
    Message
      i Padronizando nomes dos logradouros...[K
      v Padronizando nomes dos logradouros... [xxx ms][K
      
      i Padronizando números...[K
      v Padronizando números... [xxx ms][K
      
      i Trazendo números para o logradouro completo...[K
      v Trazendo números para o logradouro completo... [xxx ms][K
      

