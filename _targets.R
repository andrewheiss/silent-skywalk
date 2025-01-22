library(targets)
library(tarchetypes)
library(tibble)

# Set the _targets store so that scripts in subdirectories can access targets
# without using withr::with_dir() (see https://github.com/ropensci/targets/discussions/885)
#
# This hardcodes the absolute path in _targets.yaml, so to make this more
# portable, we rewrite it every time this pipeline is run (and we don't track
# _targets.yaml with git)
tar_config_set(
  store = here::here("_targets"),
  script = here::here("_targets.R")
)

options(
  tidyverse.quiet = TRUE,
  dplyr.summarise.inform = FALSE
)

# Bayes stuff
suppressPackageStartupMessages(library(brms))
options(
  mc.cores = 4,
  brms.backend = "cmdstanr",
  brms.threads = 2
)

set.seed(265927) # From random.org

tar_option_set(
  packages = c("tidyverse"),
  format = "qs"
)

# here::here() returns an absolute path, which then gets stored in tar_meta and
# becomes computer-specific (i.e. /Users/andrew/Research/blah/thing.Rmd).
# There's no way to get a relative path directly out of here::here(), but
# fs::path_rel() works fine with it (see
# https://github.com/r-lib/here/issues/36#issuecomment-530894167)
here_rel <- function(...) {fs::path_rel(here::here(...))}

# Load R scripts with functions to use in the pipeline
lapply(list.files("R", full.names = TRUE, recursive = TRUE), source)

# Actual pipeline ---------------------------------------------------------
list(
  ## Data and draws ----  
  tar_target(
    qualtrics_anonymized_file,
    here_rel("data", "raw_data", "conjointqsf_final.csv"),
    format = "file"
  ),

  tar_target(
    ipums_dat_file,
    here_rel("data", "raw_data", "ipums-cps", "cps_00006.dat.gz"),
    format = "file"
  ),
  tar_target(
    ipums_ddi_file,
    here_rel("data", "raw_data", "ipums-cps", "cps_00006.xml"),
    format = "file"
  ),
  
  tar_target(data_processed, make_clean_data(qualtrics_anonymized_file)),
  tar_target(data_sans_conjoint, data_processed[["data_clean"]]),
  tar_target(data_full, data_processed[["data_final"]]),
  
  ## Graphics and tables ----
  tar_target(graphic_functions, lst(
    theme_ngo, set_annotation_fonts, clrs, 
    build_ci, fmt_decimal, fmt_decimal2, fmt_pp_int, label_pp, fmt_pct, fmt_pp2
  )),
  tar_target(table_functions, lst(opts_int, opts_theme, inline_listify)),
  tar_target(diagnostic_functions, lst(plot_trace, plot_trank, plot_pp)),
  
  ## Models ----
  tar_target(m_treatment_only, f_treatment_only(data_full)),
  
  ## Create reference grid(s) ----
  tar_target(grid_treatment_only, create_grid_treatment_only(data_full)),
  
  ## Calculate predicted values for reference grids ----
  tar_target(preds_conditional_treatment_only_full, 
    create_preds_conditional_treatment_only(m_treatment_only, grid_treatment_only)
  ),
  tar_target(preds_conditional_treatment_only,
    filter_responses_only(preds_conditional_treatment_only_full)
  ),
  tar_target(preds_new_treatment_only_full, 
    create_preds_new_treatment_only(m_treatment_only, grid_treatment_only)
  ),
  tar_target(preds_new_treatment_only,
    filter_responses_only(preds_new_treatment_only_full)
  ),

  ## Helper objects like lookup tables
  tar_target(level_lookup, make_level_lookup(grid_treatment_only)),
  tar_target(feature_lookup, make_feature_lookup()),
  
  ## Miscellaneous analysis stuff
  tar_target(model_summary_table, build_modelsummary(m_treatment_only)),
  
  tar_target(participant_summary, create_sample_summary(data_sans_conjoint)),
  tar_target(cps_props, calc_population_props(ipums_dat_file, ipums_ddi_file)),
  tar_target(cps_diffs, calc_cps_diffs(participant_summary, cps_props)),
  
  ## Manuscript and notebook ----
  tar_quarto(manuscript, path = "manuscript", quiet = FALSE),
  tar_quarto(website, path = ".", quiet = FALSE),
  tar_target(deploy_script, here_rel("deploy.sh"), format = "file"),
  tar_target(deploy, {
    # Force a dependency
    website
    # Run the deploy script
    if (Sys.getenv("UPLOAD_WEBSITES") == "TRUE") processx::run(paste0("./", deploy_script))
  }),
  
  ## Render the README ----
  tar_quarto(readme, here_rel("README.qmd"))
)
