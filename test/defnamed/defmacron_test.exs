defmodule Defnamed.DefmacronTest do
  use ExUnit.Case

  [
    Defnamed.Support.DefmacronTest,
    Defnamed.Support.KernelDefmacronTest
  ]
  |> Enum.each(fn mod ->
    test "defmacron basic #{mod}" do
      require unquote(mod), as: DefmacronTest
      message = "from user Dan"
      input = 123
      result = DefmacronTest.invalid_type(message: message, input: input)
      assert %DefmacronTest{message: ^message, input: ^input, reason: :invalid_type} = result

      DefmacronTest.invalid_type(message: actual_message, input: actual_input) = result
      assert actual_message == message
      assert actual_input == input
    end

    test "defmacron optional #{mod}" do
      require unquote(mod), as: DefmacronTest
      message = "from user Dan"
      result = DefmacronTest.invalid_type(message: message)
      assert %DefmacronTest{message: ^message, reason: :invalid_type} = result

      DefmacronTest.invalid_type(message: actual_message, input: actual_input) = result
      assert actual_message == message
      assert actual_input == nil
    end

    test "defmacron optional arity 0 #{mod}" do
      require unquote(mod), as: DefmacronTest
      assert %DefmacronTest{message: nil, input: nil, reason: :invalid_type} = DefmacronTest.invalid_type()
    end

    test "defmacron compiletime error - not keyword #{mod}" do
      require unquote(mod), as: DefmacronTest

      assert_raise Defnamed.Exception.NotKeyword,
                   "#{unquote(mod)}.invalid_type argument should be keyword list which can contain only [:input, :message] keys without duplication, but argument is not a keyword: {:foo, [], #{
                     inspect(__MODULE__)
                   }}",
                   fn ->
                     quote do
                       foo = 123
                       require unquote(DefmacronTest)
                       DefmacronTest.invalid_type(foo)
                     end
                     |> Code.compile_quoted()
                   end
    end

    test "defn compiletime error - invalid arg name #{mod}" do
      require unquote(mod), as: DefmacronTest

      assert_raise Defnamed.Exception.InvalidArgNames,
                   "#{unquote(mod)}.invalid_type argument should be keyword list which can contain only [:input, :message] keys without duplication, but got invalid :foo key",
                   fn ->
                     quote do
                       message = "from user Dan"
                       input = 123
                       foo = "foo"
                       require unquote(DefmacronTest)
                       DefmacronTest.invalid_type(message: message, input: input, foo: foo)
                     end
                     |> Code.compile_quoted()
                   end
    end

    test "defn compiletime error - key duplication #{mod}" do
      require unquote(mod), as: DefmacronTest

      assert_raise Defnamed.Exception.ArgNamesDuplication,
                   "#{unquote(mod)}.invalid_type argument should be keyword list which can contain only [:input, :message] keys without duplication, but keys [:input] are duplicated",
                   fn ->
                     quote do
                       message = "from user Dan"
                       input = 123
                       require unquote(DefmacronTest)
                       DefmacronTest.invalid_type(message: message, input: input, input: input)
                     end
                     |> Code.compile_quoted()
                   end
    end
  end)
end
