defmodule MediaWatch.Repo.Migrations.AddShowOccurrenceLock do
  use Ecto.Migration

  def change do
    table = "show_occurrences_invitations"

    [
      {"delete", "BEFORE DELETE", "OLD"},
      {"insert", "BEFORE INSERT", "NEW"},
      {"update", "BEFORE UPDATE", "NEW"}
    ]
    |> Enum.each(&install_triggers_on_table(table, &1))
  end

  defp install_triggers_on_table(table, {name, operation, row}) do
    trigger_name = "#{table}_check_lock_on_#{name}"

    execute_trigger(
      trigger_name,
      table,
      "SELECT RAISE(ABORT, \"trigger:#{trigger_name}:show_occurrence_locked\")",
      operation: operation,
      when:
        "EXISTS(SELECT 1 FROM show_occurrences so WHERE so.id = #{row}.show_occurrence_id AND so.\"manual_edited?\")"
    )
  end

  defp execute_trigger(name, table, code, opts) do
    {operation, opts} = opts |> Keyword.pop!(:operation)
    {when_stmt, opts} = opts |> Keyword.pop(:when)

    unless opts |> Enum.empty?(),
      do: raise("Unknown options in opts : #{opts |> Keyword.keys() |> inspect}")

    operation_stmt = "#{operation} ON #{table}"
    when_stmt = unless is_nil(when_stmt), do: "WHEN #{when_stmt}", else: ""

    execute(
      """
      CREATE TRIGGER #{name}
      #{operation_stmt}
      #{when_stmt}
      BEGIN
        #{code};
      END;
      """,
      "DROP TRIGGER #{name}"
    )
  end
end
