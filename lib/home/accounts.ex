defmodule Home.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Home.Repo
  alias Home.Accounts.AdminLiteInvite
  alias Home.Accounts.{User, UserToken, UserNotifier, UserIdentity}
  alias Home.Accounts.VerificationRequest

 @pubsub Home.PubSub
  @topic "verification_requests"

  def subscribe_verification_requests do
    Phoenix.PubSub.subscribe(@pubsub, @topic)
  end

 def create_verification_request(attrs) do
    %VerificationRequest{}
    |> VerificationRequest.changeset(attrs) # Explicitly module-scoped
    |> Repo.insert()
    |> case do
      {:ok, request} ->
        Phoenix.PubSub.broadcast(@pubsub, @topic, {:new_verification_request, request})
        {:ok, request}

      error ->
        error
    end
  end
  @doc """
  Returns an '%Ecto.Changeset{}' for tracking user registration changes.
  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, validate_unique: false)
  end

  def change_user_login(user, attrs \\ %{}) do
    User.change_user_login(user, attrs)
  end

  @doc """
  Registers a user in the database
  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  #for finding user and creating if no one this is for sign in by google
  def find_or_create_google_user(google_user) do
  google_id = google_user["sub"]
  email = google_user["email"]


  case Repo.get_by(UserIdentity, provider: "google", provider_user_id: google_id) do
   %UserIdentity{user_id: user_id} ->
  {:ok, get_user!(user_id)}

    nil ->
      case get_user_by_email(email) do
        %User{} = user ->
          create_google_identity(user, google_id)

        nil ->
          create_google_user(google_user, google_id)
      end
  end
end

## for creating google identity

 defp create_google_identity(user, google_id) do
  %UserIdentity{}
  |> UserIdentity.changeset(%{
    provider: "google",
    provider_user_id: google_id,
    user_id: user.id
  })
  |> Repo.insert()
  |> case do
    {:ok, _identity} -> user
    {:error, changeset} -> {:error, changeset}
  end
end

## for creating the user
defp create_google_user(google_user, google_id) do
  Repo.transact(fn ->
    with {:ok, user} <-
           %User{}
           |> User.registration_changeset(%{
             names: google_user["name"],
             email: google_user["email"],
             confirmed_at: DateTime.utc_now()
           })
           |> Repo.insert(),
         {:ok, _identity} <-
           %UserIdentity{}
           |> UserIdentity.changeset(%{
             provider: "google",
             provider_user_id: google_id,
             user_id: user.id
           })
           |> Repo.insert() do
      {:ok, user}
    else
      {:error, changeset} ->
        {:error, changeset}
    end
  end)
end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)

    IO.inspect(user, label: "USER FROM DATABASE")
    IO.inspect(User.valid_password?(user, password), label: "PASSWORD VALID?")

    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `Home.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `Home.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end

  def create_admin_lite_invite(%User{role: "admin"} = admin, email) do
  token =
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64(padding: false)

  expires_at =
    DateTime.utc_now()
    |> DateTime.add(7, :day)

  %AdminLiteInvite{}
  |> AdminLiteInvite.changeset(%{
    email: email,
    token: token,
    invite_type: "admin_lite",
    expires_at: expires_at,
    created_by_id: admin.id
  })
  |> Repo.insert()
end

#creating the admin lite
def create_admin_lite_invite(%User{}, _email) do
  {:error, :unauthorized}
end

#getting the admin lite token
def get_admin_lite_invite_by_token(token) do
  Repo.get_by(AdminLiteInvite, token: token)
end

#validation function
def get_valid_invite_by_token(token) do
  case Repo.get_by(AdminLiteInvite, token: token) do
    nil ->
      {:error, :not_found}

    %AdminLiteInvite{used_at: nil, expires_at: expires_at} = invite ->
      if DateTime.compare(expires_at, DateTime.utc_now()) == :gt do
        {:ok, invite}
      else
        {:error, :expired}
      end

    %AdminLiteInvite{used_at: _} ->
      {:error, :used}
  end
end

#for landlord request
# def create_verification_request(attrs) do
#   %VerificationRequest{}
#   |> VerificationRequest.changeset(attrs)
#   |> Repo.insert()
# end

 #for collecting admin requests from the db
  def list_verification_requests do
  Repo.all(VerificationRequest)
end

#for verfifying token validity
def get_invite_by_token(token) when is_binary(token) do
  case Repo.get_by(AdminLiteInvite, token: token) do
    nil -> {:error, :not_found}
    %AdminLiteInvite{used: true} = invite -> {:error, :already_used, invite}
    %AdminLiteInvite{used: false} = invite -> {:ok, invite}
  end
end

  def mark_invite_as_used(%AdminLiteInvite{} = invite) do
    invite
    |> Ecto.Changeset.change(%{used: true})
    |> Repo.update()
  end

  #for fetching admin lite invites
  def list_admin_lite_invites do
    Repo.all(from i in AdminLiteInvite, order_by: [desc: i.inserted_at])
  end

  #for suspending admine lites
  def delete_admin_lite_invite(id) do
  case Repo.get(AdminLiteInvite, id) do
    nil -> {:error, :not_found}
    invite -> Repo.delete(invite)
  end
end

def toggle_suspend_invite(id) do
  case Repo.get(AdminLiteInvite, id) do
    nil -> {:error, :not_found}
    invite ->
      # Toggles suspended state (requires a `suspended` boolean column on admin_lite_invites)
      current_status = Map.get(invite, :suspended, false)

      invite
      |> Ecto.Changeset.change(%{suspended: !current_status})
      |> Repo.update()
  end
end

@doc """
Creates an invite record for admin_lite or landlord roles.
"""
def create_invite(attrs \\ %{}) do
  %AdminLiteInvite{}
  |> AdminLiteInvite.changeset(attrs)
  |> Repo.insert()
end
end
