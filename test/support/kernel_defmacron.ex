defmodule Defnamed.Support.KernelDefmacronTest do
  use Defnamed, replace_kernel: true

  defexception [:message, :input, :reason]

  defmacro invalid_type(message: message \\ nil, input: input \\ nil) do
    quote do
      %unquote(__MODULE__){message: unquote(message), input: unquote(input), reason: :invalid_type}
    end
  end

  defmacro invalid_format(message: message, input: input) do
    quote do
      %unquote(__MODULE__){message: unquote(message), input: unquote(input), reason: :invalid_format}
    end
  end
end
