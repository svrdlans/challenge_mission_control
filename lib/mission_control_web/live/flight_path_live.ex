defmodule MissionControlWeb.FlightPathLive do
  use MissionControlWeb, :live_view

  alias MissionControl.FlightPaths

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        mass: "",
        step: new_step(),
        flight_path: [],
        total_fuel: nil,
        insert_disabled: true,
        errors: [],
        action_options: FlightPaths.action_input_options(),
        planet_options: FlightPaths.planet_input_options()
      )

    {:ok, socket}
  end

  def handle_event("validate", params, socket) do
    param_mass = params["mass"] || ""
    param_action = params["action"] || ""
    param_planet = params["planet"] || ""
    flight_path = socket.assigns.flight_path
    errors = []

    {mass, errors} =
      case parse_mass(param_mass) do
        {:ok, mass} -> {mass, errors}
        {:error, error} -> {nil, [error | errors]}
      end

    {step, errors} =
      case parse_step(param_action, param_planet) do
        {:ok, step} -> {step, errors}
        {:error, error} -> {new_step(param_action, param_planet), [error | errors]}
      end

    {total_fuel, errors} =
      if mass && flight_path != [] do
        case FlightPaths.calculate_fuel_for_flight_path(flight_path, mass) do
          {:ok, total_fuel} -> {total_fuel, errors}
          {:error, error} -> {nil, [parse_error(error) | errors]}
        end
      else
        {nil, errors}
      end

    insert_disabled = param_action == "" or param_planet == ""

    socket =
      assign(socket,
        mass: mass,
        step: step,
        total_fuel: total_fuel,
        insert_disabled: insert_disabled,
        errors: Enum.reverse(errors)
      )

    {:noreply, socket}
  end

  def handle_event("add_to_flight_path", _params, socket) do
    %{step: step, flight_path: flight_path, mass: mass} = socket.assigns

    flight_path_step = to_flight_path_step(step)
    flight_path = flight_path ++ [flight_path_step]
    total_fuel = recalculate_total_fuel(flight_path, mass)

    socket = assign(socket, flight_path: flight_path, total_fuel: total_fuel)

    {:noreply, socket}
  end

  def handle_event("remove_from_flight_path", %{"index" => index}, socket) do
    id = String.to_integer(index)
    %{flight_path: flight_path, mass: mass} = socket.assigns

    flight_path =
      flight_path
      |> Enum.reject(&(&1.id == id))

    total_fuel = recalculate_total_fuel(flight_path, mass)

    socket = assign(socket, flight_path: flight_path, total_fuel: total_fuel)
    {:noreply, socket}
  end

  defp recalculate_total_fuel(flight_path, mass) do
    with {:ok, mass} <- parse_mass(mass),
         {:ok, total_fuel} <- FlightPaths.calculate_fuel_for_flight_path(flight_path, mass) do
      total_fuel
    else
      _ -> nil
    end
  end

  defp to_flight_path_step(%{action: action, planet: planet}) do
    %{
      id: System.unique_integer([:monotonic]),
      action: String.to_atom(action),
      planet: String.to_atom(planet)
    }
  end

  defp new_step, do: new_step("", "")
  defp new_step(action, planet), do: %{action: action, planet: planet}

  defp parse_mass(""), do: {:error, "Mass is required"}

  defp parse_mass(mass_str) when is_binary(mass_str) do
    case Integer.parse(mass_str) do
      {mass, ""} when mass > 0 -> {:ok, mass}
      {_mass, ""} -> {:error, "Mass must be positive"}
      _ -> {:error, "Mass must be a number greater than 0"}
    end
  end

  defp parse_mass(mass) when is_integer(mass) and mass > 0,
    do: {:ok, mass}

  defp parse_mass(_), do: {:error, "Mass must be a number greater than 0"}

  def parse_step(action, planet) when action == "" or planet == "",
    do: {:error, "Both action and planet must be selected"}

  def parse_step(action, planet), do: {:ok, new_step(action, planet)}

  def parse_error(:invalid_equipment_mass), do: "Mass must be a number greater than 0"
  def parse_error(:empty_flight_path), do: "Flight path must have at least one step"
  def parse_error(:invalid_flight_path), do: "Flight path contains unexpected values"
  def parse_error(other) when is_binary(other), do: other

  defp to_label(value) when is_atom(value) do
    value
    |> to_string()
    |> String.capitalize()
  end
end
