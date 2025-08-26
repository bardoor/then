defmodule ThenTest do
  use ExUnit.Case
  doctest Then

  defmodule TestModule do
    use Then

    @then :log_result
    def add(a, b) do
      a + b
    end

    @then :log_with_prefix
    def multiply(a, b) do
      a * b
    end

    def divide(a, b) do
      a / b
    end

    @then :handle_atom
    def return_atom do
      :success
    end

    @then :handle_error
    def may_fail(should_fail) do
      if should_fail do
        raise "Something went wrong"
      else
        :ok
      end
    end

    def log_result(result) do
      send(self(), {:logged, result})
    end

    def log_with_prefix(result) do
      send(self(), {:logged_with_prefix, "Result: #{result}"})
    end

    def handle_atom(:success) do
      send(self(), {:atom_handled, :success})
    end

    def handle_error(:ok) do
      send(self(), {:error_handled, :no_error})
    end
  end

  describe "@then functionality" do
    test "calls after function with result" do
      result = TestModule.add(2, 3)

      assert result == 5
      assert_received {:logged, 5}
    end

    test "calls correct after function for different functions" do
      result1 = TestModule.add(2, 3)
      result2 = TestModule.multiply(4, 5)

      assert result1 == 5
      assert result2 == 20
      assert_received {:logged, 5}
      assert_received {:logged_with_prefix, "Result: 20"}
    end

    test "functions without @after work normally" do
      result = TestModule.divide(10, 2)

      assert result == 5.0
      refute_received _any_message
    end

    test "handles different return types" do
      result = TestModule.return_atom()

      assert result == :success
      assert_received {:atom_handled, :success}
    end

    test "after callback is called even when function raises" do
      assert_raise RuntimeError, "Something went wrong", fn ->
        TestModule.may_fail(true)
      end

      refute_received _any_message
    end

    test "after callback is called when function succeeds" do
      result = TestModule.may_fail(false)

      assert result == :ok
      assert_received {:error_handled, :no_error}
    end
  end

  defmodule MultipleAftersModule do
    use Then

    @then :first_callback
    @then :second_callback
    def test_function do
      :result
    end

    def first_callback(result) do
      send(self(), {:first, result})
    end

    def second_callback(result) do
      send(self(), {:second, result})
    end
  end

  describe "multiple @then attributes" do
    test "only the last @then is used" do
      result = MultipleAftersModule.test_function()

      assert result == :result
      refute_received {:first, :result}
      assert_received {:second, :result}
    end
  end

  defmodule NoAfterModule do
    use Then

    def normal_function do
      :normal_result
    end
  end

  describe "modules without @then" do
    test "work normally" do
      result = NoAfterModule.normal_function()

      assert result == :normal_result
      refute_received _any_message
    end
  end

  defmodule PrivateFunctionModule do
    use Then

    def call_private do
      private_with_then(42)
    end

    @then :log_private
    defp private_with_then(value) do
      value * 2
    end

    def log_private(result) do
      send(self(), {:private_logged, result})
    end
  end

  describe "private functions with @then" do
    test "work with defp" do
      result = PrivateFunctionModule.call_private()

      assert result == 84
      assert_received {:private_logged, 84}
    end
  end

  defmodule MultiClauseModule do
    use Then

    @then :log_pattern_match
    def process_data(%{type: "user", name: name}) do
      {:ok, "User: #{name}"}
    end

    def process_data(%{type: "admin", name: name}) do
      {:ok, "Admin: #{name}"}
    end

    def process_data(_) do
      {:error, "unknown type"}
    end

    def log_pattern_match(result) do
      send(self(), {:pattern_logged, result})
    end
  end

  describe "functions with multiple clauses" do
    test "applies @then to all clauses of the function" do
      result1 = MultiClauseModule.process_data(%{type: "user", name: "John"})
      assert result1 == {:ok, "User: John"}
      assert_received {:pattern_logged, {:ok, "User: John"}}

      result2 = MultiClauseModule.process_data(%{type: "admin", name: "Jane"})
      assert result2 == {:ok, "Admin: Jane"}
      assert_received {:pattern_logged, {:ok, "Admin: Jane"}}

      result3 = MultiClauseModule.process_data(%{invalid: "data"})
      assert result3 == {:error, "unknown type"}
      assert_received {:pattern_logged, {:error, "unknown type"}}
    end
  end

  describe "multiple @then attributes for the same function" do
    test "raises compilation error" do
      code = quote do
        defmodule MultipleThensModule do
          use Then

          @then :log_first
          def calculate(:double, x) do
            x * 2
          end

          @then :log_second
          def calculate(:triple, x) do
            x * 3
          end
        end
      end

      assert_raise CompileError, ~r/Multiple @then attributes for function calculate\/2/, fn ->
        Code.compile_quoted(code)
      end
    end
  end

  defmodule AttributesModule do
    use Then

    @doc "Adds two numbers together"
    @spec add(integer(), integer()) :: integer()
    @then :log_addition
    def add(a, b) do
      a + b
    end

    @doc false
    @then :log_internal
    def internal_function(x) do
      x + 1
    end

    def log_addition(result) do
      send(self(), {:addition_logged, result})
    end

    def log_internal(result) do
      send(self(), {:internal_logged, result})
    end
  end

  describe "function attributes compatibility" do
    test "works with @spec and @doc" do
      result1 = AttributesModule.add(5, 3)
      assert result1 == 8
      assert_received {:addition_logged, 8}

      result2 = AttributesModule.internal_function(10)
      assert result2 == 11
      assert_received {:internal_logged, 11}
    end

    test "spec validation still works" do
      assert is_integer(AttributesModule.add(1, 2))
      assert is_integer(AttributesModule.internal_function(5))
    end
  end

  defmodule PrivateCallbackModule do
    use Then

    @then :private_logger
    def public_function(x) do
      x * 10
    end

    defp private_logger(result) do
      send(self(), {:private_callback_called, result})
    end
  end

  describe "private callback functions" do
    test "works with private callback functions" do
      result = PrivateCallbackModule.public_function(5)

      assert result == 50
      assert_received {:private_callback_called, 50}
    end
  end
end
