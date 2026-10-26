source(file.path(getwd(), "code", "01_paths_and_setup.R"))

library(ipumsr)
library(dplyr)
library(tidyr)

xml_file <- file.path(data_dir, "cps_00003.xml")
if (!file.exists(xml_file)) {
  stop(
    "Missing IPUMS metadata file: ", xml_file,
    ". Place the CPS XML metadata file in the data/ folder before running the analysis."
  )
}

microdata_files <- list.files(
  data_dir,
  pattern = "cps_00003\\.(dat|dat\\.gz|csv|csv\\.gz)$",
  ignore.case = TRUE,
  full.names = TRUE
)

if (length(microdata_files) == 0L) {
  stop(
    "No CPS microdata file was found in ", data_dir,
    ". Download the matching cps_00003 data file (for example, a .dat or .dat.gz file) to the data directory before running the analysis."
  )
}

microdata_file <- sort(microdata_files)[1]

message("Reading IPUMS metadata from: ", xml_file)
message("Reading microdata from: ", microdata_file)

ddi <- read_ipums_ddi(xml_file)
cps <- read_ipums_micro(ddi, data_file = microdata_file)

cps_clean <- cps %>%
  transmute(
    survey_year = as.numeric(YEAR),
    labor_year  = as.numeric(YEAR) - 1,
    age         = as.numeric(AGE),
    educ_code   = as.numeric(EDUC),
    work_code   = as.numeric(WORKLY),
    wage        = as.numeric(INCWAGE),
    weeks_unem  = as.numeric(WKSUNEM1),
    weight      = as.numeric(ASECWT)
  ) %>%
  filter(
    survey_year >= 2001,
    survey_year <= 2025
  ) %>%
  filter(
    age >= 25,
    age <= 64,
    !is.na(weight),
    weight > 0
  ) %>%
  mutate(
    education = case_when(
      educ_code >= 2 & educ_code <= 72 ~ "Less than high school",
      educ_code == 73 ~ "High school diploma",
      educ_code >= 80 & educ_code <= 100 ~ "Some college / Associate",
      educ_code %in% c(110, 111) ~ "4 years college / Bachelor's",
      educ_code >= 120 & educ_code <= 125 ~ "5+ years college / Graduate",
      TRUE ~ NA_character_
    )
  ) %>%
  mutate(
    education = factor(
      education,
      levels = c(
        "Less than high school",
        "High school diploma",
        "Some college / Associate",
        "4 years college / Bachelor's",
        "5+ years college / Graduate"
      ),
      ordered = TRUE
    )
  ) %>%
  filter(!is.na(education))

saveRDS(cps_clean, file.path(data_dir, "cps_clean.rds"))

message("Prepared data saved to: ", file.path(data_dir, "cps_clean.rds"))
