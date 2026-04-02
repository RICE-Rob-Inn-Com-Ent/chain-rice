package queue

// TODO:
// [ ] implement base workflow struct:
//     Workflow struct — registered with Temporal worker
//     all workflows idempotent — safe to retry
// [ ] implement rice kingdom workflows:
//     SnapshotWorkflow — scheduled YugabyteDB backup
//     AuditWorkflow — scheduled security audit
//     ModelSyncWorkflow — syncs SAGE model registry
//     CompilationWorkflow — long-running rice cook compilation
//     DeployWorkflow — production deployment pipeline
// [ ] all workflow timeouts from env vars:
//     RICE_WORKFLOW_{NAME}_TIMEOUT_S — per workflow
//     RICE_WORKFLOW_DEFAULT_TIMEOUT_S — fallback

import (
	"go.temporal.io/sdk/workflow"
)

// WorkflowContext is the context passed to workflow functions.
type WorkflowContext = workflow.Context

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
