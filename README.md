# Then

[![Elixir CI](https://github.com/bardoor/then/actions/workflows/elixir.yml/badge.svg)](https://github.com/bardoor/then/actions/workflows/elixir.yml)
[![Hex.pm Version](https://img.shields.io/hexpm/v/then.svg)](https://hex.pm/packages/then)
[![Hex.pm Downloads](https://img.shields.io/hexpm/dt/then.svg)](https://hex.pm/packages/then)
[![Documentation](https://img.shields.io/badge/docs-hexdocs-blue.svg)](https://hexdocs.pm/then)

Because sometimes you want to do something *after* a function, but don't want to clutter its code.

Put `@then :callback` or `@then {Module, :callback}` above a function and it will automatically 
call the callback after execution. Function result stays unchanged, callback is called for side effects.

## Installation

```elixir
def deps do
  [{:then, "~> 1.2.0"}]
end
```

## Basic Usage

### Simple Local Callbacks

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

### External Module Callbacks

You can also call functions from other modules:

```elixir
defmodule Calculator do
  use Then

  @then {IO, :puts}
  def multiply(a, b) do
    a * b
  end

  @then {MyAudit, :track_operation}
  def divide(a, b) when b != 0 do
    a / b
  end
end

defmodule MyAudit do
  def track_operation(result) do
    IO.puts("Operation completed with result: #{result}")
  end
end
```

**Aliased modules work too:**

```elixir
defmodule Calculator do
  alias IO, as: MyIO
  use Then

  @then {MyIO, :puts}
  def calculate(x) do
    x * 2
  end
end
```

### Real-world Example

```elixir
defmodule UserService do
  use Then

  @then :audit_creation
  def new_user(params) do
    case params do
      %{email: email, name: name} -> {:ok, %User{name: name, email: email}}
      _ -> {:error, "Required fields are missing"}
    end
  end

  # side effects separately
  def audit_creation({:ok, user}), do: IO.puts("✅ User #{user.email} created")
  def audit_creation({:error, reason}), do: IO.puts("❌ User creation failed: #{reason}")
end
```

### Compatibility

Works perfectly with other function attributes:

```elixir
defmodule MyService do
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

`@spec`, `@doc`, `@deprecated` and other attributes work as expected.
Callback functions can be private (`defp`).

### Limitations

- One `@then` per function (compilation error if you try to use multiple)
- Callback is not called if function raises an exception
- For functions with multiple clauses, `@then` applies to all clauses
- External module callbacks must be available at compile time

### Callback Formats

`@then` accepts two formats:
- `:function_name` - calls local function
- `{ModuleName, :function_name}` - calls function from external module

### Why Use This?

It's simple and clear. Move log and other side-effects out of your b