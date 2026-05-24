package queue

import (
	"context"
	"log/slog"

	kit "github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src"
	"github.com/nats-io/nats.go"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/trace"
	commonpb "go.temporal.io/api/common/v1"
	"go.temporal.io/sdk/activity"
	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/converter"
	"go.temporal.io/sdk/interceptor"
	"go.temporal.io/sdk/workflow"
)

const smithTemporalHeaderKey = "x-smith-kit-v1"

type smithWorkflowCtxKey struct{}

// SmithWorkflowContextKey carries propagated SMITH trace metadata on [workflow.Context] inside workflow code.
var SmithWorkflowContextKey = smithWorkflowCtxKey{}

// SmithWorkflowHeader is stored under [SmithWorkflowContextKey] after header extraction.
// UserID is forwarded for session identity; callers must validate it before trust (authorization boundary).
type SmithWorkflowHeader struct {
	TraceID string `json:"trace_id,omitempty"`
	SpanID  string `json:"span_id,omitempty"`
	UserID  string `json:"user_id,omitempty"`
}

// SmithHeaderFromWorkflow returns propagated header data, if any.
func SmithHeaderFromWorkflow(ctx workflow.Context) *SmithWorkflowHeader {
	if ctx == nil {
		return nil
	}
	h, _ := ctx.Value(SmithWorkflowContextKey).(*SmithWorkflowHeader)
	return h
}

type smithKitPropagator struct{}

// SmithKitContextPropagator serializes [kit.Context] trace ids and identity hints into workflow headers and restores them on the worker side.
func SmithKitContextPropagator() workflow.ContextPropagator {
	return smithKitPropagator{}
}

func (smithKitPropagator) Inject(ctx context.Context, w workflow.HeaderWriter) error {
	return injectSmithHeader(ctx, w)
}

func (smithKitPropagator) InjectFromWorkflow(ctx workflow.Context, w workflow.HeaderWriter) error {
	h := SmithHeaderFromWorkflow(ctx)
	if h == nil {
		return nil
	}
	pl, err := converter.GetDefaultDataConverter().ToPayload(h)
	if err != nil {
		return err
	}
	w.Set(smithTemporalHeaderKey, pl)
	return nil
}

func (smithKitPropagator) Extract(ctx context.Context, r workflow.HeaderReader) (context.Context, error) {
	pl, ok := r.Get(smithTemporalHeaderKey)
	if !ok {
		return ctx, nil
	}
	var h SmithWorkflowHeader
	if err := converter.GetDefaultDataConverter().FromPayload(pl, &h); err != nil {
		return ctx, err
	}
	return applySmithHeaderToContext(ctx, &h), nil
}

func (smithKitPropagator) ExtractToWorkflow(ctx workflow.Context, r workflow.HeaderReader) (workflow.Context, error) {
	pl, ok := r.Get(smithTemporalHeaderKey)
	if !ok {
		return ctx, nil
	}
	var h SmithWorkflowHeader
	if err := converter.GetDefaultDataConverter().FromPayload(pl, &h); err != nil {
		return ctx, err
	}
	return workflow.WithValue(ctx, SmithWorkflowContextKey, &h), nil
}

func injectSmithHeader(ctx context.Context, w workflow.HeaderWriter) error {
	k := kit.FromContext(ctx)
	if k == nil {
		return nil
	}
	h := SmithWorkflowHeader{}
	if k.TraceID.IsValid() {
		h.TraceID = k.TraceID.String()
	}
	if k.SpanID.IsValid() {
		h.SpanID = k.SpanID.String()
	}
	if k.Meta != nil {
		if uid, ok := k.Meta.Get(kit.MetaUserID); ok && uid != "" {
			h.UserID = uid
		}
	}
	if h.TraceID == "" && h.SpanID == "" && h.UserID == "" {
		return nil
	}
	pl, err := converter.GetDefaultDataConverter().ToPayload(h)
	if err != nil {
		return err
	}
	w.Set(smithTemporalHeaderKey, pl)
	return nil
}

