defmodule EctoDiff do
  @moduledoc """
  Generates a data structure describing the difference between two Ecto structs.
  """

  alias Ecto.Association.NotLoaded

  @type effect :: :added | :deleted | :changed | :replaced

  @type t :: %__MODULE__{
          struct: atom(),
          primary_key: %{required(atom()) => any()},
          changes: %{required(atom()) => any()},
          effect: effect(),
          previous: Ecto.Schema.t(),
          current: Ecto.Schema.t()
        }

  defstruct [:struct, :primary_key, :changes, :effect, :previous, :current]

  @spec diff(Ecto.Schema.t() | nil, Ecto.Schema.t()) :: {:ok, t()} | {:ok, :unchanged}
  def diff(previous, current) do
    diff = do_diff(previous, current)

    if no_changes?(diff) do
      {:ok, :unchanged}
    else
      {:ok, diff}
    end
  end

  defp do_diff(nil, %struct{} = current) do
    previous = struct!(struct)
    diff = do_diff(previous, current)
    %{diff | effect: :added}
  end

  defp do_diff(%struct{} = previous, nil) do
    primary_key_fields = struct.__schema__(:primary_key)

    %__MODULE__{
      struct: struct,
      primary_key: Map.take(previous, primary_key_fields),
      changes: %{},
      effect: :deleted,
      previous: previous,
      current: nil
    }
  end

  defp do_diff(%struct{} = previous, %struct{} = current) do
    primary_key_fields = struct.__schema__(:primary_key)

    changes =
      fields(previous, current)
      |> Map.merge(associations(previous, current))
      |> Map.merge(embeds(previous, current))

    previous_primary_key = Map.take(previous, primary_key_fields)
    current_primary_key = Map.take(current, primary_key_fields)

    effect =
      if !primary_key_nil?(previous_primary_key) && !primary_key_nil?(current_primary_key) &&
           previous_primary_key != current_primary_key do
        :replaced
      else
        :changed
      end

    %__MODULE__{
      struct: struct,
      primary_key: current_primary_key,
      changes: changes,
      effect: effect,
      previous: previous,
      current: current
    }
  end

  defp fields(%struct{} = previous, %struct{} = current) do
    field_names = struct.__schema__(:fields) -- struct.__schema__(:embeds)

    field_names
    |> Enum.reduce([], &field(previous, current, &1, &2))
    |> Map.new()
  end

  defp field(previous, current, field, acc) do
    previous_value = Map.get(previous, field)
    current_value = Map.get(current, field)

    if previous_value === current_value do
      acc
    else
      [{field, {previous_value, current_value}} | acc]
    end
  end

  defp embeds(%struct{} = previous, %struct{} = current) do
    embed_names = struct.__schema__(:embeds)

    embed_names
    |> Enum.reduce([], &embed(previous, current, &1, &2))
    |> Map.new()
  end

  defp embed(%struct{} = previous, %struct{} = current, embed, acc) do
    embed_details = struct.__schema__(:embed, embed)

    previous_embed = Map.get(previous, embed)
    current_embed = Map.get(current, embed)

    if is_nil(previous_embed) && is_nil(current_embed) do
      acc
    else
      diff_association(previous_embed, current_embed, embed_details, acc)
    end
  end

  defp associations(%struct{} = previous, %struct{} = current) do
    association_names = struct.__schema__(:associations)

    association_names
    |> Enum.reduce([], &association(previous, current, &1, &2))
    |> Map.new()
  end

  defp association(%struct{} = previous, %struct{} = current, association, acc) do
    association_details = struct.__schema__(:association, association)

    previous_value = Map.get(previous, association)
    current_value = Map.get(current, association)

    diff_association(previous_value, current_value, association_details, acc)
  end

  defp diff_association(%NotLoaded{}, %NotLoaded{}, %{cardinality: :one} = assoc, acc) do
    diff_association(nil, nil, assoc, acc)
  end

  defp diff_association(%NotLoaded{}, %NotLoaded{}, %{cardinality: :many} = assoc, acc) do
    diff_association([], [], assoc, acc)
  end

  defp diff_association(_previous, %NotLoaded{}, %{field: field}, _acc) do
    raise "previously loaded association `#{field}` not loaded in current struct"
  end

  defp diff_association(%NotLoaded{}, current, %{cardinality: :one} = assoc, acc) do
    diff_association(nil, current, assoc, acc)
  end

  defp diff_association(%NotLoaded{}, current, %{cardinality: :many} = assoc, acc) do
    diff_association([], current, assoc, acc)
  end

  defp diff_association(nil, nil, %{cardinality: :one}, acc), do: acc

  defp diff_association([], [], %{cardinality: :many}, acc), do: acc

  defp diff_association(previous, current, %{cardinality: :one, field: field}, acc) do
    assoc_diff = do_diff(previous, current)

    if no_changes?(assoc_diff) do
      acc
    else
      [{field, assoc_diff} | acc]
    end
  end

  defp diff_association(previous, current, %{cardinality: :many, field: field, related: struct}, acc) do
    primary_key_fields = struct.__schema__(:primary_key)

    if primary_key_fields == [],
      do: raise("cannot determine difference in many association with no primary key for `#{struct}`")

    {previous_map, keys} =
      Enum.reduce(previous, {%{}, []}, fn x, {map, keys} ->
        key = Map.take(x, primary_key_fields)
        {Map.put(map, key, x), [key | keys]}
      end)

    {current_map, keys} =
      Enum.reduce(current, {%{}, keys}, fn x, {map, keys} ->
        key = Map.take(x, primary_key_fields)
        {Map.put(map, key, x), [key | keys]}
      end)

    keys = keys |> Enum.reverse() |> Enum.uniq()

    diffs =
      Enum.map(keys, fn key ->
        prev_child = Map.get(previous_map, key)
        current_child = Map.get(current_map, key)

        do_diff(prev_child, current_child)
      end)
      |> Enum.reject(&no_changes?/1)

    if diffs == [] do
      acc
    else
      [{field, diffs} | acc]
    end
  end

  defp no_changes?(%{effect: :changed, changes: map}) when map == %{}, do: true
  defp no_changes?(_), do: false

  defp primary_key_nil?(key), do: Enum.all?(key, fn {_key, value} -> is_nil(value) end)
end

defimpl Inspect, for: EctoDiff do
  import Inspect.Algebra

  def inspect(diff, opts) do
    list =
      for attr <- [:struct, :primary_key, :effect, :previous, :current, :changes] do
        {attr, Map.get(diff, attr)}
      end

    unquote(:container_doc)("#EctoDiff<", list, ">", opts, fn
      {:struct, struct}, opts -> concat("struct: ", to_doc(struct, opts))
      {:primary_key, primary_key}, opts -> concat("primary_key: ", to_doc(primary_key, opts))
      {:effect, effect}, opts -> concat("effect: ", to_doc(effect, opts))
      {:changes, changes}, opts -> concat("changes: ", to_doc(changes, opts))
      {:previous, previous}, _opts -> concat("previous: ", to_struct(previous, opts))
      {:current, current}, _opts -> concat("current: ", to_struct(current, opts))
    end)
  end

  defp to_struct(%{__struct__: struct}, _opts), do: "#" <> Kernel.inspect(struct) <> "<>"
  defp to_struct(other, opts), do: to_doc(other, opts)
end
