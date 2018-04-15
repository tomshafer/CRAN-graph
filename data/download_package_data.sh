#!/usr/bin/env sh

# Download all index pages from web/packages
wget \
  --no-parent -nc -r --wait=0.4 -A 'index.html' \
  http://cran.r-project.org/web/packages
