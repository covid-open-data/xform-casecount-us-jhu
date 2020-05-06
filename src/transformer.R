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
  x %>%
    tidyr::pivot_longer(
      cols = ends_with("20"),
      names_to = "date",
      values_to = name) %>%
    dplyr::rename(
      province_state = "Province/State",
      country_region = "Country/Region") %>%
    dplyr::rename_all(tolower) %>%
    dplyr::mutate(date = fix_date(date))
}

dc <- process(dc, "n_case")
dd <- process(dd, "n_death")

# join cases and deaths
d <- left_join(dc, select(dd, -lat, -long),
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

readr::write_csv(admin0, "admin0.csv")

# TODO: need to use "datautils" here to roll up to continent, WHO region

global <- admin0 %>%
  dplyr::group_by(date) %>%
  dplyr::summarise(cases = sum(cases), deaths = sum(deaths))

readr::write_csv(admin0, "global.csv")
