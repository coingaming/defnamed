defmodule DefnamedTest do
  use ExUnit.Case
  use Defnamed
  doctest Defnamed

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

  test "can't fallback when :fallback is not specified" do
    assert_raise ArgumentError,
                 "#{__MODULE__}.caller_test can accept only keyword list as named argument, but got 123",
                 fn ->
                   quote do
                     require unquote(__MODULE__)
                     unquote(__MODULE__).caller_test(123)
                   end
                   |> Code.compile_quoted()
                 end

    assert_raise ArgumentError,
                 "#{__MODULE__}.caller_test was called with unacceptable aruments [:foo], it only can accept [:hello]",
                 fn ->
                   quote do
                     require unquote(__MODULE__)
                     unquote(__MODULE__).caller_test(foo: 123)
                   end
                   |> Code.compile_quoted()
                 end
  end

  defn fallback_test(foo: foo, bar: bar), fallback: :custom_fallback do
    foo ++ bar
  end

  defmacro custom_fallback(some) do
    some
    |> Keyword.keyword?()
    |> case do
      true ->
        raise("unacceptable named args #{inspect(some)}")

      false ->
        quote do
          fallback_test(foo: unquote(some), bar: [4])
        end
    end
  end

  test "can fallback" do
    assert [1, 2, 3, 4] == fallback_test(foo: [1, 2], bar: [3, 4])
    assert [1, 2, 3, 4] == fallback_test([1, 2, 3])
  end
end
