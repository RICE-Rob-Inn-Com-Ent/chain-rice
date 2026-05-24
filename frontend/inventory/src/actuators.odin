// Driver resolution + actuator hooks for BARD inventory (perform / think).
package bard_inventory

import "core:fmt"

// Driver_Status mirrors infra/out/cue/atlas_schema.cue #DriverStatus.
Driver_Status :: enum u8 {
	Resolved        = 0,
	MissingWarning  = 1,
	SkippedBuiltin  = 2,
}

Driver_Record :: struct {
	id:      string,
	status:  Driver_Status,
	source:  string,
	message: string,
}

// resolve_driver_builtin — maps a probed device id to a driver record (extend per OS).
resolve_driver_builtin :: proc(kind, probe_id: string) -> Driver_Record {
	return Driver_Record{
		id      = fmt.tprintf("%s:%s", kind, probe_id),
		status  = .Resolved,
		source  = "bard_inventory",
		message = "",
	}
}
