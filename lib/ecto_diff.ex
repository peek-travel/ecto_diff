defmodule EctoDiff do
  @moduledoc """
  Generates a data structure describing the difference between two ecto structs.

  For details on how to generate an `t:EctoDiff.t/0` struct, see: `diff/2`.

  For details on what the generated struct looks like, see: `t:EctoDiff.t/0`.
  """

  @behaviour Access

  alias Ecto.Association.NotLoaded

  @typedoc """
  The type of change for a given struct.

  Each `t:EctoDiff.t/0` struct will have a field describing what happened to the given Ecto schema struct.
  The values can be one of the following:

  * `:added` - This struct is new and was not present previously. This happens when the primary struct, or an associated
               struct, was added during an update or insert.
  * `:deleted` - This struct was previously present, but no longer is.
  * `:changed` - This struct existed previously and still does, but some of its fields and/or associations have changed.
  * `:replaced` - This struct was replaced with a completely new one. This happens with `belongs_to` or `embeds_one`
                  associations with the `on_replace: :nilify` option set.
  """
  @type effect :: :added | :deleted | :changed | :replaced

  @typedoc """
  Describes all changes made during an insert or update operation.

  The following fields should be considered public:

  * `struct` - The module atom of the ecto schema being diffed.
  * `primary_key` - The primary key(s) of the ecto struct. This is a `map` of all primary keys in case of composite
  keys. For most common use-cases this will just be the map `%{id: id}`.
  * `changes` - A `map` representing all changes made. The keys will be fields and associations defined in the ecto
  schema, but only fields and associations with changes will be present. For changed fields, the value
  will be a `tuple` representing the previous and new values (i.e. `{previous, new}`). For associations,
  the value will be another `t:EctoDiff.t/0` struct for cardinality "one" associations, or a list of
  `t:EctoDiff.t/0` structs for cardinality "many" associations.
  * `effect` - The type of change for this ecto struct. See `t:effect/0` for details.
  * `previous` - The previous struct itself.
  * `current` - The current (new) struct itself.
  """
  @type t :: %__MODULE__{
          struct: atom(),
          primary_key: %{required(struct_field) => any()},
          changes: %{required(struct_field) => any()},
          effect: effect(),
          previous: Ecto.Schema.t(),
          current: Ecto.Schema.t()
        }

  @typedoc """
  Configurable options for `diff/3`.

  ## Options

  * `:overrides` - A keyword list or map which provides a reference from a struct
    to a key (or list of keys) on that struct which will be used as the primary key
    (simple or composite) for diffing.
  * `:include_virtual_fields` - A boolean which determines whether or not virtual fields
    should be included in the diff. Defaults to `false`.
  """
  @type diff_opts :: [
          overrides: overrides,
          include_virtual_fields: boolean
        ]

  @typedoc """
  A keyword list or a map which specifies an override from an Ecto schema to the desired
  primary key, for use in comparing structs.

  Structs that are not specified will be compared using their default primary key.

  ## Examples:

      [{Pet, :refid}, {Skill, :id}]

  or

      %{Skill => :refid, Owner => [:id, :refid]}
  """
  @type overrides :: [{module, primary_key}] | %{module => primary_key}

  @typedoc """
  A struct field or list of fields used to define a simple or composite primary key.
  """
  @type primary_key :: struct_field | [struct_field]

  @typedoc """
  A field defined on a struct.
  """
  @type struct_field :: atom

  defstruct [:struct, :primary_key, :changes, :effect, :previous, :current]

  @doc """
  Returns an `t:EctoDiff.t/0` describing the difference between two given ecto structs.

  The "previous" struct can be `nil`, to represent an insert operation.

  ## Examples

  A new struct being inserted:

        iex> {:ok, pet} = %{name: "Spot"} |> Pet.new() |> Repo.insert()
        iex> {:ok, diff} = EctoDiff.diff(nil, pet)
        iex> diff
        #EctoDiff<
          struct: Pet,
          primary_key: %{id: 1},
          effect: :added,
          previous: #Pet<>,
          current: #Pet<>,
          changes: %{
            id: {nil, 1},
            name: {nil, "Spot"}
          }
        >

  A struct being updated:

        iex> {:ok, pet} = %{name: "Spot"} |> Pet.new() |> Repo.insert()
        iex> {:ok, updated_pet} = pet |> Pet.update(%{name: "McFluffFace"}) |> Repo.update()
        iex> {:ok, diff} = EctoDiff.diff(pet, updated_pet)
        iex> diff
        #EctoDiff<
          struct: Pet,
          primary_key: %{id: 1},
          effect: :changed,
          previous: #Pet<>,
          current: #Pet<>,
          changes: %{
            name: {"Spot", "McFluffFace"}
          }
        >

  A nested has_many association being updated:

        iex> {:ok, initial_pet} =
        ...>   %{name: "Spot", skills: [%{name: "Eating"}, %{name: "Sleeping"}, %{name: "Scratching"}]}
        ...>   |> Pet.new()
        ...>   |> Repo.insert()
        iex> [eating_id, sleeping_id, _scratching_id] = Enum.map(initial_pet.skills, & &1.id)
        iex> {:ok, updated_pet} =
        ...>   initial_pet
        ...>   |> Pet.update(%{skills: [%{id: eating_id}, %{id: sleeping_id, level: 2}, %{name: "Meowing"}]})
        ...>   |> Repo.update()
        iex> {:ok, diff} = EctoDiff.diff(initial_pet, updated_pet)
        iex> diff
        #EctoDiff<
          struct: Pet,
          primary_key: %{id: 1},
          effect: :changed,
          previous: #Pet<>,
          current: #Pet<>,
          changes: %{
            skills: [
              #EctoDiff<
                struct: Skill,
                primary_key: %{id: 2},
                effect: :changed,
                previous: #Skill<>,
                current: #Skill<>,
                changes: %{
                  level: {1, 2}
                }
              >,
              #EctoDiff<
                struct: Skill,
                primary_key: %{id: 3},
                effect: :deleted,
                previous: #Skill<>,
                current: #Skill<>,
                changes: %{}
              >,
              #EctoDiff<
                struct: Skill,
                primary_key: %{id: 4},
                effect: :added,
                previous: #Skill<>,
                current: #Skill<>,
                changes: %{
                  id: {nil, 4},
                  pet_id: {nil, 1},
                  name: {nil, "Meowing"}
                }
              >
            ]
          }
        >

    Using an override to specify a composite primary key:

        iex> {:ok, pet} = %{name: "Spot", type: "Calico"} |> Pet.new() |> Repo.insert()
        iex> {:ok, diff} = EctoDiff.diff(nil, pet, overrides: %{Pet => [:name, :type]})
        iex> diff
        #EctoDiff<
          struct: Pet,
          primary_key: %{name: "Spot", type: "Calico"},
          effect: :added,
          previous: #Pet<>,
          current: #Pet<>,
          changes: %{
            id: {nil, 1},
            name: {nil, "Spot"},
            type: {"Cat", "Calico"}
          }
        >
  """
  @spec diff(Ecto.Schema.t() | nil, Ecto.Schema.t() | nil) :: {:ok, t()} | {:ok, :unchanged}
  def diff(previous, current), do: diff(previous, current, [])

  @doc """
  An alternate form of `diff/2` which allows options to be specified.

  See `t:diff_opts/0` for available options.
  """
  @spec diff(Ecto.Schema.t() | nil, Ecto.Schema.t() | nil, diff_opts) :: {:ok, t()} | {:ok, :unchanged}
  def diff(previous, current, opts) do
    diff = do_diff(previous, current, opts)

    if no_changes?(diff) do
      {:ok, :unchanged}
    else
      {:ok, diff}
    end
  end

  defp do_diff(nil, %struct{} = current, opts) do
    previous = struct!(struct)
    diff = do_diff(previous, current, opts)
    %{diff | effect: :added}
  end

  defp do_diff(%struct{} = previous, nil, opts) do
    primary_key_fields = get_primary_key_fields(struct, opts)

    %__MODULE__{
      struct: struct,
      primary_key: Map.take(previous, primary_key_fields),
      changes: %{},
      effect: :deleted,
      previous: previous,
      current: nil
    }
  end

  defp do_diff(%struct{} = previous, %struct{} = current, opts) do
    primary_key_fields = get_primary_key_fields(struct, opts)

    field_changes = fields(previous, current, opts)

    changes =
      field_changes
      |> Map.merge(associations(previous, current, opts))
      |> Map.merge(embeds(previous, current, opts))

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

  defp fields(%struct{} = previous, %struct{} = current, opts) do
    include_virtual_fields? = Keyword.get(opts, :include_virtual_fields, false)
    field_names = struct.__schema__(:fields) -- struct.__schema__(:embeds)

    field_names
    |> maybe_include_virtual_fields(struct, include_virtual_fields?)
    |> Enum.reduce([], &field(previous, current, &1, &2))
    |> Map.new()
  end

  defp maybe_include_virtual_fields(names, struct, true), do: names ++ struct.__schema__(:virtual_fields)
  defp maybe_include_virtual_fields(names, _struct, false), do: names

  defp field(previous, current, field, acc) do
    previous_value = Map.get(previous, field)
    current_value = Map.get(current, field)

    if previous_value === current_value do
      acc
    else
      [{field, {previous_value, current_value}} | acc]
    end
  end

  defp embeds(%struct{} = previous, %struct{} = current, opts) do
    embed_names = struct.__schema__(:embeds)

    embed_names
    |> Enum.reduce([], &embed(previous, current, &1, &2, opts))
    |> Map.new()
  end

  defp embed(%struct{} = previous, %struct{} = current, embed, acc, opts) do
    embed_details = struct.__schema__(:embed, embed)

    previous_embed = Map.get(previous, embed)
    current_embed = Map.get(current, embed)

    if is_nil(previous_embed) && is_nil(current_embed) do
      acc
    else
      diff_association(previous_embed, current_embed, embed_details, acc, opts)
    end
  end

  defp associations(%struct{} = previous, %struct{} = current, opts) do
    association_names = struct.__schema__(:associations)

    association_names
    |> Enum.reduce([], &association(previous, current, &1, &2, opts))
    |> Map.new()
  end

  defp association(%struct{} = previous, %struct{} = current, association, acc, opts) do
    association_details = struct.__schema__(:association, association)

    previous_value = Map.get(previous, association)
    current_value = Map.get(current, association)

    diff_association(previous_value, current_value, association_details, acc, opts)
  end

  defp diff_association(%NotLoaded{}, %NotLoaded{}, %{cardinality: :one} = assoc, acc, opts) do
    diff_association(nil, nil, assoc, acc, opts)
  end

  defp diff_association(%NotLoaded{}, %NotLoaded{}, %{cardinality: :many} = assoc, acc, opts) do
    diff_association([], [], assoc, acc, opts)
  end

  defp diff_association(_previous, %NotLoaded{}, %{field: field}, _acc, _opts) do
    raise "previously loaded association `#{field}` not loaded in current struct"
  end

  defp diff_association(%NotLoaded{}, current, %{cardinality: :one} = assoc, acc, opts) do
    diff_association(nil, current, assoc, acc, opts)
  end

  defp diff_association(%NotLoaded{}, current, %{cardinality: :many} = assoc, acc, opts) do
    diff_association([], current, assoc, acc, opts)
  end

  defp diff_association(nil, nil, %{cardinality: :one}, acc, _opts), do: acc

  defp diff_association([], [], %{cardinality: :many}, acc, _opts), do: acc

  defp diff_association(previous, current, %{cardinality: :one, field: field}, acc, opts) do
    assoc_diff = do_diff(previous, current, opts)

    if no_changes?(assoc_diff) do
      acc
    else
      [{field, assoc_diff} | acc]
    end
  end

  defp diff_association(previous, current, %{cardinality: :many, field: field, related: struct}, acc, opts) do
    primary_key_fields = get_primary_key_fields(struct, opts)

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
      keys
      |> Enum.map(fn key ->
        prev_child = Map.get(previous_map, key)
        current_child = Map.get(current_map, key)

        do_diff(prev_child, current_child, opts)
      end)
      |> Enum.reject(&no_changes?/1)

    if diffs == [] do
      acc
    else
      [{field, diffs} | acc]
    end
  end

  defp get_primary_key_fields(struct, opts) do
    overrides = Keyword.get(opts, :overrides, [])

    case overrides[struct] do
      nil -> struct.__schema__(:primary_key)
      keys -> validate_keys!(struct, List.wrap(keys))
    end
  end

  defp validate_keys!(struct, []) do
    raise "no keys specified in override for #{inspect(struct)}"
  end

  defp validate_keys!(struct, keys) do
    struct_fields = struct.__schema__(:fields) || []
    missing = Enum.filter(keys, &(&1 not in struct_fields))

    if missing != [] do
      raise "the keys #{inspect(missing)} for #{inspect(struct)} are invalid or missing"
    end

    keys
  end

  defp no_changes?(%{effect: :changed, changes: map}) when map == %{}, do: true
  defp no_changes?(_), do: false

  defp primary_key_nil?(key), do: Enum.all?(key, fn {_key, value} -> is_nil(value) end)

  @impl Access
  defdelegate fetch(diff, key), to: Map

  @impl Access
  defdelegate get_and_update(diff, key, update_fn), to: Map

  @impl Access
  defdelegate pop(diff, key), to: Map
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
