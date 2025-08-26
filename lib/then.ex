defmodule Then do
  @moduledoc """
  Because sometimes you want to do something *after* a function, but don't want to clutter its code.

  Put `@then :callback` above a function and it will automatically call `callback(result)` after execution.
  Function result stays unchanged, callback is called for side effects.

  ## Basic Usage

      defmodule MyModule do
        use Then

        @then :log
        def add(a, b) do
          a + b
        end

        def log(result) do
          IO.puts("Got \#{result}")
        end
      end

      MyModule.add(2, 3)
      # Got 5
      # => 5

  ## Real-world Example

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
        def audit_creation({:ok, user}), do: Logger.info("User \#{user.email} created")
        def audit_creation({:error, reason}), do: Logger.warn("User wasn't created. \#{reason}")
      end

  ## Compatibility

  Works perfectly with other function attributes:

      defmodule MyService do
        use Then

        @doc "Gets age from params"
        @spec get_age(map()) :: integer()
        @then :log_term
        def get_age(params) do
          params[:age] || 0
        end

        defp log_term(term), do: IO.puts("[log-term] \#{term}")
      end

  `@spec`, `@doc`, `@deprecated` and other attributes work as expected.
  Callback functions can be private (`defp`).

  ## Limitations

  - One `@then` per function (compilation error if you try to use multiple)
  - Callback is not called if function raises an exception
  - For functions with multiple clauses, `@then` applies to all clauses

  ## Why Use This?

  It's simple and clear. Move log and other side-effects out of your beautiful logic.
  """

  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :then, persist: false)
      Module.register_attribute(__MODULE__, :functions_with_then, accumulate: true, persist: false)
      @on_definition Then
      @before_compile Then
    end
  end

  def __on_definition__(env, kind, function_name, args, _guards, _body) when kind in [:def, :defp] do
    then_callback = Module.get_attribute(env.module, :then)

    if then_callback do
      Module.delete_attribute(env.module, :then)
      arity = length(args)

      existing_functions = Module.get_attribute(env.module, :functions_with_then) || []
      function_key = {function_name, arity}

      if Enum.any?(existing_functions, fn {name, ar, _callback} -> {name, ar} == function_key end) do
        raise CompileError,
          file: env.file,
          line: env.line,
          description: "Multiple @then attributes for function #{function_name}/#{arity}. " <>
                      "Only one @then per function is allowed."
      end

      Module.put_attribute(env.module, :functions_with_then, {function_name, arity, then_callback})
    end
  end

  def __on_definition__(_env, _kind, _function_name, _args, _guards, _body) do
    :ok
  end

  defmacro __before_compile__(env) do
    functions_with_then = Module.get_attribute(env.module, :functions_with_then) || []

    wrapped_functions =
      functions_with_then
      |> Enum.map(fn {function_name, arity, callback_name} ->
        args = Macro.generate_arguments(arity, __MODULE__)

        quote do
          defoverridable [{unquote(function_name), unquote(arity)}]

          def unquote(function_name)(unquote_splicing(args)) do
            result = super(unquote_splicing(args))
            unquote(callback_name)(result)
            result
          end
        end
      end)

    quote do
      unquote_splicing(wrapped_functions)
    end
  end
end
