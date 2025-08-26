defmodule Then do
  @moduledoc """
  Simple way to set after-function callbacks.

  Put `@then :callback` or `@then {Module, :callback}` above a function and it will automatically
  call the callback after execution. Function result stays unchanged, callback is called for side effects.

  See the main documentation for detailed usage examples and API reference.
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

      validated_callback = validate_callback_format(then_callback, env)

      existing_functions = Module.get_attribute(env.module, :functions_with_then, [])

      if function_already_has_then?(existing_functions, function_name, arity) do
        raise CompileError,
          file: env.file,
          line: env.line,
          description: "Multiple @then attributes for function #{function_name}/#{arity}. " <>
                      "Only one @then per function is allowed."
      end

      Module.put_attribute(env.module, :functions_with_then, {function_name, arity, validated_callback})
    end
  end

  def __on_definition__(_env, _kind, _function_name, _args, _guards, _body) do
    :ok
  end

  defp function_already_has_then?(existing_functions, function_name, arity) do
    Enum.any?(existing_functions, fn {name, ar, _callback} ->
      {name, ar} == {function_name, arity}
    end)
  end

  defp validate_callback_format(callback, env) do
    case callback do
      atom when is_atom(atom) ->
        {:local, atom}

      {module, function} when is_atom(module) and is_atom(function) ->
        {:external, module, function}

      _ ->
        raise CompileError,
          file: env.file,
          line: env.line,
          description: "Invalid @then format. Expected :function_name or {Module, :function_name}, got: #{inspect(callback)}"
    end
  end

  defmacro __before_compile__(env) do
    wrapped_functions =
      env.module
      |> Module.get_attribute(:functions_with_then, [])
      |> Enum.map(&generate_wrapped_function/1)

    quote do
      unquote_splicing(wrapped_functions)
    end
  end

  defp generate_wrapped_function({function_name, arity, callback_spec}) do
    args = Macro.generate_arguments(arity, __MODULE__)
    callback_call = generate_callback_call(callback_spec)

    quote do
      defoverridable [{unquote(function_name), unquote(arity)}]

      def unquote(function_name)(unquote_splicing(args)) do
        result = super(unquote_splicing(args))
        unquote(callback_call)
        result
      end
    end
  end

  defp generate_callback_call({:local, function_name}) do
    quote do
      unquote(function_name)(result)
    end
  end

  defp generate_callback_call({:external, module, function_name}) do
    quote do
      unquote(module).unquote(function_name)(result)
    end
  end
end
