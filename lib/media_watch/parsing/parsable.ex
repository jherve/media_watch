defmodule MediaWatch.Parsing.Parsable do
  @callback parse(any()) :: map()
end
