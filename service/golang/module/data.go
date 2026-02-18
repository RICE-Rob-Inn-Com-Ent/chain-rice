package module

import (
	"database/sql"

	"github.com/chainrice/rice/backend/app/services"
	"github.com/chainrice/rice/backend/module/cqrs"
	"github.com/chainrice/rice/backend/module/data"
	"github.com/chainrice/rice/backend/module/ddd"
	tokenpkg "github.com/chainrice/rice/backend/module/token"
)

// ============================================================================
// Cloud Provider Types
// ============================================================================

// CloudProvider represents cloud provider type (re-exported from services package)
type CloudProvider = services.CloudProvider

const (
	CloudProviderLocal = services.CloudProviderLocal
	CloudProviderAWS    = services.CloudProviderAWS
	CloudProviderGCP    = services.CloudProviderGCP
	CloudProviderAzure  = services.CloudProviderAzure
)

// ============================================================================
// Data Rows Interface
// ============================================================================

// Rows represents query result rows (compatible with sql.Rows and bigquery.RowIterator)
type Rows interface {
	Next() bool
	Scan(dest ...interface{}) error
	Close() error
	Err() error
}

// Schema represents table schema definition
type Schema struct {
	Fields []SchemaField
}

// SchemaField represents a single field in a schema
type SchemaField struct {
	Name        string
	Type        string
	Mode        string // NULLABLE, REQUIRED, REPEATED
	Description string
}

// SQLRowsAdapter adapts sql.Rows to Rows interface
type SQLRowsAdapter struct {
	*sql.Rows
}

// Next implements Rows interface
func (r *SQLRowsAdapter) Next() bool {
	return r.Rows.Next()
}

// Scan implements Rows interface
func (r *SQLRowsAdapter) Scan(dest ...interface{}) error {
	return r.Rows.Scan(dest...)
}

// Close implements Rows interface
func (r *SQLRowsAdapter) Close() error {
	return r.Rows.Close()
}

// Err implements Rows interface
func (r *SQLRowsAdapter) Err() error {
	return r.Rows.Err()
}

// ============================================================================
// Compatibility Exports - Re-export types from subpackages
// ============================================================================

// Database types (re-exported from module/data)
type (
	PostgresConfig     = data.PostgresConfig
	PostgresConnection = data.PostgresConnection
	PostgresKeeper     = data.PostgresKeeper
	MongoConfig        = data.MongoConfig
	MongoClient        = data.MongoClient
	MongoKeeper        = data.MongoKeeper
	RedisConfig        = data.RedisConfig
	RedisClient        = data.RedisClient
	RedisKeeper        = data.RedisKeeper
	CassandraConfig    = data.CassandraConfig
	CassandraClient    = data.CassandraClient
	CassandraKeeper    = data.CassandraKeeper
	CockroachConfig    = data.CockroachConfig
	CockroachConnection = data.CockroachConnection
	CockroachKeeper    = data.CockroachKeeper
)

// Database functions (re-exported from module/data)
var (
	PostgresDefaultConfig = data.PostgresDefaultConfig
	PostgresFromEnv       = data.PostgresFromEnv
	PostgresNewConnection = data.PostgresNewConnection
	PostgresNewKeeper     = data.PostgresNewKeeper
	MongoDefaultConfig    = data.MongoDefaultConfig
	MongoFromEnv          = data.MongoFromEnv
	MongoNewConnection    = data.MongoNewConnection
	MongoNewKeeper        = data.MongoNewKeeper
	RedisDefaultConfig    = data.RedisDefaultConfig
	RedisFromEnv          = data.RedisFromEnv
	RedisNewConnection    = data.RedisNewConnection
	RedisNewKeeper        = data.RedisNewKeeper
	CassandraDefaultConfig = data.CassandraDefaultConfig
	CassandraFromEnv       = data.CassandraFromEnv
	CassandraNewConnection = data.CassandraNewConnection
	CassandraNewKeeper     = data.CassandraNewKeeper
	CockroachDefaultConfig = data.CockroachDefaultConfig
	CockroachFromEnv       = data.CockroachFromEnv
	CockroachNewConnection = data.CockroachNewConnection
	CockroachNewKeeper     = data.CockroachNewKeeper
)

