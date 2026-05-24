// Wnętrze czarnej skrzynki — generuje finalny plik atlas.sys z pełnego zestawu sond (hardware / network / peripherals).
package bard_inventory

import "core:fmt"
import "core:os"
import "core:strings"

// Nazwa pliku w katalogu inventory (obok src/).
ATLAS_SYS_BASENAME :: "atlas.sys"
ATLAS_FORMAT_VERSION :: "1"

@(private = "file")
cpu_model_string :: proc(hw: ^Hardware_Report) -> string {
	if hw.cpu_model_len <= 0 {
		return "unknown"
	}
	return string(hw.cpu_model[:hw.cpu_model_len])
}

@(private = "file")
append_section_header :: proc(b: ^strings.Builder, title: string) {
	fmt.sbprintf(b, "[%s]\n", title)
}

// generate_atlas_sys — zapisuje finalny manifest (atlas.sys) do output_path.
generate_atlas_sys :: proc(
	hw: ^Hardware_Report,
	net: ^Network_Report,
	per: ^Peripheral_Report,
	output_path: string,
) -> bool {
	sb: strings.Builder
	strings.builder_init(&sb, context.temp_allocator)
	defer strings.builder_destroy(&sb)

	fmt.sbprintf(&sb, "schema=atlas.sys.v2\n")
	fmt.sbprintf(&sb, "format_version=%s\n", ATLAS_FORMAT_VERSION)
	fmt.sbprintf(&sb, "generator=bard_inventory\n\n")

	append_section_header(&sb, "hardware")
	fmt.sbprintf(&sb, "cpu_model=%q\n", cpu_model_string(hw))
	fmt.sbprintf(&sb, "logical_cores=%d\n", hw.logical_cores)
	fmt.sbprintf(&sb, "cpu_physical_packages=%d\n", hw.cpu_physical_packages)
	fmt.sbprintf(&sb, "cpu_cores_per_package=%d\n", hw.cpu_cores_per_package)
	fmt.sbprintf(&sb, "cpu_siblings_per_cpu=%d\n", hw.cpu_siblings_per_cpu)
	fmt.sbprintf(&sb, "mem_total_kb=%d\n", hw.mem_total_kb)
	fmt.sbprintf(&sb, "mem_available_kb=%d\n", hw.mem_available_kb)
	fmt.sbprintf(&sb, "mem_swap_total_kb=%d\n", hw.mem_swap_total_kb)
	fmt.sbprintf(&sb, "mem_swap_free_kb=%d\n", hw.mem_swap_free_kb)
	fmt.sbprintf(&sb, "mem_buffers_kb=%d\n", hw.mem_buffers_kb)
	fmt.sbprintf(&sb, "mem_cached_kb=%d\n", hw.mem_cached_kb)
	fmt.sbprintf(&sb, "gpu_drm_count=%d\n", hw.gpu_count)
	for i in 0 ..< hw.gpu_count {
		line := string(hw.gpu_lines[i][:hw.gpu_line_lens[i]])
		fmt.sbprintf(&sb, "gpu_drm_%d=%q\n", i, line)
	}
	fmt.sbprintf(&sb, "nvidia_proc_gpu_count=%d\n", hw.nvidia_proc_gpu_count)
	for i in 0 ..< hw.nvidia_proc_gpu_count {
		sn := string(hw.nvidia_gpu_snippets[i][:hw.nvidia_gpu_snippet_lens[i]])
		fmt.sbprintf(&sb, "nvidia_proc_%d=%q\n", i, sn)
	}
	nvml_flag := "false"
	if hw.nvml_ok {
		nvml_flag = "true"
	}
	fmt.sbprintf(&sb, "nvml_ok=%s\n", nvml_flag)
	fmt.sbprintf(&sb, "nvml_device_count=%d\n", hw.nvml_device_count)
	for i in 0 ..< hw.nvml_device_count {
		if i >= len(hw.nvml_device_names) {
			break
		}
		nm := string(hw.nvml_device_names[i][:hw.nvml_device_name_lens[i]])
		fmt.sbprintf(&sb, "nvml_device_%d=%q\n", i, nm)
	}

	append_section_header(&sb, "network")
	fmt.sbprintf(&sb, "tcp_socket_rows=%d\n", net.tcp_socket_rows)
	fmt.sbprintf(&sb, "udp_socket_rows=%d\n", net.udp_socket_rows)
	fmt.sbprintf(&sb, "tcp_listen_rows=%d\n", net.tcp_listen_rows)
	fmt.sbprintf(&sb, "tcp_established_rows=%d\n", net.tcp_established_rows)
	fmt.sbprintf(&sb, "wlan_count=%d\n", net.wlan_count)
	for i in 0 ..< net.wlan_count {
		w := string(net.wlan_iface_names[i][:net.wlan_iface_name_lens[i]])
		fmt.sbprintf(&sb, "wlan_%d=%q\n", i, w)
	}
	fmt.sbprintf(&sb, "bluetooth_hci_count=%d\n", net.bluetooth_hci_count)
	fmt.sbprintf(&sb, "drone_hint_udp_hits=%d\n", net.drone_hint_udp_hits)
	fmt.sbprintf(&sb, "drone_hint_udp6_hits=%d\n", net.drone_hint_udp6_hits)
	fmt.sbprintf(&sb, "ip_camera_tcp_hints=%d\n", net.ip_camera_tcp_hints)
	fmt.sbprintf(&sb, "ip_camera_udp_hints=%d\n", net.ip_camera_udp_hints)

	append_section_header(&sb, "peripherals")
	fmt.sbprintf(&sb, "input_sysfs_count=%d\n", per.input_sysfs_count)
	for i in 0 ..< per.input_sysfs_count {
		nm := string(per.input_sysfs_names[i][:per.input_sysfs_name_lens[i]])
		fmt.sbprintf(&sb, "input_%d=%q\n", i, nm)
	}
	fmt.sbprintf(&sb, "dev_input_event_count=%d\n", per.dev_input_event_count)
	fmt.sbprintf(&sb, "hid_keyboard_like=%d\n", per.hid_keyboard_like)
	fmt.sbprintf(&sb, "hid_mouse_like=%d\n", per.hid_mouse_like)
	fmt.sbprintf(&sb, "hid_touchpad_like=%d\n", per.hid_touchpad_like)
	fmt.sbprintf(&sb, "hid_button_like=%d\n", per.hid_button_like)
	fmt.sbprintf(&sb, "hid_other=%d\n", per.hid_other)
	fmt.sbprintf(&sb, "display_connector_count=%d\n", per.display_connector_count)
	for i in 0 ..< per.display_connector_count {
		did := string(per.display_connector_ids[i][:per.display_connector_id_lens[i]])
		dst := string(per.display_status_text[i][:per.display_status_lens[i]])
		fmt.sbprintf(&sb, "display_%d_id=%q\n", i, did)
		fmt.sbprintf(&sb, "display_%d_status=%q\n", i, dst)
	}

	text := strings.to_string(sb)
	return os.write_entire_file_from_string(output_path, text) == os.ERROR_NONE
}

// atlas_path_in_inventory — …/inventory/atlas.sys dla podanego katalogu inventory (folder zawierający src/).
atlas_path_in_inventory :: proc(inventory_directory: string, allocator := context.allocator) -> string {
	dir := strings.trim_right(inventory_directory, "/")
	path_buf: [1024]u8
	n := fmt.bprintf(path_buf[:], "%s/%s", dir, ATLAS_SYS_BASENAME)
	return strings.clone(string(path_buf[:n]), allocator)
}

// run_full_inventory_atlas — pełny przebieg i zapis finalnego atlas.sys.
run_full_inventory_atlas :: proc(inventory_directory: string) -> bool {
	hw: Hardware_Report
	net: Network_Report
	per: Peripheral_Report
	if !hardware_probe(&hw) {
		return false
	}
	network_probe(&net)
	peripherals_probe(&per)
	out := atlas_path_in_inventory(inventory_directory)
	defer delete(out)
	return generate_atlas_sys(&hw, &net, &per, out)
}
