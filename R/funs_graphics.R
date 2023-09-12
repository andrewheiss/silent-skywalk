# Colors
# https://carto.com/carto-colors/
clrs <- list(
  prism = rcartocolor::carto_pal(name = "Prism"),
  peach = rcartocolor::carto_pal(name = "Peach")
)


# Theme stuff
theme_ngo <- function() {
  theme_minimal(base_family = "Libre Franklin") +
    theme(panel.grid.minor = element_blank(),
      plot.title = element_text(family = "Libre Franklin", face = "bold"),
      axis.title.x = element_text(
        family = "Libre Franklin SemiBold", face = "plain",
        hjust = 0, size = rel(0.9), 
        margin = margin(t = 10)),
      axis.title.y = element_text(
        family = "Libre Franklin SemiBold", face = "plain",
        hjust = 1, size = rel(0.9), 
        margin = margin(r = 10)),
      strip.text = element_text(family = "Libre Franklin", face = "bold",
        size = rel(0.75), hjust = 0),
      strip.background = element_rect(fill = "grey90", color = NA))
}

set_annotation_fonts <- function() {
  ggplot2::update_geom_defaults("label", list(family = "Libre Franklin", face = "plain"))
  ggplot2::update_geom_defaults("text", list(family = "Libre Franklin", face = "plain"))
}


# Labeling and formatting stuff
build_ci <- function(lower, upper) {
  glue::glue("[{fmt_decimal(lower)}, {fmt_decimal(upper)}]")
}

# Put these scales things in functions so that they work like regular functions,
# otherwise {targets} complains that "... may be used in an incorrect context"
fmt_decimal <- \(x) scales::label_number(accuracy = 0.001, style_negative = "minus")(x)

label_pp <- function(x) {
  scales::label_number(accuracy = 1, scale = 100, 
    suffix = " pp.", style_negative = "minus")(x)
}
