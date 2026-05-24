package workspace

// CLERK/MASON validation schema for runtime atlas.sys (perform output). Not emitted to disk.

#DriverStatus: "resolved" | "missing_warning" | "skipped_builtin"

#DriverRecord: {
	id:     string
	status: #DriverStatus
	source: string | *""
	message: string | *""
}

#AtlasSysV2: {
	schema:         "atlas.sys.v2"
	format:         "manifest"
	os:             string
	pixi_platform?: string
	hardware: {
		cpu_model?:       string
		logical_cores?:   int
		mem_total_kb?:    int
		nvml_ok?:         bool
		...
	}
	network: {
		wlan_count?: int
		...
	}
	peripherals: {
		input_sysfs_count?: int
		...
	}
	drivers?: [...#DriverRecord]
}
