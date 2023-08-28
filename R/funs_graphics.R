# Colors
# https://carto.com/carto-colors/
clrs <- list(
  prism = rcartocolor::carto_pal(name = "Prism"),
  peach = rcartocolor::carto_pal(name = "Peach")
)


# Theme stuff
theme_ngo <- function() {
  theme_minimal(base_family = "Clear Sans") +
    theme(panel.grid.minor = element_blank(),
      plot.title = element_text(family = "Clear Sans", face = "bold"),
      axis.title.x = element_text(hjust = 0),
      axis.title.y = element_text(hjust = 1),
      strip.text = element_text(family = "Clear Sans", face = "bold",
        size = rel(0.75), hjust = 0),
      strip.background = element_rect(fill = "grey90", color = NA))
}

set_annotation_fonts <- function() {
  ggplot2::update_geom_defaults("label", list(family = "Clear Sans", face = "plain"))
  ggplot2::update_geom_defaults("text", list(family = "Clear Sans", face = "plain"))
}


# Labeling and formatting stuff
build_ci <- function(lower, upper) {
  glue::glue("[{fmt_decimal(lower)}, {fmt_decimal(upper)}]")
}
