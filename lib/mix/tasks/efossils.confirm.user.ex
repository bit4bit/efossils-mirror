defmodule Mix.Tasks.Efossils.Confirm.User do
  use Mix.Task
  @shortdoc "force a user confirmation"

  alias Efossils.Repo
  alias Efossils.Accounts

  def run([username]) do
    Mix.Task.run("app.start")
    user = Accounts.get_user_by_username!(username)
    PowEmailConfirmation.Ecto.Context.confirm_email(user, otp_app: :efossils)
  end
end
