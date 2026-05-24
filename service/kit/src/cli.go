package kit

// CLI foundation for .rice / SMITH: Cobra, slog, trace correlation, and kit errors.

import (
	"context"
	"crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"github.com/spf13/cobra"
	"go.opentelemetry.io/otel/trace"
)

// Standard global CLI flags (see [AddGlobalFlags]).
const (
	CLIFlagDebug   = "debug"
	CLIFlagJSONLog = "json-log"
	CLIFlagTraceID = "trace-id"
)

const (
	flagDebug   = CLIFlagDebug
	flagJSONLog = CLIFlagJSONLog
	flagTraceID = CLIFlagTraceID
)

// Command aliases [cobra.Command] pointers so SMITH CLIs share one vocabulary.
type Command = *cobra.Command

// Version is the binary version (set via ldflags from Back2 / Buck2 / go build -ldflags).
// See also [BuildTime] and [GitCommit] in main.go.
//
// Example:
//
//	-ldflags="-X github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src.Version=0.4.1 \
//	  -X github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src.BuildTime=... \
//	  -X github.com/RICE-Rob-Inn-Com-Ent/rice/service/kit/src.GitCommit=..."
var Version = "(devel)"

// SetVersion assigns [Version] (e.g. from tests or a non-ldflags bootstrap).
func SetVersion(v string) { Version = v }

// NewCommand returns a [Command] with SMITH defaults (quiet Cobra error/usage noise).
func NewCommand(name, short, long string) Command {
	return &cobra.Command{
		Use:           name,
		Short:         short,
		Long:          long,
		SilenceUsage:  true,
		SilenceErrors: true,
	}
}

// AddGlobalFlags registers persistent flags on root and wires [syncCLIFromFlags] before any
// existing PersistentPreRunE. Call on the root command once; child commands inherit flags.
func AddGlobalFlags(root Command) {
	if root == nil {
		return
	}
	fs := root.PersistentFlags()
	fs.BoolP(flagDebug, "d", false, "enable debug logs (slog level debug)")
	fs.Bool(flagJSONLog, false, "emit logs and kit errors as JSON on stderr")
	fs.String(flagTraceID, "", "trace id for correlation (32 hex chars); a new id is generated if omitted")

	prev := root.PersistentPreRunE
	root.PersistentPreRunE = func(cmd *cobra.Command, args []string) error {
		if err := syncCLIFromFlags(cmd); err != nil {
			return err
		}
		if prev != nil {
			return prev(cmd, args)
		}
		return nil
	}
}

func syncCLIFromFlags(cmd *cobra.Command) error {
	debug, _ := cmd.Flags().GetBool(flagDebug)
	jsonLog, _ := cmd.Flags().GetBool(flagJSONLog)

	level := slog.LevelInfo
	if debug {
		level = slog.LevelDebug
	}
	opts := &slog.HandlerOptions{Level: level}
	var h slog.Handler
	if jsonLog {
		h = slog.NewJSONHandler(os.Stderr, opts)
	} else {
		h = slog.NewTextHandler(os.Stderr, opts)
	}
	slog.SetDefault(slog.New(h))
	return nil
}

// CommandContext returns a [*Context] for use inside [cobra.Command.Run] / RunE.
// It wraps [cobra.Command.Context] (from [cobra.Command.ExecuteContext]), ensures a valid
// trace id (from --trace-id or freshly generated), and attaches it to the returned context.
func CommandContext(cmd *cobra.Command) *Context {
	if cmd == nil {
		return NewContext(context.Background(), cliMetadataFromFlags(nil))
	}
	base := cmd.Context()
	if base == nil {
		base = context.Background()
	}
	meta := cliMetadataFromFlags(cmd)

	tidStr, _ := cmd.Flags().GetString(flagTraceID)
	tidStr = strings.TrimSpace(strings.TrimPrefix(tidStr, "0x"))
	var tid trace.TraceID
	if tidStr != "" {
		var err error
		tid, err = trace.TraceIDFromHex(tidStr)
		if err != nil {
			slog.Warn("invalid --trace-id; generating a new trace id", "error", err)
			tid = mustRandomTraceID()
		}
	} else {
		tid = mustRandomTraceID()
	}
	sid := mustRandomSpanID()
	sc := trace.NewSpanContext(trace.SpanContextConfig{
		TraceID:    tid,
		SpanID:     sid,
		TraceFlags: trace.FlagsSampled,
	})
	base = trace.ContextWithSpanContext(base, sc)
	if meta != nil {
		meta.Set(MetaTraceID, tid.String())
		meta.Set(MetaSpanID, sid.String())
	}
	return NewContext(base, meta)
}

