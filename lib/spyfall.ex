defmodule Spyfall do
  use Application

  def start(_type, _args) do
    # Spyfall.Supervisor.start_link
    Slack.Bot.start_link(Spyfall.Bot, [], System.get_env("SLACK_BOT_TOKEN"))
    Spyfall.Game.start_link()
  end
end
