defmodule HomeWeb.GoogleAuthController do
  use HomeWeb, :controller

  alias Assent.Strategy.Google

  def request(conn, _params) do
    config = [
      client_id: Application.fetch_env!(:home, :google_oauth)[:client_id],
      client_secret: Application.fetch_env!(:home, :google_oauth)[:client_secret],
      redirect_uri: url(~p"/auth/google/callback")
    ]

    case Google.authorize_url(config) do
      {:ok, %{url: url, session_params: session_params}} ->
        conn
        |> put_session(:google_session_params, session_params)
        |> redirect(external: url)

      {:error, reason} ->
        IO.inspect(reason, label: "GOOGLE AUTHORIZATION ERROR")

        conn
        |> put_flash(:error, "Unable to connect to Google.")
        |> redirect(to: ~p"/profile")
    end
  end
  def callback(conn, params) do
  session_params = get_session(conn, :google_session_params)

  config =
    [
      client_id: Application.fetch_env!(:home, :google_oauth)[:client_id],
      client_secret: Application.fetch_env!(:home, :google_oauth)[:client_secret],
      redirect_uri: url(~p"/auth/google/callback")
    ]
    |> Keyword.put(:session_params, session_params)

  case Google.callback(config, params) do
    {:ok, %{user: google_user}} ->
  case Accounts.find_or_create_google_user(google_user) do
    {:ok, user} ->
      conn
      |> put_flash(:info, "Successfully signed in with Google!")
      |> UserAuth.log_in_user(user, %{})

    user ->
      conn
      |> put_flash(:info, "Successfully signed in with Google!")
      |> UserAuth.log_in_user(user, %{})

    {:error, reason} ->
      IO.inspect(reason, label: "GOOGLE USER ERROR")

      conn
      |> put_flash(:error, "Unable to sign in with Google.")
      |> redirect(to: ~p"/profile")
    end
  end
 end
end
