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

