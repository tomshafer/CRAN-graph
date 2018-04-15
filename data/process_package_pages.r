## Process a bunch of CRAN package index pages to extract as much
## metadata as they'll give us.
## 2018-04-15

library(magrittr)
library(tidyverse)
library(rvest)
library(here)
library(pbapply)


## Get the raw data

get_package_name <- . %>%
  html_node("h2") %>%
  html_text() %>%
  str_extract("^[^:]+")

get_package_info <- . %>%
  html_nodes("table") %>%
  extract2(1) %>%
  html_table(header = FALSE) %>%
  mutate(X1 = str_trim(str_to_lower(str_remove_all(X1, "[^a-zA-Z]")))) %>%
  spread(X1, X2)

make_package_tbl <- function(file_path, verbose = FALSE) {
  if (verbose) {
    message(file_path)
  }

  html_tree <- read_html(file_path)
  pkg_name  <- html_tree %>% get_package_name()
  pkg_table <- html_tree %>% get_package_info()
  pkg_table$package <- pkg_name

  pkg_table
}


# This takes quite a while, but pblapply() was bailing out for some reason
package_data <- list.files(
  here("data/cran.r-project.org/web/packages"),
  recursive = TRUE, pattern = "index.html",
  full.names = TRUE) %>%
  map_df(make_package_tbl) %>%
  as_tibble()

package_data


## Parse into nodes and edges

# Elementwise: Split a character vector into pieces, get rid of version
# numbers, and collect per-package lists of package names. Return a list
# fopr, e.g., list columns.
get_ref_names <- . %>%
  str_split(",") %>%
  map(~ map_chr(str_split(str_trim(.x), " "), ~ .x[[1]]))


package_names <- package_data %>%
  select(package, depends, imports, linkingto, enhances, suggests)

package_names <- package_names %>%
  mutate_at(vars(-package), get_ref_names)

# Unnest everything for igraph, etc.
package_names <- package_names %>%
  rename(from = package) %>%
  gather(type, to, -from) %>%
  unnest(to) %>%
  mutate(type = str_to_title(type)) %>%
  select(from, to, everything())


package_data %>% saveRDS(here("data/package_data.rds"))
package_names %>% saveRDS(here("data/package_names.rds"))
