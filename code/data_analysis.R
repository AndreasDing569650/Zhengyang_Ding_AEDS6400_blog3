library(ipumsr)
library(dplyr)
library(ggplot2)
library(tidyr)
library(readr)

ddi <- read_ipums_ddi(
  "C:/Users/lenovo/Desktop/AEDS6400_blog3/data/cps_00003.xml"
)
cps <- read_ipums_micro(ddi)

dim(cps)
names(cps)
summary(cps$AGE)
summary(cps$EDUC)
summary(cps$WORKLY)
summary(cps$INCWAGE)
summary(cps$WKSUNEM1)
summary(cps$ASECWT)

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
head(cps_clean)
summary(cps_clean)

cps_clean <- cps_clean %>%
  filter(
    age >= 25,
    age <= 64,
    !is.na(weight),
    weight > 0
  )
nrow(cps_clean)
summary(cps_clean$age)

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
table(cps_clean$education)
prop.table(
  table(cps_clean$education)
)
table(
  cps_clean$work_code,
  useNA = "ifany"
)
summary(cps_clean$wage)
table(
  cps_clean$wage == 99999999,
  useNA = "ifany"
)
table(
  cps_clean$weeks_unem,
  useNA = "ifany"
)

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


# figure 1

employment_data <- cps_clean %>%
  filter(
    work_code %in% c(1, 2)
  ) %>%
  mutate(
    worked = ifelse(
      work_code == 2,
      1,
      0
    )
  ) %>%
  group_by(
    labor_year,
    education
  ) %>%
  summarise(
    employment_rate =
      weighted_mean(
        worked,
        weight
      ) * 100,
    n = n(),
    .groups = "drop"
  )
head(employment_data)
summary(
  employment_data$employment_rate
)
ggplot(
  employment_data,
  aes(
    x = labor_year,
    y = employment_rate,
    color = education
  )
) +
  geom_line(
    linewidth = 1
  ) +
  labs(
    title = "Employment Rates by Educational Attainment",
    subtitle = "U.S. adults aged 25-64",
    x = "Year",
    y = "Employment rate (%)",
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
  "employment_rate_by_education.png",
  width = 10,
  height = 6,
  dpi = 300
)

# figure 2

wage_data <- cps_clean %>%
  filter(
    !is.na(wage),
    wage > 0,
    wage < 99999999
  )
cpi <- read.csv(
  "https://fred.stlouisfed.org/graph/fredgraph.csv?id=CPIAUCSL"
)
head(cpi)
names(cpi)
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
head(cpi_annual)
tail(cpi_annual)
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
summary(
  wage_data$real_wage_2024
)
sum(
  is.na(wage_data$CPIAUCSL)
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
head(wage_summary)
summary(
  wage_summary$median_wage
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

# figure 3

unemployment_data <- cps_clean %>%
  filter(
    !is.na(weeks_unem),
    weeks_unem >= 0,
    weeks_unem <= 52
  ) %>%
  mutate(
    any_unemployment =
      ifelse(
        weeks_unem > 0,
        1,
        0
      )
  ) %>%
  group_by(
    labor_year,
    education
  ) %>%
  summarise(
    unemployment_share =
      weighted_mean(
        any_unemployment,
        weight
      ) * 100,
    n = n(),
    .groups = "drop"
  )
head(unemployment_data)
summary(
  unemployment_data$unemployment_share
)
ggplot(
  unemployment_data,
  aes(
    x = labor_year,
    y = unemployment_share,
    color = education
  )
) +
  geom_line(
    linewidth = 1
  ) +
  labs(
    title = "Share Experiencing Unemployment by Educational Attainment",
    subtitle = "U.S. adults aged 25-64",
    x = "Year",
    y = "Share experiencing unemployment (%)",
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
  "unemployment_by_education.png",
  width = 10,
  height = 6,
  dpi = 300
)