package kit

// TODO:
// [ ] implement validator singleton via go-playground/validator:
//     New() *validator.Validate — cached, thread-safe
//     register custom validators on init
// [ ] implement struct validation:
//     Validate(v any) error — returns ValidationError
//     ValidateCtx(ctx, v any) error — with context
// [ ] implement custom validators:
//     rice_uuid: validates UUID format
//     rice_chain_id: validates Cosmos chain ID format
//     rice_paseto: validates PASETO token structure
//     rice_nats_subject: validates NATS subject pattern
// [ ] implement ValidationError:
//     Field, Tag, Value per failed constraint
//     maps to ConnectRPC status code InvalidArgument

import (
	"fmt"
	"strings"
	"sync"

	"github.com/go-playground/validator/v10"
)

var (
	validateOnce sync.Once
	validateV    *validator.Validate
)

// Validator returns the shared [validator.Validate] instance (lazy init).
func Validator() *validator.Validate {
	validateOnce.Do(func() {
		validateV = validator.New()
	})
	return validateV
}

// ValidateStruct runs validation tags on s.
func ValidateStruct(s interface{}) error {
	return Validator().Struct(s)
}

// ValidateVar runs a single rule against a value (e.g. "required", "email").
func ValidateVar(field interface{}, tag string) error {
	return Validator().Var(field, tag)
}

// FieldLevel is passed to custom validation funcs.
type FieldLevel = validator.FieldLevel

// ValidationErrors is the typed error returned for struct validation failures.
type ValidationErrors = validator.ValidationErrors

// RegisterValidation registers a custom validation with the shared validator.
func RegisterValidation(tag string, fn validator.Func, callValidationEvenIfNull ...bool) error {
	return Validator().RegisterValidation(tag, fn, callValidationEvenIfNull...)
}

// RegisterValidationCtx registers a context-aware custom validation.
func RegisterValidationCtx(tag string, fn validator.FuncCtx, callValidationEvenIfNull ...bool) error {
	return Validator().RegisterValidationCtx(tag, fn, callValidationEvenIfNull...)
}

// RegisterAlias registers a tag alias (e.g. "cid" -> "len=32").
func RegisterAlias(alias, tag string) {
	Validator().RegisterAlias(alias, tag)
}

// ValidationErrorLines formats validator errors as one human-readable line per field.
func ValidationErrorLines(err error) []string {
	if err == nil {
		return nil
	}
	var ves validator.ValidationErrors
	if !As(err, &ves) {
		return []string{err.Error()}
	}
	lines := make([]string, 0, len(ves))
	for _, fe := range ves {
		lines = append(lines, fmt.Sprintf("%s: %s", fe.Namespace(), msgForTag(fe)))
	}
	return lines
}

// FormatValidationError joins validation lines for logs or HTTP 400 bodies.
func FormatValidationError(err error) string {
	lines := ValidationErrorLines(err)
	if len(lines) == 0 {
		return ""
	}
	return strings.Join(lines, "; ")
}

func msgForTag(fe validator.FieldError) string {
	switch fe.Tag() {
	case "required":
		return "required"
	case "email":
		return "must be a valid email"
	case "uuid":
		return "must be a valid UUID"
	default:
		return fe.Error()
	}
}
