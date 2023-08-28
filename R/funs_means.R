calculate_grid_means <- function(draws, ref_grid) {
  library(tidybayes)
  
  draws <- readRDS(draws)

  grid_means <- draws %>% 
    pivot_wider(names_from = i, values_from = Gamma) %>% 
    group_by(j, .chain, .iteration, .draw) %>% 
    nest() %>% 
    mutate(pi = map(data, ~{
      preds <- as.numeric(ref_grid$matrix %*% as.numeric(.))
      ref_grid$all_combos %>% 
        mutate(
          .linpred = preds, 
          # fake bc it's not actually mean(posterior_predict(.))
          .epred = plogis(preds)
        )
    })) %>% 
    select(-data) %>% 
    unnest(pi)
  
  return(grid_means)
}
