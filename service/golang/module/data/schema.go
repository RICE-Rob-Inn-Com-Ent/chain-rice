package data

import "../../../module/data/fmt"

// GenerateStarSchemaSQL generates SQL CREATE TABLE statements for star schema
func GenerateStarSchemaSQL(schema StarSchema, provider string) string {
	var sql string

	// Create dimension tables
	for _, dim := range schema.Dimensions {
		sql += generateDimensionSQL(dim, provider) + "\n\n"
	}

	// Create fact table
	sql += generateFactSQL(schema.FactTable, schema.Dimensions, provider)

	return sql
}

func generateDimensionSQL(dim Dimension, provider string) string {
	columns := make([]string, len(dim.Columns))
	for i, col := range dim.Columns {
		colType := mapDWHType(col.Type, provider)
		nullable := ""
		if col.IsKey {
			nullable = "NOT NULL"
		}
		columns[i] = fmt.Sprintf("    %s %s %s", col.Name, colType, nullable)
	}

	pkCol := ""
	for _, col := range dim.Columns {
		if col.IsKey {
			pkCol = col.Name
			break
		}
	}

	pkConstraint := ""
	if pkCol != "" {
		pkConstraint = fmt.Sprintf(",\n    PRIMARY KEY (%s)", pkCol)
	}

	return fmt.Sprintf("CREATE TABLE %s (\n%s%s\n);", dim.Name, fmt.Sprintf("%s", columns[0]), pkConstraint)
}

func generateFactSQL(fact FactTable, dims []Dimension, provider string) string {
	columns := make([]string, len(fact.Columns))
	for i, col := range fact.Columns {
		colType := mapDWHType(col.Type, provider)
		columns[i] = fmt.Sprintf("    %s %s", col.Name, colType)
	}

	// Add foreign keys
	fkConstraints := make([]string, 0)
	for _, dim := range dims {
		for _, col := range dim.Columns {
			if col.IsKey {
				fkConstraints = append(fkConstraints, fmt.Sprintf("    FOREIGN KEY (%s_id) REFERENCES %s(%s)", dim.Name, dim.Name, col.Name))
				break
			}
		}
	}

	constraints := ""
	if len(fkConstraints) > 0 {
		constraints = ",\n" + fmt.Sprintf("%s", fkConstraints[0])
	}

	return fmt.Sprintf("CREATE TABLE %s (\n%s%s\n);", fact.Name, fmt.Sprintf("%s", columns[0]), constraints)
}

func mapDWHType(typ string, provider string) string {
	typeMap := map[string]map[string]string{
		"gcp": {
			"STRING":    "STRING",
			"INTEGER":   "INT64",
			"FLOAT":     "FLOAT64",
			"BOOLEAN":   "BOOL",
			"DATE":      "DATE",
			"TIMESTAMP": "TIMESTAMP",
		},
		"aws": {
			"STRING":    "VARCHAR(256)",
			"INTEGER":   "BIGINT",
			"FLOAT":     "DOUBLE PRECISION",
			"BOOLEAN":   "BOOLEAN",
			"DATE":      "DATE",
			"TIMESTAMP": "TIMESTAMP",
		},
		"azure": {
			"STRING":    "VARCHAR(256)",
			"INTEGER":   "BIGINT",
			"FLOAT":     "FLOAT",
			"BOOLEAN":   "BIT",
			"DATE":      "DATE",
			"TIMESTAMP": "DATETIME2",
		},
	}

	if providerMap, ok := typeMap[provider]; ok {
		if mapped, ok := providerMap[typ]; ok {
			return mapped
		}
	}
	return "STRING"
}
