# padronizacao character->integer gera warning com certos inputs

    Code
      res <- tester(c("1", "1 2 ", "A"), formato = "integer")
    Condition <warning_endbr_conversao_invalida>
      Warning in `padronizar_numeros()`:
      Alguns números não puderam ser convertidos para integer, introduzindo NAs no resultado.

