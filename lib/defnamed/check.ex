defmodule Defnamed.Check do
  require Defnamed.Exception, as: E

  @type t ::
          :ok
          | E.NotKeyword.t()
          | E.InvalidArgNames.t()
          | E.ArgNamesDuplication.t()
          | E.MissingRequiredArgs.t()

  defmacro ok do
    :ok
  end

  E.error_exception_list()
  |> Enum.each(fn {error, exception} ->
    defmacro unquote(error)(message) do
      exception = unquote(exception)

      quote do
        %unquote(exception){message: unquote(message)}
      end
    end
  end)

  @spec validate_kv!(term, MapSet.t(atom), list(atom), String.t()) :: :ok | no_return
  def validate_kv!(kv, %MapSet{} = valid_keys, required_keys, message)
      when is_list(required_keys) and is_binary(message) do
    kv
    |> validate_kv(valid_keys, required_keys, message)
    |> maybe_raise
  end

  @spec maybe_raise(t) :: :ok | no_return
  defp maybe_raise(ok() = result) do
    result
  end

  E.error_exception_list()
  |> Enum.each(fn {_, exception} ->
    defp maybe_raise(%unquote(exception){} = e) do
      raise(e)
    end
  end)

  @spec validate_kv(term, MapSet.t(atom), list(atom), String.t()) :: t
  defp validate_kv(kv, %MapSet{} = valid_keys, required_keys, message)
       when is_list(required_keys) and is_binary(message) do
    with ok() <- validate_kv_type(kv, message),
         ok() <- validate_kv_uniqueness(kv, message),
         ok() <- validate_kv_required_keys(kv, required_keys, message),
         ok() <- validate_kv_keys(kv, valid_keys, message) do
      ok()
    else
      error -> error
    end
  end

  @spec validate_kv_type(term, String.t()) :: :ok | E.NotKeyword.t()
  defp validate_kv_type(kv, message) when is_binary(message) do
    kv
    |> Keyword.keyword?()
    |> case do
      true -> ok()
      false -> not_keyword(message)
    end
  end

  @spec validate_kv_uniqueness(Keyword.t(), String.t()) :: :ok | E.ArgNamesDuplication.t()
  defp validate_kv_uniqueness(kv, message) when is_list(kv) and is_binary(message) do
    kv
    |> Enum.uniq_by(fn {k, _} -> k end)
    |> length
    |> case do
      l when l == length(kv) -> ok()
      _ -> arg_names_duplication(message)
    end
  end

  @spec validate_kv_required_keys(Keyword.t(), list(atom), String.t()) ::
          :ok | E.MissingRequiredArgs.t()
  defp validate_kv_required_keys(kv, required_keys, message)
       when is_list(kv) and is_list(required_keys) and is_binary(message) do
    actual_keys = kv |> Keyword.keys() |> MapSet.new()

    required_keys
    |> Enum.reduce_while(ok(), fn key, ok() ->
      actual_keys
      |> MapSet.member?(key)
      |> case do
        true -> ok()
        false -> missing_required_args(message)
      end
    end)
  end

  @spec validate_kv_keys(Keyword.t(), MapSet.t(atom), String.t()) :: :ok | E.InvalidArgNames.t()
  defp validate_kv_keys(kv, %MapSet{} = valid_keys, message)
       when is_list(kv) and is_binary(message) do
    kv
    |> Enum.reduce_while(ok(), fn {key, _}, ok() ->
      valid_keys
      |> MapSet.member?(key)
      |> case do
        true -> {:cont, ok()}
        false -> {:halt, invalid_arg_names(message)}
      end
    end)
  end
end
