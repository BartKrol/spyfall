#TODO - refactor to storage
defmodule Spyfall.Game do
  def start_link do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end

  def play(game_id) do
    game = Agent.get(__MODULE__, &Map.get(&1, game_id))
    if Enum.count(game.players) >= 1 do
      spy = Enum.random(game.players)
      location = Enum.random(locations())

      Agent.update(__MODULE__, &Map.put(&1, game_id, %{ game | :status => :starting, :spy => spy, :location => location }))
      { :ok, location, spy, game.players }
    else
      { :error, "Not enough players!" }
    end
  end

  def accuse(game_id, player) do
    game = Agent.get(__MODULE__, &Map.get(&1, game_id))

    Agent.update(__MODULE__, &Map.put(&1, game_id, %{ game | status: :finished }))

    if game.spy === player do
      "Players won!"
    else
      "Spy won! It was: " <> game.spy
    end
  end

  def guess(game_id, location) do
    game = Agent.get(__MODULE__, &Map.get(&1, game_id))

    Agent.update(__MODULE__, &Map.put(&1, game_id, %{ game | status: :finished }))

    if game.locaiton === location do
      "Spy won!"
    else
      "Players won! It was: " <> game.location
    end
  end

  def add_player(game_id, player) do
    Agent.update(__MODULE__, fn map -> 
      game = Map.get(map, game_id)
      Map.put(map, game_id, %{ game | :players => game.players ++ [player] })
    end)
  end

  def start(game_id) do
    game = %{ status: :playing, players: [], spy: nil, location: nil }
    Agent.update(__MODULE__, &Map.put(&1, game_id, game))
    game_id
  end

  def status(game_id) do
    Agent.get(__MODULE__, &Map.get(&1, game_id))
  end

  # TODO: Move to config file
  defp locations do 
    [
      "Airplane",
      "Bank",
      "Beach",
      "Cathedral",
      "Circus Tent",
      "Corporate Party",
      "Crusader Army",
      "Casino",
      "Day Spa",
      "Embassy",
      "Hospital",
      "Hotel",
      "Military Base",
      "Movie Studio",
      "Ocean Liner",
      "Passenger Train",
      "Pirate Ship",
      "Polar Station",
      "Police Station",
      "Restaurant",
      "School",
      "Service Station",
      "Space Station",
      "Submarine",
      "Supermarket",
      "Theater",
      "University",
      "World War II Squad"
    ]
  end
end
