# Resolve project root in a way that works from repo root, code/ folder, or any other working directory.
project_root <- if (file.exists(file.path(getwd(), "AEDS6400_blog3.Rproj"))) {
  normalizePath(getwd(), winslash = "/", mustWork = TRUE)
} else if (file.exists(file.path("..", "AEDS6400_blog3.Rproj"))) {
  normalizePath("..", winslash = "/", mustWork = TRUE)
} else if (file.exists(file.path("code", "AEDS6400_blog3.Rproj"))) {
  normalizePath(file.path(getwd(), "code"), winslash = "/", mustWork = TRUE)
} else {
  # Final fallback: use the current working directory.
  normalizePath(getwd(), winslash = "/", mustWork = TRUE)
}

# GitHub repo structure paths.
data_dir <- file.path(project_root, "data")
figure_dir <- file.path(project_root, "figure")

if (!dir.exists(data_dir)) {
  stop("Data directory not found: ", data_dir)
}
if (!dir.exists(figure_dir)) {
  dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
}

library(ipumsr)
library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)

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
    survey_year <= 2025,
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

weighted_mean <- function(x, w) {
  valid <- !is.na(x) &
    !is.na(w) &
    is.finite(x) &
    is.finite(w) &
    w > 0

  if (!any(valid)) {
    return(NA_real_)
  }

  weighted.mean(x[valid], w[valid])
}

weighted_median <- function(x, w) {
  valid <- !is.na(x) &
    !is.na(w) &
    is.finite(x) &
    is.finite(w) &
    w > 0

  x <- x[valid]
  w <- w[valid]

  if (length(x) == 0) {
    return(NA_real_)
  }

  ord <- order(x)
  x <- x[ord]
  w <- w[ord]
  cumulative_weight <- cumsum(w)
  cutoff <- sum(w) / 2

  x[which(cumulative_weight >= cutoff)[1]]
}

# Figure 1: employment rate
employment_data <- cps_clean %>%
  filter(work_code %in% c(1, 2)) %>%
  mutate(worked = ifelse(work_code == 2, 1, 0)) %>%
  group_by(labor_year, education) %>%
  summarise(
    employment_rate = weighted_mean(worked, weight) * 100,
    n = n(),
    .groups = "drop"
  )

p1 <- ggplot(employment_data, aes(x = labor_year, y = employment_rate, color = education)) +
  geom_line(linewidth = 1) +
  labs(
    title = "Employment Rates by Educational Attainment",
    subtitle = "U.S. adults aged 25-64",
    x = "Year",
    y = "Employment rate (%)",
    color = "Educational attainment"
  ) +
  guides(color = guide_legend(nrow = 2, byrow = TRUE)) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 9),
    plot.title = element_text(face = "bold")
  )

ggsave(file.path(figure_dir, "employment_rate_by_education.png"), plot = p1, width = 10, height = 6, dpi = 300)

# Figure 2: wage
cpi <- read.csv("https://fred.stlouisfed.org/graph/fredgraph.csv?id=CPIAUCSL")
cpi$year <- format(as.Date(cpi$observation_date), "%Y")
cpi_annual <- aggregate(CPIAUCSL ~ year, data = cpi, FUN = mean)
cpi_annual$year <- as.numeric(cpi_annual$year)
cpi_2024 <- cpi_annual %>%
  filter(year == 2024) %>%
  pull(CPIAUCSL)

wage_data <- cps_clean %>%
  filter(!is.na(wage), wage > 0, wage < 99999999) %>%
  left_join(cpi_annual, by = c("labor_year" = "year")) %>%
  mutate(real_wage_2024 = wage * cpi_2024 / CPIAUCSL)

wage_summary <- wage_data %>%
  group_by(labor_year, education) %>%
  summarise(
    median_wage = weighted_median(real_wage_2024, weight),
    n = n(),
    .groups = "drop"
  )

p2 <- ggplot(wage_summary, aes(x = labor_year, y = median_wage, color = education)) +
  geom_line(linewidth = 1) +
  labs(
    title = "Median Annual Wage by Educational Attainment",
    subtitle = "U.S. adults aged 25-64, expressed in 2024 dollars",
    x = "Year",
    y = "Median annual wage (2024 dollars)",
    color = "Educational attainment"
  ) +
  guides(color = guide_legend(nrow = 2, byrow = TRUE)) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 9),
    plot.title = element_text(face = "bold")
  )

ggsave(file.path(figure_dir, "median_wage_by_education.png"), plot = p2, width = 10, height = 6, dpi = 300)

# Figure 3: unemployment share
unemployment_data <- cps_clean %>%
  filter(!is.na(weeks_unem), weeks_unem >= 0, weeks_unem <= 52) %>%
  mutate(any_unemployment = ifelse(weeks_unem > 0, 1, 0)) %>%
  group_by(labor_year, education) %>%
  summarise(
    unemployment_share = weighted_mean(any_unemployment, weight) * 100,
    n = n(),
    .groups = "drop"
  )

p3 <- ggplot(unemployment_data, aes(x = labor_year, y = unemployment_share, color = education)) +
  geom_line(linewidth = 1) +
  labs(
    title = "Share Experiencing Unemployment by Educational Attainment",
    subtitle = "U.S. adults aged 25-64",
    x = "Year",
    y = "Share experiencing unemployment (%)",
    color = "Educational attainment"
  ) +
  guides(color = guide_legend(nrow = 2, byrow = TRUE)) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 9),
    plot.title = element_text(face = "bold")
  )

ggsave(file.path(figure_dir, "unemployment_by_education.png"), plot = p3, width = 10, height = 6, dpi = 300)

message("Project root: ", project_root)
message("Data directory: ", data_dir)
message("Figure directory: ", figure_dir)
message("All figures saved in the repository's figure/ folder.")
