# Database Interfaces Guide for Chain-Rice Project

## Current Project Structure Analysis

Your project is a **Cosmos SDK blockchain application** using the modern **collections** approach for state management. Here's where all database-related interfaces and types should be organized:

## 1. Protocol Buffer Definitions (Proto Files)
**Location**: `proto/chainrice/chainrice/v1/`

This is where you define the **data schemas** that will be stored in the database:

```
proto/chainrice/chainrice/v1/
├── genesis.proto    # Genesis state definitions
├── params.proto     # Module parameters
├── query.proto      # Query request/response types
├── tx.proto         # Transaction message types
└── [your-data].proto # Custom data structures
```

### Current Files:
- **`genesis.proto`**: Defines the initial state structure
- **`params.proto`**: Module configuration parameters
- **`query.proto`**: Query interfaces for reading data
- **`tx.proto`**: Transaction types for writing data

### What to Add:
- Create new `.proto` files for any custom data structures you need to store
- Examples: `user.proto`, `token.proto`, `nft.proto`, etc.

## 2. Generated Go Types
**Location**: `x/chainrice/types/`

After defining protobuf schemas, the generated Go types are placed here:

```
x/chainrice/types/
├── *.pb.go          # Generated protobuf types
├── keys.go          # Storage key definitions
├── params.go        # Parameter validation logic
├── genesis.go       # Genesis state helpers
├── codec.go         # Encoding/decoding setup
└── expected_keepers.go # Interface definitions for other modules
```

### Current Structure:
- **`keys.go`**: Defines storage prefixes and keys
- **`params.go`**: Parameter validation and defaults
- **Generated files**: `*.pb.go` files contain the actual data structures

## 3. Database Access Layer (Keeper)
**Location**: `x/chainrice/keeper/`

This is where you implement the **database interface logic**:

```
x/chainrice/keeper/
├── keeper.go        # Main keeper with collections schema
├── msg_server.go    # Transaction handlers
├── query.go         # Query handlers
├── genesis.go       # Genesis state management
└── [custom].go      # Custom database operations
```

### Current Implementation:
```go
// In keeper.go
type Keeper struct {
    storeService corestore.KVStoreService
    cdc          codec.Codec
    addressCodec address.Codec
    authority    []byte
    
    Schema collections.Schema           // Database schema
    Params collections.Item[types.Params] // Parameter storage
}
```

## 4. Best Practices for Adding New Database Interfaces

### Step 1: Define Data Structure in Proto
Create a new `.proto` file in `proto/chainrice/chainrice/v1/`:

```protobuf
// Example: user.proto
syntax = "proto3";
package chainrice.chainrice.v1;

message User {
  string address = 1;
  string name = 2;
  uint64 balance = 3;
  repeated string permissions = 4;
}
```

### Step 2: Add Storage Keys
Update `x/chainrice/types/keys.go`:

```go
// Add new storage prefixes
var (
    ParamsKey = collections.NewPrefix("p_chainrice")
    UserKey   = collections.NewPrefix("u_user")      // New
    TokenKey  = collections.NewPrefix("t_token")     // New
)
```

### Step 3: Update Keeper Schema
Modify `x/chainrice/keeper/keeper.go`:

```go
type Keeper struct {
    // ... existing fields ...
    
    // Add new collections
    Users  collections.Map[string, types.User]
    Tokens collections.IndexedMap[uint64, types.Token, TokenIndexes]
}

func NewKeeper(...) Keeper {
    sb := collections.NewSchemaBuilder(storeService)
    
    k := Keeper{
        // ... existing fields ...
        
        // Initialize new collections
        Users: collections.NewMap(sb, types.UserKey, "users", 
               collections.StringKey, codec.CollValue[types.User](cdc)),
        Tokens: collections.NewIndexedMap(sb, types.TokenKey, "tokens",
                collections.Uint64Key, codec.CollValue[types.Token](cdc),
                NewTokenIndexes(sb)),
    }
    
    // ... rest of initialization
}
```

### Step 4: Add CRUD Operations
Create dedicated keeper methods:

```go
// x/chainrice/keeper/user.go
func (k Keeper) GetUser(ctx context.Context, address string) (types.User, error) {
    return k.Users.Get(ctx, address)
}

func (k Keeper) SetUser(ctx context.Context, user types.User) error {
    return k.Users.Set(ctx, user.Address, user)
}

func (k Keeper) DeleteUser(ctx context.Context, address string) error {
    return k.Users.Remove(ctx, address)
}
```

### Step 5: Update Query Service
Add queries in `proto/chainrice/chainrice/v1/query.proto`:

```protobuf
service Query {
    // ... existing queries ...
    
    rpc GetUser(QueryUserRequest) returns (QueryUserResponse) {
        option (google.api.http).get = "/chain-rice/chainrice/v1/user/{address}";
    }
}

message QueryUserRequest {
    string address = 1;
}

message QueryUserResponse {
    User user = 1;
}
```

### Step 6: Update Transaction Service
Add transactions in `proto/chainrice/chainrice/v1/tx.proto`:

```protobuf
service Msg {
    // ... existing messages ...
    
    rpc CreateUser(MsgCreateUser) returns (MsgCreateUserResponse);
    rpc UpdateUser(MsgUpdateUser) returns (MsgUpdateUserResponse);
}
```

## 5. Directory Structure Summary

```
Your Database Interfaces Should Be Located In:

1. Data Schemas (Proto):     proto/chainrice/chainrice/v1/*.proto
2. Generated Types:          x/chainrice/types/*.pb.go
3. Storage Keys:             x/chainrice/types/keys.go
4. Database Logic:           x/chainrice/keeper/*.go
5. Query Handlers:           x/chainrice/keeper/query*.go
6. Transaction Handlers:     x/chainrice/keeper/msg_*.go
```

## 6. Code Generation Commands

After adding new proto files, regenerate the code:

```bash
# Generate protobuf files
make proto-gen

# Alternative using buf
buf generate
```

## 7. Current State Analysis

Your project currently has:
- ✅ Basic keeper structure with collections
- ✅ Parameter storage interface
- ✅ Genesis state management
- ✅ Query/transaction service definitions

**What's Missing for Full Database Interface:**
- Custom data type definitions beyond parameters
- Multiple collection types (Maps, IndexedMaps, etc.)
- Complex query interfaces
- Business logic database operations

## Conclusion

All database interfaces in your Cosmos SDK project should follow this layered approach:
1. **Proto definitions** for data schemas
2. **Generated types** for Go structures  
3. **Keeper collections** for database access
4. **CRUD methods** for business logic
5. **Query/TX services** for external access

This structure ensures type safety, efficient storage, and clear separation of concerns in your blockchain application.