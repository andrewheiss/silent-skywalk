suppressPackageStartupMessages(library(tidybayes))

# Lookup tables
# Little table of all feature level labels in the right order
make_level_lookup <- function(grid) {
  level_lookup <- tibble(
    feature = c(
      "feat_org", "feat_issue", "feat_transp", 
      "feat_acc", "feat_funding", "feat_govt"
    ),
    feature_short = c(
      "feat_org", "feat_issue", "feat_transp_short", 
      "feat_acc_short", "feat_funding_short", "feat_govt_short"
    )
  ) %>%
    mutate(across(
      c(feature, feature_short),
      list(level = ~ map(.x, ~ {
        x <- grid[[.x]]
        if (is.numeric(x)) {
          ""
        } else if (is.factor(x)) {
          levels(x)
        } else {
          sort(unique(x))
        }
      }))
    )) %>%
    unnest(c(feature_level, feature_short_level)) %>%
    mutate(across(c(feature_level, feature_short_level), ~ fct_inorder(.)))

  return(level_lookup)
}

# Little table for all feature labels in the right order
make_feature_lookup <- function() {
  feature_lookup <- tribble(
    ~feature,      ~feature_nice,
    "feat_org",     "Organizations",
    "feat_issue",   "Issue areas",
    "feat_transp",  "Transparency",
    "feat_acc",     "Accountability",
    "feat_funding", "Funding sources",
    "feat_govt",    "Relationship with host government"
  ) %>% 
    mutate(amce_var = str_replace(feature, "feat_", "amces_")) %>% 
    mutate(mm_var = str_replace(feature, "feat_", "mms_")) %>% 
    mutate(feature_nice = fct_inorder(feature_nice))
  
  return(feature_lookup)
}

filter_responses_only <- function(preds) {
  preds %>% 
    # Get rid of all category 0 rows
    filter(.category != 0) %>% 
    # Stop grouping by category so we can add the three categories together
    ungroup(.category) %>% 
    # Add .draw as a group so that we collapse the epreds within each draw
    group_by(.draw, .add = TRUE) %>% 
    # Combine the three epreds
    summarize(.epred = sum(.epred))
}

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
