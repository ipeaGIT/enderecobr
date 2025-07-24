# --- Warning customizado --------------------------------------------------

def warning_endbr(message: str, call: Optional[str] = None) -> None:
    """
    Dispara um warning do tipo UserWarning (ou subclasse específica),
    igual ao cli::cli_warn() do R.
    """
    # 1) descobrir quem chamou
    caller = sys._getframe(1)
    func_name = caller.f_code.co_name  # e.g. "warning_meusalvamento"
    # 2) construir nome da classe de warning
    suffix = func_name.replace("warning_", "", 1)
    warn_class_name = f"warning_endbr_{suffix}"
    # 3) criar dinamicamente a subclasse de UserWarning
    WarnCls = type(warn_class_name, (UserWarning,), {})
    # 4) disparar
    warnings.warn(message, category=WarnCls)
