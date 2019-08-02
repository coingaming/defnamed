defmodule Defnamed.Kernel do
  defmacro def(x, y) do
    quote location: :keep do
      defn(unquote(x), unquote(y))
    end
  end

  defmacro defp(x, y) do
    quote location: :keep do
      defpn(unquote(x), unquote(y))
    end
  end

  defmacro defmacro(x, y) do
    quote location: :keep do
      defmacron(unquote(x), unquote(y))
    end
  end

  defmacro defmacrop(x, y) do
    quote location: :keep do
      defmacropn(unquote(x), unquote(y))
    end
  end
end
