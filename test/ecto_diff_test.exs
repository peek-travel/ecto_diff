defmodule EctoDiffTest do
  @moduledoc false

  use EctoDiff.DataCase

  describe "diff/3" do
    test "no changes" do
      {:ok, pet} = %{name: "Spot"} |> Pet.new() |> Repo.insert()

      assert {:ok, :unchanged} = EctoDiff.diff(pet, pet, overrides: %{Pet => :refid})
    end

    test "insert" do
      {:ok, pet} = %{name: "Spot"} |> Pet.new() |> Repo.insert()
      refid = pet.refid

      {:ok, diff} = EctoDiff.diff(nil, pet, overrides: %{Pet => :refid})

      assert %EctoDiff{
               effect: :added,
               primary_key: %{refid: ^refid},
               changes: %{
                 id: {nil, _id},
                 name: {nil, "Spot"},
                 refid: {nil, ^refid}
               }
             } = diff
    end

    test "update" do
      {:ok, pet} = %{name: "Spot"} |> Pet.new() |> Repo.insert()
      {:ok, updated_pet} = pet |> Pet.update(%{name: "McFluffFace"}) |> Repo.update()
      refid = pet.refid

      {:ok, diff} = EctoDiff.diff(pet, updated_pet, overrides: %{Pet => :refid})

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{refid: ^refid},
               changes: %{
                 name: {"Spot", "McFluffFace"}
               }
             } = diff
    end

    test "delete" do
      {:ok, pet} = %{name: "Spot"} |> Pet.new() |> Repo.insert()
      refid = pet.refid

      {:ok, diff} = EctoDiff.diff(pet, nil, overrides: %{Pet => :refid})

      assert %EctoDiff{
               effect: :deleted,
               primary_key: %{refid: ^refid},
               changes: %{}
             } = diff
    end

    test "insert with belongs_to" do
      {:ok, pet} = %{name: "Spot", owner: %{name: "Chris"}} |> Pet.new() |> Repo.insert()
      id = pet.id
      refid = pet.refid
      owner_id = pet.owner.id

      {:ok, diff} = EctoDiff.diff(nil, pet, overrides: [{Pet, :refid}, {Owner, :id}])

      assert %EctoDiff{
               effect: :added,
               primary_key: %{refid: ^refid},
               changes: %{
                 id: {nil, ^id},
                 name: {nil, "Spot"},
                 refid: {nil, ^refid},
                 owner_id: {nil, ^owner_id},
                 owner: %EctoDiff{
                   effect: :added,
                   primary_key: %{id: ^owner_id},
                   changes: %{
                     id: {nil, ^owner_id},
                     name: {nil, "Chris"}
                   }
                 }
               }
             } = diff
    end

    test "insert with multiple association types" do
      {:ok, pet} =
        %{
          name: "Spot",
          skills: [%{name: "Eating"}, %{name: "Sleeping"}],
          owner: %{name: "Samuel"},
          details: %{description: "It's a kitty!"}
        }
        |> Pet.new()
        |> Repo.insert()

      %{
        id: pet_id,
        refid: pet_refid,
        skills: [
          %{id: eating_id, refid: eating_refid},
          %{id: sleeping_id, refid: sleeping_refid}
        ],
        owner: %{id: owner_id, refid: owner_refid},
        details: %{description: description, id: detail_id}
      } = pet

      {:ok, diff} = EctoDiff.diff(nil, pet, overrides: %{Pet => :refid, Skill => :refid})

      assert %EctoDiff{
               effect: :added,
               primary_key: %{refid: ^pet_refid},
               changes: %{
                 id: {nil, ^pet_id},
                 name: {nil, "Spot"},
                 refid: {nil, ^pet_refid},
                 owner: %EctoDiff{
                   effect: :added,
                   primary_key: %{id: ^owner_id},
                   changes: %{
                     name: {nil, "Samuel"},
                     id: {nil, ^owner_id},
                     refid: {nil, ^owner_refid}
                   }
                 },
                 skills: [
                   %EctoDiff{
                     effect: :added,
                     primary_key: %{refid: ^eating_refid},
                     changes: %{
                       id: {nil, ^eating_id},
                       pet_id: {nil, ^pet_id},
                       name: {nil, "Eating"},
                       refid: {nil, ^eating_refid}
                     }
                   },
                   %EctoDiff{
                     effect: :added,
                     primary_key: %{refid: ^sleeping_refid},
                     changes: %{
                       id: {nil, ^sleeping_id},
                       pet_id: {nil, ^pet_id},
                       name: {nil, "Sleeping"},
                       refid: {nil, ^sleeping_refid}
                     }
                   }
                 ],
                 details: %EctoDiff{
                   effect: :added,
                   primary_key: %{id: ^detail_id},
                   changes: %{
                     id: {nil, ^detail_id},
                     description: {nil, ^description}
                   }
                 }
               }
             } = diff
    end

    test "raises when invalid override keys are specified" do
      {:ok, pet} = %{name: "Spot", skills: [%{name: "Karate", level: 6}]} |> Pet.new() |> Repo.insert()

      assert_raise RuntimeError, "the keys [:badkey] for EctoDiff.Skill are invalid or missing", fn ->
        {:ok, _diff} = EctoDiff.diff(nil, pet, overrides: %{Skill => [:name, :badkey]})
      end

      assert_raise RuntimeError, "no keys specified in override for EctoDiff.Skill", fn ->
        {:ok, _diff} = EctoDiff.diff(nil, pet, overrides: %{Skill => []})
      end
    end

    test "includes changes to virtual fields" do
      {:ok, pet} = %{name: "Spot", owner: %{name: "Chris"}} |> Pet.new() |> Repo.insert()
      pet = Map.put(pet, :owner_email, "user@example.com")
      id = pet.id

      {:ok, diff} = EctoDiff.diff(nil, pet)

      assert %EctoDiff{
               effect: :added,
               primary_key: %{id: ^id},
               changes: %{
                 id: {nil, ^id},
                 name: {nil, "Spot"},
                 owner_email: {nil, "user@example.com"}
               }
             } = diff
    end
  end

  describe "diff/2" do
    test "no changes" do
      {:ok, pet} = %{name: "Spot"} |> Pet.new() |> Repo.insert()

      assert {:ok, :unchanged} = EctoDiff.diff(pet, pet)
    end

    test "insert" do
      {:ok, pet} = %{name: "Spot"} |> Pet.new() |> Repo.insert()
      id = pet.id

      {:ok, diff} = EctoDiff.diff(nil, pet)

      assert %EctoDiff{
               effect: :added,
               primary_key: %{id: ^id},
               changes: %{
                 id: {nil, ^id},
                 name: {nil, "Spot"}
               }
             } = diff
    end

    test "update" do
      {:ok, pet} = %{name: "Spot"} |> Pet.new() |> Repo.insert()
      {:ok, updated_pet} = pet |> Pet.update(%{name: "McFluffFace"}) |> Repo.update()
      id = pet.id

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 name: {"Spot", "McFluffFace"}
               }
             } = diff
    end

    test "delete" do
      {:ok, pet} = %{name: "Spot"} |> Pet.new() |> Repo.insert()
      id = pet.id

      {:ok, diff} = EctoDiff.diff(pet, nil)

      assert %EctoDiff{
               effect: :deleted,
               primary_key: %{id: ^id},
               changes: %{}
             } = diff
    end

    test "insert with default" do
      {:ok, pet} = %{name: "Porthos", type: "Dog"} |> Pet.new() |> Repo.insert()
      id = pet.id

      {:ok, diff} = EctoDiff.diff(nil, pet)

      assert %EctoDiff{
               effect: :added,
               primary_key: %{id: ^id},
               changes: %{
                 id: {nil, ^id},
                 name: {nil, "Porthos"},
                 type: {"Cat", "Dog"}
               }
             } = diff
    end

    # Belongs To Association

    test "no changes with belongs_to" do
      {:ok, pet} = %{name: "Spot", owner: %{name: "Chris"}} |> Pet.new() |> Repo.insert()

      assert {:ok, :unchanged} = EctoDiff.diff(pet, pet)
    end

    test "insert with belongs_to" do
      {:ok, pet} = %{name: "Spot", owner: %{name: "Chris"}} |> Pet.new() |> Repo.insert()
      id = pet.id
      owner_id = pet.owner.id

      {:ok, diff} = EctoDiff.diff(nil, pet)

      assert %EctoDiff{
               effect: :added,
               primary_key: %{id: ^id},
               changes: %{
                 id: {nil, ^id},
                 name: {nil, "Spot"},
                 owner_id: {nil, ^owner_id},
                 owner: %EctoDiff{
                   effect: :added,
                   primary_key: %{id: ^owner_id},
                   changes: %{
                     id: {nil, ^owner_id},
                     name: {nil, "Chris"}
                   }
                 }
               }
             } = diff
    end

    test "insert with nil belongs_to" do
      {:ok, pet} = %{name: "Spot", owner: nil} |> Pet.new() |> Repo.insert()
      id = pet.id

      {:ok, diff} = EctoDiff.diff(nil, pet)

      assert %EctoDiff{
               effect: :added,
               primary_key: %{id: ^id},
               changes: %{
                 id: {nil, ^id},
                 name: {nil, "Spot"}
               }
             } = diff
    end

    test "update with adding a new belongs_to" do
      {:ok, pet} = %{name: "Spot", owner: nil} |> Pet.new() |> Repo.insert()
      {:ok, updated_pet} = pet |> Pet.update(%{owner: %{name: "Chris"}}) |> Repo.update()
      id = pet.id
      owner_id = updated_pet.owner.id

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 owner_id: {nil, ^owner_id},
                 owner: %EctoDiff{
                   effect: :added,
                   primary_key: %{id: ^owner_id},
                   changes: %{
                     id: {nil, ^owner_id},
                     name: {nil, "Chris"}
                   }
                 }
               }
             } = diff
    end

    # TODO: the following case only tests belongs_to with on_replace: :update
    # other cases should be written for on_replace: :nilify and :delete

    test "update a belongs_to using on_replace: :update" do
      {:ok, pet} = %{name: "Spot", owner: %{name: "Chris"}} |> Pet.new() |> Repo.insert()
      {:ok, updated_pet} = pet |> Pet.update(%{owner: %{name: "John"}}) |> Repo.update()
      id = pet.id
      owner_id = pet.owner.id

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 owner: %EctoDiff{
                   effect: :changed,
                   primary_key: %{id: ^owner_id},
                   changes: %{
                     name: {"Chris", "John"}
                   }
                 }
               }
             } = diff
    end

    test "update with deleting a belongs_to" do
      {:ok, pet} = %{name: "Spot", owner: %{name: "Chris"}} |> Pet.new() |> Repo.insert()
      {:ok, updated_pet} = pet |> Pet.update(%{owner: nil}) |> Repo.update()
      id = pet.id
      owner_id = pet.owner.id

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 owner_id: {^owner_id, nil},
                 owner: %EctoDiff{
                   effect: :deleted,
                   primary_key: %{id: ^owner_id},
                   changes: %{}
                 }
               }
             } = diff
    end

    test "update that doesn't change a loaded belongs_to does not include it in diff" do
      {:ok, pet} = %{name: "Spot", owner: %{name: "Chris"}} |> Pet.new() |> Repo.insert()
      {:ok, updated_pet} = pet |> Pet.update(%{name: "McFluffFace"}) |> Repo.update()
      id = pet.id

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 name: {"Spot", "McFluffFace"}
               }
             } = diff

      refute Map.has_key?(diff.changes, :owner)
    end

    # Has Many Association

    test "no changes with has_many" do
      {:ok, pet} = %{name: "Spot", skills: [%{name: "Eating"}, %{name: "Sleeping"}]} |> Pet.new() |> Repo.insert()

      assert {:ok, :unchanged} = EctoDiff.diff(pet, pet)
    end

    test "insert with has_many" do
      {:ok, pet} = %{name: "Spot", skills: [%{name: "Eating"}, %{name: "Sleeping"}]} |> Pet.new() |> Repo.insert()
      id = pet.id
      [eating_id, sleeping_id] = Enum.map(pet.skills, & &1.id)

      {:ok, diff} = EctoDiff.diff(nil, pet)

      assert %EctoDiff{
               effect: :added,
               primary_key: %{id: ^id},
               changes: %{
                 id: {nil, ^id},
                 name: {nil, "Spot"},
                 skills: [
                   %EctoDiff{
                     effect: :added,
                     primary_key: %{id: ^eating_id},
                     changes: %{
                       id: {nil, ^eating_id},
                       pet_id: {nil, ^id},
                       name: {nil, "Eating"}
                     }
                   },
                   %EctoDiff{
                     effect: :added,
                     primary_key: %{id: ^sleeping_id},
                     changes: %{
                       id: {nil, ^sleeping_id},
                       pet_id: {nil, ^id},
                       name: {nil, "Sleeping"}
                     }
                   }
                 ]
               }
             } = diff
    end

    test "insert with empty has_many" do
      {:ok, pet} = %{name: "Spot", skills: []} |> Pet.new() |> Repo.insert()
      id = pet.id

      {:ok, diff} = EctoDiff.diff(nil, pet)

      assert %EctoDiff{
               effect: :added,
               primary_key: %{id: ^id},
               changes: %{
                 id: {nil, ^id},
                 name: {nil, "Spot"}
               }
             } = diff
    end

    test "update with adding new has_many records" do
      {:ok, pet} = %{name: "Spot", skills: []} |> Pet.new() |> Repo.insert()
      {:ok, updated_pet} = pet |> Pet.update(%{skills: [%{name: "Eating"}, %{name: "Sleeping"}]}) |> Repo.update()
      id = pet.id
      [eating_id, sleeping_id] = Enum.map(updated_pet.skills, & &1.id)

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 skills: [
                   %EctoDiff{
                     effect: :added,
                     primary_key: %{id: ^eating_id},
                     changes: %{
                       id: {nil, ^eating_id},
                       pet_id: {nil, ^id},
                       name: {nil, "Eating"}
                     }
                   },
                   %EctoDiff{
                     effect: :added,
                     primary_key: %{id: ^sleeping_id},
                     changes: %{
                       id: {nil, ^sleeping_id},
                       pet_id: {nil, ^id},
                       name: {nil, "Sleeping"}
                     }
                   }
                 ]
               }
             } = diff
    end

    test "update with has_many, updating one of many records" do
      {:ok, pet} = %{name: "Spot", skills: [%{name: "Eating"}, %{name: "Sleeping"}]} |> Pet.new() |> Repo.insert()
      id = pet.id
      [eating_id, sleeping_id] = Enum.map(pet.skills, & &1.id)

      {:ok, updated_pet} =
        pet |> Pet.update(%{skills: [%{id: eating_id}, %{id: sleeping_id, level: 2}]}) |> Repo.update()

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 skills: [
                   %EctoDiff{
                     effect: :changed,
                     primary_key: %{id: ^sleeping_id},
                     changes: %{
                       level: {1, 2}
                     }
                   }
                 ]
               }
             } = diff
    end

    test "update with has_many, removing one of many records using on_replace: :delete" do
      {:ok, pet} = %{name: "Spot", skills: [%{name: "Eating"}, %{name: "Sleeping"}]} |> Pet.new() |> Repo.insert()
      id = pet.id
      [eating_id, sleeping_id] = Enum.map(pet.skills, & &1.id)

      {:ok, updated_pet} = pet |> Pet.update(%{skills: [%{id: eating_id}]}) |> Repo.update()

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 skills: [
                   %EctoDiff{
                     effect: :deleted,
                     primary_key: %{id: ^sleeping_id},
                     changes: %{}
                   }
                 ]
               }
             } = diff
    end

    test "update that doesn't change a loaded has_many does not include it in diff" do
      {:ok, pet} = %{name: "Spot", skills: [%{name: "Eating"}, %{name: "Sleeping"}]} |> Pet.new() |> Repo.insert()
      {:ok, updated_pet} = pet |> Pet.update(%{name: "McFluffFace"}) |> Repo.update()
      id = pet.id

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 name: {"Spot", "McFluffFace"}
               }
             } = diff

      refute Map.has_key?(diff.changes, :skills)
    end

    test "update with has_many while adding a new record, removing a record, updating a record, and leaving one alone" do
      {:ok, pet} =
        %{name: "Spot", skills: [%{name: "Eating"}, %{name: "Sleeping"}, %{name: "Scratching"}]}
        |> Pet.new()
        |> Repo.insert()

      id = pet.id
      [eating_id, sleeping_id, scratching_id] = Enum.map(pet.skills, & &1.id)

      {:ok, updated_pet} =
        pet
        |> Pet.update(%{skills: [%{id: eating_id}, %{id: sleeping_id, level: 2}, %{name: "Meowing"}]})
        |> Repo.update()

      [^eating_id, ^sleeping_id, meowing_id] = Enum.map(updated_pet.skills, & &1.id)

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 skills: [
                   %EctoDiff{
                     effect: :changed,
                     primary_key: %{id: ^sleeping_id},
                     changes: %{
                       level: {1, 2}
                     }
                   },
                   %EctoDiff{
                     effect: :deleted,
                     primary_key: %{id: ^scratching_id},
                     changes: %{}
                   },
                   %EctoDiff{
                     effect: :added,
                     primary_key: %{id: ^meowing_id},
                     changes: %{
                       id: {nil, ^meowing_id},
                       pet_id: {nil, ^id},
                       name: {nil, "Meowing"}
                     }
                   }
                 ]
               }
             } = diff
    end

    # Has Many through polymorphic Association

    test "no changes with has_many through" do
      {:ok, pet} =
        %{
          name: "Spot",
          skills: [%{name: "Eating"}, %{name: "Sleeping"}],
          resources: [
            %{toys: [%{name: "ball", type: "play", quantity: 1}, %{name: "mouse", type: "play", quantity: 2}]}
          ]
        }
        |> Pet.new()
        |> Repo.insert()

      assert {:ok, :unchanged} = EctoDiff.diff(pet, pet)
    end

    test "insert with has_many through" do
      {:ok, pet} =
        %{
          name: "Spot",
          resources: [
            %{toys: [%{name: "ball", type: "play", quantity: 1}, %{name: "mouse", type: "play", quantity: 2}]}
          ]
        }
        |> Pet.new()
        |> Repo.insert()

      pet = Repo.preload(pet, :toys)

      id = pet.id
      [%{id: resource_id}] = pet.resources
      [ball_id, mouse_id] = Enum.map(pet.toys, & &1.id)

      {:ok, diff} = EctoDiff.diff(nil, pet)
      [%{changes: %{toys: resource_toys}}] = diff.changes.resources

      assert resource_toys == diff.changes.toys

      assert %EctoDiff{
               effect: :added,
               primary_key: %{id: ^id},
               changes: %{
                 id: {nil, ^id},
                 name: {nil, "Spot"},
                 resources: [
                   %EctoDiff{
                     effect: :added,
                     changes: %{
                       pet_id: {nil, ^id}
                     }
                   }
                 ],
                 toys: [
                   %EctoDiff{
                     effect: :added,
                     primary_key: %{id: ^ball_id},
                     changes: %{
                       id: {nil, ^ball_id},
                       resource_id: {nil, ^resource_id},
                       name: {nil, "ball"}
                     }
                   },
                   %EctoDiff{
                     effect: :added,
                     primary_key: %{id: ^mouse_id},
                     changes: %{
                       id: {nil, ^mouse_id},
                       resource_id: {nil, ^resource_id},
                       name: {nil, "mouse"}
                     }
                   }
                 ]
               }
             } = diff
    end

    test "insert with empty has_many through" do
      {:ok, pet} =
        %{
          name: "Spot",
          resources: [
            %{toys: []}
          ]
        }
        |> Pet.new()
        |> Repo.insert()

      id = pet.id

      {:ok, diff} = EctoDiff.diff(nil, pet)

      assert %EctoDiff{
               effect: :added,
               primary_key: %{id: ^id},
               changes: %{
                 id: {nil, ^id},
                 name: {nil, "Spot"},
                 resources: [
                   %EctoDiff{
                     effect: :added,
                     changes: %{
                       pet_id: {nil, ^id}
                     }
                   }
                 ]
               }
             } = diff
    end

    test "update with adding new has_many through records" do
      {:ok, pet} = %{name: "Spot", resources: []} |> Pet.new() |> Repo.insert()

      {:ok, updated_pet} =
        pet
        |> Pet.update(%{
          resources: [
            %{toys: [%{name: "ball", type: "play", quantity: 1}, %{name: "mouse", type: "play", quantity: 2}]}
          ]
        })
        |> Repo.update()

      updated_pet = Repo.preload(updated_pet, :toys)

      id = pet.id
      [%{id: resource_id}] = updated_pet.resources
      %{"ball" => ball_id, "mouse" => mouse_id} = Enum.into(updated_pet.toys, %{}, &{&1.name, &1.id})

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)
      [%{changes: %{toys: resource_toys}}] = diff.changes.resources

      assert resource_toys == diff.changes.toys

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 resources: [
                   %EctoDiff{
                     effect: :added,
                     changes: %{
                       pet_id: {nil, ^id},
                       toys: [
                         %EctoDiff{
                           effect: :added,
                           changes: %{}
                         },
                         %EctoDiff{
                           effect: :added,
                           changes: %{}
                         }
                       ]
                     }
                   }
                 ],
                 toys: [
                   %EctoDiff{
                     effect: :added,
                     primary_key: %{id: ^ball_id},
                     changes: %{
                       id: {nil, ^ball_id},
                       resource_id: {nil, ^resource_id},
                       name: {nil, "ball"}
                     }
                   },
                   %EctoDiff{
                     effect: :added,
                     primary_key: %{id: ^mouse_id},
                     changes: %{
                       id: {nil, ^mouse_id},
                       resource_id: {nil, ^resource_id},
                       name: {nil, "mouse"}
                     }
                   }
                 ]
               }
             } = diff
    end

    test "update with has_many through, updating one of many records" do
      {:ok, pet} =
        %{
          name: "Spot",
          resources: [
            %{toys: [%{name: "ball", type: "play", quantity: 1}, %{name: "mouse", type: "play", quantity: 2}]}
          ]
        }
        |> Pet.new()
        |> Repo.insert()

      id = pet.id
      pet = Repo.preload(pet, :toys)

      %{"ball" => ball_id, "mouse" => mouse_id} = Enum.into(pet.toys, %{}, &{&1.name, &1.id})
      [%{id: resource_id}] = pet.resources

      {:ok, updated_pet} =
        pet
        |> Pet.update(%{
          resources: [
            %{id: resource_id, toys: [%{id: ball_id, quantity: 5}, %{id: mouse_id}]}
          ]
        })
        |> Repo.update()

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)
      [%{changes: %{toys: resource_toys}}] = diff.changes.resources

      assert resource_toys == diff.changes.toys

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 resources: [
                   %EctoDiff{
                     effect: :changed,
                     primary_key: %{id: ^resource_id},
                     changes: %{
                       toys: [
                         %EctoDiff{
                           effect: :changed,
                           primary_key: %{id: ^ball_id},
                           changes: %{
                             quantity: {1, 5}
                           }
                         }
                       ]
                     }
                   }
                 ],
                 toys: [
                   %EctoDiff{
                     effect: :changed,
                     primary_key: %{id: ^ball_id},
                     changes: %{
                       quantity: {1, 5}
                     }
                   }
                 ]
               }
             } = diff
    end

    test "update with has_many through, removing one of many records using on_replace: :delete" do
      {:ok, pet} =
        %{name: "Spot", resources: [%{toys: [%{name: "ball", type: "play", quantity: 1}]}]}
        |> Pet.new()
        |> Repo.insert()

      pet = Repo.preload(pet, :toys)
      id = pet.id
      [%{id: resource_id}] = pet.resources
      [ball_id] = Enum.map(pet.toys, & &1.id)

      {:ok, updated_pet} = pet |> Pet.update(%{resources: [%{id: resource_id, toys: []}]}) |> Repo.update()

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)
      [%{changes: %{toys: resource_toys}}] = diff.changes.resources

      assert resource_toys == diff.changes.toys

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 resources: [
                   %EctoDiff{
                     effect: :changed,
                     primary_key: %{id: ^resource_id},
                     changes: %{
                       toys: [
                         %EctoDiff{
                           effect: :deleted,
                           primary_key: %{id: ^ball_id},
                           current: nil,
                           changes: %{}
                         }
                       ]
                     }
                   }
                 ],
                 toys: [
                   %EctoDiff{
                     effect: :deleted,
                     primary_key: %{id: ^ball_id},
                     current: nil,
                     changes: %{}
                   }
                 ]
               }
             } = diff
    end

    test "update that doesn't change a loaded has_many through does not include it in diff" do
      {:ok, pet} =
        %{name: "Spot", resources: [%{toys: [%{name: "ball", type: "play", quantity: 1}]}]}
        |> Pet.new()
        |> Repo.insert()

      pet = Repo.preload(pet, :toys)
      {:ok, updated_pet} = pet |> Pet.update(%{name: "McFluffFace"}) |> Repo.update()
      id = pet.id

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               struct: Pet,
               primary_key: %{id: id},
               previous: pet,
               current: updated_pet,
               changes: %{
                 name: {"Spot", "McFluffFace"}
               }
             } == diff
    end

    # Embeds One Association

    test "no changes with embeds_one" do
      {:ok, pet} = %{name: "Spot", details: %{description: "It's a kitty!"}} |> Pet.new() |> Repo.insert()

      assert {:ok, :unchanged} = EctoDiff.diff(pet, pet)
    end

    test "insert with embeds_one" do
      {:ok, pet} = %{name: "Spot", details: %{description: "It's a kitty!"}} |> Pet.new() |> Repo.insert()
      id = pet.id
      details_id = pet.details.id

      {:ok, diff} = EctoDiff.diff(nil, pet)

      assert %EctoDiff{
               effect: :added,
               primary_key: %{id: ^id},
               changes: %{
                 id: {nil, ^id},
                 name: {nil, "Spot"},
                 details: %EctoDiff{
                   effect: :added,
                   primary_key: %{id: ^details_id},
                   changes: %{
                     id: {nil, ^details_id},
                     description: {nil, "It's a kitty!"}
                   }
                 }
               }
             } = diff
    end

    test "update with adding a new embeds_one" do
      {:ok, pet} = %{name: "Spot"} |> Pet.new() |> Repo.insert()
      {:ok, updated_pet} = pet |> Pet.update(%{details: %{description: "It's a kitty!"}}) |> Repo.update()
      id = pet.id
      details_id = updated_pet.details.id

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 details: %EctoDiff{
                   effect: :added,
                   primary_key: %{id: ^details_id},
                   changes: %{
                     id: {nil, ^details_id},
                     description: {nil, "It's a kitty!"}
                   }
                 }
               }
             } = diff
    end

    # TODO: the following case only tests embeds_one with on_replace: :update
    # other cases should be written for other options to on_replace

    test "update an embeds_one using on_replace: :update" do
      {:ok, pet} = %{name: "Spot", details: %{description: "It's a kitty!"}} |> Pet.new() |> Repo.insert()
      {:ok, updated_pet} = pet |> Pet.update(%{details: %{description: "so... fluffy..."}}) |> Repo.update()
      id = pet.id
      details_id = pet.details.id

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 details: %EctoDiff{
                   effect: :changed,
                   primary_key: %{id: ^details_id},
                   changes: %{
                     description: {"It's a kitty!", "so... fluffy..."}
                   }
                 }
               }
             } = diff
    end

    test "update with deleting an embeds_one" do
      {:ok, pet} = %{name: "Spot", details: %{description: "It's a kitty!"}} |> Pet.new() |> Repo.insert()
      {:ok, updated_pet} = pet |> Pet.update(%{details: nil}) |> Repo.update()
      id = pet.id
      details_id = pet.details.id

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 details: %EctoDiff{
                   effect: :deleted,
                   primary_key: %{id: ^details_id},
                   changes: %{}
                 }
               }
             } = diff
    end

    test "update that doesn't change an embeds_one does not include it in diff" do
      {:ok, pet} = %{name: "Spot", details: %{description: "It's a kitty!"}} |> Pet.new() |> Repo.insert()
      {:ok, updated_pet} = pet |> Pet.update(%{name: "McFluffFace"}) |> Repo.update()
      id = pet.id

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 name: {"Spot", "McFluffFace"}
               }
             } = diff

      refute Map.has_key?(diff.changes, :details)
    end

    # Embeds Many Association

    test "no changes with embeds_many" do
      {:ok, pet} = %{name: "Spot", quotes: [%{quote: "Meow!"}, %{quote: "Nyan!"}]} |> Pet.new() |> Repo.insert()

      assert {:ok, :unchanged} = EctoDiff.diff(pet, pet)
    end

    test "insert with embeds_many" do
      {:ok, pet} = %{name: "Spot", quotes: [%{quote: "Meow!"}, %{quote: "Nyan!"}]} |> Pet.new() |> Repo.insert()
      id = pet.id
      [quote1_id, quote2_id] = Enum.map(pet.quotes, & &1.id)

      {:ok, diff} = EctoDiff.diff(nil, pet)

      assert %EctoDiff{
               effect: :added,
               primary_key: %{id: ^id},
               changes: %{
                 id: {nil, ^id},
                 name: {nil, "Spot"},
                 quotes: [
                   %EctoDiff{
                     effect: :added,
                     primary_key: %{id: ^quote1_id},
                     changes: %{
                       id: {nil, ^quote1_id},
                       quote: {nil, "Meow!"}
                     }
                   },
                   %EctoDiff{
                     effect: :added,
                     primary_key: %{id: ^quote2_id},
                     changes: %{
                       id: {nil, ^quote2_id},
                       quote: {nil, "Nyan!"}
                     }
                   }
                 ]
               }
             } = diff
    end

    test "update with adding new embeds_many records" do
      {:ok, pet} = %{name: "Spot"} |> Pet.new() |> Repo.insert()
      {:ok, updated_pet} = pet |> Pet.update(%{quotes: [%{quote: "Meow!"}, %{quote: "Nyan!"}]}) |> Repo.update()
      id = pet.id
      [quote1_id, quote2_id] = Enum.map(updated_pet.quotes, & &1.id)

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 quotes: [
                   %EctoDiff{
                     effect: :added,
                     primary_key: %{id: ^quote1_id},
                     changes: %{
                       id: {nil, ^quote1_id},
                       quote: {nil, "Meow!"}
                     }
                   },
                   %EctoDiff{
                     effect: :added,
                     primary_key: %{id: ^quote2_id},
                     changes: %{
                       id: {nil, ^quote2_id},
                       quote: {nil, "Nyan!"}
                     }
                   }
                 ]
               }
             } = diff
    end

    test "update with embeds_many, updating one of many records" do
      {:ok, pet} = %{name: "Spot", quotes: [%{quote: "Meow!"}, %{quote: "Nyan!"}]} |> Pet.new() |> Repo.insert()
      id = pet.id
      [quote1_id, quote2_id] = Enum.map(pet.quotes, & &1.id)

      {:ok, updated_pet} =
        pet |> Pet.update(%{quotes: [%{id: quote1_id, quote: "Myaw?"}, %{id: quote2_id}]}) |> Repo.update()

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 quotes: [
                   %EctoDiff{
                     effect: :changed,
                     primary_key: %{id: ^quote1_id},
                     changes: %{
                       quote: {"Meow!", "Myaw?"}
                     }
                   }
                 ]
               }
             } = diff
    end

    test "update with embeds_many, removing one of many records using on_replace: :delete" do
      {:ok, pet} = %{name: "Spot", quotes: [%{quote: "Meow!"}, %{quote: "Nyan!"}]} |> Pet.new() |> Repo.insert()
      id = pet.id
      [quote1_id, quote2_id] = Enum.map(pet.quotes, & &1.id)

      {:ok, updated_pet} = pet |> Pet.update(%{quotes: [%{id: quote2_id}]}) |> Repo.update()

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 quotes: [
                   %EctoDiff{
                     effect: :deleted,
                     primary_key: %{id: ^quote1_id},
                     changes: %{}
                   }
                 ]
               }
             } = diff
    end

    test "update that doesn't change an embeds_many does not include it in diff" do
      {:ok, pet} = %{name: "Spot", quotes: [%{quote: "Meow!"}, %{quote: "Nyan!"}]} |> Pet.new() |> Repo.insert()
      {:ok, updated_pet} = pet |> Pet.update(%{name: "McFluffFace"}) |> Repo.update()
      id = pet.id

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 name: {"Spot", "McFluffFace"}
               }
             } = diff

      refute Map.has_key?(diff.changes, :quotes)
    end

    test "update with embeds_many while adding a new record, removing a record, updating a record, and leaving one alone" do
      {:ok, pet} =
        %{name: "Spot", quotes: [%{quote: "Meow!"}, %{quote: "Nyan!"}, %{quote: "Myaw?"}]}
        |> Pet.new()
        |> Repo.insert()

      id = pet.id
      [quote1_id, quote2_id, quote3_id] = Enum.map(pet.quotes, & &1.id)

      {:ok, updated_pet} =
        pet
        |> Pet.update(%{quotes: [%{id: quote1_id}, %{id: quote2_id, quote: "Nyaaaan!"}, %{quote: "Hello!"}]})
        |> Repo.update()

      [^quote1_id, ^quote2_id, quote4_id] = Enum.map(updated_pet.quotes, & &1.id)

      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert %EctoDiff{
               effect: :changed,
               primary_key: %{id: ^id},
               changes: %{
                 quotes: [
                   %EctoDiff{
                     effect: :changed,
                     primary_key: %{id: ^quote2_id},
                     changes: %{
                       quote: {"Nyan!", "Nyaaaan!"}
                     }
                   },
                   %EctoDiff{
                     effect: :deleted,
                     primary_key: %{id: ^quote3_id},
                     changes: %{}
                   },
                   %EctoDiff{
                     effect: :added,
                     primary_key: %{id: ^quote4_id},
                     changes: %{
                       id: {nil, ^quote4_id},
                       quote: {nil, "Hello!"}
                     }
                   }
                 ]
               }
             } = diff
    end
  end

  describe "EctoDiff structs" do
    test "can be traversed with Access behaviours" do
      {:ok, pet} = %{name: "Spot", quotes: [%{quote: "Meow!"}, %{quote: "Nyan!"}]} |> Pet.new() |> Repo.insert()
      {:ok, updated_pet} = pet |> Pet.update(%{name: "McFluffFace"}) |> Repo.update()

      {:ok, create_diff} = EctoDiff.diff(nil, pet)
      {:ok, diff} = EctoDiff.diff(pet, updated_pet)

      assert get_in(diff, [:struct]) == EctoDiff.Pet
      assert get_in(diff, [:changes, :name, Access.elem(1)]) == "McFluffFace"

      assert %{changes: %{name: {_, new_name}}} =
               put_in(create_diff, [:changes, :name, Access.elem(1)], "NewNameForKitty")

      assert new_name == "NewNameForKitty"

      assert Access.pop(diff, :nonexistent_key) == {nil, diff}

      assert {EctoDiff.Pet, updated_diff} = Access.pop(diff, :struct)
      refute Map.has_key?(updated_diff, :struct)
    end
  end
end