func applySmithHeaderToContext(ctx context.Context, h *SmithWorkflowHeader) context.Context {
	if h == nil || ctx == nil {
		return ctx
	}
	if h.TraceID != "" && h.SpanID != "" {
		tid, e1 := trace.TraceIDFromHex(h.TraceID)
		sid, e2 := trace.SpanIDFromHex(h.SpanID)
		if e1 == nil && e2 == nil {
			sc := trace.NewSpanContext(trace.SpanContextConfig{
				TraceID:    tid,
				SpanID:     sid,
				Remote:     true,
				TraceFlags: trace.FlagsSampled,
			})
			ctx = trace.ContextWithSpanContext(ctx, sc)
		}
	}
	if h.UserID != "" {
		var meta *kit.Metadata
		if k := kit.FromContext(ctx); k != nil && k.Meta != nil {
			meta = k.Meta.Clone()
		} else {
			meta = &kit.Metadata{}
		}
		meta.Set(kit.MetaUserID, h.UserID)
		ctx = kit.NewContext(ctx, meta).ToContext()
	}
	return ctx
}

// temporalHeaderCarrier adapts Temporal header payloads to [go.opentelemetry.io/otel/propagation.TextMapCarrier] (W3C traceparent / tracestate).
type temporalHeaderCarrier map[string]*commonpb.Payload

func (c temporalHeaderCarrier) Get(key string) string {
	p, ok := c[key]
	if !ok || p == nil {
		return ""
	}
	return string(p.GetData())
}

func (c temporalHeaderCarrier) Set(key, value string) {
	if c == nil || key == "" {
		return
	}
	c[key] = &commonpb.Payload{
		Metadata: map[string][]byte{
			converter.MetadataEncoding: []byte(converter.MetadataEncodingBinary),
		},
		Data: []byte(value),
	}
}

func (c temporalHeaderCarrier) Keys() []string {
	if c == nil {
		return nil
	}
	keys := make([]string, 0, len(c))
	for k := range c {
		keys = append(keys, k)
	}
	return keys
}

func injectTemporalTraceHeaders(ctx context.Context) {
	h := interceptor.Header(ctx)
	if h == nil {
		return
	}
	otel.GetTextMapPropagator().Inject(ctx, temporalHeaderCarrier(h))
}

func enrichActivityContext(ctx context.Context) context.Context {
	h := interceptor.Header(ctx)
	if h == nil {
		return ctx
	}
	ctx = otel.GetTextMapPropagator().Extract(ctx, temporalHeaderCarrier(h))
	if pl, ok := h[smithTemporalHeaderKey]; ok {
		var sh SmithWorkflowHeader
		if err := converter.GetDefaultDataConverter().FromPayload(pl, &sh); err == nil {
			ctx = applySmithHeaderToContext(ctx, &sh)
		}
	}
	return ctx
}

// --- NATS: W3C + identity ---

type natsHeaderCarrier struct {
	h nats.Header
}

func (c *natsHeaderCarrier) Get(key string) string {
	if c.h == nil {
		return ""
	}
	return c.h.Get(key)
}

func (c *natsHeaderCarrier) Set(key, value string) {
	if c.h == nil || key == "" {
		return
	}
	c.h.Set(key, value)
}

func (c *natsHeaderCarrier) Keys() []string {
	if c.h == nil {
		return nil
	}
	keys := make([]string, 0, len(c.h))
	for k := range c.h {
		keys = append(keys, k)
	}
	return keys
}

// InjectTrace writes W3C trace context from kit.Context into NATS headers and copies session UserID ([kit.MetaUserID]) when present.
func InjectTrace(ctx *kit.Context, msg *nats.Msg) {
	if msg == nil {
		return
	}
	if msg.Header == nil {
		msg.Header = make(nats.Header)
	}
	parent := context.Background()
	if ctx != nil {
		parent = ctx.ToContext()
	}
	carrier := &natsHeaderCarrier{h: msg.Header}
	otel.GetTextMapPropagator().Inject(parent, carrier)
	if ctx != nil && ctx.Meta != nil {
		if uid, ok := ctx.Meta.Get(kit.MetaUserID); ok && uid != "" {
			msg.Header.Set(kit.MetaUserID, uid)
		}
	}
}

