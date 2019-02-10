defmodule EfossilsWeb.PowMailer do
  @moduledoc false
  use Pow.Phoenix.Mailer
  use Swoosh.Mailer, otp_app: :efossils

  import Swoosh.Email
  @from_name Application.get_env(:efossils, :email_from_name)
  @from_email Application.get_env(:efossils, :email_from_email)

  def cast(email) do
    new()
    |> from({@from_name, @frome_email})
    |> to({email.user.name, email.user.email})
    |> subject(email.subject)
    |> text_body(email.text)
    |> html_body(email.html)
  end

  def process(email), do: deliver(email)
end
