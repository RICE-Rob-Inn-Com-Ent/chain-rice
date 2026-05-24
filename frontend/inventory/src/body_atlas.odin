// body atlas.sys v2 — os + pixi_platform + hardware + driver roll-up for pour/perform/forge.
package bard_inventory

import "core:fmt"
import "core:os"
import "core:strings"

@(private = "file")
runtime_os_name :: proc() -> string {
	when ODIN_OS == .Linux {
		return "linux"
	}
	when ODIN_OS == .Windows {
		return "windows"
	}
	when ODIN_OS == .Darwin {
		return "darwin"
	}
	return "unknown"
}

@(private = "file")
emit_driver :: proc(b: ^strings.Builder, idx: ^int, kind, value: string) {
	fmt.sbprintf(b, "%d=id:%s:%s status=resolved source=body-odin\n", idx^, kind, value)
	idx^ += 1
}

// generate_body_atlas_sys — writes repo-root atlas.sys (v2 manifest + pixi_platform).
generate_body_atlas_sys :: proc(
	hw: ^Hardware_Report,
	net: ^Network_Report,
	per: ^Peripheral_Report,
	pixi_platform: string,
	output_path: string,
) -> bool {
	sb: strings.Builder
	strings.builder_init(&sb, context.temp_allocator)
	defer strings.builder_destroy(&sb)

	fmt.sbprintf(&sb, "schema=atlas.sys.v2\n")
	fmt.sbprintf(&sb, "format=manifest\n")
	fmt.sbprintf(&sb, "os=%s\n", runtime_os_name())
	fmt.sbprintf(&sb, "pixi_platform=%s\n", pixi_platform)
	modular := "false"
	if body_wants_modular(hw) {
		modular = "true"
	}
	fmt.sbprintf(&sb, "modular_stack=%s\n", modular)
	fmt.sbprintf(&sb, "generator=body-odin\n\n")

	fmt.sbprintf(&sb, "[hardware]\n")
	fmt.sbprintf(&sb, "cpu_model=%q\n", cpu_model_string(hw))
	fmt.sbprintf(&sb, "logical_cores=%d\n", hw.logical_cores)
	fmt.sbprintf(&sb, "mem_total_kb=%d\n", hw.mem_total_kb)
	nvml := "false"
	if hw.nvml_ok {
		nvml = "true"
	}
	fmt.sbprintf(&sb, "nvml_ok=%s\n", nvml)
	fmt.sbprintf(&sb, "gpu_drm_count=%d\n", hw.gpu_count)
	fmt.sbprintf(&sb, "nvml_device_count=%d\n", hw.nvml_device_count)
	fmt.sbprintf(&sb, "\n")

	fmt.sbprintf(&sb, "[network]\n")
	fmt.sbprintf(&sb, "wlan_count=%d\n", net.wlan_count)
	fmt.sbprintf(&sb, "\n")

	fmt.sbprintf(&sb, "[peripherals]\n")
	fmt.sbprintf(&sb, "input_sysfs_count=%d\n", per.input_sysfs_count)
	fmt.sbprintf(&sb, "\n")

	fmt.sbprintf(&sb, "[drivers]\n")
	idx := 0
	for i in 0 ..< per.input_sysfs_count {
		nm := string(per.input_sysfs_names[i][:per.input_sysfs_name_lens[i]])
		emit_driver(&sb, &idx, "input", nm)
	}
	for i in 0 ..< hw.gpu_count {
		line := string(hw.gpu_lines[i][:hw.gpu_line_lens[i]])
		emit_driver(&sb, &idx, "gpu", line)
	}
	for i in 0 ..< hw.nvml_device_count {
		if i >= len(hw.nvml_device_names) {
			break
		}
		nm := string(hw.nvml_device_names[i][:hw.nvml_device_name_lens[i]])
		emit_driver(&sb, &idx, "nvml", nm)
	}
	if idx == 0 {
		fmt.sbprintf(&sb, "0=id:platform:host status=skipped_builtin source=body-odin\n")
		idx = 1
	}
	fmt.sbprintf(&sb, "count=%d\n", idx)

	text := strings.to_string(sb)
	return os.write_entire_file_from_string(output_path, text) == os.ERROR_NONE
}

// body_materialize — scan body, write atlas.sys, sync pixi.toml to one platform.
body_materialize :: proc(repo_root: string, atlas_output_path: string) -> bool {
	hw: Hardware_Report
	net: Network_Report
	per: Peripheral_Report
	if !hardware_probe(&hw) {
		return false
	}
	network_probe(&net)
	peripherals_probe(&per)

	platform := detect_pixi_platform()
	if !generate_body_atlas_sys(&hw, &net, &per, platform, atlas_output_path) {
		return false
	}
	return sync_pixi_toml_body(repo_root, platform, &hw)
}
