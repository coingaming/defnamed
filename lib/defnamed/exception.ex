defmodule Defnamed.Exception do
  @error_list [
    :not_keyword,
    :invalid_arg_names,
    :arg_names_duplication,
    :missing_required_args
  ]

  @exception_list @error_list
                  |> Stream.map(&(&1 |> Atom.to_string() |> Macro.camelize()))
                  |> Enum.map(&Module.concat(__MODULE__, &1))

  defmacro error_exception_list do
    @error_list
    |> Enum.zip(@exception_list)
  end

  @exception_list
  |> Enum.each(fn mod ->
    defmodule mod do
      @type t :: %__MODULE__{message: String.t()}
      defexception [:message]
    end
  end)
end
