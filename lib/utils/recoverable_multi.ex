defmodule MediaWatch.RecoverableMulti do
  @moduledoc "An extension of `Ecto.Multi` that can auto-recover if some ignored operations fail"

  alias Ecto.Multi

  @type wrap_intermediate ::
          (intermediate_result :: any -> {:ok, any} | {:ignore, any} | {:error, any})

  @spec new(Multi.t(), wrap_intermediate) :: Multi.t()
  def new(multi = %Multi{}, wrap_intermediate_result)
      when is_function(wrap_intermediate_result, 1) do
    multi
    |> Multi.to_list()
    |> Enum.reduce(Multi.new(), fn {name, {:insert, cs, []}}, multi ->
      multi
      |> Multi.run(name, fn repo, _ ->
        # All the operations within the transaction are assumed to be 'successful'
        # whatever their actual result, so that the whole transaction can complete.
        {:ok, repo.insert(cs) |> wrap_intermediate_result.()}
      end)
    end)
    |> Multi.run(:control_stage, &fail_if_any_error/2)
  end

  @spec remove_steps(Multi.t(), [binary()]) :: Multi.t()
  def remove_steps(multi = %Multi{}, names) do
    multi
    |> Multi.to_list()
    |> Enum.reject(fn {step, _} -> step in names end)
    |> Enum.reduce(Multi.new(), fn
      {name, {operation, cs, []}}, multi -> apply(Multi, operation, [multi, name, cs])
      {name, {operation, fun}}, multi -> apply(Multi, operation, [multi, name, fun])
    end)
  end

  @spec is_empty?(Multi.t()) :: boolean()
  def is_empty?(multi = %Multi{}), do: multi |> Multi.to_list() |> length() == 1

  @spec wrap_transaction_result(result :: any()) ::
          {:ok, ok :: map()}
          | {:error, ok :: map(), ignored :: map(), failed :: map()}
  def wrap_transaction_result({:error, :control_stage, nil, changes}) do
    res =
      changes
      |> Enum.group_by(&categorize_intermediate/1)
      |> Map.new(fn {k, v} -> {k, v |> Map.new(&unwrap_intermediate/1)} end)

    {:error, res |> Map.get(:ok, %{}), res |> Map.get(:ignore, %{}), res |> Map.get(:error, %{})}
  end

  def wrap_transaction_result({:ok, changes}) do
    res =
      changes
      |> Map.drop([:control_stage])
      |> Enum.group_by(&categorize_intermediate/1)
      |> Map.new(fn {k, v} -> {k, v |> Map.new(&unwrap_intermediate/1)} end)

    {:ok, res |> Map.get(:ok, %{})}
  end

  defp categorize_intermediate({_k, {:error, _v}}), do: :error
  defp categorize_intermediate({_k, {:ignore, _v}}), do: :ignore
  defp categorize_intermediate({_k, {:ok, _v}}), do: :ok

  defp unwrap_intermediate({k, {type, v}}) when type in [:ignore, :ok, :error], do: {k, v}

  defp fail_if_any_error(_repo, changes) do
    # If there is any actual error within the transaction's operations, the
    # final stage enforces a rollback. Ignored stages are also rolled back
    # because they might consist of several operations, some of which might
    # have completed (e.g. insertion of an object whose associated object violates
    # some unique constraint)
    case changes |> Enum.group_by(&categorize_intermediate/1) |> Map.new() do
      map when is_map_key(map, :error) or is_map_key(map, :ignore) ->
        {:error, nil}

      _only_ok_map = %{ok: _} ->
        {:ok, nil}
    end
  end
end
