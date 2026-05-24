package kit

// Rice-aware assertions for SMITH services. Intended for use from *_test.go files
// (and any test package that imports kit); helpers require a *testing.T.
//
// This file is normal Go source (not //go:build test) so downstream services can
// import [Tester] and package-level helpers. The standard go test command does not
// enable a "test" build tag; using that tag would require every invocation to pass
// -tags=test and would break default workflows.

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"slices"
	"strings"
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
)

// TestingT matches testify [require.TestingT] (works with assert.* helpers too).
type TestingT = require.TestingT

// Re-export commonly used testify helpers for *_test.go files.
var (
	RequireNoError = require.NoError
	RequireEqual   = require.Equal
	RequireTrue    = require.True
	RequireFalse   = require.False
	AssertEqual    = assert.Equal
	AssertNoError  = assert.NoError
	AssertTrue     = assert.True
	AssertFalse    = assert.False
)

// Mock is a testify mock for generated factories.
type Mock = mock.Mock

// Suite is a testify suite base for table-driven + lifecycle hooks.
type Suite = suite.Suite

// NewMock returns a fresh mock.Mock (useful in small table tests).
func NewMock() *mock.Mock {
	return &mock.Mock{}
}

// FailNow fails the test immediately (alias for Require-style fatals).
func FailNow(t TestingT, msg string, args ...interface{}) {
	require.FailNow(t, msg, args...)
}

// callHelper invokes tb.Helper() when tb supports it (*testing.T, testify suites, etc.).
func callHelper(tb TestingT) {
	if h, ok := tb.(interface{ Helper() }); ok {
		h.Helper()
	}
}

// Tester wraps [*testing.T] with .rice / SMITH-aware assertions.
type Tester struct {
	T *testing.T
}

// NewTester returns a [Tester] bound to t.
func NewTester(t *testing.T) Tester {
	if t == nil {
		panic("kit.NewTester: nil *testing.T")
	}
	return Tester{T: t}
}

// NoError asserts err is nil. If err wraps or is an [*AppError], the failure
// message includes Code and Message for faster diagnosis in SMITH services.
func (a Tester) NoError(err error, msgAndArgs ...interface{}) {
	a.T.Helper()
	if err == nil {
		return
	}
	var app *AppError
	if errors.As(err, &app) && app != nil {
		require.Fail(a.T, riceFailMsg(
			"unexpected .rice AppError",
			fmt.Sprintf("id=%s\ncode=%q\nmessage=%q\nhttp=%d\ngrpc=%v\ntrace_id=%q\ncause=%v\nfull error: %v",
				app.ID.String(), app.Code, app.Message, app.Status, app.GRPC, app.TraceID, app.Cause, err),
		), msgAndArgs...)
		return
	}
	require.NoError(a.T, err, msgAndArgs...)
}

// HasCode asserts err is or wraps an [*AppError] with the given machine code.
func (a Tester) HasCode(err error, expectedCode string, msgAndArgs ...interface{}) {
	a.T.Helper()
	var app *AppError
	if !errors.As(err, &app) || app == nil {
		require.Fail(a.T, riceFailMsg(
			"expected *kit.AppError in error chain",
			fmt.Sprintf("expected code %q but error is not an AppError: %T: %v", expectedCode, err, err),
		), msgAndArgs...)
		return
	}
	if app.Code != expectedCode {
		require.Fail(a.T, riceFailMsg(
			"AppError code mismatch",
			fmt.Sprintf("expected code %q, got %q (message=%q, cause=%v)", expectedCode, app.Code, app.Message, app.Cause),
		), msgAndArgs...)
	}
}

// HasMetadata asserts ctx carries [Metadata] with key present (value may be "").
func (a Tester) HasMetadata(ctx *Context, key string, msgAndArgs ...interface{}) {
	a.T.Helper()
	if ctx == nil {
		require.Fail(a.T, riceFailMsg("kit.Context is nil", "cannot read metadata from nil *kit.Context"), msgAndArgs...)
		return
	}
	if ctx.Meta == nil {
		require.Fail(a.T, riceFailMsg(
			"kit.Context.Meta is nil",
			"expected metadata bag on .rice Context; attach Meta in the test or production path",
		), msgAndArgs...)
		return
	}
	if _, ok := ctx.Meta.Get(key); !ok {
		require.Fail(a.T, riceFailMsg(
			fmt.Sprintf("metadata key %q missing", key),
			"current keys: "+metadataKeyList(ctx.Meta),
		), msgAndArgs...)
	}
}

