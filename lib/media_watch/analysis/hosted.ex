defmodule MediaWatch.Analysis.Hosted do
  @doc "Get the list of hosts"
  @callback get_hosts() :: [binary()]

  @doc "Get a list of alternate hosts"
  @callback get_alternate_hosts() :: [binary()]

  @optional_callbacks get_alternate_hosts: 0
end
