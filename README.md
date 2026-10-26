# AEDS 6400 Blog Post 3

## Research Purpose

This repository contains the code and data for my AEDS 6400 blog post 3 assignment.

This blog post explores the following question: how are education attainment and labor market outcomes related in the United States, and how does this relationship change over time?

The analysis targets adults in the U.S., aged 25-64, and the observation covers the period of 2000-2024. Individuals are divided into five groups according to educational attainment: less than high school, high school, some college, bachelor's degree, and graduate degree.

I employ the following three dimensions to evaluate labor market outcomes: whether individuals worked during the year, how much their income was (if they worked), and whether they experienced unemployment during the year.

## Data

I use individual samples during the period 2001-2025 because surveys collected information from the previous year instead of the current year. Therefore, the observation window corresponds to 2000-2024.

The main explanatory variable, educational attainment, is measured using the EDUC variable. EDUC records the highest level of schooling or degree completed, therefore covering many grades and degrees.

For the first dimension, we calculate the share of people who worked during the year among the sum for each group. This comes from the variable WORKLY from the CPS dataset. The same is conducted for those who experienced unemployment using UNEMP and labor status indicators.

For the second dimension, we use the variable INCWAGE as the original data source, which reports income in nominal U.S. dollars. We first transfer the income to real terms using the 2024 CPI as the deflator.

All the shares and descriptive values above are calculated in the weighted form according to the person-level sampling weight from the dataset. This enables our findings to depict the whole U.S. labor market.

This produces three consistent time-series visualizations that can be compared directly across education groups.

## Repository Structure

```text
Zhengyang_Ding_AEDS6400_blog3/
├── code/
│   ├── data_analysis.R
│
├── data/
│   ├── cps_00003.xml
│   ├── cps_00003.dat
│
├── figure/
│   ├── employment_rate_by_education.png
│   ├── median_wage_by_education.png
│   └── unemployment_by_education.png
│
├── README.md
└── AEDS6400_blog3.Rproj
```
