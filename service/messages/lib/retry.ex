defmodule Smith.Messages.Retry do
  @moduledoc """
  Retries a thunk with exponential backoff and optional jitter — for flaky mesh / auto-repair paths.

  Default: retry `{:error, _}` and `5xx` `Finch.Response` bodies.
  """

  @doc """
  Executes `fun` (arity 0) until it returns a non-retryable result or `max_attempts` is exhausted.

  Options:
  - `:max_attempts` — default `3`
  - `:initial_backoff_ms` — default `100`
  - `:max_backoff_ms` — default `10_000`
  - `:jitter_ratio` — extra random delay as a fraction of the base delay (default `0.25`)
  - `:retry_on?` — `(any() -> boolean)`; overrides built-in predicate when set
  """
  @spec with_retry((-> any()), keyword()) :: any()
  def with_retry(fun, opts \\ []) when is_function(fun, 0) do
    max_attempts = Keyword.get(opts, :max_attempts, 3)
    initial = Keyword.get(opts, :initial_backoff_ms, 100)
    max_backoff = Keyword.get(opts, :max_backoff_ms, 10_000)
    jitter = Keyword.get(opts, :jitter_ratio, 0.25)
    retry_on? = Keyword.get(opts, :retry_on?, &default_retry?/1)

    do_retry(fun, 1, max_attempts, initial, max_backoff, jitter, retry_on?)
  end

  defp do_retry(fun, attempt, max_attempts, backoff, max_backoff, jitter, retry_on?) do
    result = fun.()

    if retry_on?.(result) and attempt < max_attempts do
      sleep(backoff, jitter)
      do_retry(fun, attempt + 1, max_attempts, next_backoff(backoff, max_backoff), max_backoff, jitter, retry_on?)
    else
      result
    end
  end

  defp default_retry?({:error, _}), do: true
  defp default_retry?({:ok, %Finch.Response{status: s}}) when s >= 500 and s < 600, do: true
  defp default_retry?(_), do: false

  defp next_backoff(current, max_backoff) do
    min(trunc(current * 2), max_backoff)
  end

  defp sleep(ms, jitter_ratio) do
    jitter = if jitter_ratio > 0, do: :rand.uniform(max(1, trunc(ms * jitter_ratio))), else: 0
    Process.sleep(ms + jitter)
  end
end
