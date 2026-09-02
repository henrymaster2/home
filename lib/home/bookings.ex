defmodule Home.Bookings do
  @moduledoc """
  The Bookings context.
  """

  import Ecto.Query, warn: false
  alias Home.Repo

  alias Home.Bookings.Booking
  alias Home.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any booking changes.

  The broadcasted messages match the pattern:

    * {:created, %Booking{}}
    * {:updated, %Booking{}}
    * {:deleted, %Booking{}}

  """
  def subscribe_bookings(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Home.PubSub, "user:#{key}:bookings")
  end

  defp broadcast_booking(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Home.PubSub, "user:#{key}:bookings", message)
  end

  @doc """
  Returns the list of bookings.

  ## Examples

      iex> list_bookings(scope)
      [%Booking{}, ...]

  """
  def list_bookings(%Scope{} = scope) do
    Repo.all_by(Booking, user_id: scope.user.id)
  end

  @doc """
  Gets a single booking.

  Raises `Ecto.NoResultsError` if the Booking does not exist.

  ## Examples

      iex> get_booking!(scope, 123)
      %Booking{}

      iex> get_booking!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_booking!(%Scope{} = scope, id) do
    Repo.get_by!(Booking, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a booking.

  ## Examples

      iex> create_booking(scope, %{field: value})
      {:ok, %Booking{}}

      iex> create_booking(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_booking(%Scope{} = scope, attrs) do
    with {:ok, booking = %Booking{}} <-
           %Booking{}
           |> Booking.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_booking(scope, {:created, booking})
      {:ok, booking}
    end
  end

  @doc """
  Updates a booking.

  ## Examples

      iex> update_booking(scope, booking, %{field: new_value})
      {:ok, %Booking{}}

      iex> update_booking(scope, booking, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_booking(%Scope{} = scope, %Booking{} = booking, attrs) do
    true = booking.user_id == scope.user.id

    with {:ok, booking = %Booking{}} <-
           booking
           |> Booking.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_booking(scope, {:updated, booking})
      {:ok, booking}
    end
  end

  @doc """
  Deletes a booking.

  ## Examples

      iex> delete_booking(scope, booking)
      {:ok, %Booking{}}

      iex> delete_booking(scope, booking)
      {:error, %Ecto.Changeset{}}

  """
  def delete_booking(%Scope{} = scope, %Booking{} = booking) do
    true = booking.user_id == scope.user.id

    with {:ok, booking = %Booking{}} <-
           Repo.delete(booking) do
      broadcast_booking(scope, {:deleted, booking})
      {:ok, booking}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking booking changes.

  ## Examples

      iex> change_booking(scope, booking)
      %Ecto.Changeset{data: %Booking{}}

  """
  def change_booking(%Scope{} = scope, %Booking{} = booking, attrs \\ %{}) do
    true = booking.user_id == scope.user.id

    Booking.changeset(booking, attrs, scope)
  end
end
