use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :efossils, EfossilsWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :efossils, Efossils.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "neurodev",
  password: "neurodev",
  database: "efossils_test",
  hostname: "10.0.0.150",
  pool: Ecto.Adapters.SQL.Sandbox
