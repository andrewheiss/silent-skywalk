opts_int <- function(x, ...) {
  x %>% 
    opt_interactive(use_compact_mode = TRUE, use_highlight = TRUE, ...)
}

opts_theme <- function(x) {
  x %>% 
    opt_table_font(font = "Inter") %>% 
    tab_options(column_labels.font.weight = "bold",
      row_group.font.weight = "bold")
}

#' Inline Listify
#'
#' This function takes a vector of characters, prefixes each element with a
#' number in parentheses, and collapses them into a single string separated by
#' semicolons.
#'
#' @param x A vector of characters.
#'
#' @return A single string where each element from the input vector is prefixed
#'   with a number in parentheses and separated by semicolons.
#'
#' @examples
#' inline_listify(c("apple", "banana", "cherry"))
inline_listify <- function(x) {
  numbers <- seq_along(x)
  prefixed <- paste0("(", numbers, ") ", x)
  collapsed <- paste(prefixed, collapse = "; ")
  return(collapsed)
}
