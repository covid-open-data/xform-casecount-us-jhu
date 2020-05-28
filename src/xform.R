suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(geoutils))

dir.create("output", showWarning = FALSE)
dir.create("output/admin0", showWarning = FALSE)
dir.create("output/admin1", showWarning = FALSE)
dir.create("output/admin2", showWarning = FALSE)

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
    # dplyr::mutate(date = parsedate::parse_date(date))
    dplyr::mutate(date = fix_date(date))
}

dc <- process(dc, "n_case")
dd <- process(dd, "n_death")

message("Most recent date for global data: ", max(dc$date))

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

# now need to get ISO2 codes since they don't provide them...
lookup <- suppressMessages(readr::read_csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/UID_ISO_FIPS_LookUp_Table.csv", na = ""))

lookup <- lookup %>%
  dplyr::select(iso2, Country_Region) %>%
  dplyr::distinct() %>%
  dplyr::rename(admin0_code = iso2, country = Country_Region)

lookup$admin0_code[is.na(lookup$admin0_code)] <- "ZZ"

admin0 <- dplyr::left_join(admin0, lookup, by = "country") %>%
  dplyr::select(admin0_code, date, cases, deaths)

continents <- admin0 %>%
  dplyr::left_join(geoutils::admin0, by = "admin0_code") %>%
  dplyr::group_by(continent_code, date) %>%
  dplyr::summarise(cases = sum(cases), deaths = sum(deaths))

who_regions <- admin0 %>%
  dplyr::left_join(geoutils::admin0, by = "admin0_code") %>%
  dplyr::group_by(who_region_code, date) %>%
  dplyr::summarise(cases = sum(cases), deaths = sum(deaths))

global <- admin0 %>%
  dplyr::group_by(date) %>%
  dplyr::summarise(cases = sum(cases), deaths = sum(deaths))

readr::write_csv(admin0, "output/admin0/all.csv")
readr::write_csv(continents, "output/continents.csv")
readr::write_csv(who_regions, "output/who_regions.csv")
readr::write_csv(global, "output/global.csv")

########
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
      admin0_code = "US",
      admin2_code = sprintf("%05d", FIPS),
      admin1_code = substr(admin2_code, 1, 2)
    ) %>%
    # 80 and 90 are "out of state" or "unassigned"
    # 88 and 99 are cruise ships
    # 00 have NA FIPS - ignore all these for now
    dplyr::filter(!admin1_code %in% c("80", "90", "00", "88", "99")) %>%
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
