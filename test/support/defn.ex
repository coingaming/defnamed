defmodule Defnamed.Support.DefnTest do
  use Defnamed

  defn concat(left: left, right: right, separator: separator) when is_binary(separator) do
    "#{left}#{separator}#{right}"
  end

  defn concat(left: left, right: right, separator: nil) do
    "#{left}#{right}"
  end

  defn concat(separator: separator) do
    raise ArgumentError, "separator should be string or nil (unset), but got: #{inspect(separator)}"
  end

  defn validate_homepage(uri: %URI{host: host}, user: user) when is_binary(host) and is_binary(user) do
    String.contains?(host, user)
  end

  defn validate_homepage(uri: _) do
    false
  end
end
