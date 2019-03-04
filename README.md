# Defnamed

<img src="priv/img/logo.jpg" width="300"/>

Named (or labeled) arguments is powerful abstraction which simplifies complexity of big arity function calls. If function arity is more than 1, usually it's not obvious which arguments to pass in which order (especially in dynamically typed languages like Elixir). And named arguments solve this issue very elegant way:

```elixir
# instead of standard call
authenticate(
  uri,
  user,
  password,
  allow_http?
)

# we will write
authenticate(
  uri: uri,
  user: user,
  password: password,
  allow_http?: allow_http?
)
```

A lot of languages support named arguments by default (Scala, Kotlin, Smalltalk, R and others), but Elixir does not. Named arguments can be naively "emulated" with passing to functions one keyword list, map or Elixir structure, but it gives no compile-time guarantees what this function will be called properly (because Elixir is dynamically typed language and argument of function can't be checked in compile time).

The main purpose of this package is to provide extended versions of standard `def/2`, `defp/2`, `defmacro/2`, `defmacrop/2` expressions with compile-time checked named arguments.

## Installation

The package can be installed by adding `defnamed` to list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:defnamed, "~> 0.1"}
  ]
end
```

## Example

Let's define function which converts number to string to show how package works:

```elixir
defmodule Num do
  use Defnamed

  defn to_string(
         number: number,
         decimals: _ \\ 2,
         view: _  \\ nil
       )
       when is_integer(number) do
    Integer.to_string(number)
  end

  defn to_string(
         number: number,
         decimals: decimals,
         view: view
       )
       when is_float(number) and
              is_integer(decimals) and
              decimals >= 0 and
              view in [nil, :compact, :scientific] do
    opts =
      case view do
        nil -> [{:decimals, decimals}]
        :compact -> [{:decimals, decimals}, view]
        :scientific -> [{view, decimals}]
      end

    :erlang.float_to_binary(number, opts)
  end

  defn to_string(number: nan) do
    raise ArgumentError, "term is not a number #{inspect(nan)}"
  end
end
```

And then we can call named functions through helper macro interface:

```elixir
iex> require Num
iex> number = 12.123
iex> Num.to_string(number: number, decimals: 2)
"12.12"
iex> number = 12
iex> Num.to_string(number: number)
"12"
iex> number = :foo
iex> Num.to_string(number: number)
** (ArgumentError) term is not a number :foo
```

If we will try to pass argument with incorrect name, compile-time error will be generated:

```elixir
iex> Num.to_string(number: number, decimals: 2, foo: 0)
** (Defnamed.Exception.InvalidArgNames) Elixir.Num.to_string argument should be keyword list which can contain only [:decimals, :number, :view] keys without duplication, and mandatory [:number] keys, but got invalid :foo key
```

Also it will be compile-time error if we duplicate argument:

```elixir
iex> Num.to_string(number: number, decimals: 2, decimals: 2)
** (Defnamed.Exception.ArgNamesDuplication) Elixir.Num.to_string argument should be keyword list which can contain only [:decimals, :number, :view] keys without duplication, and mandatory [:number] keys, but keys [:decimals] are duplicated
```

Or pass not keyword list

```elixir
iex> Num.to_string(number)
** (Defnamed.Exception.NotKeyword) Elixir.Num.to_string argument should be keyword list which can contain only [:decimals, :number, :view] keys without duplication, and mandatory [:number] keys, but argument is not a keyword: {:number, [line: 11], nil}
```

Or not pass required argument (argument is required if default value was not specified)

```elixir
iex> Num.to_string(decimals: 2)
** (Defnamed.Exception.MissingRequiredArgs) Elixir.Num.to_string argument should be keyword list which can contain only [:decimals, :number, :view] keys without duplication, and mandatory [:number] keys, but required :number key is not presented
```

Macro which define named expressions have the same functionality/syntax like standard kernel macro, but just have **n** postfix:

| Kernel | Defnamed |
|--------|----------|
| def | defn |
| defp | defpn |
| defmacro | defmacron |
| defmacrop | defmacropn |

All standard features like multiple clauses, guard expressions, underscore expression and pattern matching are supported.

## Design decisions

First version of `Defnamed` macros are just simple macro which generate code "just in place" without accumulating some state in module attributes. Design of library gives some minor limitations:

- To call named expression, module with definitions should be required in place where it is used
- Default arguments can be defined only in first named clause (like in normal kernel expressions)
- Default arguments in other named clauses (not first) will be ignored
- All desired argument names should be defined in first clause, new arguments can't be defined in other clauses (if these args are not needed in first clause - underscore can be used to ignore them)
- It's impossible to define clause with 0 arguments - if it's needed to do this, just use at least one named argument with underscore value
