# AEDS 6400 Blog Post 3

## Research Purpose

This repository contains the code and data for my AEDS 6400 blog post 3 assignment.

This blog post explores the following question: how are education attainment and labor market outcomes related in the United States, and how does this relationship change over time?

The analysis targets adults in the U.S., aged 25-64, and the observation covers the period of 2000-2024. Individuals are divided into five groups according to educational attainment: less than high school, high school diploma, some college/associate degree, bachelor's degree, and graduate degree.

I employ the following three dimensions to evaluate labor market outcomes: whether individuals worked during the year, how much their income was (if they worked), and whether they experienced unemployment.

## Data

I use individual samples during the period 2001-2025 because surveys collected information from the previous year instead of the current year. Therefore, the observation window corresponds to 2000-2024 in calendar-year terms.

The main explanatory variable, educational attainment, is measured using the EDUC variable. EDUC records the highest level of schooling or degree completed, therefore covering many grades and degree categories.

For the first dimension, we calculate the share of people who worked during the year among the sum for each group. This comes from the variable WORKLY from the CPS dataset. The same is conducted for the unemployment outcome using the variable WKSUNEM1.

For the second dimension, we use the variable INCWAGE as the original data source, which reports income in nominal U.S. dollars. We first transfer the income to real terms using the 2024 CPI as the deflator, then summarize the typical pay level by education group.

All the shares and descriptive values above are calculated in the weighted form according to the person-level sampling weight from the dataset. This enables our findings to depict the whole U.S. labor market rather than only the observed sample.

This produces three consistent time-series visualizations that can be compared directly across education groups.

## Repository Structure

Regarding data, because the DAT file of the original data, as well as the cleaned data, are too large to be uploaded to GitHub (over 25mb), and there are potential copyright problems with the data source, only the metadata file and processed outputs are included here.

```text
Zhengyang_Ding_AEDS6400_blog3/
├── code/
│   ├── data_analysis.R
│
├── data/
│   ├── cps_00003.xml
│
├── figure/
│   ├── employment_rate_by_education.png
│   ├── median_wage_by_education.png
│   └── unemployment_by_education.png
│
├── README.md
└── AEDS6400_blog3.Rproj
```

## What the code does

The script `code/data_analysis.R` reads the CPS microdata and metadata stored in the `data/` folder, filters the sample to U.S. adults ages 25-64, and classifies respondents into education groups.

It then computes annual weighted estimates of:

- employment rate
- median annual wage in 2024 dollars
- unemployment share

Finally, it saves three plots to the `figure/` folder:

- `employment_rate_by_education.png`
- `median_wage_by_education.png`
- `unemployment_by_education.png`

The purpose of the analysis is to compare labor market outcomes across education levels and examine how these differences change over time.

## Input data

This project requires the CPS ASEC IPUMS extract files in the `data/` directory.

The script looks for:

- `data/cps_00003.xml` — the IPUMS DDI metadata file
- one matching microdata file such as:
  - `cps_00003.dat`
  - `cps_00003.dat.gz`
  - `cps_00003.csv`
  - `cps_00003.csv.gz`

The script relies on the following variables from the CPS data:

- `YEAR`
- `AGE`
- `EDUC`
- `WORKLY`
- `INCWAGE`
- `WKSUNEM1`
- `ASECWT`

## Output files

Running the script creates the following output in the `figure/` directory:

- `employment_rate_by_education.png` — employment rate by year and educational attainment
- `median_wage_by_education.png` — median annual wage by year and educational attainment, adjusted to 2024 dollars
- `unemployment_by_education.png` — unemployment share by year and educational attainment

## How to reproduce the analysis

1. Open the project in RStudio using `AEDS6400_blog3.Rproj` or set the working directory to the project root.
2. Install the required packages if they are not already installed:

```r
install.packages(c("ipumsr", "dplyr", "ggplot2", "tidyr", "readr"))
```

3. Place the required CPS metadata and microdata files into the `data/` folder.
4. Run the analysis script:

```r
source("code/data_analysis.R")
```

5. Check the generated figures in the `figure/` folder.

If the data files are missing, the script will stop with a clear error message explaining which file is required.
