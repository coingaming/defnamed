defmodule Defnamed.DefmacronTest do
  use ExUnit.Case
  require Defnamed.Support.DefmacronTest, as: DefmacronTest

  test "defmacron basic" do
    message = "from user Dan"
    input = 123
    result = DefmacronTest.invalid_type(message: message, input: input)
    assert %DefmacronTest{message: ^message, input: ^input, reason: :invalid_type} = result

    DefmacronTest.invalid_type(message: actual_message, input: actual_input) = result
    assert actual_message == message
    assert actual_input == input
  end

  test "defmacron optional" do
    message = "from user Dan"
    result = DefmacronTest.invalid_type(message: message)
    assert %DefmacronTest{message: ^message, reason: :invalid_type} = result

    DefmacronTest.invalid_type(message: actual_message, input: actual_input) = result
    assert actual_message == message
    assert actual_input == nil
  end

  test "defmacron optional arity 0" do
    assert %DefmacronTest{message: nil, input: nil, reason: :invalid_type} = DefmacronTest.invalid_type()
  end

  test "defmacron compiletime error - not keyword" do
    assert_raise Defnamed.Exception.NotKeyword,
                 "Elixir.Defnamed.Support.DefmacronTest.invalid_type argument should be keyword list which can contain only [:input, :message] keys without duplication, but argument is not a keyword: {:foo, [], #{
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

  test "defn compiletime error - invalid arg name" do
    assert_raise Defnamed.Exception.InvalidArgNames,
                 "Elixir.Defnamed.Support.DefmacronTest.invalid_type argument should be keyword list which can contain only [:input, :message] keys without duplication, but got invalid :foo key",
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

  test "defn compiletime error - key duplication" do
    assert_raise Defnamed.Exception.ArgNamesDuplication,
                 "Elixir.Defnamed.Support.DefmacronTest.invalid_type argument should be keyword list which can contain only [:input, :message] keys without duplication, but keys [:input] are duplicated",
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
end
