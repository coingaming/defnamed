# Defnamed

<img src="priv/img/logo.jpg" width="300"/>

Named (or labeled) arguments is powerful abstraction which simplifies complexity of big arity function calls. If function arity is more than 1, usually it's not obvious which arguments to pass in which order (especially in dynamically typed languages like Elixir). And named arguments solve this issue very elegant way:

```elixir
# instead of standard call
authenticate(
  ip_address,
  user,
  password,
  allow_http?
)

# we will write
authenticate(
  ip_address: ip_address,
  user: user,
  password: password,
  allow_http?: allow_http?
)
```

A lot of languages support named arguments natively (Scala, Kotlin, Smalltalk, R and others), but Elixir does not. Named arguments can be naively "emulated" with passing to functions one keyword list, map or Elixir structure, but it gives no compile-time guarantees what this function will be called properly (because Elixir is dynamically typed language and argument of function can't be checked in compile time).

The main purpose of this package is to provide extended versions of standard `def/2`, `defp/2`, `defmacro/2`, `defmacrop/2` expressions with compile-time checked named arguments.

## Installation

The package can be installed by adding `defnamed` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:defnamed, "~> 0.1.0"}
  ]
end
```

## Example

*... to be continued ...*
