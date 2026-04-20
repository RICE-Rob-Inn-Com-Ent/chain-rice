package main

import (
	"context"
	"fmt"
)

// Serve runs a full Audit then prints production deploy TODOs.
func (m *Rice) Serve(ctx context.Context, project string) error {
	if err := m.Audit(ctx); err != nil {
		return err
	}
	fmt.Printf("serve: TODO CHIEF — production deploy for %s\n", project)
	return nil
}
