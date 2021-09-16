defmodule ChatWeb.RoomLive do
  use ChatWeb, :live_view
  require Logger
  alias ChatWeb.Endpoint
  alias ChatWeb.Presence

  @impl true
  def mount(%{"id" => room_id} = _params, _session, socket) do
    topic = "room:" <> room_id
    username = MnemonicSlugs.generate_slug(2)

    if connected?(socket) do
      Endpoint.subscribe(topic)
      Presence.track(self(), topic, username, %{})
    end

    {:ok,
     assign(socket,
       room_id: room_id,
       topic: topic,
       username: username,
       message: "",
       messages: [],
       temporary_assigns: [messages: []],
       user_list: []
     )}
  end

  @impl true
  def handle_event("submit_message", %{"chat" => %{"message" => message}}, socket) do
    Logger.info(message: message)

    Endpoint.broadcast(socket.assigns.topic, "new-message", %{
      uuid: UUID.uuid4(),
      username: socket.assigns.username,
      content: message
    })

    {:noreply, assign(socket, message: "")}
  end

  @impl true
  def handle_event("form_updated", %{"chat" => %{"message" => message}}, socket) do
    Logger.info(message: message)
    {:noreply, assign(socket, message: message)}
  end

  @impl true
  def handle_info(%{event: "new-message", payload: message}, socket) do
    Logger.info(payload: message)
    {:noreply, assign(socket, messages: [message])}
  end

  @impl true
  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        socket
      ) do
    Logger.info(joins: joins)

    join_messages =
      joins
      |> Map.keys()
      |> Enum.map(fn username ->
        %{
          type: :system,
          uuid: UUID.uuid4(),
          content: "#{username} joined the chat."
        }
      end)

    leave_messages =
      leaves
      |> Map.keys()
      |> Enum.map(fn username ->
        %{
          type: :system,
          uuid: UUID.uuid4(),
          content: "#{username} left the chat."
        }
      end)

    Logger.info(leaves: leaves)

    user_list = Presence.list(socket.assigns.topic) |> Map.keys()
    Logger.info(users: user_list)

    {:noreply, assign(socket, messages: join_messages ++ leave_messages, user_list: user_list)}
  end

  def display_message(%{type: :system, uuid: uuid, content: content}) do
    ~E"""
    <li id="<%= uuid %>"> <em><%= content %></em></li>
    """
  end

  def display_message(%{username: username, uuid: uuid, content: content}) do
    ~E"""
    <li id="<%= uuid %>"> <strong><%= username %>: </strong><%= content %> </li>
    """
  end
end
