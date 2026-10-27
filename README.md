# AEDS 6400 Blog Post 3

## Research Purpose

This repository contains the code and data for my AEDS 6400 blog post 3 assignment.

This blog post explores the following question: how are educational attainment and labor market outcomes related in the United States, and how does this relationship change over time?

The analysis focuses on U.S. adults ages 25-64 and covers the period from 2000 to 2024. Individuals are divided into five groups based on educational attainment: less than high school, high school diploma, some college / associate degree, four-year college / bachelor's degree, and graduate degree.

I use three outcome dimensions to evaluate labor market performance:

- whether individuals worked during the year
- how much income they earned if they worked
- how long individuals spent looking for work or being on layoff

These measures are then compared across education groups over time to show how educational differences in labor market outcomes evolve.

## Data

The analysis uses CPS ASEC microdata from IPUMS for the years 2001-2025. The survey records information for the previous year, so the labor-market measures are aligned to the period 2000-2024.

The main explanatory variable is educational attainment, measured using the `EDUC` variable. `EDUC` records the highest level of schooling or degree completed and is used to construct the five education groups.

For the employment measure, I calculate the weighted share of adults who worked during the year using `WORKLY`. For the income measure, I use `INCWAGE` and convert nominal earnings into real 2024 dollars using the CPI. For the job-search measure, I use `WKSUNEM1`, which records the number of weeks a person spent looking for work or on layoff.

All estimates are computed using the person-level sampling weight (`ASECWT`) so the results represent the broader U.S. adult population.

## Repository Structure

The repository is organized into separate R scripts for each figure, with one script responsible for the data preparation and plotting of each outcome.

```text
Zhengyang_Ding_AEDS6400_blog3/
├── code/
│   ├── figure_1.R
│   ├── figure_2.R
│   └── figure_3.R
│
├── data/
│   ├── cps_00003.xml
│
├── figure/
│   ├── employment_rate_by_education.png
│   ├── median_wage_by_education.png
│   └── average_weeks_unem_by_education.png
│
├── README.md
├── .gitignore
└── AEDS6400_blog3.Rproj
```

## What each code script does

The project is split into three separate plotting scripts in the `code/` folder. Each script reads the same CPS data, applies the same age and education filtering, and saves one figure to the `figure/` folder.

- `code/figure_1.R` creates the employment-rate figure.
  - It filters the sample to adults ages 25-64.
  - It maps each respondent to an education group.
  - It calculates the weighted employment rate by year and education level.
  - It saves the result as `figure/employment_rate_by_education.png`.

- `code/figure_2.R` creates the wage figure.
  - It uses `INCWAGE` and converts wages to real 2024 dollars using the CPI.
  - It computes the weighted median annual wage by year and education group.
  - It saves the result as `figure/median_wage_by_education.png`.

- `code/figure_3.R` creates the job-search duration figure.
  - It uses `WKSUNEM1` to measure the average number of weeks spent looking for work or on layoff.
  - This figure is framed as a measure of labor market friction and difficulty in job matching, rather than simply unemployment share.
  - It saves the result as `figure/average_weeks_unem_by_education.png`.

Together, these three scripts produce a consistent set of figures showing how employment, wages, and job-search duration vary by education level over time.

## Input data

This project requires the CPS ASEC IPUMS extract files in the `data/` directory.

The script looks for:

- `data/cps_00003.xml` — the IPUMS DDI metadata file
- one matching microdata file such as:
  - `cps_00003.dat`
  - `cps_00003.dat.gz`
  - `cps_00003.csv`
  - `cps_00003.csv.gz`

The scripts rely on the following variables from the CPS data:

- `YEAR`
- `AGE`
- `EDUC`
- `WORKLY`
- `INCWAGE`
- `WKSUNEM1`
- `ASECWT`

## Output files

Running the scripts creates the following outputs in the `figure/` directory:

- `employment_rate_by_education.png` — employment rate by year and educational attainment
- `median_wage_by_education.png` — median annual wage by year and educational attainment, adjusted to 2024 dollars
- `average_weeks_unem_by_education.png` — average number of weeks looking for work or on layoff by year and educational attainment

## How to reproduce the analysis

1. Open the project in RStudio using `AEDS6400_blog3.Rproj` or set the working directory to the project root.
2. Install the required packages if they are not already installed:

```r
install.packages(c("ipumsr", "dplyr", "ggplot2", "tidyr", "readr"))
```

3. Place the required CPS metadata and microdata files into the `data/` folder.
4. Run the plotting scripts individually:

```r
source("code/figure_1.R")
source("code/figure_2.R")
source("code/figure_3.R")
```

5. Check the generated figures in the `figure/` folder.

If the data files are missing, the script will stop with a clear error message explaining which file is required.
