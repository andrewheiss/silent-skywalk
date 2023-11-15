build_modelsummary <- function(model) {
  suppressPackageStartupMessages(library(modelsummary))
  
  coef_lookup <- tribble(
    ~term, ~feature, ~level,
    "feat_transpTransparency:Yes", "Transparency", "Transparency:Yes",
    "feat_accAccountability:Yes", "Accountability", "Accountability:Yes",
    "feat_govtCriticizedbygovernment", "Relationship with host government", "Criticized",
    "feat_govtUndergovernmentcrackdown", "Relationship with host government", "Under crackdown",
    "feat_orgGreenpeace", "Organizations", "Greenpeace",
    "feat_orgOxfam", "Organizations", "Oxfam",
    "feat_orgRedCross", "Organizations", "Red Cross",
    "feat_issueEnvironment", "Issue areas", "Environment",
    "feat_issueHumanrights", "Issue areas", "Human rights",
    "feat_issueRefugeerelief", "Issue areas", "Refugee relief",
    "feat_fundingFundedprimarilybyahandfulofwealthyprivatedonors", "Funding sources", "Few wealthy donors",
    "feat_fundingFundedprimarilybygovernmentgrants", "Funding sources", "Government grants",
    "Intercept", "Intercept", "Intercept"
  ) %>% 
    mutate(across(c(feature, level), ~fct_inorder(.x)))

  # Need to use <<- so that these functions go to the parent environment so that
  # modelsummary() can see them
  tidy.brmsimple <<- function(x, ...) {
    class(x) <- "brmsfit"
    s <- summary(x)
    
    ret <- data.frame(
      term = row.names(s$fixed),
      estimate = s$fixed[, 1],
      conf.low = s$fixed[, 3],
      conf.high = s$fixed[, 4]
    ) %>% 
      separate_wider_delim(term, delim = "_", names = c("group", "term"), too_many = "merge") %>% 
      mutate(group = str_replace(group, "mu", "µ")) %>% 
      left_join(coef_lookup, by = join_by(term)) %>% 
      mutate(Level = level) %>% 
      rename(term_original = term, term = level, Feature = feature) %>% 
      arrange(Feature, Level)
    
    return(ret)
  }
  
  glance.brmsimple <<- function(x, ...) {
    ret <- data.frame(
      N = nrow(x$data)
    )
    
    return(ret)
  }
  
  # Make a fake simplified version of brms's class
  class(model) <- "brmsimple"
  
  msl <- modelsummary(
    model, 
    output = "modelsummary_list"
  )
  
  return(msl)
}


create_sample_summary <- function(survey_results) {
  vars_to_summarize <- tribble(
    ~category, ~variable, ~clean_name,
    "Demographics", "Q5.12", "Gender",
    "Demographics", "Q5.17", "Age",
    "Demographics", "Q5.13", "Marital status",
    "Demographics", "Q5.14", "Education",
    "Demographics", "Q5.15", "Income",
    "Attitudes toward charity", "Q2.5", "Frequency of donating to charity",
    "Attitudes toward charity", "Q2.6", "Amount of donations to charity last year",
    "Attitudes toward charity", "Q2.7_f", "Importance of trusting charities",
    "Attitudes toward charity", "Q2.8_f", "Level of trust in charities",
    "Attitudes toward charity", "Q2.10", "Frequency of volunteering",
    "Politics, ideology, and religion", "Q2.1", "Frequency of following national news",
    "Politics, ideology, and religion", "Q5.7", "Traveled to a developing country",
    "Politics, ideology, and religion", "Q5.1", "Voted in last election",
    "Politics, ideology, and religion", "Q5.6_f", "Trust in political institutions and the state",
    "Politics, ideology, and religion", "Q5.2_f", "Political ideology",
    "Politics, ideology, and religion", "Q5.4", "Involvement in activist causes",
    "Politics, ideology, and religion", "Q5.8", "Frequency of attending religious services",
    "Politics, ideology, and religion", "Q5.9", "Importance of religion"
  )
  
  summarize_factor <- function(x) {
    output <- table(x) %>% 
      as_tibble() %>% 
      magrittr::set_colnames(., c("level", "count")) %>% 
      mutate(level = factor(level, levels = levels(x))) %>%
      mutate(prop = count / sum(count),
        nice_prop = scales::label_percent(accuracy = 0.1)(prop))
    
    return(list(output))
  }
  
  participant_summary <- survey_results %>% 
    select(one_of(vars_to_summarize$variable)) %>% 
    summarize(across(everything(), summarize_factor)) %>% 
    pivot_longer(cols = everything(), names_to = "variable", values_to = "details") %>% 
    left_join(vars_to_summarize, by = "variable") %>% 
    unnest(details) %>% 
    mutate(level = as.character(level)) %>% 
    mutate(level = case_when(
      variable == "Q2.7_f" & level == "1" ~ "1 (not important)",
      variable == "Q2.7_f" & level == "7" ~ "7 (important)",
      variable == "Q2.8_f" & level == "1" ~ "1 (no trust)",
      variable == "Q2.8_f" & level == "7" ~ "7 (complete trust)",
      variable == "Q5.6_f" & level == "1" ~ "1 (no trust)",
      variable == "Q5.6_f" & level == "7" ~ "7 (complete trust)",
      variable == "Q5.2_f" & level == "1" ~ "1 (extremely liberal)",
      variable == "Q5.2_f" & level == "7" ~ "7 (extremely conservative)",
      variable == "Q5.15" & level == "Less than median" ~ "Less than 2017 national median ($61,372)",
      variable == "Q5.17" & level == "Less than median" ~ "Less than 2017 national median (36)",
      TRUE ~ level
    )) %>% 
    mutate(category = fct_inorder(category, ordered = TRUE))
  
  return(participant_summary)
}
