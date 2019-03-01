defmodule DefnamedTest do
  use ExUnit.Case
  use Defnamed
  doctest Defnamed

  defpn function_basic_test(a: a, b: b) when is_binary(a) and is_binary(b), do: a <> " " <> b
  defpn function_basic_test(a: a, b: b) when is_binary(a), do: a <> " " <> inspect(b)
  defpn function_basic_test(a: a, b: b) when is_binary(b), do: inspect(a) <> " " <> b
  defpn function_basic_test(a: a, b: b), do: inspect(a) <> " " <> inspect(b)

  test "function_basic_test success" do
    a = "hello"
    b = "world"
    assert "hello world" == function_basic_test(a: a, b: b)

    a = 1
    b = "world"
    assert "1 world" == function_basic_test(a: a, b: b)

    a = "hello"
    b = 1
    assert "hello 1" == function_basic_test(a: a, b: b)

    a = 1
    b = 2
    assert "1 2" == function_basic_test(a: a, b: b)

    a = 1
    assert "1 nil" == function_basic_test(a: a)

    assert "nil nil" == function_basic_test()
  end

  defpn function_caller_test(hello: world) when is_binary(world), caller: caller do
    caller
  end

  defpn function_caller_test(hello: _), caller: caller do
    caller
  end

  test "function_caller_test - can access __CALLER__" do
    hello = "world"
    assert %Macro.Env{module: __MODULE__} = function_caller_test(hello: hello)
    hello = 123
    assert %Macro.Env{module: __MODULE__} = function_caller_test(hello: hello)
    assert %Macro.Env{module: __MODULE__} = function_caller_test()
  end

  defmacron macro_basic_test(a: a, b: b) do
    quote do
      unquote(a) + unquote(b)
    end
  end

  test "macro_basic_test success" do
    a = 1
    b = 2
    assert 3 == macro_basic_test(a: a, b: b)
  end

  defmacropn macro_caller_test(hello: world) when is_binary(world), caller: caller do
    caller
    |> Macro.escape()
  end

  defmacropn macro_caller_test(hello: _), caller: caller do
    caller
    |> Macro.escape()
  end

  test "macro_caller_test - can access __CALLER__" do
    assert %Macro.Env{module: __MODULE__} = macro_caller_test(hello: "world")
    assert %Macro.Env{module: __MODULE__} = macro_caller_test(hello: 123)
    assert %Macro.Env{module: __MODULE__} = macro_caller_test()
  end

  defmacron number_pair(left: left, right: right) when is_number(left) and is_number(right) do
    quote do
      {unquote(left), unquote(right)}
    end
  end

  defmacron number_pair(left: left, right: right) do
    quote do
      raise ArgumentError, unquote("invalid left = #{inspect(left)} OR right = #{inspect(right)}")
    end
  end

  test "macro_guards" do
    assert {1, 2} == number_pair(left: 1, right: 2)

    assert_raise ArgumentError, "invalid left = 1 OR right = :foo", fn ->
      quote do
        require unquote(__MODULE__)
        unquote(__MODULE__).number_pair(left: 1, right: :foo)
      end
      |> Code.compile_quoted()
    end
  end
end
