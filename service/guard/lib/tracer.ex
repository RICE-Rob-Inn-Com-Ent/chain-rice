defmodule Service.Guard.Tracer do
  @moduledoc """
  Spans around supervision cycles (crash → restart → recover).

  Default implementation runs the callback without OTel. To enable tracing, add
  `require OpenTelemetry.Tracer` at the call site and use `OpenTelemetry.Tracer.with_span/3`,
  or extend this module with your OTLP pipeline.
  """

  # TODO:
  # [ ] implement OTel tracer for Elixir:
  #     OpenTelemetry.Tracer.start_span/2 for guard operations
  #     every supervision event gets a span
  # [ ] implement trace context propagation:
  #     extract trace context from NATS messages
  #     inject into Elixir process dictionary
  # [ ] implement distributed trace linking:
  #     links Go service spans to Elixir supervision spans

  @spec with_span(String.t(), map(), (-> term())) :: term()
  def with_span(_name, _attributes \\ %{}, fun) when is_function(fun, 0), do: fun.()
end
