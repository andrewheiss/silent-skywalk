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

set.seed(265927) # From random.org

tar_option_set(
  packages = c("tidyverse", "Matrix"),
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
  tar_target(gammas_intercept_only,
    here_rel("data", "raw_data", "posterior_draws", "intercept.rds"),
    format = "file"
  ),
  
  
  ## Graphics and tables ----
  tar_target(graphic_functions, lst(
    theme_ngo, set_annotation_fonts, clrs, build_ci
  )),
  tar_target(table_functions, lst(opts_int, opts_theme)),
  
  
  ## Create reference grid(s) ----
  tar_target(ref_grid_features_only, create_ref_grid_features_only()),
  
  ## Calculate predicted values for reference grids ----
  tar_target(means_features_only, calculate_grid_means(gammas_intercept_only, ref_grid_features_only))#,

  ## Analysis ----
  # tar_target(summary_activities, make_activities_summary(survey_orgs)),
  # tar_target(models_activities, make_activities_models(summary_activities))#,
  # 
  # Manuscript and analysis notebook ----
  # tar_quarto(output_nice, path = "manuscript", quiet = FALSE, profile = "nice"),
  # tar_quarto(output_ms, path = "manuscript", quiet = FALSE, profile = "ms"),
  # tar_quarto(website, path = ".", quiet = FALSE),
  # tar_target(deploy_script, here_rel("deploy.sh"), format = "file"),
  # tar_target(deploy, {
  #   # Force a dependency
  #   website
  #   # Run the deploy script
  #   if (Sys.getenv("UPLOAD_WEBSITES") == "TRUE") processx::run(paste0("./", deploy_script))
  # })
)
