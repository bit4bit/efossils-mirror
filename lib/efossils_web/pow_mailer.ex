defmodule EfossilsWeb.PowMailer do
  @moduledoc false
  use Pow.Phoenix.Mailer
  use Swoosh.Mailer, otp_app: :my_app

  import Swoosh.Email

  def cast(email) do
    new()
    |> from({"Efossils", "myapp@example.com"})
    |> to({"", email.user.email})
    |> subject(email.subject)
    |> text_body(email.text)
    |> html_body(email.html)
  end

  def process(email), do: deliver(email)
end
