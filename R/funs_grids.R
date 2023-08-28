create_ref_grid_features_only <- function() {
  suppressPackageStartupMessages(library(Matrix))
  
  all_combos <- expand_grid(
    feat_org = c("Amnesty International", "Greenpeace", "Oxfam", "Red Cross"), 
    feat_issue = c("Emergency response", "Environment", "Human rights", "Refugee relief"),
    feat_transp = c("No", "Yes"), 
    feat_acc = c("No", "Yes"),
    feat_funding = c("Many small donors", "Handful of wealthy private donors", "Government grants"),
    feat_govt = c("Friendly", "Criticized", "Under crackdown")
  ) %>% 
    mutate(across(everything(), ~fct_inorder(.)))
  
  all_combos_design_grid <- sparse.model.matrix(
    ~ 0 + feat_org + feat_issue + feat_transp + 
      feat_acc + feat_funding + feat_govt, 
    data = all_combos
  )
  
  return(lst(all_combos, matrix = all_combos_design_grid))
}
