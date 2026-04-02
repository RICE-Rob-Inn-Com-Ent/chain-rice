package web

// TODO:
// [ ] implement error handler for Fiber:
//     ErrorHandler(ctx *fiber.Ctx, err error) error
//     converts: RiceError → fiber.Error → JSON response
//     converts: ConnectRPC errors → HTTP errors
// [ ] implement error response format:
//     { code: string, message: string, details: [] }
//     matches proto google.rpc.Status format

import "errors"

var (
	errNilBucket = errors.New("web: nil blob bucket")
	errNilKeeper = errors.New("web: nil secrets keeper")
)
