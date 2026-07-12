import Config

# Configure your database for local development safely
config :home, Home.Repo,
  url: System.get_env("DATABASE_URL"),
  ssl: true,
  ssl_opts: [
    verify: :verify_none
  ],
  pool_size: 10,
  queue_target: 10_000,
  queue_interval: 1000,
  timeout: 30_000

# For development, we disable any cache and enable
# debugging and code reloading.
config :home, HomeWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "NsvvSCIinvjXYWX1PsGFVBnbVBPc6TZAGB8tikLioiqw3V1dnsFcwRvbiVTmky4y",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:home, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:home, ~w(--watch)]}
  ]

# Reload browser tabs when matching files change.
config :home, HomeWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      # Static assets, except user uploads
      ~r"priv/static/(?!uploads/).*\.(js|css|png|jpeg|jpg|gif|svg)$",
      # Gettext translations
      ~r"priv/gettext/.*\.po$",
      # Router, Controllers, LiveViews and LiveComponents
      ~r"lib/home_web/router\.ex$",
      ~r"lib/home_web/(controllers|live|components)/.*\.(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :home, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :default_formatter, format: "[$level] $message\n"

# Set a higher stacktrace during development.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Include debug annotations and locations in rendered markup.
  debug_heex_annotations: true,
  debug_attributes: true,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false