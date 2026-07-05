defmodule Home.PropertiesTest do
  use Home.DataCase

  alias Home.Properties

  describe "properties" do
    alias Home.Properties.Property

    import Home.AccountsFixtures, only: [user_scope_fixture: 0]
    import Home.PropertiesFixtures

    @invalid_attrs %{
      status: nil,
      title: nil,
      location: nil,
      night_price: nil,
      day_price: nil,
      tier: nil,
      wifi: nil,
      tv: nil,
      music_system: nil,
      unavailable_until: nil
    }

    test "list_properties/1 returns all scoped properties" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      property = property_fixture(scope)
      other_property = property_fixture(other_scope)
      assert Properties.list_properties(scope) == [property]
      assert Properties.list_properties(other_scope) == [other_property]
    end

    test "get_property!/2 returns the property with given id" do
      scope = user_scope_fixture()
      property = property_fixture(scope)
      other_scope = user_scope_fixture()
      assert Properties.get_property!(scope, property.id) == property

      assert_raise Ecto.NoResultsError, fn ->
        Properties.get_property!(other_scope, property.id)
      end
    end

    test "create_property/2 with valid data creates a property" do
      valid_attrs = %{
        status: "some status",
        title: "some title",
        location: "some location",
        night_price: 42,
        day_price: 42,
        tier: "some tier",
        wifi: true,
        tv: true,
        music_system: true,
        unavailable_until: ~D[2026-06-30]
      }

      scope = user_scope_fixture()

      assert {:ok, %Property{} = property} = Properties.create_property(scope, valid_attrs)
      assert property.status == "some status"
      assert property.title == "some title"
      assert property.location == "some location"
      assert property.night_price == 42
      assert property.day_price == 42
      assert property.tier == "some tier"
      assert property.wifi == true
      assert property.tv == true
      assert property.music_system == true
      assert property.unavailable_until == ~D[2026-06-30]
      assert property.user_id == scope.user.id
    end

    test "create_property/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Properties.create_property(scope, @invalid_attrs)
    end

    test "update_property/3 with valid data updates the property" do
      scope = user_scope_fixture()
      property = property_fixture(scope)

      update_attrs = %{
        status: "some updated status",
        title: "some updated title",
        location: "some updated location",
        night_price: 43,
        day_price: 43,
        tier: "some updated tier",
        wifi: false,
        tv: false,
        music_system: false,
        unavailable_until: ~D[2026-07-01]
      }

      assert {:ok, %Property{} = property} =
               Properties.update_property(scope, property, update_attrs)

      assert property.status == "some updated status"
      assert property.title == "some updated title"
      assert property.location == "some updated location"
      assert property.night_price == 43
      assert property.day_price == 43
      assert property.tier == "some updated tier"
      assert property.wifi == false
      assert property.tv == false
      assert property.music_system == false
      assert property.unavailable_until == ~D[2026-07-01]
    end

    test "update_property/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      property = property_fixture(scope)

      assert_raise MatchError, fn ->
        Properties.update_property(other_scope, property, %{})
      end
    end

    test "update_property/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      property = property_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Properties.update_property(scope, property, @invalid_attrs)

      assert property == Properties.get_property!(scope, property.id)
    end

    test "delete_property/2 deletes the property" do
      scope = user_scope_fixture()
      property = property_fixture(scope)
      assert {:ok, %Property{}} = Properties.delete_property(scope, property)
      assert_raise Ecto.NoResultsError, fn -> Properties.get_property!(scope, property.id) end
    end

    test "delete_property/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      property = property_fixture(scope)
      assert_raise MatchError, fn -> Properties.delete_property(other_scope, property) end
    end

    test "change_property/2 returns a property changeset" do
      scope = user_scope_fixture()
      property = property_fixture(scope)
      assert %Ecto.Changeset{} = Properties.change_property(scope, property)
    end
  end

  describe "property_images" do
    alias Home.Properties.PropertyImage

    import Home.AccountsFixtures, only: [user_scope_fixture: 0]
    import Home.PropertiesFixtures

    @invalid_attrs %{image_url: nil}

    test "list_property_images/1 returns all scoped property_images" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      property_image = property_image_fixture(scope)
      other_property_image = property_image_fixture(other_scope)
      assert Properties.list_property_images(scope) == [property_image]
      assert Properties.list_property_images(other_scope) == [other_property_image]
    end

    test "get_property_image!/2 returns the property_image with given id" do
      scope = user_scope_fixture()
      property_image = property_image_fixture(scope)
      other_scope = user_scope_fixture()
      assert Properties.get_property_image!(scope, property_image.id) == property_image

      assert_raise Ecto.NoResultsError, fn ->
        Properties.get_property_image!(other_scope, property_image.id)
      end
    end

    test "create_property_image/2 with valid data creates a property_image" do
      valid_attrs = %{image_url: "some image_url"}
      scope = user_scope_fixture()

      assert {:ok, %PropertyImage{} = property_image} =
               Properties.create_property_image(scope, valid_attrs)

      assert property_image.image_url == "some image_url"
      assert property_image.user_id == scope.user.id
    end

    test "create_property_image/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Properties.create_property_image(scope, @invalid_attrs)
    end

    test "update_property_image/3 with valid data updates the property_image" do
      scope = user_scope_fixture()
      property_image = property_image_fixture(scope)
      update_attrs = %{image_url: "some updated image_url"}

      assert {:ok, %PropertyImage{} = property_image} =
               Properties.update_property_image(scope, property_image, update_attrs)

      assert property_image.image_url == "some updated image_url"
    end

    test "update_property_image/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      property_image = property_image_fixture(scope)

      assert_raise MatchError, fn ->
        Properties.update_property_image(other_scope, property_image, %{})
      end
    end

    test "update_property_image/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      property_image = property_image_fixture(scope)

      assert {:error, %Ecto.Changeset{}} =
               Properties.update_property_image(scope, property_image, @invalid_attrs)

      assert property_image == Properties.get_property_image!(scope, property_image.id)
    end

    test "delete_property_image/2 deletes the property_image" do
      scope = user_scope_fixture()
      property_image = property_image_fixture(scope)
      assert {:ok, %PropertyImage{}} = Properties.delete_property_image(scope, property_image)

      assert_raise Ecto.NoResultsError, fn ->
        Properties.get_property_image!(scope, property_image.id)
      end
    end

    test "delete_property_image/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      property_image = property_image_fixture(scope)

      assert_raise MatchError, fn ->
        Properties.delete_property_image(other_scope, property_image)
      end
    end

    test "change_property_image/2 returns a property_image changeset" do
      scope = user_scope_fixture()
      property_image = property_image_fixture(scope)
      assert %Ecto.Changeset{} = Properties.change_property_image(scope, property_image)
    end
  end
end
