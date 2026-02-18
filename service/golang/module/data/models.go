package data

// FactColumn represents a column in a fact table
type FactColumn struct {
	Name        string
	Type        string
	IsMeasure   bool
	Aggregation string // sum, avg, count, min, max
}

// DimColumn represents a column in a dimension table
type DimColumn struct {
	Name        string
	Type        string
	IsKey       bool
	IsAttribute bool
	SCDType     string // Type 1, Type 2, Type 3
}

// FactTable represents a fact table in dimensional model
type FactTable struct {
	Name    string
	Columns []FactColumn
	Grain   string // daily, transactional, periodic snapshot
}

// Dimension represents a dimension table
type Dimension struct {
	Name         string
	Columns      []DimColumn
	SCDType      string // Type 1, Type 2, Type 3
	SurrogateKey bool
}

// StarSchema represents Kimball star schema
type StarSchema struct {
	FactTable  FactTable
	Dimensions []Dimension
}

// NormalizedSchema represents Inmon normalized approach
type NormalizedSchema struct {
	Tables []NormalizedTable
}

// NormalizedTable represents a table in normalized schema
type NormalizedTable struct {
	Name    string
	Columns []DimColumn
	Keys    []string
}

// Hub represents a hub in Data Vault
type Hub struct {
	Name         string
	BusinessKey  string
	LoadDate     string
	RecordSource string
}

// Satellite represents a satellite in Data Vault
type Satellite struct {
	Name         string
	HubName      string
	Columns      []DimColumn
	LoadDate     string
	LoadEndDate  string
	RecordSource string
}

// Link represents a link in Data Vault
type Link struct {
	Name         string
	HubNames     []string
	LoadDate     string
	RecordSource string
}

// DataVaultSchema represents Data Vault 2.0 schema
type DataVaultSchema struct {
	Hubs       []Hub
	Satellites []Satellite
	Links      []Link
}
