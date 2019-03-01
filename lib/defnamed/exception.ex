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

  @doc """
  List of pairs {error, Exception}

  ## Examples

  ```
  iex> require #{__MODULE__}
  #{__MODULE__}
  iex> #{__MODULE__}.error_exception_list
  [
    not_keyword: #{__MODULE__}.NotKeyword,
    invalid_arg_names: #{__MODULE__}.InvalidArgNames,
    arg_names_duplication: #{__MODULE__}.ArgNamesDuplication,
    missing_required_args: #{__MODULE__}.MissingRequiredArgs
  ]
  ```
  """
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
