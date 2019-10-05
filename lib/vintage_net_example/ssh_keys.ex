defmodule VintageNetExample.Keys do
  @moduledoc false

  @private_key_path "/root/ssh_host_key"

  @doc """
  Create the key callback spec for :ssh.daemon.
  """
  @spec key_cb() :: {module(), keyword()}
  def key_cb() do
    authorized_keys =
      Application.get_env(:vintage_net_example, :authorized_keys, [])
      |> Enum.join("\n")

    decoded_authorized_keys = :public_key.ssh_decode(authorized_keys, :auth_keys)
    {__MODULE__, [authorized_keys: decoded_authorized_keys]}
  end

  def host_key(:"ecdsa-sha2-nistp256", _options) do
    create_or_return_private_key()
  end

  def host_key(_key, _options) do
    {:error, :einval}
  end

  def is_auth_key(key, _user, options) do
    # Grab the decoded authorized keys from the options
    cb_opts = Keyword.get(options, :key_cb_private)
    keys = Keyword.get(cb_opts, :authorized_keys)

    # If any of them match, then we're good.
    Enum.any?(keys, fn {k, _info} -> k == key end)
  end

  defp create_or_return_private_key() do
    case File.read(@private_key_path) do
      {:ok, contents} ->
        {:ok, :public_key.der_decode(:ECPrivateKey, contents)}

      _error ->
        # Create an ECDSA key
        private_key = :public_key.generate_key({:namedCurve, {1, 2, 840, 10045, 3, 1, 7}})
        der_private_key = :public_key.der_encode(:ECPrivateKey, private_key)
        File.write!(@private_key_path, der_private_key)
        {:ok, private_key}
    end
  end
end
