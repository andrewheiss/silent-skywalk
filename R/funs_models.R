f_treatment_only <- function(dat) {
  BAYES_SEED <- 706615  # From random.org

  categorical_priors <- c(
    prior(normal(0, 3), class = b, dpar = mu1),
    prior(normal(0, 3), class = b, dpar = mu2),
    prior(normal(0, 3), class = b, dpar = mu3),
    prior(exponential(1), class = sd, dpar = mu1),
    prior(exponential(1), class = sd, dpar = mu2),
    prior(exponential(1), class = sd, dpar = mu3) # ,
  )

  model <- brm(
    bf(choice_alt ~
      # Conjoint attributes (treatment variables)
      feat_org + feat_issue + feat_transp + feat_acc + feat_funding + feat_govt +
      # Respondent-specific intercepts
      (1 | id)),
    data = dat,
    family = categorical(refcat = "0"),
    prior = categorical_priors,
    chains = 4, warmup = 1000, iter = 5000, seed = BAYES_SEED, refresh = 10
  )

  return(model)
}