// ExtractTrace rebuilds a [context.Context] with remote OTel span context and optional [kit.MetaUserID] from the message.
func ExtractTrace(msg *nats.Msg) context.Context {
	if msg == nil || msg.Header == nil {
		return context.Background()
	}
	ctx := otel.GetTextMapPropagator().Extract(context.Background(), &natsHeaderCarrier{h: msg.Header})
	if uid := msg.Header.Get(kit.MetaUserID); uid != "" {
		meta := &kit.Metadata{}
		meta.Set(kit.MetaUserID, uid)
		ctx = kit.NewContext(ctx, meta).ToContext()
	}
	return ctx
}

// --- Temporal: unified client + worker interceptor ---

type smithQueueInterceptor struct {
	interceptor.InterceptorBase
}

// NewSmithQueueInterceptor returns a full [interceptor.Interceptor] (client outbound + worker inbound) for SMITH tracing and logging.
func NewSmithQueueInterceptor() interceptor.Interceptor {
	return &smithQueueInterceptor{}
}

// NewSmithClientInterceptor is the client-only view of [NewSmithQueueInterceptor] for [client.Options.Interceptors].
func NewSmithClientInterceptor() interceptor.ClientInterceptor {
	return NewSmithQueueInterceptor()
}

func (*smithQueueInterceptor) InterceptClient(next interceptor.ClientOutboundInterceptor) interceptor.ClientOutboundInterceptor {
	return &smithClientOutbound{
		ClientOutboundInterceptorBase: interceptor.ClientOutboundInterceptorBase{Next: next},
	}
}

func (*smithQueueInterceptor) InterceptActivity(ctx context.Context, next interceptor.ActivityInboundInterceptor) interceptor.ActivityInboundInterceptor {
	return &smithActivityInbound{
		ActivityInboundInterceptorBase: interceptor.ActivityInboundInterceptorBase{Next: next},
	}
}

func (*smithQueueInterceptor) InterceptWorkflow(ctx workflow.Context, next interceptor.WorkflowInboundInterceptor) interceptor.WorkflowInboundInterceptor {
	return &smithWorkflowInbound{
		WorkflowInboundInterceptorBase: interceptor.WorkflowInboundInterceptorBase{Next: next},
	}
}

type smithClientOutbound struct {
	interceptor.ClientOutboundInterceptorBase
}

func (o *smithClientOutbound) ExecuteWorkflow(ctx context.Context, in *interceptor.ClientExecuteWorkflowInput) (client.WorkflowRun, error) {
	injectTemporalTraceHeaders(ctx)
	action := "ExecuteWorkflow"
	if in != nil && in.WorkflowType != "" {
		action = in.WorkflowType
	}
	run, err := o.Next.ExecuteWorkflow(ctx, in)
	o.logClient(ctx, action, err)
	return run, err
}

func (o *smithClientOutbound) CreateSchedule(ctx context.Context, in *interceptor.ScheduleClientCreateInput) (client.ScheduleHandle, error) {
	h, err := o.Next.CreateSchedule(ctx, in)
	o.logClient(ctx, "CreateSchedule", err)
	return h, err
}

func (o *smithClientOutbound) SignalWorkflow(ctx context.Context, in *interceptor.ClientSignalWorkflowInput) error {
	injectTemporalTraceHeaders(ctx)
	action := "SignalWorkflow"
	if in != nil && in.SignalName != "" {
		action = in.SignalName
	}
	err := o.Next.SignalWorkflow(ctx, in)
	o.logClient(ctx, action, err)
	return err
}

func (o *smithClientOutbound) SignalWithStartWorkflow(ctx context.Context, in *interceptor.ClientSignalWithStartWorkflowInput) (client.WorkflowRun, error) {
	injectTemporalTraceHeaders(ctx)
	action := "SignalWithStartWorkflow"
	if in != nil && in.WorkflowType != "" {
		action = in.WorkflowType
	}
	run, err := o.Next.SignalWithStartWorkflow(ctx, in)
	o.logClient(ctx, action, err)
	return run, err
}

