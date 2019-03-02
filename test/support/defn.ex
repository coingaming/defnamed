defmodule Defnamed.Support.DefnTest do
  use Defnamed

  defn concat(left: left \\ "", right: right \\ "", separator: separator \\ "") when is_binary(separator) do
    left <> separator <> right
  end

  defn concat(separator: separator) do
    raise ArgumentError, "separator should be string, but got: #{inspect(separator)}"
  end

  defn validate_homepage(user: user \\ "anon", uri: %URI{host: host})
       when is_binary(user) and is_binary(host) do
    String.contains?(host, user)
  end

  defn validate_homepage(uri: _) do
    false
  end
end
