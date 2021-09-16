defmodule MediaWatch.PubSub do
  alias Phoenix.PubSub
  alias __MODULE__, as: ThisPubSub

  def subscribe(msg), do: PubSub.subscribe(ThisPubSub, msg)
  def broadcast(topic, msg), do: PubSub.broadcast(ThisPubSub, topic, msg)
end
