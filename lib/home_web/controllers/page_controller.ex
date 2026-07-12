defmodule HomeWeb.PageController do
  use HomeWeb, :controller
  import Ecto.Query
  
  alias Home.Repo
  alias Home.Properties.Property

  def home(conn, _params) do
    # Queries the DB directly and preloads the images to prevent crashing
    properties =
      Property
      |> order_by(desc: :id)
      |> preload(:property_images)
      |> Repo.all()

    render(conn, :home, properties: properties)
  end
end