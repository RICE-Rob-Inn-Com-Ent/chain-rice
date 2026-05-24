package kit

// Struct and Var validation via go-playground/validator with SMITH [*Error] responses.
// Cross-field rules like required_if, excluded_if, eqfield, etc. are built into v10;
// this file adds rice-specific uuid (via [Validate]) and slug tags.

import (
	"errors"
	"fmt"
	"net/http"
	"reflect"
	"regexp"
	"strings"
	"sync"

	"github.com/go-playground/validator/v10"
	"google.golang.org/grpc/codes"
)

var (
	validateOnce sync.Once
	validateV    *validator.Validate

	slugPattern = regexp.MustCompile(`^[a-z0-9]+(?:-[a-z0-9]+)*$`)

	// regMu serializes tag registration; the [*validator.Validate] itself is safe for
	// concurrent Struct/Var after registrations complete (register at process init).
	regMu sync.Mutex
)

// Validator returns the shared [*validator.Validate] (lazy init, cached struct tags).
func Validator() *validator.Validate {
	validateOnce.Do(initValidator)
	return validateV
}

func initValidator() {
	v := validator.New(validator.WithRequiredStructEnabled())
	v.RegisterTagNameFunc(jsonFieldName)
	must(v.RegisterValidation("uuid", validateRiceUUID))
	must(v.RegisterValidation("slug", validateSlug))
	validateV = v
}

func must(err error) {
	if err != nil {
		panic("kit.validate init: " + err.Error())
	}
}

// jsonFieldName prefers the `json` name for error detail keys; falls back to the struct field name.
func jsonFieldName(fld reflect.StructField) string {
	tag := fld.Tag.Get("json")
	if tag == "" || tag == "-" {
		return fld.Name
	}
	name := strings.SplitN(tag, ",", 2)[0]
	if name == "" || name == "-" {
		return fld.Name
	}
	return name
}

// validateRiceUUID replaces the library `uuid` tag so strings match [Validate] (google/uuid rules).
func validateRiceUUID(fl validator.FieldLevel) bool {
	switch x := fl.Field().Interface().(type) {
	case string:
		return x == "" || Validate(x)
	case *string:
		if x == nil {
			return true
		}
		return *x == "" || Validate(*x)
	case UUID:
		return !IsNil(x)
	case *UUID:
		if x == nil {
			return true
		}
		return !IsNil(*x)
	default:
		return false
	}
}

// validateSlug enforces URL-friendly slugs: lowercase [a-z0-9], single hyphens between segments.
func validateSlug(fl validator.FieldLevel) bool {
	switch x := fl.Field().Interface().(type) {
	case string:
		return x == "" || slugPattern.MatchString(x)
	case *string:
		if x == nil {
			return true
		}
		return *x == "" || slugPattern.MatchString(*x)
	default:
		return false
	}
}

// Struct validates s using `validate` tags. On failure it returns a [*Error] with HTTP 400,
// code VALIDATION_FAILED, and Details keyed by JSON field names (or struct field names).
func Struct(s any) error {
	if err := Validator().Struct(s); err != nil {
		return wrapValidationErr(err, "validator.Struct")
	}
	return nil
}

// ValidateStruct is an alias for [Struct].
func ValidateStruct(s any) error {
	return Struct(s)
}

// Var validates a single value against tag (e.g. "required,email", "uuid").
// On failure it returns the same [*Error] shape as [Struct].
func Var(v any, tag string) error {
	if err := Validator().Var(v, tag); err != nil {
		return wrapValidationErr(err, "validator.Var")
	}
	return nil
}

// ValidateVar is an alias for [Var].
func ValidateVar(field any, tag string) error {
	return Var(field, tag)
}

// RegisterCustomTag registers a validation tag on the shared validator.
// Call only from init() or other startup paths; if you register after validators
// are in use, use this function (it takes regMu). Prefer a single init order per process.
func RegisterCustomTag(tag string, fn validator.Func) error {
	regMu.Lock()
	defer regMu.Unlock()
	return Validator().RegisterValidation(tag, fn)
}

// RegisterValidation registers a custom validation (locked; safe vs concurrent first Struct).
func RegisterValidation(tag string, fn validator.Func, callValidationEvenIfNull ...bool) error {
	regMu.Lock()
	defer regMu.Unlock()
	return Validator().RegisterValidation(tag, fn, callValidationEvenIfNull...)
}

// RegisterValidationCtx registers a context-aware validation (locked).
func RegisterValidationCtx(tag string, fn validator.FuncCtx, callValidationEvenIfNull ...bool) error {
	regMu.Lock()
	defer regMu.Unlock()
	return Validator().RegisterValidationCtx(tag, fn, callValidationEvenIfNull...)
}

// RegisterAlias registers a tag alias (locked).
func RegisterAlias(alias, tag string) {
	regMu.Lock()
	defer regMu.Unlock()
	Validator().RegisterAlias(alias, tag)
}

func wrapValidationErr(err error, op string) error {
	var inv *validator.InvalidValidationError
	if errors.As(err, &inv) {
		return Internal("validation: invalid input").Wrap(err, op)
	}
	var ves validator.ValidationErrors
	if errors.As(err, &ves) {
		return New("VALIDATION_FAILED", "validation failed", http.StatusBadRequest, codes.InvalidArgument).
			WithDetails(validationDetailsMap(ves)).
			Wrap(err, op)
	}
	return New("VALIDATION_FAILED", err.Error(), http.StatusBadRequest, codes.InvalidArgument).Wrap(err, op)
}

func validationDetailsMap(ves validator.ValidationErrors) map[string]any {
	details := make(map[string]any, len(ves))
	for _, fe := range ves {
		key := validationDetailKey(fe)
		msg := validationFailureReason(fe)
		if prev, ok := details[key]; ok {
			details[key] = fmt.Sprintf("%v; %s", prev, msg)
			continue
		}
		details[key] = msg
	}
	return details
}

func validationDetailKey(fe validator.FieldError) string {
	if ns := fe.Namespace(); ns != "" {
		return ns
	}
	if f := fe.Field(); f != "" {
		return f
	}
	return "_"
}

func validationFailureReason(fe validator.FieldError) string {
	tag := fe.ActualTag()
	if param := fe.Param(); param != "" {
		return fmt.Sprintf("%s (param=%q)", tag, param)
	}
	return tag
}

// FieldLevel is passed to custom validation funcs.
type FieldLevel = validator.FieldLevel

// ValidationErrors is the typed slice from go-playground/validator.
type ValidationErrors = validator.ValidationErrors

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
		lines = append(lines, fmt.Sprintf("%s: %s", fe.Namespace(), validationFailureReason(fe)))
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
