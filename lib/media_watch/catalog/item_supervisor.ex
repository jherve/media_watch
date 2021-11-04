defmodule MediaWatch.Catalog.ItemSupervisor do
  use Supervisor
  require Logger
  alias MediaWatch.Catalog
  alias MediaWatch.Catalog.ItemWorker

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = Catalog.all() |> Enum.map(&Supervisor.child_spec({ItemWorker, &1}, id: &1))

    case Catalog.try_to_insert_all_channels() do
      {:error, e} -> Logger.error("Could not insert channels : #{inspect(e)}")
      _ -> nil
    end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
