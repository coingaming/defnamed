defmodule Defnamed.Support.KernelDefnTest do
  use Defnamed, replace_kernel: true

  def concat(left: left \\ "", right: right \\ "", separator: separator \\ "") when is_binary(separator) do
    left <> separator <> right
  end

  def concat(separator: separator) do
    raise ArgumentError, "separator should be string, but got: #{inspect(separator)}"
  end

  def validate_homepage(user: user \\ "anon", uri: %URI{host: host})
      when is_binary(user) and is_binary(host) do
    String.contains?(host, user)
  end

  def validate_homepage(uri: _) do
    false
  end

  def generate_message(user: user, uri: uri) do
    validate_homepage(user: user, uri: uri)
    |> case do
      true -> concat(left: "homepage is good for you", separator: ", ", right: user)
      false -> concat(left: "homepage is invalid for you", separator: ", ", right: user)
    end
  end
end
