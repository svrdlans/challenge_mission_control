defmodule MissionControl.FlightPaths do
  @moduledoc """
  Provides flight path validation functions and fuel calculation functions.
  """

  @planet_gravity %{
    earth: 9.807,
    moon: 1.62,
    mars: 3.711
  }

  @valid_actions ~w(launch land)a
  @valid_planets ~w(earth moon mars)a

  @action_input_options [
    {"Action", ""},
    {"Launch", "launch"},
    {"Land", "land"}
  ]

  @planet_input_options [
    {"Planet", ""},
    {"Earth", "earth"},
    {"Moon", "moon"},
    {"Mars", "mars"}
  ]

  @doc """
  Validates that a flight path is properly structured.

  ## Rules

    * Must have at least one valid step
    * Each action must be a tuple of `{:launch | :land, planet}`
    * Planet must be one of `:earth`, `:moon`, or `:mars`
  """
  def validate_flight_path([]), do: {:error, :empty_flight_path}

  def validate_flight_path(flight_path) when is_list(flight_path) do
    valid? =
      Enum.all?(flight_path, fn
        %{action: action, planet: planet}
        when action in @valid_actions and planet in @valid_planets ->
          true

        _ ->
          false
      end)

    if valid?, do: :ok, else: {:error, :invalid_flight_path}
  end

  @doc """
  Does final validation for equipment_mass.

  Returns:
    * `:ok` - when passed `equipment_mass` is integer greater than 0,
    * otherwise returns `{:error, :invalid_equipment_mass}`
  """
  def validate_equipment_mass(equipment_mass)
      when is_integer(equipment_mass) and equipment_mass > 0,
      do: :ok

  def validate_equipment_mass(_), do: {:error, :invalid_equipment_mass}

  @doc """
  Validates flight path and equipment_mass and calculates fuel required for
  flight path.

  Returns:
    * `{:ok, total_fuel}` - for valid inputs
    * otherwise returns `{:error, :invalid_flight_path}` or `{:error,
      :invalid_equipment_mass}`
  """
  def calculate_fuel_for_flight_path(flight_path, equipment_mass) do
    with :ok <- validate_flight_path(flight_path),
         :ok <- validate_equipment_mass(equipment_mass) do
      {:ok, do_calculate_fuel_for_flight_path(flight_path, equipment_mass)}
    end
  end

  # Does the actual fuel calculation for flight path after validation
  defp do_calculate_fuel_for_flight_path(flight_path, equipment_mass) do
    flight_path
    |> Enum.reverse()
    |> Enum.reduce(0, fn action, total_fuel ->
      fuel_for_action = calculate_fuel_for_step(action, equipment_mass + total_fuel)
      fuel_for_action + total_fuel
    end)
  end

  # Calculates fuel required by a flight step for passed mass
  defp calculate_fuel_for_step(%{action: action, planet: planet}, mass)
       when action in @valid_actions and planet in @valid_planets and is_integer(mass) and
              mass > 0 do
    action_formula = fetch_action_formula!(action)
    gravity = fetch_gravity!(planet)

    mass
    |> action_formula.(gravity)
    |> calculate_cumulative_fuel(gravity, action_formula)
  end

  # Cumulatively calculates required fuel
  defp calculate_cumulative_fuel(mass, gravity, formula, total_fuel \\ 0)

  defp calculate_cumulative_fuel(mass, gravity, formula, total_fuel)
       when mass > 0 and is_function(formula, 2) do
    mass
    |> formula.(gravity)
    |> calculate_cumulative_fuel(gravity, formula, mass + total_fuel)
  end

  defp calculate_cumulative_fuel(_mass, _gravity, _formula, total_fuel), do: total_fuel

  def action_input_options, do: @action_input_options

  def planet_input_options, do: @planet_input_options

  defp fetch_action_formula!(:launch), do: &launch_formula/2
  defp fetch_action_formula!(:land), do: &landing_formula/2

  defp fetch_gravity!(planet), do: Map.fetch!(@planet_gravity, planet)

  defp launch_formula(mass, gravity) do
    (mass * gravity * 0.042 - 33)
    |> floor()
  end

  defp landing_formula(mass, gravity) do
    (mass * gravity * 0.033 - 42)
    |> floor()
  end
end