func cliMetadataFromFlags(cmd *cobra.Command) *Metadata {
	md := &Metadata{}
	if cmd == nil {
		return md
	}
	if d, _ := cmd.Flags().GetBool(flagDebug); d {
		md.Set("rice.debug", "true")
	}
	return md
}

func mustRandomTraceID() trace.TraceID {
	var id trace.TraceID
	if _, err := rand.Read(id[:]); err != nil {
		panic(err)
	}
	return id
}

func mustRandomSpanID() trace.SpanID {
	var id trace.SpanID
	if _, err := rand.Read(id[:]); err != nil {
		panic(err)
	}
	return id
}

// Execute runs root with signal-aware cancellation (SIGINT, SIGTERM), applies [Version] to the
// root's version output, enforces silence of default Cobra usage/error printing, and formats
// [*Error] results for stderr per --json-log.
func Execute(root Command) error {
	if root == nil {
		return errors.New("kit.Execute: nil root command")
	}
	root.SilenceUsage = true
	root.SilenceErrors = true
	if root.Version == "" {
		root.Version = Version
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	err := root.ExecuteContext(ctx)
	jsonLog := false
	if root.PersistentFlags().Lookup(flagJSONLog) != nil {
		jsonLog, _ = root.PersistentFlags().GetBool(flagJSONLog)
	}

	if err == nil {
		return nil
	}
	if errors.Is(err, context.Canceled) {
		_, _ = fmt.Fprintln(os.Stderr, "interrupted")
		return err
	}

	var ke *Error
	if errors.As(err, &ke) && ke != nil {
		writeCLIError(os.Stderr, ke, jsonLog)
		return err
	}
	_, _ = fmt.Fprintln(os.Stderr, err.Error())
	return err
}

type cliErrorJSON struct {
	ID       string         `json:"id"`
	Code     string         `json:"code"`
	Message  string         `json:"message"`
	HTTP     int            `json:"http_status,omitempty"`
	GRPC     int            `json:"grpc_code,omitempty"`
	TraceID  string         `json:"trace_id,omitempty"`
	Details  map[string]any `json:"details,omitempty"`
	Cause    string         `json:"cause,omitempty"`
	GRPCCode string         `json:"grpc_code_name,omitempty"`
}

func writeCLIError(w io.Writer, e *Error, jsonLog bool) {
	if e == nil {
		return
	}
	if jsonLog {
		payload := cliErrorJSON{
			ID:       e.ID.String(),
			Code:     e.Code,
			Message:  e.Message,
			HTTP:     e.Status,
			GRPC:     int(e.GRPC),
			GRPCCode: e.GRPC.String(),
			TraceID:  e.TraceID,
			Details:  e.Details,
		}
		if e.Cause != nil {
			payload.Cause = e.Cause.Error()
		}
		enc := json.NewEncoder(w)
		enc.SetEscapeHTML(false)
		_ = enc.Encode(payload)
		return
	}

	_, _ = fmt.Fprintf(w, "%s: %s\n", e.Code, e.Message)
	_, _ = fmt.Fprintf(w, "  id: %s\n", e.ID.String())
	if e.TraceID != "" {
		_, _ = fmt.Fprintf(w, "  trace_id: %s\n", e.TraceID)
	}
	if len(e.Details) > 0 {
		_, _ = fmt.Fprintln(w, "  details:")
		for k, v := range e.Details {
			_, _ = fmt.Fprintf(w, "    %s: %v\n", k, v)
		}
	}
	if e.Cause != nil {
		_, _ = fmt.Fprintf(w, "  cause: %s\n", e.Cause.Error())
	}
}
