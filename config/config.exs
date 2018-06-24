# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :efossils,
  ecto_repos: [Efossils.Repo]

# Configures the endpoint
config :efossils, EfossilsWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "nU4sFCd9FUhwBRt42DkS4UKewXXpsCI2wwTfiCT7dkCwQk42jRwm1BrzhnOV1GOZ",
  render_errors: [view: EfossilsWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Efossils.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# %% Coherence Configuration %%   Don't remove this line
config :coherence,
  user_schema: Efossils.Coherence.User,
  repo: Efossils.Repo,
  module: Efossils,
  web_module: EfossilsWeb,
  router: EfossilsWeb.Router,
  messages_backend: EfossilsWeb.Coherence.Messages,
  logged_out_url: "/",
  email_from_name: "Your Name",
  email_from_email: "yourname@example.com",
  opts: [:authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token, :invitable, :registerable]

config :coherence, EfossilsWeb.Coherence.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: "your api key here"
# %% End Coherence Configuration %%
