#!/bin/sh

find _build/prod/ -name "*.tar.gz" -exec stat -c "%n %Y" {} \; | sort -rnk 2,2 | head -1 | cut -d ' ' -f 1 | xargs realpath
