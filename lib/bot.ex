defmodule Spyfall.Bot do
  use Slack

  def handle_connect(slack, state) do
    IO.puts "Connected as #{slack.me.name}"
    {:ok, state}
  end

  def handle_event(message = %{type: "message"}, slack, state) do
    IO.inspect message

    if Map.has_key?(message, :text) and String.starts_with?(message.text, "spyfall") do
      command = String.replace_prefix(message.text, "spyfall ", "")
      handle_spyfall_message(command, message, slack)
    end

    {:ok, state}
  end

  def handle_event(_, _, state), do: {:ok, state}

  def handle_info({:message, text, channel}, slack, state) do
    IO.puts "Sending your message, captain!"

    send_message(text, channel, slack)

    {:ok, state}
  end

  def handle_info(_, _, state), do: {:ok, state}

  defp handle_spyfall_message("start", message, slack) do
    game_id(message) |> Spyfall.Game.start
    send_thread("Send `spyfall join`, to join game :)", message.channel, message.ts, slack)
  end

  defp handle_spyfall_message("join", message, slack) do
    game_id(message) |> Spyfall.Game.add_player(message.user)
    send_thread("Player: @" <> get_player_name(message.user) <> " added", message.channel, message.thread_ts, slack)
  end

  defp handle_spyfall_message("play", message, slack) do
    { _, location, spy, players } = game_id(message) |> Spyfall.Game.play
    Enum.filter(players, fn(player) -> player !== spy end)
    |> Enum.each(fn(player) -> get_player_message(location) |> send_message("@" <> get_player_name(player), slack) end)
    get_spy_message() |> send_message("@" <> get_player_name(spy), slack)
    send_thread("Starting game", message.channel, message.thread_ts, slack)
  end

  defp handle_spyfall_message("accuse " <> player, message, slack) do
    result = Spyfall.Game.accuse(game_id(message), player)
    send_thread(result, message.channel, message.thread_ts, slack)
  end

  defp handle_spyfall_message("guess " <> location, message, slack) do
    result = Spyfall.Game.guess(game_id(message), location)
    send_thread(result, message.channel, message.thread_ts, slack)
  end

  defp handle_spyfall_message(_, _, _) do
    IO.puts "Wrong command"
  end

  defp send_thread(text, channel, ts, slack) do
    %{
      type: "message",
      text: text,
      channel: channel,
      thread_ts: ts
    }
      |> Poison.encode!()
      |> send_raw(slack)
  end

  defp game_id(%{ :thread_ts => thread_ts, :team => team }) do
    thread_ts <> "." <> team
  end

  defp game_id(%{ :ts => ts, :team => team }) do
    ts <> "." <> team
  end

  defp get_player_name(user_id) do
    %{ "user" => %{ "name" => name } } = Slack.Web.Users.info(user_id, %{token: System.get_env("SLACK_TOKEN")})
    name
  end

  defp get_player_message(location) do
    "You are all in " <> location
  end

  defp get_spy_message() do
    "You are a spy"
  end
end