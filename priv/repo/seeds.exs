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

Efossils.Repo.delete_all Efossils.User

Efossils.User.changeset(%Efossils.User{}, %{name: "Efossils user",
                                            username: "efossils_main",
                                            lower_name: "efossils_main",
                                            email: "efossils@local.local",
                                            password: "efossilslocalhost",
                                            confirm_password: "efossilslocalhost"})
|> Efossils.Repo.insert!
|> PowEmailConfirmation.Ecto.Context.confirm_email(otp_app: :efossils)

Efossils.User.changeset(%Efossils.User{}, %{name: "Efossils Collaborator",
                                            username: "efossils_collaborator",
                                            lower_name: "efossils_collaborator",
                                            email: "efossilscollaborator@local.local",
                                            password: "efossilslocalhost",
                                            confirm_password: "efossilslocalhost"})
|> Efossils.Repo.insert!
|> PowEmailConfirmation.Ecto.Context.confirm_email(otp_app: :efossils)

