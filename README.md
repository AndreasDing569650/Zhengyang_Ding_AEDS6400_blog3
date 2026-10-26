source(file.path(getwd(), "code", "01_paths_and_setup.R"))

library(ggplot2)
library(dplyr)
library(tidyr)

clean_data_path <- file.path(data_dir, "cps_clean.rds")
if (!file.exists(clean_data_path)) {
  stop(
    "Cleaned CPS data not found at ", clean_data_path,
    ". Run code/02_data_preparation.R first to generate the cleaned dataset."
  )
}

cps_clean <- readRDS(clean_data_path)

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

cpi <- read.csv("https://fred.stlouisfed.org/graph/fredgraph.csv?id=CPIAUCSL")
cpi$year <- format(as.Date(cpi$observation_date), "%Y")
cpi_annual <- aggregate(CPIAUCSL ~ year, data = cpi, FUN = mean)
cpi_annual$year <- as.numeric(cpi_annual$year)
cpi_2024 <- cpi_annual %>% filter(year == 2024) %>% pull(CPIAUCSL)

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

message("Saved figures to: ", figure_dir)
