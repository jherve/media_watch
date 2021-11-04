#!/bin/sh

get_app() {
  mix run --no-start -e "Mix.Project.config[:app] |> IO.puts" | tail -1
}

APP_NAME=`get_app`

find _build/prod/rel/$APP_NAME/releases -type d -exec stat -c "%n %Y" {} \; | sort -rnk 2,2 | head -1 | cut -d ' ' -f 1 | xargs realpath
