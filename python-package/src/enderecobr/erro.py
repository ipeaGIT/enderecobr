# --- Base de erro --------------------------------------------------------

class EndbrError(Exception):
    """Classe base para erros do enderecobr."""
    pass

def erro_endbr(message: str, call: Optional[str] = None) -> None:
    """
    Lança uma exceção do tipo EndbrError (ou subclasse específica),
    igual ao cli::cli_abort() do R.
    """
    # 1) descobrir o nome da função que chamou este erro
    caller = sys._getframe(1)
    func_name = caller.f_code.co_name  # e.g. "erro_minhalogica"
    # 2) construir nome da classe: "erro_endbr_<sufixo>"
    suffix = func_name.replace("erro_", "", 1)
    err_class_name = f"erro_endbr_{suffix}"
    # 3) criar dinamicamente a subclasse
    ErrCls = type(err_class_name, (EndbrError,), {})
    # 4) lançar
    raise ErrCls(message)
