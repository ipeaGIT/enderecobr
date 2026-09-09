# As mensagens de progresso do cli podem conter códigos de escape ANSI (ex.: ESC[K),
# dependendo se o stdout suporta ANSI ou não. Isso varia entre ambientes (ex.:
# terminal interativo vs. R CMD check), então os removemos para que os snapshots
# sejam estáveis. Também removemos os tempos de execução, que variam entre execuções.
simplificar_mensagens <- function(x) {
  x <- gsub("\033\\[[0-9;]*[A-Za-z]", "", x)
  sub("\\[\\d+.*\\]", "[xxx ms]", x)
}