// Data warehouse types (commented out due to import cycle with module/store)
// Uncomment when import cycle is resolved
/*
type (
	DataWarehouseClient  = store.DataWarehouseClient
	DataWarehouseConfig  = store.DataWarehouseConfig
	DataWarehouseKeeper  = store.DataWarehouseKeeper
)

var (
	NewDataWarehouseClient = store.NewDataWarehouseClient
	DefaultDataWarehouseConfig = store.DefaultDataWarehouseConfig
	DataWarehouseFromEnv   = store.DataWarehouseFromEnv
	NewDataWarehouseKeeper = store.NewDataWarehouseKeeper
)
*/

// DDD types (re-exported from module/ddd)
type (
	Order              = ddd.Order
	OrderStatus        = ddd.OrderStatus
	OrderItem          = ddd.OrderItem
	Project            = ddd.Project
	ProjectStatus      = ddd.ProjectStatus
	Subdomain          = ddd.Subdomain
	SubdomainType      = ddd.SubdomainType
	Money              = ddd.Money
	Currency           = ddd.Currency
	Email              = ddd.Email
	Address            = ddd.Address
	OrderRepository    = ddd.OrderRepository
	ProjectRepository  = ddd.ProjectRepository
	PricingService     = ddd.PricingService
	RoutingService     = ddd.RoutingService
	CreateOrderCommand = ddd.CreateOrderCommand
	OrderItemDTO       = ddd.OrderItemDTO
	CreateOrderHandler = ddd.CreateOrderHandler
	CreateSubdomainCommand = ddd.CreateSubdomainCommand
	CreateSubdomainHandler = ddd.CreateSubdomainHandler
	GetSubdomainRoutingQuery = ddd.GetSubdomainRoutingQuery
	GetSubdomainRoutingResult = ddd.GetSubdomainRoutingResult
	GetSubdomainRoutingHandler = ddd.GetSubdomainRoutingHandler
	DDDKeeper          = ddd.DDDKeeper
)

// DDD functions (re-exported from module/ddd)
var (
	NewOrder              = ddd.NewOrder
	NewProject            = ddd.NewProject
	NewSubdomain          = ddd.NewSubdomain
	NewMoney              = ddd.NewMoney
	NewEmail              = ddd.NewEmail
	NewAddress            = ddd.NewAddress
	NewPricingService     = ddd.NewPricingService
	NewRoutingService     = ddd.NewRoutingService
	NewCreateOrderHandler = ddd.NewCreateOrderHandler
	NewCreateSubdomainHandler = ddd.NewCreateSubdomainHandler
	NewGetSubdomainRoutingHandler = ddd.NewGetSubdomainRoutingHandler
	NewDDDKeeper          = ddd.NewDDDKeeper
)

// CQRS types (re-exported from module/cqrs)
type (
	CQRSCommand         = cqrs.CQRSCommand
	CQRSCommandHandler  = cqrs.CQRSCommandHandler
	CQRSCommandBus      = cqrs.CQRSCommandBus
	CQRSQuery           = cqrs.CQRSQuery
	CQRSQueryHandler    = cqrs.CQRSQueryHandler
	CQRSQueryBus        = cqrs.CQRSQueryBus
	CQRSEvent           = cqrs.CQRSEvent
	CQRSEventStore      = cqrs.CQRSEventStore
	CQRSPostgresEventStore = cqrs.CQRSPostgresEventStore
	CQRSDomainEvent     = cqrs.CQRSDomainEvent
	CQRSBaseEvent       = cqrs.CQRSBaseEvent
	CQRSUserCreatedEvent = cqrs.CQRSUserCreatedEvent
	CQRSUserUpdatedEvent = cqrs.CQRSUserUpdatedEvent
	CQRSUserDeletedEvent = cqrs.CQRSUserDeletedEvent
	CQRSOrderCreatedEvent = cqrs.CQRSOrderCreatedEvent
	CQRSOrderPaidEvent = cqrs.CQRSOrderPaidEvent
	CQRSOrderShippedEvent = cqrs.CQRSOrderShippedEvent
	CQRSOrderDeliveredEvent = cqrs.CQRSOrderDeliveredEvent
	CQRSOrderCancelledEvent = cqrs.CQRSOrderCancelledEvent
	CQRSKeeper          = cqrs.CQRSKeeper
	CQRSCreateUserCommand = cqrs.CQRSCreateUserCommand
	CQRSUpdateUserCommand = cqrs.CQRSUpdateUserCommand
	CQRSDeleteUserCommand = cqrs.CQRSDeleteUserCommand
	CQRSGetUserByIDQuery = cqrs.CQRSGetUserByIDQuery
	CQRSListUsersQuery  = cqrs.CQRSListUsersQuery
	CQRSSearchUsersQuery = cqrs.CQRSSearchUsersQuery
)

