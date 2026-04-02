package kit

// TODO:
// [ ] define RiceError wrapping all service errors:
//     Code ErrorCode — maps to ConnectRPC/gRPC status
//     Message string — human-readable
//     Details []proto.Message — structured error details from gen/
//     Cause error — wrapped original error
// [ ] define ErrorCode enum:
//     NotFound, InvalidArgument, Unauthorized, Forbidden,
//     Internal, Unavailable, AlreadyExists, ResourceExhausted
// [ ] implement error constructors per code:
//     NotFoundErr(msg string) RiceError
//     InvalidArgErr(msg string, field string) RiceError
// [ ] implement ConnectRPC error conversion:
//     ToConnectError(err RiceError) *connect.Error
//     FromConnectError(err *connect.Error) RiceError
// [ ] implement gRPC status conversion:
//     ToGRPCStatus(err RiceError) *status.Status

import (
	"errors"
	"fmt"
	"runtime/debug"
)

// Wrap returns fmt.Errorf("%s: %w", msg, err).
func Wrap(err error, msg string) error {
	if err == nil {
		return nil
	}
	return fmt.Errorf("%s: %w", msg, err)
}

// Wrapf wraps err with formatted context.
func Wrapf(err error, format string, args ...interface{}) error {
	if err == nil {
		return nil
	}
	return fmt.Errorf("%s: %w", fmt.Sprintf(format, args...), err)
}

// Sentinel errors: compare with [errors.Is].

// Join combines multiple errors (stdlib [errors.Join]).
func Join(errs ...error) error {
	return errors.Join(errs...)
}

// Is reports whether err matches target (stdlib [errors.Is]).
func Is(err, target error) bool {
	return errors.Is(err, target)
}

// As finds the first error in err's chain that matches target (stdlib [errors.As]).
func As(err error, target any) bool {
	return errors.As(err, target)
}

// Unwrap returns the next error in err's chain (stdlib [errors.Unwrap]).
func Unwrap(err error) error {
	return errors.Unwrap(err)
}

// StackTrace returns the current goroutine stack (for logs when wrapping is not enough).
func StackTrace() []byte {
	return debug.Stack()
}
