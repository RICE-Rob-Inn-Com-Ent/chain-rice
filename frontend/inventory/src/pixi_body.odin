// Pixi platform sync from machine body (no shell) — used by body_main before pixi install.
package bard_inventory

import "core:fmt"
import "core:os"
import "core:strings"

// detect_pixi_platform — conda-forge / pixi platform slug for this host.
detect_pixi_platform :: proc() -> string {
	when ODIN_OS == .Linux {
		when ODIN_ARCH == .arm64 {
			return "linux-aarch64"
		}
		return "linux-64"
	}
	when ODIN_OS == .Darwin {
		when ODIN_ARCH == .arm64 {
			return "osx-arm64"
		}
		return "osx-64"
	}
	when ODIN_OS == .Windows {
		return "win-64"
	}
	return "linux-64"
}

@(private = "file")
replace_platforms_line :: proc(content: string, platform: string, allocator := context.temp_allocator) -> (string, bool) {
	new_line := fmt.tprintf(`platforms = ["%s"]`, platform)
	lines := strings.split_lines(content, allocator)
	defer delete(lines)
	found := false
	for &line in lines {
		trimmed := strings.trim_space(line)
		if strings.has_prefix(trimmed, "platforms ") || strings.has_prefix(trimmed, "platforms=") {
			line = new_line
			found = true
			break
		}
	}
	if !found {
		return "", false
	}
	return strings.join(lines[:], "\n", allocator), true
}

// body_wants_modular — NVIDIA stack (NVML or /proc/driver/nvidia) → modular-channels (mojo, max).
// DRM iGPU alone does not enable modular (avoids broken channel on CPU-only paths).
body_wants_modular :: proc(hw: ^Hardware_Report) -> bool {
	return hw.nvml_ok || hw.nvml_device_count > 0 || hw.nvidia_proc_gpu_count > 0
}

@(private = "file")
replace_line_prefix :: proc(
	lines: ^[dynamic]string,
	prefix: string,
	new_line: string,
) -> bool {
	found := false
	for &line in lines^ {
		trimmed := strings.trim_space(line)
		if strings.has_prefix(trimmed, prefix) {
			line = new_line
			found = true
			break
		}
	}
	return found
}

@(private = "file")
ordered_insert :: proc(lines: ^[dynamic]string, at: int, line: string) {
	if at < 0 || at > len(lines^) {
		append(lines, line)
		return
	}
	append(lines, "")
	copy(lines[at + 1:], lines[at:])
	lines[at] = line
}

@(private = "file")
filter_dependency_lines :: proc(lines: ^[dynamic]string, names: []string) {
	filtered := make([dynamic]string, 0, len(lines^), context.temp_allocator)
	for line in lines^ {
		trimmed := strings.trim_space(line)
		skip := false
		for name in names {
			if strings.has_prefix(trimmed, name) {
				skip = true
				break
			}
		}
		if !skip {
			append(&filtered, line)
		}
	}
	clear(lines)
	for line in filtered {
		append(lines, line)
	}
}

// sync_pixi_toml_body — platforms, channels, and optional mojo/max from hardware body.
sync_pixi_toml_body :: proc(repo_root: string, platform: string, hw: ^Hardware_Report) -> bool {
	root := strings.trim_right(strings.trim_space(repo_root), "/")
	path := fmt.tprintf("%s/pixi.toml", root)
	data, ok := os.read_entire_file(path)
	if !ok {
		return false
	}
	lines := strings.split_lines(string(data), context.temp_allocator)
	dyn: [dynamic]string
	for line in lines {
		append(&dyn, line)
	}
	defer delete(dyn)

	modular := body_wants_modular(hw)
	channels_line: string
	if modular {
		channels_line = `channels = ["conda-forge", "modular-channels"]`
	} else {
		channels_line = `channels = ["conda-forge"]`
	}
	if !replace_line_prefix(&dyn, "channels", channels_line) {
		return false
	}
	if !replace_line_prefix(&dyn, "platforms", fmt.tprintf(`platforms = ["%s"]`, platform)) {
		return false
	}
	if !modular {
		filter_dependency_lines(&dyn, []string{"mojo =", "max ="})
	} else {
		has_mojo, has_max := false, false
		for line in dyn {
			t := strings.trim_space(line)
			if strings.has_prefix(t, "mojo =") {
				has_mojo = true
			}
			if strings.has_prefix(t, "max =") {
				has_max = true
			}
		}
		insert_at := -1
		for line, i in dyn {
			if strings.has_prefix(strings.trim_space(line), "python =") {
				insert_at = i + 1
				break
			}
		}
		if insert_at >= 0 {
			if !has_mojo {
				inject := "mojo = \"0.26.1\"        # Mojo — body-odin (GPU/NVML)"
				ordered_insert(&dyn, insert_at, inject)
				insert_at += 1
			}
			if !has_max {
				inject := "max = \"24.4.0\"         # MAX — body-odin (GPU/NVML)"
				ordered_insert(&dyn, insert_at, inject)
			}
		}
	}
	updated := strings.join(dyn[:], "\n", context.temp_allocator)
	if !strings.has_suffix(updated, "\n") {
		updated = fmt.tprintf("%s\n", updated)
	}
	return os.write_entire_file_from_string(path, updated) == os.ERROR_NONE
}

// sync_pixi_toml_platforms — rewrite `platforms = [...]` in repo-root pixi.toml for this body only.
sync_pixi_toml_platforms :: proc(repo_root: string, platform: string) -> bool {
	root := strings.trim_right(strings.trim_space(repo_root), "/")
	path := fmt.tprintf("%s/pixi.toml", root)
	data, ok := os.read_entire_file(path)
	if !ok {
		return false
	}
	updated, ok2 := replace_platforms_line(string(data), platform)
	if !ok2 {
		return false
	}
	if !strings.has_suffix(updated, "\n") {
		updated = fmt.tprintf("%s\n", updated)
	}
	return os.write_entire_file_from_string(path, updated) == os.ERROR_NONE
}
