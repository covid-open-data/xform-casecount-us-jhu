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


dsumm <- d %>%
  group_by(country_region, date) %>%
  summarise(
    cases = sum(n_case),
    deaths = sum(n_death)) %>%
  ungroup() %>%
  filter(!(cases == 0 & deaths == 0)) %>%
  rename(region = "country_region")


dc <- process(dc, "n_case")
dd <- process(dd, "n_death")

message("Most recent date for global data: ", max(dc$date))

# join cases and deaths
d <- dplyr::left_join(dc, select(dd, -lat, -long),
  by = c("province_state", "country_region", "date"))

# they break things down to admin1 level in some cases - want to roll these up
# however, we want overseas regions / territories to still be separate
fix <- c("Denmark", "France", "Netherlands", "United Kingdom")
idx <- which(d$country_region %in% fix & d$province_state != "")
d$country_region[idx] <- d$province_state[idx]

admin0 <- d %>%
  dplyr::group_by(country_region, date) %>%
  dplyr::summarise(
    cases = sum(n_case, na.rm = TRUE),
    deaths = sum(n_death, na.rm = TRUE)) %>%
  dplyr::filter(date >= min(date[cases > 0])) %>%
  dplyr::ungroup() %>%
  dplyr::rename(admin0_name = "country_region") %>%
  dplyr::arrange(admin0_name, date)

# now need to get ISO2 codes since they don't provide them...
lookup <- suppressMessages(readr::read_csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/UID_ISO_FIPS_LookUp_Table.csv", na = ""))

lookup <- lookup %>%
  dplyr::select(iso2, Country_Region) %>%
  dplyr::distinct() %>%
  dplyr::rename(admin0_code = iso2, admin0_name = Country_Region)

# need to fix issue with countries with multiple country codes
repeats <- lookup %>%
  group_by(admin0_name) %>%
  tally() %>%
  filter(n > 1) %>%
  pull(admin0_name)

lookup %>%
  group_by(admin0_name) %>%
  slice(1) %>%
  filter(admin0_name %in% repeats)
# 1 CN          China         
# 2 DK          Denmark       
# 3 FR          France        
# 4 NL          Netherlands   
# 5 GB          United Kingdom
# 6 US          US   

lookup <- lookup %>%
  group_by(admin0_name) %>%
  slice(1)

lookup$admin0_code[is.na(lookup$admin0_code)] <- "ZZ"

admin0 <- dplyr::left_join(admin0, lookup, by = "admin0_name") %>%
  dplyr::select(admin0_code, date, cases, deaths)

continents <- admin0 %>%
  dplyr::left_join(geoutils::admin0, by = "admin0_code") %>%
  dplyr::group_by(continent_code, date) %>%
  dplyr::filter(!is.na(continent_code)) %>%
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
