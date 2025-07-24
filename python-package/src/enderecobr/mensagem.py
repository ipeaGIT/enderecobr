# --- Mensagem de progresso ------------------------------------------------

def mensagem_progresso_endbr(msg: str) -> None:
    """
    Se getOption("rlib_message_verbosity") ou getOption("enderecobr.verbose")
    estiverem em "verbose", mostra msg na tela (equivalente ao cli_progress_step()).
    """
    rlib_verbose = os.getenv("RLIB_MESSAGE_VERBOSITY", "quiet") == "verbose"
    pkg_verbose = os.getenv("ENDERECOBR_VERBOSE",      "quiet") == "verbose"

    if rlib_verbose or pkg_verbose:
        # se tiver click instalado, usar click.echo() para cores e flush automático
        try:
            import click
            click.echo(msg)
        except ImportError:
            print(msg)

