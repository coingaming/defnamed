defmodule DefnamedTest do
  use ExUnit.Case
  use Defnamed
  doctest Defnamed

  defn basic_test(a: a, b: b) when is_binary(a) and is_binary(b), do: a <> " " <> b
  defn basic_test(a: a, b: b) when is_binary(a), do: a <> " " <> inspect(b)
  defn basic_test(a: a, b: b) when is_binary(b), do: inspect(a) <> " " <> b
  defn basic_test(a: a, b: b), do: inspect(a) <> " " <> inspect(b)

  test "basic success" do
    assert "hello world" == basic_test(a: "hello", b: "world")
    assert "1 world" == basic_test(a: 1, b: "world")
    assert "hello 1" == basic_test(a: "hello", b: 1)
    assert "1 2" == basic_test(a: 1, b: 2)
  end

  test "not keyword" do
    assert_raise Defnamed.Exception.NotKeyword,
                 "Elixir.DefnamedTest.basic_test argument should be keyword list which can contain only [:a, :b] keys without duplication, but argument is not a keyword: 1",
                 fn ->
                   quote do
                     require unquote(__MODULE__)
                     unquote(__MODULE__).basic_test(1)
                   end
                   |> Code.compile_quoted()
                 end
  end

  test "key duplication" do
    assert_raise Defnamed.Exception.ArgNamesDuplication,
                 "Elixir.DefnamedTest.basic_test argument should be keyword list which can contain only [:a, :b] keys without duplication, but keys [:b] are duplicated",
                 fn ->
                   quote do
                     require unquote(__MODULE__)
                     unquote(__MODULE__).basic_test(a: "hello", b: "world", b: "world")
                   end
                   |> Code.compile_quoted()
                 end
  end

  test "invalid key" do
    assert_raise Defnamed.Exception.InvalidArgNames,
                 "Elixir.DefnamedTest.basic_test argument should be keyword list which can contain only [:a, :b] keys without duplication, but got invalid :foo key",
                 fn ->
                   quote do
                     require unquote(__MODULE__)
                     unquote(__MODULE__).basic_test(a: "hello", b: "world", foo: 1)
                   end
                   |> Code.compile_quoted()
                 end
  end

  defn caller_test(hello: world) when is_binary(world), caller: caller do
    caller
  end

  defn caller_test(hello: _), caller: caller do
    caller
  end

  test "can access __CALLER__" do
    assert %Macro.Env{module: __MODULE__} = caller_test(hello: "world")
    assert %Macro.Env{module: __MODULE__} = caller_test(hello: 123)
    assert %Macro.Env{module: __MODULE__} = caller_test()
  end
end
