package errors

import (
	"fmt"
	"net/http"
)

// ErrorCode represents application error codes
type ErrorCode string

const (
	// ErrorCodeNotFound indicates resource not found
	ErrorCodeNotFound ErrorCode = "NOT_FOUND"

	// ErrorCodeValidation indicates validation error
	ErrorCodeValidation ErrorCode = "VALIDATION_ERROR"

	// ErrorCodeUnauthorized indicates authentication error
	ErrorCodeUnauthorized ErrorCode = "UNAUTHORIZED"

	// ErrorCodeForbidden indicates authorization error
	ErrorCodeForbidden ErrorCode = "FORBIDDEN"

	// ErrorCodeConflict indicates resource conflict
	ErrorCodeConflict ErrorCode = "CONFLICT"

	// ErrorCodeInternal indicates internal server error
	ErrorCodeInternal ErrorCode = "INTERNAL_ERROR"

	// ErrorCodeBadRequest indicates bad request
	ErrorCodeBadRequest ErrorCode = "BAD_REQUEST"
)

// AppError represents an application error
type AppError struct {
	Code       ErrorCode `json:"code"`
	Message    string    `json:"message"`
	Details    string    `json:"details,omitempty"`
	HTTPStatus int       `json:"-"`
	Err        error     `json:"-"`
}

// Error implements error interface
func (e *AppError) Error() string {
	if e.Details != "" {
		return fmt.Sprintf("%s: %s (%s)", e.Code, e.Message, e.Details)
	}
	return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

// Unwrap returns the underlying error
func (e *AppError) Unwrap() error {
	return e.Err
}

// NewAppError creates a new application error
func NewAppError(code ErrorCode, message string, httpStatus int) *AppError {
	return &AppError{
		Code:       code,
		Message:    message,
		HTTPStatus: httpStatus,
	}
}

// WithDetails adds details to the error
func (e *AppError) WithDetails(details string) *AppError {
	e.Details = details
	return e
}

// WithError wraps an underlying error
func (e *AppError) WithError(err error) *AppError {
	e.Err = err
	if e.Details == "" && err != nil {
		e.Details = err.Error()
	}
	return e
}

// Predefined error constructors

// NewNotFoundError creates a not found error
func NewNotFoundError(resource string) *AppError {
	return NewAppError(
		ErrorCodeNotFound,
		fmt.Sprintf("%s not found", resource),
		http.StatusNotFound,
	)
}

// NewValidationError creates a validation error
func NewValidationError(message string) *AppError {
	return NewAppError(
		ErrorCodeValidation,
		message,
		http.StatusBadRequest,
	)
}

// NewUnauthorizedError creates an unauthorized error
func NewUnauthorizedError(message string) *AppError {
	if message == "" {
		message = "Unauthorized"
	}
	return NewAppError(
		ErrorCodeUnauthorized,
		message,
		http.StatusUnauthorized,
	)
}

// NewForbiddenError creates a forbidden error
func NewForbiddenError(message string) *AppError {
	if message == "" {
		message = "Forbidden"
	}
	return NewAppError(
		ErrorCodeForbidden,
		message,
		http.StatusForbidden,
	)
}

// NewConflictError creates a conflict error
func NewConflictError(message string) *AppError {
	return NewAppError(
		ErrorCodeConflict,
		message,
		http.StatusConflict,
	)
}

// NewInternalError creates an internal error
func NewInternalError(message string) *AppError {
	if message == "" {
		message = "Internal server error"
	}
	return NewAppError(
		ErrorCodeInternal,
		message,
		http.StatusInternalServerError,
	)
}

// NewBadRequestError creates a bad request error
func NewBadRequestError(message string) *AppError {
	return NewAppError(
		ErrorCodeBadRequest,
		message,
		http.StatusBadRequest,
	)
}

// IsAppError checks if error is an AppError
func IsAppError(err error) bool {
	_, ok := err.(*AppError)
	return ok
}

// AsAppError extracts AppError from error chain
func AsAppError(err error) (*AppError, bool) {
	if err == nil {
		return nil, false
	}

	var appErr *AppError
	if e, ok := err.(*AppError); ok {
		return e, true
	}

	// Try to unwrap
	for err != nil {
		if e, ok := err.(*AppError); ok {
			appErr = e
			break
		}
		if unwrapper, ok := err.(interface{ Unwrap() error }); ok {
			err = unwrapper.Unwrap()
		} else {
			break
		}
	}

	return appErr, appErr != nil
}
