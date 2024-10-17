# da erro quando cep contem letra

    Code
      padronizar_ceps("botafogo")
    Condition <erro_endpad_cep_com_letra>
      Error in `padronizar_ceps()`:
      ! CEP não deve conter letras.
      i O elemento com índice 1 possui letras.

---

    Code
      padronizar_ceps(c(NA, "oie", NA, "hehe"))
    Condition <erro_endpad_cep_com_letra>
      Error in `padronizar_ceps()`:
      ! CEP não deve conter letras.
      i Os elementos com índices 2 and 4 possuem letras.

---

    Code
      padronizar_ceps(base::letters)
    Condition <erro_endpad_cep_com_letra>
      Error in `padronizar_ceps()`:
      ! CEP não deve conter letras.
      i Os elementos com índices 1, 2, 3, ..., 25 e 26 possuem letras.

# da erro quando cep contem mais de 8 digitos

    Code
      padronizar_ceps(1e+08)
    Condition <erro_endpad_cep_com_digitos_demais>
      Error in `padronizar_ceps()`:
      ! CEP não deve conter mais que 8 dígitos.
      i O elemento com índice 1 possui mais que 8 dígitos após padronização.

---

    Code
      padronizar_ceps("222290-140")
    Condition <erro_endpad_cep_com_digitos_demais>
      Error in `padronizar_ceps()`:
      ! CEP não deve conter mais que 8 dígitos.
      i O elemento com índice 1 possui mais que 8 dígitos após padronização.

---

    Code
      padronizar_ceps(c(1e+07, 1e+08, 1e+08))
    Condition <erro_endpad_cep_com_digitos_demais>
      Error in `padronizar_ceps()`:
      ! CEP não deve conter mais que 8 dígitos.
      i Os elementos com índices 2 and 3 possuem mais que 8 dígitos após padronização.

---

    Code
      padronizar_ceps(rep(1e+08, 20))
    Condition <erro_endpad_cep_com_digitos_demais>
      Error in `padronizar_ceps()`:
      ! CEP não deve conter mais que 8 dígitos.
      i Os elementos com índices 1, 2, 3, ..., 19 e 20 possuem mais que 8 dígitos após padronização.

