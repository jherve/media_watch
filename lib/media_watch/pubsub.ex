defmodule MediaWatch.PubSub do
  alias Phoenix.PubSub
  alias __MODULE__, as: ThisPubSub

  def subscribe(topic), do: PubSub.subscribe(ThisPubSub, topic)
  def broadcast(topic, msg), do: PubSub.broadcast(ThisPubSub, topic, msg)
end
