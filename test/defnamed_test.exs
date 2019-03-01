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
end
