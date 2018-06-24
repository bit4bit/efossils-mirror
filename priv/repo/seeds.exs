# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Efossils.Repo.insert!(%Efossils.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

Efossils.Repo.delete_all Efossils.Coherence.User

Efossils.Coherence.User.changeset(%Efossils.Coherence.User{}, %{name: "Efossils user", email: "efossils@local.local", password: "efossils", password_confirmation: "efossils"})
|> Efossils.Repo.insert!
|> Coherence.ControllerHelpers.confirm!
