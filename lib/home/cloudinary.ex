defmodule Home.Cloudinary do
  @moduledoc """
  Minimal signed-upload client for Cloudinary. No external HTTP dependency —
  uses Erlang's built-in `:httpc`.

  Reads credentials from environment variables at runtime:
    CLOUDINARY_CLOUD_NAME
    CLOUDINARY_API_KEY
    CLOUDINARY_API_SECRET

  Make sure `:inets` and `:ssl` are started. In `mix.exs`, under `application/0`:

      def application do
        [
          mod: {Home.Application, []},
          extra_applications: [:logger, :runtime_tools, :inets, :ssl]
        ]
      end
  """

  @doc """
  Uploads a file from a local path to Cloudinary.

  Returns `{:ok, secure_url}` on success or `{:error, reason}` on failure.
  """
  def upload(local_path) when is_binary(local_path) do
    with {:ok, cloud_name} <- fetch_env("CLOUDINARY_CLOUD_NAME"),
         {:ok, api_key} <- fetch_env("CLOUDINARY_API_KEY"),
         {:ok, api_secret} <- fetch_env("CLOUDINARY_API_SECRET") do
      timestamp = System.system_time(:second) |> Integer.to_string()
      signature = sign(%{"timestamp" => timestamp}, api_secret)

      url = "https://api.cloudinary.com/v1_1/#{cloud_name}/image/upload"
      boundary = "----ElixirCloudinaryBoundary#{System.unique_integer([:positive])}"

      body =
        [
          text_part(boundary, "api_key", api_key),
          text_part(boundary, "timestamp", timestamp),
          text_part(boundary, "signature", signature),
          file_part(boundary, "file", Path.basename(local_path), File.read!(local_path)),
          "--#{boundary}--\r\n"
        ]
        |> IO.iodata_to_binary()

      do_request(url, boundary, body)
    end
  end

  defp do_request(url, boundary, body) do
    content_type = ~c"multipart/form-data; boundary=#{boundary}"

    request = {String.to_charlist(url), [], content_type, body}

    case :httpc.request(:post, request, [], body_format: :binary) do
      {:ok, {{_http_version, 200, _reason}, _headers, resp_body}} ->
        case Jason.decode(resp_body) do
          {:ok, %{"secure_url" => secure_url}} -> {:ok, secure_url}
          {:ok, other} -> {:error, {:unexpected_response, other}}
          {:error, reason} -> {:error, {:invalid_json, reason}}
        end

      {:ok, {{_http_version, status, _reason}, _headers, resp_body}} ->
        {:error, {:http_error, status, resp_body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_env(key) do
    case System.get_env(key) do
      nil -> {:error, {:missing_env, key}}
      "" -> {:error, {:missing_env, key}}
      value -> {:ok, value}
    end
  end

  defp sign(params, api_secret) do
    params
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.map_join("&", fn {k, v} -> "#{k}=#{v}" end)
    |> Kernel.<>(api_secret)
    |> then(&:crypto.hash(:sha, &1))
    |> Base.encode16(case: :lower)
  end

  defp text_part(boundary, name, value) do
    "--#{boundary}\r\n" <>
      "Content-Disposition: form-data; name=\"#{name}\"\r\n\r\n" <>
      "#{value}\r\n"
  end

  defp file_part(boundary, name, filename, content) do
    "--#{boundary}\r\n" <>
      "Content-Disposition: form-data; name=\"#{name}\"; filename=\"#{filename}\"\r\n" <>
      "Content-Type: application/octet-stream\r\n\r\n" <>
      content <> "\r\n"
  end
end