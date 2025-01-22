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
    "Attitudes toward charity", "Q2.7", "Importance of trusting charities",
    "Attitudes toward charity", "Q2.8", "Level of trust in charities",
    "Attitudes toward charity", "Q2.10", "Frequency of volunteering",
    "Politics, ideology, and religion", "Q2.1", "Frequency of following national news",
    "Politics, ideology, and religion", "Q5.7", "Traveled to a developing country",
    "Politics, ideology, and religion", "Q5.1", "Voted in last election",
    "Politics, ideology, and religion", "Q5.6", "Trust in political institutions and the state",
    "Politics, ideology, and religion", "Q5.2", "Political ideology",
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

  results_to_test <- survey_results %>%
    mutate(
      female = Q5.12 == "Gender: Female",
      age = Q5.17 == "Age: More than median",
      married = Q5.13 == "Marital status: Married",
      college = Q5.14 %in% c(
        "Education: 4 year degree", 
        "Education: Graduate or professional degree", 
        "Education: Doctorate"
      ),
      income = Q5.15 == "Income: More than median",
      volunteering = Q2.10 != "Volunteer frequency: Haven't volunteered in past 12 months",
      donating = Q2.5 == "Donation frequency: More than once a month, less than once a year",
      voting = Q5.1 == "Voted in last election: Yes"
    ) %>%
    select(female, age, married, college, income, volunteering, donating, voting) %>%
    mutate(across(everything(), as.numeric))

  participant_summary <- survey_results %>% 
    select(one_of(vars_to_summarize$variable)) %>% 
    summarize(across(everything(), summarize_factor)) %>% 
    pivot_longer(cols = everything(), names_to = "variable", values_to = "details") %>% 
    left_join(vars_to_summarize, by = "variable") %>% 
    unnest(details) %>% 
    mutate(level = as.character(level)) %>% 
    mutate(level = case_when(
      variable == "Q2.7" & level == "1" ~ "1 (not important)",
      variable == "Q2.7" & level == "7" ~ "7 (important)",
      variable == "Q2.8" & level == "1" ~ "1 (no trust)",
      variable == "Q2.8" & level == "7" ~ "7 (complete trust)",
      variable == "Q5.6" & level == "1" ~ "1 (no trust)",
      variable == "Q5.6" & level == "7" ~ "7 (complete trust)",
      variable == "Q5.2" & level == "1" ~ "1 (extremely liberal)",
      variable == "Q5.2" & level == "7" ~ "7 (extremely conservative)",
      variable == "Q5.15" & level == "Less than median" ~ "Less than 2017 national median ($61,372)",
      variable == "Q5.17" & level == "Less than median" ~ "Less than 2017 national median (36)",
      TRUE ~ level
    )) %>% 
    mutate(category = fct_inorder(category, ordered = TRUE))

  return(lst(participant_summary, results_to_test))
}


calc_population_props <- function(ipums_dat_file, ipums_ddi_file) {
  library(ipumsr)

  ipums_raw <- read_ipums_micro(read_ipums_ddi(ipums_ddi_file), verbose = FALSE)

  # Sex (`SEX`): 2019-03
  # Age (`AGE`): 2019-03
  # Marital status (`MARST`): 2019-03
  # Education (`EDUC`): 2019-03
  # Income (`INCTOT`): 2019-03

  # Donating (`VLDONATE`): 2019-09
  # Volunteering (`VLSTATUS`): 2019-09

  # Voting (`VOTED`): 2018-11

  df_demographics <- ipums_raw %>%
    filter(YEAR == 2019, MONTH == 03) %>%
    # Clean up columns not in the universe
    mutate(
      SEX = ifelse(SEX == 9, NA, SEX),
      EDUC = ifelse(EDUC <= 1 | EDUC == 999, NA, EDUC),
      INCTOT = ifelse(INCTOT == 99999999, NA, INCTOT)
    )
  
  global_demographics <- df_demographics %>% 
    summarize(
      age = weighted.mean(AGE >= 36, ASECWT), 
      female = weighted.mean(SEX == 2, ASECWT),
      married = weighted.mean(MARST %in% 1:2, na.rm = TRUE),
      college = weighted.mean(EDUC >= 111, ASECWT, na.rm = TRUE),
      income = weighted.mean(INCTOT >= 61372, ASECWT, na.rm = TRUE)
    )

  # Volunteering data comes from September 2019 CPS
  df_volunteering <- ipums_raw %>% 
    filter(YEAR == 2019, MONTH == 09) %>%
    # Clean up columns not in the universe
    mutate(across(c(VLSTATUS, VLDONATE), \(x) ifelse(x == 99, NA, x)))
  
  global_vol <- df_volunteering %>% 
    summarize(
      volunteering = weighted.mean(VLSTATUS == 1, VLSUPPWT, na.rm = TRUE),
      donating = weighted.mean(VLDONATE == 2, VLSUPPWT, na.rm = TRUE)
    )
  
  df_voting <- ipums_raw %>%
    filter(YEAR == 2018, MONTH == 11) %>%
    mutate(VOTED = ifelse(VOTED == 99, NA, VOTED))

  global_voting <- df_voting %>%
    summarize(
      voting = weighted.mean(VOTED == 2, VOSUPPWT, na.rm = TRUE)
    )
  
  return(bind_cols(global_demographics, global_vol, global_voting))
}

calc_cps_diffs <- function(participant_summary, cps_props) {
  suppressPackageStartupMessages(library(brms))
  library(tidybayes)

  model_prop <- function(sample_column, cps_prop) {
    BAYES_SEED <- 439558  # From random.org
  
    df <- tibble(
      n_yes = sum(sample_column),
      n_total = length(sample_column)
    )
  
    model <- brm(
      bf(n_yes | trials(n_total) ~ 1),
      data = df,
      family = stats::binomial(link = "identity"),
      prior = c(prior(beta(1, 1), class = "Intercept", lb = 0, ub = 1)),
      chains = 4, warmup = 1000, iter = 2000, seed = BAYES_SEED,
      refresh = 0,
      backend = "cmdstanr"
    )
  
    output <- model %>%
      spread_draws(b_Intercept) %>% 
      mutate(diff = b_Intercept - cps_prop) %>% 
      summarize(
        prop_sample = median(b_Intercept),
        diff = median_qi(diff)
      ) %>% 
      unnest(diff) %>%
      mutate(cps_prop_outside_ci = sign(ymin) == sign(ymax))
  
    return(tibble(model = list(model), output))
  }

  sample_details <- participant_summary$results_to_test

  sample_cps_props <- tribble(
    ~variable, ~sample_value, ~national_value,
    "Age (% 36+)", sample_details$age, cps_props$age,
    "Female (%)", sample_details$female, cps_props$female,
    "Married (%)", sample_details$married, cps_props$married,
    "Education (% BA+)", sample_details$college, cps_props$college,
    "Income (% $61,372+)", sample_details$income, cps_props$income,
    "Donated in past year (%)", sample_details$donating, cps_props$donating,
    "Volunteered in past year (%)", sample_details$volunteering, cps_props$volunteering,
    "Voted in last November election (%)", sample_details$voting, cps_props$voting,
  ) %>%
    mutate(prop_test_results = pmap(
      list(sample_value, national_value), \(x, y) model_prop(x, y)
    )) %>%
    unnest(prop_test_results)

  return(sample_cps_props)
}
