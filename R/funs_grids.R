create_grid_treatment_only <- function(dat) {
  all_combos <- dat %>%
    # Get all combinations of all feature levels
    tidyr::expand(feat_org, feat_issue, feat_transp, feat_acc, feat_funding, feat_govt) %>%
    
    # Make shorter versions of these levels for the sake of plotting/tables/etc.
    mutate(
      feat_transp_short = fct_relabel(feat_transp, ~ str_remove(.x, "Transparency: ")),
      feat_acc_short = fct_relabel(feat_acc, ~ str_remove(.x, "Accountability: ")),
      feat_funding_short = fct_recode(feat_funding,
        "Many small donors" = "Funded primarily by many small private donations",
        "Handful of wealthy private donors" = "Funded primarily by a handful of wealthy private donors",
        "Government grants" = "Funded primarily by government grants"
      ),
      feat_govt_short = fct_recode(feat_govt,
        "Friendly" = "Friendly relationship with government",
        "Criticized" = "Criticized by government",
        "Under crackdown" = "Under government crackdown"
      )
    ) %>%
    mutate(across(everything(), ~ fct_inorder(.)))

  return(all_combos)
}
