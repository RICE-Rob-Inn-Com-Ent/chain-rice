defmodule Service.Connection.Retry do
  @moduledoc """
  Retry wrapper for flaky HTTP calls: exponential backoff, jitter, capped attempts.

  Retries on `{:error, _}` and on `{:ok, %{status: s}}` when `s >= 500` (configurable).
  """

  # TODO:
  # [ ] implement retry with exponential backoff:
  #     retry(fun, max_attempts, base_delay_ms) → result
  #     max_attempts from RICE_CONNECTION_RETRIES env var
  #     base_delay from RICE_CONNECTION_BACKOFF_MS env var
  # [ ] implement circuit breaker:
  #     open after RICE_CONNECTION_CIRCUIT_THRESHOLD failures
  #     half-open after RICE_CONNECTION_CIRCUIT_TIMEOUT_S
  # [ ] implement retry telemetry:
  #     emits [:rice, :connection, :retry] event on each retry

  @type attempt_result :: {:ok, Finch.Response.t()} | {:error, term()}

  @doc """
  Executes `fun` until success or `max_attempts` is reached.

  Options:
  - `:max_attempts` — default 3
  - `:initial_backoff_ms` — default 100
  - `:max_backoff_ms` — default 10_000
  - `:jitter_ratio` — 0.0–1.0 fraction of backoff added randomly (default 0.25)
  - `:retry_on` — `(Finch.Response.t() | term() -> boolean)`; default retries 5xx responses
  """
  @spec with_retry((-> attempt_result()), keyword()) :: attempt_result()
  def with_retry(fun, opts \\ []) when is_function(fun, 0) do
    max_attempts = Keyword.get(opts, :max_attempts, 3)
    initial = Keyword.get(opts, :initial_backoff_ms, 100)
    max_backoff = Keyword.get(opts, :max_backoff_ms, 10_000)
    jitter = Keyword.get(opts, :jitter_ratio, 0.25)
    retry_on = Keyword.get(opts, :retry_on, &default_retry?/1)

    do_retry(fun, 1, max_attempts, initial, max_backoff, jitter, retry_on)
  end

  defp do_retry(fun, attempt, max_attempts, backoff, max_backoff, jitter, retry_on) do
    case fun.() do
      {:ok, %Finch.Response{} = resp} = ok ->
        if retry_on.(resp) and attempt < max_attempts do
          sleep(backoff, jitter)
          do_retry(fun, attempt + 1, max_attempts, next_backoff(backoff, max_backoff), max_backoff, jitter, retry_on)
        else
          ok
        end

      {:error, _} = err ->
        if attempt < max_attempts do
          sleep(backoff, jitter)
          do_retry(fun, attempt + 1, max_attempts, next_backoff(backoff, max_backoff), max_backoff, jitter, retry_on)
        else
          err
        end

      other ->
        other
    end
  end

  defp default_retry?(%Finch.Response{status: s}) when s >= 500 and s < 600, do: true
  defp default_retry?(%Finch.Response{}), do: false

  defp next_backoff(current, max_backoff) do
    min(trunc(current * 2), max_backoff)
  end

  defp sleep(ms, jitter_ratio) do
    jitter = if jitter_ratio > 0, do: :rand.uniform(trunc(ms * jitter_ratio)), else: 0
    Process.sleep(ms + jitter)
  end
end
