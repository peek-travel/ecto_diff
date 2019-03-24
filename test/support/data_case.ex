defmodule EctoDiff.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias EctoDiff.{Repo, Owner, Pet}

      import EctoDiff.DataCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EctoDiff.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(EctoDiff.Repo, {:shared, self()})
    end

    :ok
  end
end
