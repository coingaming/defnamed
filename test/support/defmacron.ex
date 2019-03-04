defmodule Defnamed.Support.DefmacronTest do
  use Defnamed

  defexception [:message, :input, :reason]

  defmacron invalid_type(message: message \\ nil, input: input \\ nil) do
    quote do
      %unquote(__MODULE__){message: unquote(message), input: unquote(input), reason: :invalid_type}
    end
  end

  defmacron invalid_format(message: message, input: input) do
    quote do
      %unquote(__MODULE__){message: unquote(message), input: unquote(input), reason: :invalid_format}
    end
  end
end
