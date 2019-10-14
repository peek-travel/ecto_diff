# EctoDiff

[![CI Status](https://github.com/peek-travel/ecto_diff/workflows/CI/badge.svg)](https://github.com/peek-travel/ecto_diff/actions)
[![codecov](https://codecov.io/gh/peek-travel/ecto_diff/branch/master/graph/badge.svg)](https://codecov.io/gh/peek-travel/ecto_diff)
[![SourceLevel](https://app.sourcelevel.io/github/peek-travel/ecto_diff.svg)](https://app.sourcelevel.io/github/peek-travel/ecto_diff)
[![Hex.pm Version](https://img.shields.io/hexpm/v/ecto_diff.svg?style=flat)](https://hex.pm/packages/ecto_diff)
[![License](https://img.shields.io/hexpm/l/ecto_diff.svg)](LICENSE.md)
[![Dependabot Status](https://api.dependabot.com/badges/status?host=github&repo=peek-travel/ecto_diff)](https://dependabot.com)

Generates a data structure that describes the differences between two [ecto](https://github.com/elixir-ecto/ecto) structs.
The primary use-case is to track what changed after calling `Repo.insert` or `Repo.update`, especially in conjunction
with complex or deeply nested `cast_assoc` associations.

## Installation

The package can be installed by adding `ecto_diff` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_diff, "~> 0.2.2"}
  ]
end
```

## Basic Usage

To demonstrate the basic use-case for EctoDiff, let's look at a simple example. Assume you have two related ecto schemas
like the following `Pet` with many `Skill`s. Importantly, we've chosen to `cast_assoc` the skills in the pet's changeset
function, and we've opted to use `on_replace: :delete` on the has_many skills association.

```elixir
defmodule Pet do
  use Ecto.Schema
  import Ecto.Changeset

  schema("pets") do
    field :name, :string
    field :type, :string, default: "Cat"

    has_many :skills, Skill, on_replace: :delete
  end

  def new(params), do: changeset(%__MODULE__{}, params)
  def update(struct, params), do: changeset(struct, params)

  defp changeset(struct, params) do
    struct
    |> cast(params, [:name, :type])
    |> cast_assoc(:skills)
  end
end

defmodule Skill do
  use Ecto.Schema
  import Ecto.Changeset

  schema("skills") do
    field :name, :string
    field :level, :integer, default: 1

    belongs_to :pet, Pet
  end

  def changeset(struct, params), do: cast(struct, params, [:name, :level])
end
```

Now let's insert a pet into the database with three initial skills, defaulting to `level: 1`.

```elixir
{:ok, initial_pet} =
  %{name: "Spot", skills: [%{name: "Eating"}, %{name: "Sleeping"}, %{name: "Scratching"}]}
  |> Pet.new()
  |> Repo.insert()
```

Later, we've decided to update this pet's name and it's skills. In this case, we're leaving "eating" alone (no changes),
we're increasing "sleeping" to `level: 2`, we're implicitly deleting "scratching" by not including it in the list
(taking advantage of `on_replace: :delete`), and we're adding a new skill "meowing".

```elixir
[eating_id, sleeping_id, scratching_id] = Enum.map(initial_pet.skills, & &1.id)

{:ok, updated_pet} =
  initial_pet
  |> Pet.update(%{name: "Spots", skills: [%{id: eating_id}, %{id: sleeping_id, level: 2}, %{name: "Meowing"}]})
  |> Repo.update()
```

Now we can use `EctoDiff` to generate a data structure that describes all changes that occurred, making it easy to walk
over all changes and act on them if desired.

```elixir
iex> EctoDiff.diff(initial_pet, updated_pet)

{:ok,
 #EctoDiff<
   struct: Pet,
   primary_key: %{id: 2},
   effect: :changed,
   previous: #Pet<>,
   current: #Pet<>,
   changes: %{
     name: {"Spot", "Spots"},
     skills: [
       #EctoDiff<
         struct: Skill,
         primary_key: %{id: 5},
         effect: :changed,
         previous: #Skill<>,
         current: #Skill<>,
         changes: %{level: {1, 2}}
       >,
       #EctoDiff<
         struct: Skill,
         primary_key: %{id: 6},
         effect: :deleted,
         previous: #Skill<>,
         current: nil,
         changes: %{}
       >,
       #EctoDiff<
         struct: Skill,
         primary_key: %{id: 7},
         effect: :added,
         previous: #Skill<>,
         current: #Skill<>,
         changes: %{id: {nil, 7}, name: {nil, "Meowing"}, pet_id: {nil, 2}}
       >
     ]
   }
 >}
```

Detailed documentation can be found at [https://hexdocs.pm/ecto_diff](https://hexdocs.pm/ecto_diff).