func (o *smithClientOutbound) CancelWorkflow(ctx context.Context, in *interceptor.ClientCancelWorkflowInput) error {
	err := o.Next.CancelWorkflow(ctx, in)
	o.logClient(ctx, "CancelWorkflow", err)
	return err
}

func (o *smithClientOutbound) TerminateWorkflow(ctx context.Context, in *interceptor.ClientTerminateWorkflowInput) error {
	err := o.Next.TerminateWorkflow(ctx, in)
	o.logClient(ctx, "TerminateWorkflow", err)
	return err
}

func (o *smithClientOutbound) QueryWorkflow(ctx context.Context, in *interceptor.ClientQueryWorkflowInput) (converter.EncodedValue, error) {
	injectTemporalTraceHeaders(ctx)
	action := "QueryWorkflow"
	if in != nil && in.QueryType != "" {
		action = in.QueryType
	}
	v, err := o.Next.QueryWorkflow(ctx, in)
	o.logClient(ctx, action, err)
	return v, err
}

func (o *smithClientOutbound) UpdateWorkflow(ctx context.Context, in *interceptor.ClientUpdateWorkflowInput) (client.WorkflowUpdateHandle, error) {
	injectTemporalTraceHeaders(ctx)
	action := "UpdateWorkflow"
	if in != nil && in.UpdateName != "" {
		action = in.UpdateName
	}
	h, err := o.Next.UpdateWorkflow(ctx, in)
	o.logClient(ctx, action, err)
	return h, err
}

func (o *smithClientOutbound) UpdateWithStartWorkflow(ctx context.Context, in *interceptor.ClientUpdateWithStartWorkflowInput) (client.WorkflowUpdateHandle, error) {
	injectTemporalTraceHeaders(ctx)
	action := "UpdateWithStartWorkflow"
	if in != nil && in.UpdateOptions != nil && in.UpdateOptions.UpdateName != "" {
		action = in.UpdateOptions.UpdateName
	}
	h, err := o.Next.UpdateWithStartWorkflow(ctx, in)
	o.logClient(ctx, action, err)
	return h, err
}

func (o *smithClientOutbound) DescribeWorkflow(ctx context.Context, in *interceptor.ClientDescribeWorkflowInput) (*interceptor.ClientDescribeWorkflowOutput, error) {
	out, err := o.Next.DescribeWorkflow(ctx, in)
	o.logClient(ctx, "DescribeWorkflow", err)
	return out, err
}

func (*smithClientOutbound) logClient(ctx context.Context, actionName string, err error) {
	st := "ok"
	if err != nil {
		st = "error"
	}
	lg := kit.Logger().With(
		slog.String("ActionName", actionName),
		slog.String("Status", st),
	)
	if err != nil {
		lg = lg.With(slog.String("err", err.Error()))
	}
	if k := kit.FromContext(ctx); k != nil && k.TraceID.IsValid() {
		lg = lg.With(slog.String("trace_id", k.TraceID.String()))
	}
	lg.InfoContext(ctx, "queue.temporal.client")
}

type smithActivityInbound struct {
	interceptor.ActivityInboundInterceptorBase
}

func (a *smithActivityInbound) ExecuteActivity(ctx context.Context, in *interceptor.ExecuteActivityInput) (interface{}, error) {
	ctx = enrichActivityContext(ctx)
	info := activity.GetInfo(ctx)
	action := info.ActivityType.Name
	out, err := a.Next.ExecuteActivity(ctx, in)
	a.logWorker(ctx, "activity.ExecuteActivity", action, err)
	return out, err
}

type smithWorkflowInbound struct {
	interceptor.WorkflowInboundInterceptorBase
}

func (w *smithWorkflowInbound) ExecuteWorkflow(ctx workflow.Context, in *interceptor.ExecuteWorkflowInput) (interface{}, error) {
	hdr := interceptor.WorkflowHeader(ctx)
	logCtx := context.Background()
	if hdr != nil {
		logCtx = otel.GetTextMapPropagator().Extract(logCtx, temporalHeaderCarrier(hdr))
	}
	action := workflow.GetInfo(ctx).WorkflowType.Name
	out, err := w.Next.ExecuteWorkflow(ctx, in)
	w.logWorkflow(logCtx, action, err)
	return out, err
}

