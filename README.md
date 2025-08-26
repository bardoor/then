# Then

[![Elixir CI](https://github.com/bardoor/then/actions/workflows/elixir.yml/badge.svg)](https://github.com/bardoor/then/actions/workflows/elixir.yml)
[![Hex.pm Version](https://img.shields.io/hexpm/v/then.svg)](https://hex.pm/packages/then)
[![Hex.pm Downloads](https://img.shields.io/hexpm/dt/then.svg)](https://hex.pm/packages/then)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/then)

Because sometimes you want to do something *after* a function, but don't want to clutter its code.

## Installation

```elixir
def deps do
  [{:then, "~> 1.0.0"}]
end
```

## How it works

Put `@then :callback` above a function and it will automatically call `callback(result)` after execution:

```elixir
defmodule MyModule do
  use Then

  @then :log
  def add(a, b) do
    a + b
  end

  def log(result) do
    IO.puts("Got #{result}")
  end
end

MyModule.add(2, 3)
# Got 5
# => 5
```

Function result stays unchanged, callback is called for side effects.

## Why you need this

For logging, metrics, notifications — all the stuff you don't want mixed with your main logic:

```elixir
defmodule UserService do
  use Then

  @then :audit_creation
  def new_user(params) do
    case params do
      %{email: email, name: name} -> {:ok, %User{name: name, email: email}}
      _ -> {:error, "Required fileds are missing"}
    end
  end

  # side effects separately
  def audit_creation({:ok, user}), do: Logger.info("User #{user.email} created")
  def audit_creation({:error, reason}), do: Logger.warn("User wasn't created. #{reason}")
end
```

## Limitations

- One `@then` per function (compilation error if you try to use multiple)
- Callback is not called if function raises an exception
- For functions with multiple clauses, `@then` applies to all clauses

## Compatibility

Works perfectly with other function attributes:

```elixir
defmodule MyModule do
  use Then

  @doc "Gets age from params"
  @spec get_age(map()) :: integer()
  @then :log_term
  def get_age(params) do
    params[:age] || 0
  end

  defp log_term(term), do: IO.puts("[log-term] #{term}")

end
```

`@spec`, `@doc`, `@deprecated` and other attributes work as expected. Callback functions can be private (`defp`).

## Why not just call the callback at the end of the function?

It's simple and clear. Move log and other side-effects out of your beautiful logic.
