defmodule MissionControlWeb.FlightPathLive do
  use MissionControlWeb, :live_view

  @action_options [
    {"Action", ""},
    {"Launch", "launch"},
    {"Land", "land"}
  ]

  @planet_options [
    {"Planet", ""},
    {"Earth", "earth"},
    {"Moon", "moon"},
    {"Mars", "mars"}
  ]

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        mass: "",
        step: new_step(),
        flight_path: [],
        total_fuel: nil,
        insert_disabled: true,
        errors: [],
        action_options: @action_options,
        planet_options: @planet_options
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

    total_fuel =
      if mass && flight_path != [],
        # FlightPaths.calculate_fuel_for_flight_path(flight_path, mass),
        do: 1111,
        else: nil

    insert_disabled = param_action == "" or param_planet == ""

    IO.inspect(errors, label: "ERR")

    socket =
      assign(socket,
        mass: mass,
        step: step,
        total_fuel: total_fuel,
        insert_disabled: insert_disabled,
        errors: Enum.reverse(errors)
      )

    IO.inspect(socket.assigns, label: "VAL")

    {:noreply, socket}
  end

  def handle_event("add_to_flight_path", _params, socket) do
    %{step: step, flight_path: flight_path, mass: mass} = socket.assigns

    flight_path_step = to_flight_path_step(step)
    flight_path = flight_path ++ [flight_path_step]

    socket = assign(socket, flight_path: flight_path, total_fuel: 2222)

    {:noreply, socket}
  end

  def handle_event("remove_from_flight_path", %{"index" => index}, socket) do
    id = String.to_integer(index)

    flight_path =
      socket.assigns.flight_path
      |> Enum.reject(&(&1.id == id))

    socket = assign(socket, flight_path: flight_path)
    {:noreply, socket}
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

  defp parse_mass(mass_str) do
    case Float.parse(mass_str) do
      {mass, ""} when mass > 0 -> {:ok, mass}
      {_mass, ""} -> {:error, "Mass must be positive"}
      _ -> {:error, "Mass must be a number greater than 0"}
    end
  end

  def parse_step(action, planet) when action == "" or planet == "",
    do: {:error, "Both action and planet must be selected"}

  def parse_step(action, planet), do: {:ok, new_step(action, planet)}

  defp to_label(value) when is_atom(value) do
    value
    |> to_string()
    |> String.capitalize()
  end
end
