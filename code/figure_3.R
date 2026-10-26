library(ipumsr)
library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)

# ============================================================
# Data loading
# ============================================================

ddi <- read_ipums_ddi(
  "D:/Rproject/6400_blog_3/cps_00003.xml"
)

cps <- read_ipums_micro(ddi)

# ============================================================
# Data cleaning
# ============================================================

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
  )

cps_clean <- cps_clean %>%
  filter(
    age >= 25,
    age <= 64,
    !is.na(weight),
    weight > 0
  )

cps_clean <- cps_clean %>%
  mutate(
    education = case_when(
      educ_code >= 2 & educ_code <= 72 ~
        "Less than high school",
      educ_code == 73 ~
        "High school diploma",
      educ_code >= 80 & educ_code <= 100 ~
        "Some college / Associate",
      educ_code %in% c(110, 111) ~
        "4 years college / Bachelor's",
      educ_code >= 120 & educ_code <= 125 ~
        "5+ years college / Graduate",
      TRUE ~ NA_character_
    )
  )

cps_clean <- cps_clean %>%
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
  )

cps_clean <- cps_clean %>%
  filter(!is.na(education))

# ============================================================
# Weighted mean
# ============================================================

weighted_mean <- function(x, w) {
  
  valid <- !is.na(x) &
    !is.na(w) &
    is.finite(x) &
    is.finite(w) &
    w > 0
  
  if (!any(valid)) {
    return(NA_real_)
  }
  
  weighted.mean(
    x[valid],
    w[valid]
  )
}

# ============================================================
# Figure 3: Weeks looking for work or on layoff
# ============================================================

unemployment_data <- cps_clean %>%
  filter(
    !is.na(weeks_unem),
    weeks_unem >= 0,
    weeks_unem <= 51
  ) %>%
  group_by(
    labor_year,
    education
  ) %>%
  summarise(
    avg_weeks_unem =
      weighted_mean(
        weeks_unem,
        weight
      ),
    n = n(),
    .groups = "drop"
  )

ggplot(
  unemployment_data,
  aes(
    x = labor_year,
    y = avg_weeks_unem,
    color = education
  )
) +
  geom_line(
    linewidth = 1
  ) +
  labs(
    title = "Average Weeks Looking for Work or on Layoff by Educational Attainment",
    subtitle = "U.S. adults aged 25-64",
    x = "Year",
    y = "Average weeks",
    color = "Educational attainment"
  ) +
  guides(
    color = guide_legend(
      nrow = 2,
      byrow = TRUE
    )
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 9),
    plot.title = element_text(face = "bold")
  )

ggsave(
  "average_weeks_unem_by_education.png",
  width = 10,
  height = 6,
  dpi = 300
)