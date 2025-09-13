package concurrency

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"
)

// Task represents a unit of work with an identifier for tracing.
type Task struct {
	ID   int
	Work func(ctx context.Context) error
}

// Result represents the outcome of a processed Task.
type Result struct {
	TaskID int
	Err    error
	Took   time.Duration
}

// ProcessWithPool runs tasks with a bounded concurrency pool.
// - Concurrency is controlled via a semaphore (buffered channel)
// - Context propagation enables cooperative cancellation
// - Fail-fast behavior configurable via stopOnFirstError
func ProcessWithPool(
	ctx context.Context,
	tasks []Task,
	maxConcurrency int,
	stopOnFirstError bool,
) ([]Result, error) {
	if maxConcurrency <= 0 {
		return nil, errors.New("maxConcurrency must be > 0")
	}

	sem := make(chan struct{}, maxConcurrency)
	results := make([]Result, len(tasks))
	var wg sync.WaitGroup

	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	var firstErr error
	var mu sync.Mutex

	for i := range tasks {
		if ctx.Err() != nil {
			break
		}

		wg.Add(1)
		sem <- struct{}{}

		go func(idx int) {
			defer wg.Done()
			defer func() { <-sem }()

			start := time.Now()
			err := tasks[idx].Work(ctx)
			results[idx] = Result{TaskID: tasks[idx].ID, Err: err, Took: time.Since(start)}

			if err != nil && stopOnFirstError {
				mu.Lock()
				if firstErr == nil {
					firstErr = fmt.Errorf("task %d failed: %w", tasks[idx].ID, err)
					cancel()
				}
				mu.Unlock()
			}
		}(i)
	}

	wg.Wait()
	return results, firstErr
}

// Example backoff strategy for transient errors.
func ExponentialBackoff(attempt int, base time.Duration, max time.Duration) time.Duration {
	if attempt < 0 {
		attempt = 0
	}
	d := base << attempt
	if d > max {
		return max
	}
	return d
}