// TracePresent asserts ctx has a non-zero, valid OpenTelemetry [trace.TraceID].
func (a Tester) TracePresent(ctx *Context, msgAndArgs ...interface{}) {
	a.T.Helper()
	if ctx == nil {
		require.Fail(a.T, riceFailMsg("kit.Context is nil", "cannot assert trace on nil *kit.Context"), msgAndArgs...)
		return
	}
	if !ctx.TraceID.IsValid() {
		require.Fail(a.T, riceFailMsg(
			"invalid or empty TraceID on kit.Context",
			fmt.Sprintf("TraceID=%s (IsValid=false); ensure OTel span context is injected in the test harness", ctx.TraceID),
		), msgAndArgs...)
	}
}

// JSONEq compares two JSON payloads (string, []byte, or [json.RawMessage]) for
// semantic equality after normalizing with [encoding/json] (whitespace and key
// order do not matter). Numbers decode as [json.Number] to preserve precision.
func (a Tester) JSONEq(expected, actual any, msgAndArgs ...interface{}) {
	a.T.Helper()
	JSONEq(a.T, expected, actual, msgAndArgs...)
}

// JSONEq compares JSON values; returns true if equal. See [Tester.JSONEq].
func JSONEq(t TestingT, expected, actual any, msgAndArgs ...interface{}) bool {
	callHelper(t)
	expB, err := jsonInputToBytes(expected)
	if err != nil {
		return assert.Fail(t, riceFailMsg("JSONEq expected: invalid input", err.Error()), msgAndArgs...)
	}
	actB, err := jsonInputToBytes(actual)
	if err != nil {
		return assert.Fail(t, riceFailMsg("JSONEq actual: invalid input", err.Error()), msgAndArgs...)
	}
	expN, err := normalizeJSON(expB)
	if err != nil {
		return assert.Fail(t, riceFailMsg("JSONEq expected: not valid JSON", err.Error()), msgAndArgs...)
	}
	actN, err := normalizeJSON(actB)
	if err != nil {
		return assert.Fail(t, riceFailMsg("JSONEq actual: not valid JSON", err.Error()), msgAndArgs...)
	}
	if bytes.Equal(expN, actN) {
		return true
	}
	return assert.Fail(t, riceFailMsg(
		"JSON mismatch after normalization (.rice API / proto JSON)",
		fmt.Sprintf("expected (normalized):\n%s\nactual (normalized):\n%s", string(expN), string(actN)),
	), msgAndArgs...)
}

// DeepDiff reports a failure if expected and actual differ, using [cmp.Diff] for
// a concise multi-line report. Pass [cmp.Option] values for custom equality
// (e.g. protobuf messages, floats).
func DeepDiff(t TestingT, expected, actual any, opts ...cmp.Option) bool {
	callHelper(t)
	if cmp.Equal(expected, actual, opts...) {
		return true
	}
	diff := cmp.Diff(expected, actual, opts...)
	return assert.Fail(t, riceFailMsg(".rice / SMITH structure mismatch (cmp.Diff)", diff))
}

// DeepDiff is a method form of [DeepDiff].
func (a Tester) DeepDiff(expected, actual any, opts ...cmp.Option) {
	a.T.Helper()
	DeepDiff(a.T, expected, actual, opts...)
}

func riceFailMsg(title, detail string) string {
	var b strings.Builder
	b.Grow(len(title) + len(detail) + 32)
	b.WriteString(".rice / SMITH assertion failed — ")
	b.WriteString(title)
	b.WriteString("\n")
	b.WriteString(detail)
	return b.String()
}

func jsonInputToBytes(v any) ([]byte, error) {
	switch x := v.(type) {
	case string:
		return []byte(x), nil
	case []byte:
		return x, nil
	case json.RawMessage:
		return []byte(x), nil
	default:
		return nil, fmt.Errorf("expected string, []byte, or json.RawMessage, got %T", v)
	}
}

func normalizeJSON(data []byte) ([]byte, error) {
	dec := json.NewDecoder(bytes.NewReader(data))
	dec.UseNumber()
	var v any
	if err := dec.Decode(&v); err != nil {
		return nil, err
	}
	if dec.More() {
		return nil, fmt.Errorf("trailing data after first JSON value")
	}
	return json.Marshal(v)
}

func metadataKeyList(md *Metadata) string {
	if md == nil {
		return "<nil>"
	}
	md.mu.RLock()
	defer md.mu.RUnlock()
	if len(md.m) == 0 {
		return "{}"
	}
	keys := make([]string, 0, len(md.m))
	for k := range md.m {
		keys = append(keys, k)
	}
	slices.Sort(keys)
	return "{" + strings.Join(keys, ", ") + "}"
}
