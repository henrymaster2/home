import Config

# Load environment variables from .env file for local development
source = Dotenvy.source!([".env"])

Enum.each(source, fn {key, value} ->
  System.put_env(key, value)
end)

# --- Database Configuration (Runs in ALL environments) ---
config :home, Home.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

# --- Cloudinary Configuration ---
config :home, :cloudinary,
  cloud_name: System.get_env("CLOUDINARY_CLOUD_NAME"),
  api_key: System.get_env("CLOUDINARY_API_KEY"),
  api_secret: System.get_env("CLOUDINARY_API_SECRET")

if System.get_env("PHX_SERVER") do
  config :home, HomeWeb.Endpoint, server: true
end

config :home, HomeWeb.Endpoint,
  http: [
    ip: {0, 0, 0, 0},
    port: String.to_integer(System.get_env("PORT", "4000"))
  ]

if config_env() == :prod do
  # Keep only prod-specific additions here (like SSL and IPv6 handling)
  maybe_ipv6 =
    if System.get_env("ECTO_IPV6") in ~w(true 1),
      do: [:inet6],
      else: []

  config :home, Home.Repo,
    socket_options: maybe_ipv6,
    ssl: true

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise "environment variable SECRET_KEY_BASE is missing."

  host = System.get_env("PHX_HOST") || "example.com"
  config :home, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :home, HomeWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    secret_key_base: secret_key_base
end