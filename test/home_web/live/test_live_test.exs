defmodule HomeWeb.TestLiveTest do
  use HomeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders the house finder for public visitors", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/test")

    assert has_element?(view, "#house-finder")
    assert has_element?(view, "#top-nav")
    assert has_element?(view, "#cinematic-scroll")
  end

  test "switches tabs and opens helper views", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/test-house")

    view
    |> element("#top-nav button[phx-value-tab='buy']")
    |> render_click()

    assert has_element?(view, "#top-nav button.top-tab-active[phx-value-tab='buy']")

    view
    |> element("#bottom-nav button[phx-value-view='help']")
    |> render_click()

    assert has_element?(view, "#help-view")

    view
    |> element("#help-back-button")
    |> render_click()

    assert has_element?(view, "#cinematic-scroll")
  end
end
