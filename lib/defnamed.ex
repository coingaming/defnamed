defmodule Defnamed do
  @moduledoc """
  Compile-time named arguments for Elixir functions and macro
  """

  @keys [
    :args_struct_list_alias,
    :args_struct_module_name,
    :args_struct_ast,
    :caller_module_name,
    :original_name,
    :original_args_kv,
    :do_name
  ]
  @enforce_keys @keys
  defstruct @keys

  @doc """
  Helper that imports `defn/2`, `defpn/2`, `defmacron/2`, `defmacropn/2`

  ## Examples

  ```
  iex> use Defnamed
  Defnamed
  ```
  """
  defmacro __using__(_) do
    quote do
      import Defnamed, only: [defn: 2]
    end
  end

  @doc """
  Define function with named arguments through public macro interface

  ## Examples

  ```
  iex> defmodule Ledger do
  ...>   use Defnamed
  ...>   defn transact(balance: balance, amount: _)
  ...>          when is_integer(balance) and (balance < 0) do
  ...>     {:error, :account_is_blocked}
  ...>   end
  ...>   defn transact(balance: balance, amount: amount)
  ...>          when is_integer(balance) and is_integer(amount) and (balance >= amount) do
  ...>     {:ok, balance + amount}
  ...>   end
  ...>   defn transact(balance: balance, amount: amount)
  ...>          when is_integer(balance) and is_integer(amount) do
  ...>     {:error, :insufficient_funds}
  ...>   end
  ...>   defn transact(balance: balance, amount: amount) do
  ...>     raise("type error in transact(balance: \#{inspect(balance)}, amount: \#{inspect(amount)})")
  ...>   end
  ...> end
  iex> quote do
  ...>   require Ledger
  ...>   Ledger.transact(balance: 100, amount: -10)
  ...> end
  ...> |> Code.eval_quoted
  {{:ok, 90}, []}
  iex> quote do
  ...>   require Ledger
  ...>   Ledger.transact(amount: -10, balance: 100)
  ...> end
  ...> |> Code.eval_quoted
  {{:ok, 90}, []}
  iex> quote do
  ...>   require Ledger
  ...>   Ledger.transact(amount: -10, foo: 100)
  ...> end
  ...> |> Code.compile_quoted
  ** (ArgumentError) Elixir.DefnamedTest.Ledger.transact was called with unacceptable aruments [:foo], it only can accept [:amount, :balance]
  ```
  """
  defmacro defn(
             {:when, original_when_meta,
              [{original_name, original_meta, [original_args_kv]} | original_guards]},
             do: original_body
           ) do
    %Macro.Env{module: caller_module_name} = __CALLER__

    %__MODULE__{do_name: do_name, args_struct_ast: args_struct_ast} =
      params = generate_params(original_name, original_args_kv, caller_module_name)

    :ok = validate_original_args_kv(params, false)

    code =
      params
      |> maybe_define_named_interface(true)
      |> Enum.concat([
        quote do
          def unquote(
                {:when, original_when_meta,
                 [{do_name, original_meta, [args_struct_ast]} | original_guards]}
              ) do
            unquote(original_body)
          end
        end
      ])

    quote do
      (unquote_splicing(code))
    end
  end

  defmacro defn({original_name, original_meta, [original_args_kv]}, do: original_body) do
    %Macro.Env{module: caller_module_name} = __CALLER__

    %__MODULE__{do_name: do_name, args_struct_ast: args_struct_ast} =
      params = generate_params(original_name, original_args_kv, caller_module_name)

    :ok = validate_original_args_kv(params, false)

    code =
      params
      |> maybe_define_named_interface(true)
      |> Enum.concat([
        quote do
          def unquote({do_name, original_meta, [args_struct_ast]}) do
            unquote(original_body)
          end
        end
      ])

    quote do
      (unquote_splicing(code))
    end
  end

  def validate_original_args_kv(
        %__MODULE__{
          caller_module_name: caller_module_name,
          original_name: original_name,
          original_args_kv: original_args_kv,
          args_struct_module_name: args_struct_module_name
        },
        validate_keys?
      )
      when is_boolean(validate_keys?) do
    original_args_kv
    |> Keyword.keyword?()
    |> case do
      true when validate_keys? ->
        acceptable_arg_names =
          args_struct_module_name.__struct__()
          |> Map.from_struct()
          |> Map.keys()
          |> MapSet.new()

        original_args_kv
        |> Keyword.keys()
        |> Enum.filter(&(not MapSet.member?(acceptable_arg_names, &1)))
        |> case do
          [] ->
            :ok

          [_ | _] = unacceptable_args ->
            message =
              "#{caller_module_name}.#{original_name} was called with unacceptable aruments #{
                inspect(unacceptable_args)
              }, it only can accept #{acceptable_arg_names |> MapSet.to_list() |> inspect}"

            raise ArgumentError, message: message
        end

      true ->
        :ok

      false ->
        message =
          "#{caller_module_name}.#{original_name} can accept only keyword list as named argument, but got #{
            inspect(original_args_kv)
          }"

        raise ArgumentError, message: message
    end
  end

  defp generate_params(original_name, original_args_kv, caller_module_name) do
    args_struct_subname =
      original_name
      |> Atom.to_string()
      |> Macro.camelize()
      |> String.to_atom()

    args_struct_list_alias =
      caller_module_name
      |> Module.split()
      |> Enum.map(&String.to_atom/1)
      |> Enum.concat([args_struct_subname])

    args_struct_module_name =
      args_struct_list_alias
      |> Module.concat()

    args_struct_ast = {
      :%,
      [],
      [
        {:__aliases__, [alias: false], args_struct_list_alias},
        {:%{}, [], original_args_kv}
      ]
    }

    %__MODULE__{
      args_struct_list_alias: args_struct_list_alias,
      args_struct_module_name: args_struct_module_name,
      args_struct_ast: args_struct_ast,
      caller_module_name: caller_module_name,
      original_name: original_name,
      original_args_kv: original_args_kv,
      do_name: String.to_atom("do_#{original_name}")
    }
  end

  defp maybe_define_named_interface(
         %__MODULE__{
           original_name: original_name,
           caller_module_name: caller_module_name,
           args_struct_list_alias: args_struct_list_alias,
           args_struct_module_name: args_struct_module_name,
           original_args_kv: original_args_kv,
           do_name: do_name
         } = params,
         define_additional_macro_layer?
       )
       when is_boolean(define_additional_macro_layer?) do
    args_struct_module_name
    |> named_module_registered?
    |> case do
      true ->
        []

      false ->
        :ok = register_named_module(args_struct_module_name)

        additional_macro_layer =
          define_additional_macro_layer?
          |> case do
            true ->
              [
                quote do
                  defmacro unquote(original_name)(kv) do
                    :ok =
                      unquote(__MODULE__).validate_original_args_kv(
                        %unquote(__MODULE__){
                          unquote(params |> Macro.escape())
                          | original_args_kv: kv
                        },
                        true
                      )

                    do_name = unquote(do_name)
                    caller_module_name = unquote(caller_module_name)

                    struct_ast = {
                      :%,
                      [],
                      [
                        {:__aliases__, [alias: false], unquote(args_struct_list_alias)},
                        {:%{}, [], kv}
                      ]
                    }

                    quote do
                      unquote(caller_module_name).unquote(do_name)(unquote(struct_ast))
                    end
                  end
                end
              ]

            false ->
              []
          end

        [
          quote do
            defmodule unquote(args_struct_module_name) do
              defstruct unquote(original_args_kv |> Keyword.keys())
            end
          end
        ]
        |> Enum.concat(additional_macro_layer)
    end
  end

  defp register_named_module(module) do
    _ = Agent.start(fn -> MapSet.new() end, name: __MODULE__)
    :ok = Agent.update(__MODULE__, &MapSet.put(&1, module))
  end

  defp named_module_registered?(module) do
    if Process.whereis(__MODULE__) do
      Agent.get(__MODULE__, &MapSet.member?(&1, module))
    else
      false
    end
  end
end
