defmodule Defnamed do
  @moduledoc """
  Compile-time named arguments for Elixir functions and macro
  """

  require Defnamed.Check, as: Check

  @compilertime_caller :caller

  @compilertime_params [
    @compilertime_caller
  ]

  @keys [
    :args_struct_list_alias,
    :args_struct_module_name,
    :args_struct_ast,
    :caller_module_name,
    :original_name,
    :original_args_kv,
    :do_name,
    @compilertime_caller
  ]
  @enforce_keys @keys
  defstruct @keys

  @type t :: %__MODULE__{
          args_struct_list_alias: list(atom),
          args_struct_module_name: module,
          args_struct_ast: tuple,
          caller_module_name: module,
          original_name: atom,
          original_args_kv: Keyword.t(),
          do_name: atom,
          caller: Macro.Env.t()
        }

  @doc """
  Helper that imports
  `defn/2`,
  `defn/3`,
  `defpn/2`,
  `defpn/3`,
  `defmacron/2`,
  `defmacron/3`,
  `defmacropn/2`,
  `defmacropn/3`

  ## Examples

  ```
  iex> use Defnamed
  Defnamed
  ```
  """
  defmacro __using__(_) do
    quote do
      import Defnamed,
        only: [
          defn: 2,
          defn: 3,
          defpn: 2,
          defpn: 3,
          defmacron: 2,
          defmacron: 3,
          defmacropn: 2,
          defmacropn: 3
        ]
    end
  end

  [
    {:def, [is_public?: true, is_macro?: false]},
    {:defp, [is_public?: false, is_macro?: false]},
    {:defmacro, [is_public?: true, is_macro?: true]},
    {:defmacrop, [is_public?: false, is_macro?: true]}
  ]
  |> Enum.each(fn {raw_expression, [is_public?: is_public?, is_macro?: is_macro?]} ->
    named_expression = "#{raw_expression}n" |> String.to_atom()

    low_level_expression =
      is_macro?
      |> case do
        true -> :defp
        false -> raw_expression
      end

    defmacro unquote(named_expression)(
               {:when, original_when_meta, [{original_name, original_meta, [original_args_kv]} | original_guards]},
               compiletime_params,
               do: original_body
             ) do
      low_level_expression = unquote(low_level_expression)
      %Macro.Env{module: caller_module_name} = __CALLER__

      %__MODULE__{
        do_name: do_name,
        args_struct_ast: args_struct_ast,
        caller: compiletime_caller
      } = params = generate_params(original_name, original_args_kv, caller_module_name, compiletime_params)

      :ok = validate_original_args_kv!(params, false)

      caller_code =
        compiletime_caller
        |> case do
          nil ->
            []

          _ ->
            [
              quote do
                unquote(compiletime_caller) = unquote(__CALLER__ |> Macro.escape())
              end
            ]
        end

      code =
        params
        |> maybe_define_named_interface(unquote(is_public?), unquote(is_macro?))
        |> Enum.concat([
          quote do
            unquote(low_level_expression)(
              unquote({:when, original_when_meta, [{do_name, original_meta, [args_struct_ast]} | original_guards]}),
              do: (unquote_splicing([caller_code, original_body]))
            )
          end
        ])

      quote do
        (unquote_splicing(code))
      end
    end

    defmacro unquote(named_expression)(
               {original_name, original_meta, [original_args_kv]},
               compiletime_params,
               do: original_body
             ) do
      low_level_expression = unquote(low_level_expression)
      %Macro.Env{module: caller_module_name} = __CALLER__

      %__MODULE__{
        do_name: do_name,
        args_struct_ast: args_struct_ast,
        caller: compiletime_caller
      } = params = generate_params(original_name, original_args_kv, caller_module_name, compiletime_params)

      :ok = validate_original_args_kv!(params, false)

      caller_code =
        compiletime_caller
        |> case do
          nil ->
            []

          _ ->
            [
              quote do
                unquote(compiletime_caller) = unquote(__CALLER__ |> Macro.escape())
              end
            ]
        end

      code =
        params
        |> maybe_define_named_interface(unquote(is_public?), unquote(is_macro?))
        |> Enum.concat([
          quote do
            unquote(low_level_expression)(
              unquote({do_name, original_meta, [args_struct_ast]}),
              do: (unquote_splicing([caller_code, original_body]))
            )
          end
        ])

      quote do
        (unquote_splicing(code))
      end
    end

    defmacro unquote(named_expression)(header, body) do
      named_expression = unquote(named_expression)

      quote do
        unquote(named_expression)(unquote(header), [], unquote(body))
      end
    end
  end)

  @spec validate_original_args_kv!(t, bool) :: :ok | no_return
  def validate_original_args_kv!(
        %__MODULE__{
          caller_module_name: caller_module_name,
          original_name: original_name,
          original_args_kv: original_args_kv,
          args_struct_module_name: args_struct_module_name
        },
        validate_keys?
      )
      when is_boolean(validate_keys?) do
    message = "#{caller_module_name}.#{original_name} argument"

    validate_keys?
    |> case do
      true ->
        acceptable_arg_names =
          args_struct_module_name.__struct__()
          |> Map.from_struct()
          |> Map.keys()
          |> MapSet.new()

        original_args_kv
        |> Check.validate_kv!(acceptable_arg_names, [], message)

      false ->
        original_args_kv
        |> Check.validate_kv!(message)
    end
  end

  defp generate_params(original_name, original_args_kv, caller_module_name, compiletime_params) do
    :ok = validate_compiletime_params!(compiletime_params)

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
      do_name: String.to_atom("do_#{original_name}"),
      caller: compiletime_params[@compilertime_caller]
    }
  end

  defp validate_compiletime_params!(compiletime_params) do
    message = "Defnamed compiletime parameters argument"

    compiletime_params
    |> Check.validate_kv!(MapSet.new(@compilertime_params), [], message)
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
         is_public?,
         is_macro?
       )
       when is_boolean(is_public?) do
    args_struct_module_name
    |> named_module_registered?
    |> case do
      true ->
        []

      false ->
        :ok = register_named_module(args_struct_module_name)

        additional_macro_layer_expression =
          is_public?
          |> case do
            true -> :defmacro
            false -> :defmacrop
          end

        zero_arity_shortcut =
          is_public?
          |> case do
            true ->
              quote do
                caller_module_name = unquote(caller_module_name)
                original_name = unquote(original_name)

                quote do
                  unquote(caller_module_name).unquote(original_name)([])
                end
              end

            false ->
              quote do
                original_name = unquote(original_name)

                quote do
                  unquote(original_name)([])
                end
              end
          end

        macro_layer_do_bloack =
          is_macro?
          |> case do
            true ->
              quote do
                {struct_ast, _} =
                  {
                    :%,
                    [],
                    [
                      {:__aliases__, [alias: false], unquote(args_struct_list_alias)},
                      {:%{}, [], Enum.map(kv, fn {k, v} -> {k, Macro.escape(v)} end)}
                    ]
                  }
                  |> Code.eval_quoted()

                unquote(do_name)(struct_ast)
              end

            false ->
              is_public?
              |> case do
                true ->
                  quote do
                    caller_module_name = unquote(caller_module_name)
                    do_name = unquote(do_name)

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

                false ->
                  quote do
                    do_name = unquote(do_name)

                    struct_ast = {
                      :%,
                      [],
                      [
                        {:__aliases__, [alias: false], unquote(args_struct_list_alias)},
                        {:%{}, [], kv}
                      ]
                    }

                    quote do
                      unquote(do_name)(unquote(struct_ast))
                    end
                  end
              end
          end

        additional_macro_layer = [
          quote do
            unquote(additional_macro_layer_expression)(
              unquote(original_name)(),
              do: unquote(zero_arity_shortcut)
            )

            unquote(additional_macro_layer_expression)(
              unquote(original_name)(kv),
              do:
                (
                  :ok =
                    %unquote(__MODULE__){
                      unquote(params |> Macro.escape())
                      | original_args_kv: kv
                    }
                    |> unquote(__MODULE__).validate_original_args_kv!(true)

                  unquote(macro_layer_do_bloack)
                )
            )
          end
        ]

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
