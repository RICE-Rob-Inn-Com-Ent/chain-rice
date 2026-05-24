// Wspólne opcje skanowania (tryb, mock sysfs/proc) dla BARD inventory.
package bard_inventory

import "core:fmt"
import "core:strings"

Atlas_Run_Mode :: enum u8 {
	Full          = 0,
	Hardware      = 1,
	Network       = 2,
	Peripherals   = 3,
	Thermal       = 4,
}

Atlas_Scan_Options :: struct {
	mode:            Atlas_Run_Mode,
	mock_base:       string,
	json_out_path:   string,
	sha256_sidecar:  bool,
}

// atlas_host_path — ścieżka hosta lub mock_base+ścieżka (mirror /proc, /sys).
atlas_host_path :: proc(host_abs: string, opts: ^Atlas_Scan_Options) -> string {
	if opts == nil || len(opts.mock_base) == 0 {
		return host_abs
	}
	b := strings.trim_space(opts.mock_base)
	b = strings.trim_suffix(b, "/")
	if len(b) == 0 {
		return host_abs
	}
	if !strings.has_prefix(host_abs, "/") {
		return host_abs
	}
	return fmt.tprintf("%s%s", b, host_abs)
}
