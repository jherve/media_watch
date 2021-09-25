defmodule MediaWatch.Catalog.ItemSupervisor do
  use Supervisor
  alias MediaWatch.Catalog
  alias MediaWatch.Catalog.ItemTask

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = Catalog.all() |> Enum.map(&Supervisor.child_spec({ItemTask, &1}, id: &1))

    Catalog.try_to_insert_all_channels()

    Supervisor.init(children, strategy: :one_for_one)
  end
end
