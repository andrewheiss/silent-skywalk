suppressPackageStartupMessages(library(tidybayes))

# Average respondent
create_preds_conditional_treatment_only <- function(model, grid) {
  preds <- model %>% 
    epred_draws(
      newdata = grid, 
      re_formula = NA
    )
}

# New respondent
create_preds_new_treatment_only <- function(model, grid) {
  preds <- model %>% 
    epred_draws(
      newdata = mutate(grid, id = -1), 
      re_formula = NULL,
      allow_new_levels = TRUE,
      sample_new_levels = "uncertainty"
    )
}
