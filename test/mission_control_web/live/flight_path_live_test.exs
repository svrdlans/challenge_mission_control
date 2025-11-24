defmodule MissionControlWeb.FlightPathLiveTest do
  use MissionControlWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "show the form for both disconnected and connected mounts", %{conn: conn} do
    # disconnected
    conn = get(conn, ~p"/flight_path")
    assert html_response(conn, 200) =~ "Flight Path Fuel Calculator"

    # connected
    {:ok, view, html} = live(conn)
    assert html =~ "Flight Path Fuel Calculator"
    assert has_element?(view, "#fuel-calculator-form")
  end

  test "when change is triggered with no inputs errors are shown", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/flight_path")
    refute has_element?(view, "#form-errors")

    html =
      view
      |> form("#fuel-calculator-form")
      |> render_change()

    assert html =~ "Mass is required"
    assert html =~ "Both action and planet must be selected"
  end

  test "when mass is entered as invalid string errors are shown", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/flight_path")
    refute has_element?(view, "#form-errors")

    html =
      view
      |> form("#fuel-calculator-form")
      |> render_change(%{"mass" => "rwer44"})

    assert html =~ "Mass must be a number greater than 0"
    assert html =~ "Both action and planet must be selected"
  end

  test "when only action or planet are selected, add button is disabled", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/flight_path")

    html =
      view
      |> form("#fuel-calculator-form")
      |> render_change(%{"action" => "launch", "planet" => ""})

    assert view
           |> has_element?("#add-to-flight-path[disabled]")

    assert html =~ "Mass is required"
    assert html =~ "Both action and planet must be selected"
  end

  test "when action and planet are selected, shows error for mass", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/flight_path")

    html =
      view
      |> form("#fuel-calculator-form")
      |> render_change(%{"action" => "launch", "planet" => "earth"})

    assert html =~ "Mass is required"
    refute html =~ "action and planet"
  end

  test "when action and planet are selected, add button is enabled", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/flight_path")

    html =
      view
      |> form("#fuel-calculator-form")
      |> render_change(%{"action" => "launch", "planet" => "earth"})

    assert html =~ "Mass is required"

    refute has_element?(view, "#add-to-flight-path[disabled]")
  end

  test "when action and planet are selected, click on add button adds step", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/flight_path")

    view
    |> form("#fuel-calculator-form")
    |> render_change(%{"action" => "launch", "planet" => "earth"})

    view
    |> element("#add-to-flight-path")
    |> render_click()

    # if remove button is shown, step is there
    assert has_element?(view, "button[id^=remove-from-flight-path-]")
  end

  test "when mass, action and planet are selected, adding step calculates fuel", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/flight_path")

    view
    |> form("#fuel-calculator-form", mass: 28801)
    |> render_change(%{"action" => "launch", "planet" => "earth"})

    view
    |> element("#add-to-flight-path")
    |> render_click()

    assert has_element?(view, "#total-fuel")
  end

  test "when step is added and removed, no fuel is shown", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/flight_path")

    view
    |> form("#fuel-calculator-form", mass: 28801)
    |> render_change(%{"action" => "launch", "planet" => "earth"})

    view
    |> element("#add-to-flight-path")
    |> render_click()

    assert has_element?(view, "#total-fuel")

    view
    |> element("button[id^=remove-from-flight-path-]")
    |> render_click()

    refute has_element?(view, "#total-fuel")
  end

  test "when mass and steps for Apollo 11 are added, shows total fuel", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/flight_path")

    view
    |> form("#fuel-calculator-form", mass: 28801)
    |> render_change(%{"action" => "launch", "planet" => "earth"})

    view
    |> element("#add-to-flight-path")
    |> render_click()

    view
    |> form("#fuel-calculator-form", mass: 28801)
    |> render_change(%{"action" => "land", "planet" => "moon"})

    view
    |> element("#add-to-flight-path")
    |> render_click()

    view
    |> form("#fuel-calculator-form", mass: 28801)
    |> render_change(%{"action" => "launch", "planet" => "moon"})

    view
    |> element("#add-to-flight-path")
    |> render_click()

    view
    |> form("#fuel-calculator-form", mass: 28801)
    |> render_change(%{"action" => "land", "planet" => "earth"})

    html =
      view
      |> element("#add-to-flight-path")
      |> render_click()

    assert has_element?(view, "#total-fuel")

    assert html =~ "51898"
  end
end
