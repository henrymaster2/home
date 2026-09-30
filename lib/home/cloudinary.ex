defmodule Home.Cloudinary do
  @moduledoc """
  Minimal signed-upload client for Cloudinary using Req.

  Reads credentials from environment variables at runtime:
    CLOUDINARY_CLOUD_NAME
    CLOUDINARY_API_KEY
    CLOUDINARY_API_SECRET
  """

  @doc """
  Uploads a file from a local path to Cloudinary.

  Returns `{:ok, secure_url}` on success or `{:error, reason}` on failure.
  """
  def upload(local_path, folder \\ "properties") when is_binary(local_path) do
  with {:ok, cloud_name} <- fetch_env("CLOUDINARY_CLOUD_NAME"),
       {:ok, api_key} <- fetch_env("CLOUDINARY_API_KEY"),
       {:ok, api_secret} <- fetch_env("CLOUDINARY_API_SECRET") do
    timestamp = System.system_time(:second) |> Integer.to_string()

    # Include folder in signature calculations
    params_to_sign = %{"timestamp" => timestamp, "folder" => folder}
    signature = sign(params_to_sign, api_secret)

    url = "https://api.cloudinary.com/v1_1/#{cloud_name}/auto/upload"

    Req.post(url,
      form_multipart: [
        api_key: api_key,
        timestamp: timestamp,
        folder: folder,
        signature: signature,
        file: {File.stream!(local_path, [], 2048), filename: Path.basename(local_path)}
      ]
    )
    |> case do
      {:ok, %Req.Response{status: 200, body: %{"secure_url" => secure_url}}} ->
        {:ok, secure_url}

      {:ok, %Req.Response{status: 200, body: body}} ->
        {:error, {:unexpected_response, body}}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
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

end
