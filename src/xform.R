suppressPackageStartupMessages(library(tidyverse))

dir.create("output", showWarning = FALSE)
dir.create("output/admin0", showWarning = FALSE)
dir.create("output/admin1", showWarning = FALSE)
dir.create("output/admin2", showWarning = FALSE)

us_urls <- list(
  cases = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv",
  deaths = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv"
)

usdc <- suppressMessages(readr::read_csv(us_urls$cases))
usdd <- suppressMessages(readr::read_csv(us_urls$deaths))

# need custom parser for date format
fix_date <- function(dt) {
  as.Date(sapply(strsplit(dt, "/"), function(x) {
    x[3] <- paste0("20", x[3])
    paste(sprintf("%02d", as.integer(x[c(3, 1, 2)])), collapse = "-")
  }))
}

us_process <- function(x, name) {
  rnm <- function(x)
    gsub("\\/", "_", tolower(x))

  x %>%
    dplyr::mutate(
      admin0_code = "US",
      admin2_code = sprintf("%05d", FIPS),
      admin1_code = substr(admin2_code, 1, 2)
    ) %>%
    # 80 and 90 are "out of state" or "unassigned"
    # 88 and 99 are cruise ships
    # 00 have NA FIPS - ignore all these for now
    dplyr::filter(!admin1_code %in% c("  ", "80", "90", "00", "88", "99")) %>%
    dplyr::select(admin0_code, admin1_code, admin2_code,
      tidyselect::ends_with("20")) %>%
    tidyr::pivot_longer(
      cols = ends_with("20"),
      names_to = "date",
      values_to = name) %>%
    dplyr::rename_all(rnm) %>%
    dplyr::mutate(date = fix_date(date))
}

usdc <- us_process(usdc, "cases")
usdd <- us_process(usdd, "deaths")

message("Most recent date for US data: ", max(usdc$date))

# join cases and deaths
usd <- dplyr::left_join(usdc, usdd,
  by = c("admin0_code", "admin2_code", "admin1_code", "date"))

usd_country <- usd %>%
  dplyr::group_by(admin0_code, date) %>%
  dplyr::summarise(cases = sum(cases), deaths = sum(deaths))

# filter out leading days in each county (zero cases)
# and get rid of counties with no cases at all
usd <- usd %>%
  dplyr::group_by(admin2_code) %>%
  dplyr::mutate(all_zero = all(cases == 0)) %>%
  dplyr::filter(!all_zero) %>%
  dplyr::mutate(min_zero_date = min(date[cases > 0])) %>%
  dplyr::filter(date >= min_zero_date) %>%
  dplyr::select(-all_zero, -min_zero_date)

usd_state <- usd %>%
  dplyr::group_by(admin0_code, admin1_code, date) %>%
  dplyr::summarise(cases = sum(cases), deaths = sum(deaths))

readr::write_csv(usd, "output/admin2/US.csv")
readr::write_csv(usd_state, "output/admin1/US.csv")
readr::write_csv(usd_country, "output/admin0/US.csv")
