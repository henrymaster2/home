defmodule Home.Properties do
  @moduledoc """
  The Properties context.
  """

  import Ecto.Query, warn: false
  alias Home.Repo

  alias Home.Properties.Property
  alias Home.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any property changes.

  The broadcasted messages match the pattern:

    * {:created, %Property{}}
    * {:updated, %Property{}}
    * {:deleted, %Property{}}

  """
  def subscribe_properties(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Home.PubSub, "user:#{key}:properties")
  end

  defp broadcast_property(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Home.PubSub, "user:#{key}:properties", message)
  end

  @doc """
  Returns the list of properties.

  ## Examples

      iex> list_properties(scope)
      [%Property{}, ...]

  """
  def list_properties(%Scope{} = scope) do
    Repo.all_by(Property, user_id: scope.user.id)
  end

  @doc """
  Gets a single property.

  Raises `Ecto.NoResultsError` if the Property does not exist.

  ## Examples

      iex> get_property!(scope, 123)
      %Property{}

      iex> get_property!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_property!(%Scope{} = scope, id) do
    Repo.get_by!(Property, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a property.

  ## Examples

      iex> create_property(scope, %{field: value})
      {:ok, %Property{}}

      iex> create_property(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_property(%Scope{} = scope, attrs) do
    with {:ok, property = %Property{}} <-
           %Property{}
           |> Property.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_property(scope, {:created, property})
      {:ok, property}
    end
  end

  @doc """
  Updates a property.

  ## Examples

      iex> update_property(scope, property, %{field: new_value})
      {:ok, %Property{}}

      iex> update_property(scope, property, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_property(%Scope{} = scope, %Property{} = property, attrs) do
    true = property.user_id == scope.user.id

    with {:ok, property = %Property{}} <-
           property
           |> Property.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_property(scope, {:updated, property})
      {:ok, property}
    end
  end

  @doc """
  Deletes a property.

  ## Examples

      iex> delete_property(scope, property)
      {:ok, %Property{}}

      iex> delete_property(scope, property)
      {:error, %Ecto.Changeset{}}

  """
  def delete_property(%Scope{} = scope, %Property{} = property) do
    true = property.user_id == scope.user.id

    with {:ok, property = %Property{}} <-
           Repo.delete(property) do
      broadcast_property(scope, {:deleted, property})
      {:ok, property}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking property changes.

  ## Examples

      iex> change_property(scope, property)
      %Ecto.Changeset{data: %Property{}}

  """
  def change_property(%Scope{} = scope, %Property{} = property, attrs \\ %{}) do
    true = property.user_id == scope.user.id

    Property.changeset(property, attrs, scope)
  end

  alias Home.Properties.PropertyImage
  alias Home.Accounts.Scope

  @doc """
  Subscribes to scoped notifications about any property_image changes.

  The broadcasted messages match the pattern:

    * {:created, %PropertyImage{}}
    * {:updated, %PropertyImage{}}
    * {:deleted, %PropertyImage{}}

  """
  def subscribe_property_images(%Scope{} = scope) do
    key = scope.user.id

    Phoenix.PubSub.subscribe(Home.PubSub, "user:#{key}:property_images")
  end

  defp broadcast_property_image(%Scope{} = scope, message) do
    key = scope.user.id

    Phoenix.PubSub.broadcast(Home.PubSub, "user:#{key}:property_images", message)
  end

  @doc """
  Returns the list of property_images.

  ## Examples

      iex> list_property_images(scope)
      [%PropertyImage{}, ...]

  """
  def list_property_images(%Scope{} = scope) do
    Repo.all_by(PropertyImage, user_id: scope.user.id)
  end

  @doc """
  Gets a single property_image.

  Raises `Ecto.NoResultsError` if the Property image does not exist.

  ## Examples

      iex> get_property_image!(scope, 123)
      %PropertyImage{}

      iex> get_property_image!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_property_image!(%Scope{} = scope, id) do
    Repo.get_by!(PropertyImage, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a property_image.

  ## Examples

      iex> create_property_image(scope, %{field: value})
      {:ok, %PropertyImage{}}

      iex> create_property_image(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_property_image(%Scope{} = scope, attrs) do
    with {:ok, property_image = %PropertyImage{}} <-
           %PropertyImage{}
           |> PropertyImage.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_property_image(scope, {:created, property_image})
      {:ok, property_image}
    end
  end

  @doc """
  Updates a property_image.

  ## Examples

      iex> update_property_image(scope, property_image, %{field: new_value})
      {:ok, %PropertyImage{}}

      iex> update_property_image(scope, property_image, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_property_image(%Scope{} = scope, %PropertyImage{} = property_image, attrs) do
    true = property_image.user_id == scope.user.id

    with {:ok, property_image = %PropertyImage{}} <-
           property_image
           |> PropertyImage.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_property_image(scope, {:updated, property_image})
      {:ok, property_image}
    end
  end

  @doc """
  Deletes a property_image.

  ## Examples

      iex> delete_property_image(scope, property_image)
      {:ok, %PropertyImage{}}

      iex> delete_property_image(scope, property_image)
      {:error, %Ecto.Changeset{}}

  """
  def delete_property_image(%Scope{} = scope, %PropertyImage{} = property_image) do
    true = property_image.user_id == scope.user.id

    with {:ok, property_image = %PropertyImage{}} <-
           Repo.delete(property_image) do
      broadcast_property_image(scope, {:deleted, property_image})
      {:ok, property_image}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking property_image changes.

  ## Examples

      iex> change_property_image(scope, property_image)
      %Ecto.Changeset{data: %PropertyImage{}}

  """
  def change_property_image(%Scope{} = scope, %PropertyImage{} = property_image, attrs \\ %{}) do
    true = property_image.user_id == scope.user.id

    PropertyImage.changeset(property_image, attrs, scope)
  end
end
