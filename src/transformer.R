suppressPackageStartupMessages(library(tidyverse))

urls <- list(
  cases = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv",
  deaths = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv"
)

dc <- suppressMessages(readr::read_csv(urls$cases))
dd <- suppressMessages(readr::read_csv(urls$deaths))

# need custom parser for date format
fix_date <- function(dt) {
  as.Date(sapply(strsplit(dt, "/"), function(x) {
    x[3] <- paste0("20", x[3])
    paste(sprintf("%02d", as.integer(x[c(3, 1, 2)])), collapse = "-")
  }))
}

# pivot from wide to long, fix date and names
process <- function(x, name) {
  rnm <- function(x)
    gsub("\\/", "_", tolower(x))

  x %>%
    tidyr::pivot_longer(
      cols = ends_with("20"),
      names_to = "date",
      values_to = name) %>%
    dplyr::rename_all(rnm) %>%
    dplyr::mutate(date = fix_date(date))
}

dc <- process(dc, "n_case")
dd <- process(dd, "n_death")

# join cases and deaths
d <- dplyr::left_join(dc, select(dd, -lat, -long),
  by = c("province_state", "country_region", "date"))

# they break things down to admin1 level in some cases - want to roll these up
# however, we want overseas regions / territories to still be separate
fix <- c("Denmark", "France", "Netherlands", "United Kingdom")
idx <- which(dc$country_region %in% fix & dc$province_state != "")
dc$country_region[idx] <- dc$province_state[idx]

admin0 <- d %>%
  dplyr::group_by(country_region, date) %>%
  dplyr::summarise(
    cases = sum(n_case),
    deaths = sum(n_death)) %>%
  dplyr::ungroup() %>%
  dplyr::filter(!(cases == 0 & deaths == 0)) %>%
  dplyr::rename(country = "country_region") %>%
  dplyr::arrange(country, date)

# TODO: need to use "datautils" functions here to get ISO2 codes

# TODO: need to use "datautils" here to roll up to continent, WHO region

global <- admin0 %>%
  dplyr::group_by(date) %>%
  dplyr::summarise(cases = sum(cases), deaths = sum(deaths))

readr::write_csv(admin0, "admin0.csv")
readr::write_csv(global, "global.csv")

# now pull US state and county-level JHU data

us_urls <- list(
  cases = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv",
  deaths = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv"
)

usdc <- suppressMessages(readr::read_csv(us_urls$cases))
usdd <- suppressMessages(readr::read_csv(us_urls$deaths))

us_process <- function(x, name) {
  rnm <- function(x)
    gsub("\\/", "_", tolower(x))

  x %>%
    dplyr::mutate(
      fips_county = sprintf("%05d", FIPS),
      fips_state = substr(fips_county, 1, 2)
    ) %>%
    # 80 and 90 are "out of state" or "unassigned"
    # 88 and 99 are cruise ships
    # 00 have NA FIPS - ignore all these for now
    dplyr::filter(!fips_state %in% c("80", "90", "00", "88", "99")) %>%
    dplyr::select(fips_county, fips_state, tidyselect::ends_with("20")) %>%
    tidyr::pivot_longer(
      cols = ends_with("20"),
      names_to = "date",
      values_to = name) %>%
    dplyr::rename_all(rnm) %>%
    dplyr::mutate(date = fix_date(date))
}

usdc <- us_process(usdc, "cases")
usdd <- us_process(usdd, "deaths")


# join cases and deaths
usd <- dplyr::left_join(usdc, usdd,
  by = c("fips_county", "fips_state", "date"))

# filter out leading days in each county (zero cases)
# and get rid of counties with no cases at all
usd <- usd %>%
  group_by(fips_county) %>%
  mutate(all_zero = all(cases == 0)) %>%
  filter(!all_zero) %>%
  mutate(min_zero_date = min(date[cases > 0])) %>%
  filter(date >= min_zero_date)

usd_state <- usd %>%
  dplyr::group_by(fips_state, date) %>%
  dplyr::summarise(cases = sum(cases), deaths = sum(deaths))

readr::write_csv(usd, "admin2_US.csv")
readr::write_csv(usd_state, "admin1_US.csv")
