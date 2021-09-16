defmodule ChatWeb.PageLive do
  use ChatWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, %{})}
  end

  @impl true
  def handle_event("random-room", _params, socket) do
    slug = "/" <> MnemonicSlugs.generate_slug(4)

    {:noreply, push_redirect(socket, to: slug)}
  end
end
