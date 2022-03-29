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

  Each `t:EctoDiff.t/0` struct will have a field describing what happened to the given ecto struct. The values can be one of
  the following:

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
          primary_key: %{required(atom()) => any()},
          changes: %{required(atom()) => any()},
          effect: effect(),
          previous: Ecto.Schema.t(),
          current: Ecto.Schema.t()
        }

  @typedoc """
  Configurable options for `diff/3`.

  ## Options

  * `:match_key` - A single atom or list of atoms which is used to compare
    structs when the `:id` field is either unavailable or unsuitable for
    comparison (e.g. can be used to compare structs with a user-provided key, for
    instance). The key must exist on all structs to be compared. All structs which
    lack the provided key(s) will be omitted from the final diff.
  """
  @type diff_opts :: [
          match_key: atom | [atom]
        ]

  defstruct [:struct, :primary_key, :changes, :effect, :previous, :current]

  @doc """
  Returns an `t:EctoDiff.t/0` describing the difference between two given ecto structs.

  The "previous" struct can be `nil`, to represent an insert operation.

  See `t:diff_opts/0` for available options.

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

  """

  @spec diff(Ecto.Schema.t() | nil, Ecto.Schema.t() | nil, diff_opts) :: {:ok, t()} | {:ok, :unchanged}
  def diff(previous, current, opts \\ []) do
    match_key = Keyword.get(opts, :match_key)
    diff = do_diff(previous, current, match_key)

    if no_changes?(diff) do
      {:ok, :unchanged}
    else
      {:ok, diff}
    end
  end

  defp do_diff(nil, %struct{} = current, match_key) do
    previous = struct!(struct)
    diff = do_diff(previous, current, match_key)
    %{diff | effect: :added}
  end

  defp do_diff(%struct{} = previous, nil, match_key) do
    primary_key_fields = get_primary_key_fields(struct, match_key)

    %__MODULE__{
      struct: struct,
      primary_key: Map.take(previous, primary_key_fields),
      changes: %{},
      effect: :deleted,
      previous: previous,
      current: nil
    }
  end

  defp do_diff(%struct{} = previous, %struct{} = current, match_key) do
    primary_key_fields = get_primary_key_fields(struct, match_key)
    field_changes = fields(previous, current)

    changes =
      field_changes
      |> Map.merge(associations(previous, current, match_key))
      |> Map.merge(embeds(previous, current, match_key))

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

  defp get_primary_key_fields(struct, match_key) when is_nil(match_key) do
    struct.__schema__(:primary_key)
  end

  defp get_primary_key_fields(_struct, match_key) do
    List.wrap(match_key)
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

  defp embeds(%struct{} = previous, %struct{} = current, match_key) do
    embed_names = struct.__schema__(:embeds)

    embed_names
    |> Enum.reduce([], &embed(previous, current, match_key, &1, &2))
    |> Map.new()
  end

  defp embed(%struct{} = previous, %struct{} = current, match_key, embed, acc) do
    embed_details = struct.__schema__(:embed, embed)

    previous_embed = Map.get(previous, embed)
    current_embed = Map.get(current, embed)

    if is_nil(previous_embed) && is_nil(current_embed) do
      acc
    else
      diff_association(previous_embed, current_embed, match_key, embed_details, acc)
    end
  end

  defp associations(%struct{} = previous, %struct{} = current, match_key) do
    association_names = struct.__schema__(:associations)

    association_names
    |> Enum.reduce([], &association(previous, current, match_key, &1, &2))
    |> Map.new()
  end

  defp association(%struct{} = previous, %struct{} = current, match_key, association, acc) do
    association_details = struct.__schema__(:association, association)

    previous_value = Map.get(previous, association)
    current_value = Map.get(current, association)

    diff_association(previous_value, current_value, match_key, association_details, acc)
  end

  defp diff_association(%NotLoaded{}, %NotLoaded{}, match_key, %{cardinality: :one} = assoc, acc) do
    diff_association(nil, nil, match_key, assoc, acc)
  end

  defp diff_association(%NotLoaded{}, %NotLoaded{}, match_key, %{cardinality: :many} = assoc, acc) do
    diff_association([], [], match_key, assoc, acc)
  end

  defp diff_association(_previous, %NotLoaded{}, _match_key, %{field: field}, _acc) do
    raise "previously loaded association `#{field}` not loaded in current struct"
  end

  defp diff_association(%NotLoaded{}, current, match_key, %{cardinality: :one} = assoc, acc) do
    diff_association(nil, current, match_key, assoc, acc)
  end

  defp diff_association(%NotLoaded{}, current, match_key, %{cardinality: :many} = assoc, acc) do
    diff_association([], current, match_key, assoc, acc)
  end

  defp diff_association(nil, nil, _match_key, %{cardinality: :one}, acc), do: acc

  defp diff_association([], [], _match_key, %{cardinality: :many}, acc), do: acc

  defp diff_association(previous, current, match_key, %{cardinality: :one, field: field}, acc) do
    assoc_diff = do_diff(previous, current, match_key)

    if no_changes?(assoc_diff) do
      acc
    else
      [{field, assoc_diff} | acc]
    end
  end

  defp diff_association(previous, current, match_key, %{cardinality: :many, field: field, related: struct}, acc) do
    primary_key_fields = get_primary_key_fields(struct, match_key)

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

        do_diff(prev_child, current_child, match_key)
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
