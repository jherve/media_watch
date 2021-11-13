defmodule MediaWatchInventory do
  alias Ecto.Multi
  alias MediaWatch.{Repo, Catalog}
  alias MediaWatch.Catalog.{Item, Channel, ChannelItem}
  @config Application.compile_env(:media_watch, __MODULE__)
  @items @config[:items]
  @channels @config[:channels]

  def all_channel_modules(), do: @channels |> Keyword.keys()

  def all(), do: @items |> Keyword.keys()

  # TODO: All this code should certainly be defined by leveraging an Inventory behaviour
  # that would allow it to be contained in a generic module of catalog, instead of in
  # this "implementation" of the Inventory
  def insert_all() do
    with {:ok, _} <- inventory_multi() |> Repo.transaction(), do: :ok
  rescue
    e -> {:error, e}
  end

  defp inventory_multi() do
    channels_multi()
    |> Multi.append(items_multi())
    |> Multi.append(channel_items_multi())
  end

  defp channels_multi() do
    config_maps = @channels |> as_list_of_maps()

    channels_in_db_multi()
    |> Multi.merge(&insert_if_missing(&1, config_maps, Channel))
  end

  defp items_multi() do
    config_maps = @items |> as_list_of_maps()

    items_in_db_multi()
    |> Multi.merge(&insert_if_missing(&1, config_maps, Item))
  end

  defp items_in_db_multi(),
    do:
      Catalog.all_items()
      |> Enum.reduce(Multi.new(), &put_fake_multi_stage/2)

  defp channels_in_db_multi(),
    do:
      Catalog.all_channels()
      |> Enum.reduce(Multi.new(), &put_fake_multi_stage/2)

  defp channel_items_multi() do
    @items
    |> as_list_of_maps()
    |> Enum.flat_map(fn attrs -> attrs.channels |> Enum.map(&{attrs.module, &1}) end)
    |> Enum.reduce(Multi.new(), fn ci = {item_module, channel_module}, multi ->
      multi
      |> Multi.run(
        ci,
        fn repo, %{^item_module => %{id: item_id}, ^channel_module => %{id: channel_id}} ->
          insert_channel_item_or_ignore(repo, item_id, channel_id)
        end
      )
    end)
  end

  defp insert_channel_item_or_ignore(repo, item_id, channel_id) do
    case %{item_id: item_id, channel_id: channel_id} |> ChannelItem.changeset() |> repo.insert do
      ok = {:ok, _} -> ok
      {:error, e} -> if ChannelItem.is_unique_error?(e), do: {:ok, :unique}, else: {:error, e}
    end
  end

  defp as_list_of_maps(inventory_config),
    do:
      inventory_config
      |> Enum.map(fn {module, attrs} -> attrs |> Map.new() |> Map.put(:module, module) end)

  defp put_fake_multi_stage(%{module: module, id: id}, multi = %Multi{}),
    do: multi |> Multi.put(module, %{id: id})

  defp insert_if_missing(changes, config_maps, struct)
       when is_map(changes) and is_list(config_maps) and is_atom(struct),
       do:
         config_maps
         |> Enum.reduce(Multi.new(), &add_insert_stage_if_not_in_changes(struct, &1, &2, changes))

  defp add_insert_stage_if_not_in_changes(
         struct,
         attrs = %{module: module},
         multi = %Multi{},
         changes
       )
       when is_atom(struct) and is_map(changes),
       do:
         if(Map.has_key?(changes, module),
           do: multi,
           else: multi |> Multi.insert(module, attrs |> struct.changeset())
         )
end
