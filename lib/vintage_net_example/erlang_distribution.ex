defmodule VintageNetExample.ErlangDistribution do
  use GenServer
  require Logger

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def init(_args) do
    _ = System.cmd("epmd", ["-daemon"])

    VintageNet.subscribe(["connection"])

    {:ok, :not_started}
  end

  def handle_info({VintageNet, ["connection"], _old, status, _meta}, :not_started)
      when status in [:lan, :internet] do
    {:ok, host} = get_host()
    node_name = to_node_name("nerves", host)
    _ = Logger.info("Starting Erlang distribution for #{node_name}")
    _ = :net_kernel.start(node_name)

    {:noreply, :started}
  end

  def handle_info(_other, state) do
    {:noreply, state}
  end

  defp get_host() do
    with {:ok, hostname} <- :inet.gethostname(),
         {:ok, {:hostent, full_name, _, _, _, _}} <- :inet.gethostbyname(hostname) do
      {:ok, full_name}
    end
  end

  defp to_node_name(name, host), do: :"#{name}@#{host}"
end
