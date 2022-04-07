defmodule EctoDiff.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      alias EctoDiff.{Owner, Pet, Repo, Skill}

      import EctoDiff.DataCase
    end
  end

  setup tags do
    :ok = Sandbox.checkout(EctoDiff.Repo)

    unless tags[:async] do
      Sandbox.mode(EctoDiff.Repo, {:shared, self()})
    end

    :ok
  end
end
