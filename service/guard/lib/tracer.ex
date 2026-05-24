defmodule Smith.Guard.Tracer do
  @moduledoc """
  OpenTelemetry spans for SMITH critical paths. Relies on `:opentelemetry` + `:opentelemetry_exporter`
  configuration (see `config/config.exs`).

  Call sites may `import Smith.Guard.Tracer` and use `span/2`, or call `with_span/3` / `with_span/4` directly.
  """

  require OpenTelemetry.Tracer

  @doc """
  Macro: runs `body` inside `OpenTelemetry.Tracer.with_span/3`.

  Example:

      require Smith.Guard.Tracer
      import Smith.Guard.Tracer

      span "rice.guard.heal", %{"component" => "watcher"} do
        do_heal()
      end
  """
  defmacro span(name, attrs \\ quote(do: %{}), do: block) do
    quote do
      require OpenTelemetry.Tracer

      OpenTelemetry.Tracer.with_span unquote(name), unquote(attrs) do
        unquote(block)
      end
    end
  end

  @doc "Runs `fun/0` inside an active span named `name`."
  @spec with_span(String.t(), (-> result)) :: result when result: var
  def with_span(name, fun) when is_binary(name) and is_function(fun, 0) do
    with_span(name, %{}, fun)
  end

  @doc "Runs `fun/0` inside an active span named `name` with attributes."
  @spec with_span(String.t(), OpenTelemetry.attributes_map(), (-> result)) :: result when result: var
  def with_span(name, attrs, fun)
      when is_binary(name) and is_map(attrs) and is_function(fun, 0) do
    OpenTelemetry.Tracer.with_span name, attrs do
      fun.()
    end
  end

  @doc "Sets a single attribute on the current span."
  def attribute(key, value) when is_binary(key) or is_atom(key) do
    OpenTelemetry.Tracer.set_attribute(key, value)
  end

  @doc "Merges multiple attributes on the current span."
  def attributes(map) when is_map(map) do
    OpenTelemetry.Tracer.set_attributes(map)
  end

  @doc "Records an error on the current span."
  def record_error(exception, attrs \\ []) do
    OpenTelemetry.Tracer.record_exception(exception, :undefined, attrs)
  end

  @doc "Marks span status (e.g. `{:error, \"reason\"}`)."
  def status(code, message \\ "") do
    OpenTelemetry.Tracer.set_status(code, message)
  end
end
