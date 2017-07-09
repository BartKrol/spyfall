defmodule Spyfall do
  use Application

  def start(_type, _args) do
    # Spyfall.Supervisor.start_link
    Slack.Bot.start_link(Spyfall.Bot, [], "xoxb-209344795617-ekjEHZbbYYPe1KojyD2qfQR9")
    Spyfall.Game.start_link()
  end
end
