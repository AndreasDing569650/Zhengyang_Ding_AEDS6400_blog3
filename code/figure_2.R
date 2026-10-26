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
# Weighted median
# ============================================================

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
  
  x[
    which(
      cumulative_weight >= cutoff
    )[1]
  ]
}

# ============================================================
# Figure 2: Wage
# ============================================================

wage_data <- cps_clean %>%
  filter(
    !is.na(wage),
    wage > 0,
    wage < 99999999
  )

cpi <- read.csv(
  "https://fred.stlouisfed.org/graph/fredgraph.csv?id=CPIAUCSL"
)

cpi$year <- format(
  as.Date(cpi$observation_date),
  "%Y"
)

cpi_annual <- aggregate(
  CPIAUCSL ~ year,
  data = cpi,
  FUN = mean
)

cpi_annual$year <- as.numeric(
  cpi_annual$year
)

cpi_2024 <- cpi_annual %>%
  filter(
    year == 2024
  ) %>%
  pull(
    CPIAUCSL
  )

wage_data <- wage_data %>%
  left_join(
    cpi_annual,
    by = c("labor_year" = "year")
  ) %>%
  mutate(
    real_wage_2024 =
      wage * cpi_2024 / CPIAUCSL
  )

wage_summary <- wage_data %>%
  group_by(
    labor_year,
    education
  ) %>%
  summarise(
    median_wage =
      weighted_median(
        real_wage_2024,
        weight
      ),
    n = n(),
    .groups = "drop"
  )

ggplot(
  wage_summary,
  aes(
    x = labor_year,
    y = median_wage,
    color = education
  )
) +
  geom_line(
    linewidth = 1
  ) +
  labs(
    title = "Median Annual Wage by Educational Attainment",
    subtitle = "U.S. adults aged 25-64, expressed in 2024 dollars",
    x = "Year",
    y = "Median annual wage (2024 dollars)",
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
  "median_wage_by_education.png",
  width = 10,
  height = 6,
  dpi = 300
)