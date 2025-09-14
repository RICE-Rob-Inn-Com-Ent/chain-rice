module chainrice/accounting-api

go 1.24.0

require (
	github.com/gin-contrib/cors v1.7.6
	github.com/gin-gonic/gin v1.10.1
	github.com/golang/protobuf v1.5.4
	github.com/google/uuid v1.6.0
	github.com/grpc-ecosystem/grpc-gateway v1.16.0
	github.com/mattn/go-sqlite3 v1.14.14
	google.golang.org/grpc v1.73.0
	google.golang.org/protobuf v1.36.6
	google.golang.org/genproto/googleapis/rpc v0.0.0-20250324211829-b45e905df463
	chainrice/shared v0.0.0
)

replace chainrice/shared => ../shared

replace google.golang.org/genproto => google.golang.org/genproto v0.0.0-20250324211829-b45e905df463