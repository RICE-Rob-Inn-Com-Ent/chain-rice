package queue

import (
	"time"

	"go.temporal.io/sdk/temporal"
	"go.temporal.io/sdk/workflow"
)

// WorkflowContext wraps [workflow.Context] with SMITH helpers. Workflow code must stay deterministic:
// use [WorkflowContext.Now] (backed by [workflow.Now]), not [time.Now]; avoid package-level randomness.
//
// Trace and identity from the SMITH kit propagator are available via [WorkflowContext.SmithHeader]
// ([SmithHeaderFromWorkflow]) on the underlying context.
type WorkflowContext struct {
	Ctx workflow.Context
}

// NewWorkflowContext builds a SMITH workflow wrapper.
func NewWorkflowContext(ctx workflow.Context) WorkflowContext {
	return WorkflowContext{Ctx: ctx}
}

// Now returns deterministic workflow time ([workflow.Now]).
func (w WorkflowContext) Now() time.Time {
	return workflow.Now(w.Ctx)
}

// SmithHeader returns propagated kit trace / user metadata, if any.
func (w WorkflowContext) SmithHeader() *SmithWorkflowHeader {
	return SmithHeaderFromWorkflow(w.Ctx)
}

// WithActivityOptions returns a copy of this wrapper with [workflow.ActivityOptions] applied to the context.
func (w WorkflowContext) WithActivityOptions(opts workflow.ActivityOptions) WorkflowContext {
	return WorkflowContext{Ctx: workflow.WithActivityOptions(w.Ctx, opts)}
}

// WithQueueActivityOptions applies [WorkflowActivityOptions] derived from [QueueOptions].
func (w WorkflowContext) WithQueueActivityOptions(q QueueOptions) WorkflowContext {
	return w.WithActivityOptions(WorkflowActivityOptions(q))
}

// WorkflowActivityOptions maps [QueueOptions] to default activity scheduling options (retry from [QueueOptions.TemporalRetryPolicy],
// start-to-close and heartbeat budgets suitable for SAGE-style long runs).
func WorkflowActivityOptions(q QueueOptions) workflow.ActivityOptions {
	rp := q.TemporalRetryPolicy()
	stc := 10 * time.Minute
	if q.WorkflowExecutionTimeout > 0 && q.WorkflowExecutionTimeout < stc {
		stc = q.WorkflowExecutionTimeout
	}
	return workflow.ActivityOptions{
		StartToCloseTimeout: stc,
		HeartbeatTimeout:    2 * time.Minute,
		RetryPolicy:         &rp,
	}
}

// ManagedWorkflowInput is a minimal saga template payload; extend or replace in your workflows.
type ManagedWorkflowInput struct {
	Payload string
}

// RollbackInput is passed to compensating activities when a saga step fails.
type RollbackInput struct {
	Step   string
	Reason string
	Meta   string
}

// SagaCompensation describes a compensating activity to run in LIFO order after a forward failure.
type SagaCompensation struct {
	Activity any
	Args     any
}

// CompensateAll runs compensations from last successful step to first (saga rollback). Errors are swallowed
// so earlier compensations still run; check worker logs for activity failures.
func CompensateAll(ctx workflow.Context, pending []SagaCompensation) {
	if len(pending) == 0 {
		return
	}
	rp := temporal.RetryPolicy{
		InitialInterval:    time.Second,
		MaximumInterval:    30 * time.Second,
		BackoffCoefficient: 2,
		MaximumAttempts:    2,
	}
	cctx := workflow.WithActivityOptions(ctx, workflow.ActivityOptions{
		StartToCloseTimeout: 5 * time.Minute,
		RetryPolicy:         &rp,
	})
	for i := len(pending) - 1; i >= 0; i-- {
		c := pending[i]
		_ = workflow.ExecuteActivity(cctx, c.Activity, c.Args).Get(cctx, nil)
	}
}

// ManagedTemplateWorkflow demonstrates a managed saga: copy this function, rename it, and add steps.
// It applies [WorkflowActivityOptions], uses deterministic time via [WorkflowContext], and defers compensations.
//
// Register with your worker together with [Activities] from [RegisterActivities] so saga activities exist.
func ManagedTemplateWorkflow(ctx workflow.Context, in ManagedWorkflowInput) (err error) {
	q := NewQueueOptions(WithMaxRetries(5))
	ctx = workflow.WithActivityOptions(ctx, WorkflowActivityOptions(q))
	wc := NewWorkflowContext(ctx)
	_ = wc.Now()
	_ = wc.SmithHeader()

	var pending []SagaCompensation
	defer func() {
		if err != nil && len(pending) > 0 {
			CompensateAll(wc.Ctx, pending)
		}
	}()

	if err = workflow.ExecuteActivity(ctx, (*Activities).SagaStepNoop, "step-1").Get(ctx, nil); err != nil {
		return err
	}
	pending = append(pending, SagaCompensation{
		Activity: (*Activities).SagaRollback,
		Args: RollbackInput{
			Step:   "step-1",
			Reason: "compensate after failure",
			Meta:   in.Payload,
		},
	})

	// Add more steps: after each successful ExecuteActivity, append the matching SagaCompensation.
	return nil
}

// ChildWorkflowOptions configures child workflow execution.
type ChildWorkflowOptions = workflow.ChildWorkflowOptions

// ExecuteChildWorkflow starts a child workflow (see SDK docs for usage).
var ExecuteChildWorkflow = workflow.ExecuteChildWorkflow

// SignalExternalWorkflow sends a signal to another workflow.
var SignalExternalWorkflow = workflow.SignalExternalWorkflow

// SetQueryHandler registers a query handler on the workflow context.
var SetQueryHandler = workflow.SetQueryHandler

// GetSignalChannel receives signals by channel name.
var GetSignalChannel = workflow.GetSignalChannel

// SideEffect executes a non-deterministic closure once (cached on replay).
var SideEffect = workflow.SideEffect
