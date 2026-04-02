package kit

// TODO:
// [ ] implement test assertion helpers via testify:
//     AssertProtoEqual(t, expected, actual proto.Message)
//     AssertNoError(t, err error, msg string)
//     AssertRiceError(t, err error, code ErrorCode)
// [ ] implement mock helpers:
//     MockUUID() string — deterministic UUID for tests
//     MockNow() time.Time — fixed time from RICE_TEST_NOW env
// [ ] implement test server helpers:
//     NewTestConnectServer(handler) *httptest.Server
//     NewTestGRPCServer(handler) *grpc.Server

import (
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
