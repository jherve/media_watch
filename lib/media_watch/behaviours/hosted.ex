defmodule MediaWatch.Analysis.Hosted do
  @doc "Get the list of hosts"
  @callback get_hosts() :: [binary()]

  @doc "Get a list of alternate hosts"
  @callback get_alternate_hosts() :: [binary()]

  @doc "Get a list of usual columnists"
  @callback get_columnists() :: [binary()]

  @optional_callbacks get_alternate_hosts: 0, get_columnists: 0

  def get_all_hosts(hosted) do
    hosted.get_hosts() ++
      if(function_exported?(hosted, :get_alternate_hosts, 0),
        do: hosted.get_alternate_hosts(),
        else: []
      ) ++
      if(function_exported?(hosted, :get_columnists, 0),
        do: hosted.get_columnists(),
        else: []
      )
  end
end
