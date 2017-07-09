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
    game_id(message) |> Spyfall.Game.register_game
    send_thread("Send `spyfall join`, to join game :)", message.channel, message.ts, slack)
  end

  defp handle_spyfall_message("join", message, slack) do
    # IO.inspect Slack.Web.Users.info(message.user)
    game_id(message) |> Spyfall.Game.add_player(message.user)
    send_thread("Player: " <> message.user <> " added", message.channel, message.thread_ts, slack)
  end

  defp handle_spyfall_message("play", message, slack) do
    { _, location, spy } = game_id(message) |> Spyfall.Game.start
    send_thread("Starting game", message.channel, message.thread_ts, slack)
  end

  defp handle_spyfall_message("accuse " <> player, message, slack) do
    result = Spyfall.Game.accuse(game_id(message), player)
    send_thread(result, message.channel, message.thread_ts, slack)
  end

  defp handle_spyfall_message("guess " <> location, message, slack) do
    IO.puts location
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
end