// CQRS functions (re-exported from module/cqrs)
var (
	CQRSNewCommandBus = cqrs.CQRSNewCommandBus
	CQRSNewQueryBus   = cqrs.CQRSNewQueryBus
	CQRSNewPostgresEventStore = cqrs.CQRSNewPostgresEventStore
	CQRSNewKeeper     = cqrs.CQRSNewKeeper
)

// Token module types and constants (re-exported from module/token)
const (
	ModuleName = tokenpkg.TokenModuleName
)

type (
	Keeper = tokenpkg.TokenKeeper
	Module = tokenpkg.TokenModule
	TokenAppModule = tokenpkg.TokenAppModule
	TokenAuthKeeper = tokenpkg.TokenAuthKeeper
	TokenBankKeeper = tokenpkg.TokenBankKeeper
)

var (
	TokenNewKeeper = tokenpkg.TokenNewKeeper
	TokenNewAppModule = tokenpkg.TokenNewAppModule
	TokenRegisterInterfaces = tokenpkg.TokenRegisterInterfaces
	TokenNewMsgServerImpl = tokenpkg.TokenNewMsgServerImpl
	TokenNewQueryServerImpl = tokenpkg.TokenNewQueryServerImpl
	TokenDefaultParams = tokenpkg.TokenDefaultParams
	TokenNewParams = tokenpkg.TokenNewParams
)

// Data engineering factory (re-exported from module/data)
type (
	DataEngineeringFactory = data.DataEngineeringFactory
	StarSchema            = data.StarSchema
	DataVaultSchema       = data.DataVaultSchema
	FactTable             = data.FactTable
	Dimension             = data.Dimension
	FactColumn            = data.FactColumn
	DimColumn             = data.DimColumn
)

var (
	NewDataEngineeringFactory = data.NewDataEngineeringFactory
	NewDataEngineeringFactoryWithProvider = data.NewDataEngineeringFactoryWithProvider
	GenerateStarSchemaSQL    = data.GenerateStarSchemaSQL
)

// DWH Keeper (commented out due to import cycle with module/store)
// Uncomment when import cycle is resolved
/*
type DWHKeeper struct {
	dwKeeper *store.DataWarehouseKeeper
}

func NewDWHKeeper(dwKeeper *store.DataWarehouseKeeper) *DWHKeeper {
	return &DWHKeeper{
		dwKeeper: dwKeeper,
	}
}
*/

// DWHKeeper is commented out due to import cycle with module/store
// Uncomment when import cycle is resolved
/*
// CreateStarSchema creates tables for a star schema
func (k *DWHKeeper) CreateStarSchema(ctx context.Context, schema data.StarSchema) error {
	// Create dimension tables first
	for _, dim := range schema.Dimensions {
		// Build CREATE TABLE statement
		// Implementation would generate SQL and execute via dwKeeper
		_ = dim
	}

	// Create fact table
	_ = schema.FactTable

	return nil
}

// GetDWKeeper returns the underlying data warehouse keeper
func (k *DWHKeeper) GetDWKeeper() *store.DataWarehouseKeeper {
	return k.dwKeeper
}
*/