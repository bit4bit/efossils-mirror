# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :efossils,
  ecto_repos: [Efossils.Repo],
  federated_name: "Efossils",
  fossil_bin: "fossil",
  fossil_base_url: "http://localhost:4000",
  fossil_repositories_path: "data/repositories",
  fossil_work_path: "data/works",
  fossil_git_mirror_path: "data/gitmirror",
  fossil_user_admin: "efossils_admin",
  fossil_mirror_ticktime: 60_000_0

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

config :efossils, :pow,
  repo: Efossils.Repo,
  user: Efossils.User,
  extensions: [PowEmailConfirmation, PowResetPassword],
  controller_callbacks: Pow.Extension.Phoenix.ControllerCallbacks,
  mailer_backend: EfossilsWeb.PowMailer,
  web_module: EfossilsWeb

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

config :scrivener_html,
  routes_helper: EfossilsWeb.Router.Helpers,
  view_style: :semantic