func (w *smithWorkflowInbound) HandleSignal(ctx workflow.Context, in *interceptor.HandleSignalInput) error {
	action := "HandleSignal"
	if in != nil && in.SignalName != "" {
		action = in.SignalName
	}
	err := w.Next.HandleSignal(ctx, in)
	hdr := interceptor.WorkflowHeader(ctx)
	logCtx := context.Background()
	if hdr != nil {
		logCtx = otel.GetTextMapPropagator().Extract(logCtx, temporalHeaderCarrier(hdr))
	}
	w.logWorkflow(logCtx, action, err)
	return err
}

func (w *smithWorkflowInbound) HandleQuery(ctx workflow.Context, in *interceptor.HandleQueryInput) (interface{}, error) {
	action := "HandleQuery"
	if in != nil && in.QueryType != "" {
		action = in.QueryType
	}
	out, err := w.Next.HandleQuery(ctx, in)
	hdr := interceptor.WorkflowHeader(ctx)
	logCtx := context.Background()
	if hdr != nil {
		logCtx = otel.GetTextMapPropagator().Extract(logCtx, temporalHeaderCarrier(hdr))
	}
	w.logWorkflow(logCtx, action, err)
	return out, err
}

func (w *smithWorkflowInbound) ExecuteUpdate(ctx workflow.Context, in *interceptor.UpdateInput) (interface{}, error) {
	action := "ExecuteUpdate"
	if in != nil && in.Name != "" {
		action = in.Name
	}
	out, err := w.Next.ExecuteUpdate(ctx, in)
	hdr := interceptor.WorkflowHeader(ctx)
	logCtx := context.Background()
	if hdr != nil {
		logCtx = otel.GetTextMapPropagator().Extract(logCtx, temporalHeaderCarrier(hdr))
	}
	w.logWorkflow(logCtx, action, err)
	return out, err
}

func (w *smithWorkflowInbound) ValidateUpdate(ctx workflow.Context, in *interceptor.UpdateInput) error {
	action := "ValidateUpdate"
	if in != nil && in.Name != "" {
		action = in.Name
	}
	err := w.Next.ValidateUpdate(ctx, in)
	hdr := interceptor.WorkflowHeader(ctx)
	logCtx := context.Background()
	if hdr != nil {
		logCtx = otel.GetTextMapPropagator().Extract(logCtx, temporalHeaderCarrier(hdr))
	}
	w.logWorkflow(logCtx, action, err)
	return err
}

func (*smithWorkflowInbound) logWorkflow(ctx context.Context, actionName string, err error) {
	st := "ok"
	if err != nil {
		st = "error"
	}
	lg := kit.Logger().With(
		slog.String("ActionName", actionName),
		slog.String("Status", st),
	)
	if err != nil {
		lg = lg.With(slog.String("err", err.Error()))
	}
	if sc := trace.SpanContextFromContext(ctx); sc.IsValid() {
		lg = lg.With(slog.String("trace_id", sc.TraceID().String()))
	}
	lg.Info("queue.temporal.workflow")
}

func (*smithActivityInbound) logWorker(ctx context.Context, component, actionName string, err error) {
	st := "ok"
	if err != nil {
		st = "error"
	}
	lg := kit.Logger().With(
		slog.String("component", component),
		slog.String("ActionName", actionName),
		slog.String("Status", st),
	)
	if err != nil {
		lg = lg.With(slog.String("err", err.Error()))
	}
	if k := kit.FromContext(ctx); k != nil && k.TraceID.IsValid() {
		lg = lg.With(slog.String("trace_id", k.TraceID.String()))
	}
	lg.InfoContext(ctx, "queue.temporal.worker")
}

// Compile-time checks for API drift.
var (
	_ interceptor.Interceptor               = (*smithQueueInterceptor)(nil)
	_ interceptor.ClientInterceptor         = (*smithQueueInterceptor)(nil)
	_ interceptor.ClientOutboundInterceptor = (*smithClientOutbound)(nil)
)
