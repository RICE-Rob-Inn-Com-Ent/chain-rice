// Wnętrze czarnej skrzynki — hardware: CPU (bebechy), RAM, GPU (DRM + /proc/driver/nvidia + NVML), Linux.
package bard_inventory

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

// Hardware_Report — CPU, pamięć, GPU (sysfs DRM, NVIDIA proc, opcjonalnie NVML).
Hardware_Report :: struct {
	cpu_model:        [256]u8,
	cpu_model_len:    int,
	logical_cores:    int,
	// Topologia / „bebechy” CPU z cpuinfo
	cpu_physical_packages: int, // max(physical id)+1
	cpu_cores_per_package: int,
	cpu_siblings_per_cpu:  int,
	mem_total_kb:          u64,
	mem_available_kb:      u64,
	mem_swap_total_kb:     u64,
	mem_swap_free_kb:      u64,
	mem_buffers_kb:        u64,
	mem_cached_kb:         u64,
	// GPU — DRM (PCI vendor/device)
	gpu_lines:     [8][128]u8,
	gpu_line_lens: [8]int,
	gpu_count:     int,
	// NVIDIA — /proc/driver/nvidia/gpus/*/information (skrót)
	nvidia_proc_gpu_count:    int,
	nvidia_gpu_snippets:      [8][384]u8,
	nvidia_gpu_snippet_lens:  [8]int,
	// NVML — libnvidia-ml.so (hardware_nvml.odin)
	nvml_ok:               bool,
	nvml_device_count:     int,
	nvml_device_names:     [8][96]u8,
	nvml_device_name_lens: [8]int,
}

@(private = "file")
parse_meminfo_kb :: proc(data: string, key: string) -> u64 {
	lines := strings.split_lines(data, context.temp_allocator)
	defer delete(lines)
	for line in lines {
		if strings.has_prefix(line, key) {
			colon := strings.index(line, ":")
			if colon < 0 {
				continue
			}
			rest := strings.trim_space(line[colon + 1:])
			fields := strings.fields(rest)
			if len(fields) >= 1 {
				if v, ok := strconv.parse_u64(fields[0]); ok {
					delete(fields)
					return v
				}
			}
			delete(fields)
		}
	}
	return 0
}

@(private = "file")
count_cpu_processors :: proc(data: string) -> int {
	n := 0
	lines := strings.split_lines(data, context.temp_allocator)
	defer delete(lines)
	for line in lines {
		if strings.has_prefix(line, "processor\t") || strings.has_prefix(line, "processor ") {
			n += 1
		}
	}
	return n
}

@(private = "file")
first_model_name :: proc(data: string, out: ^[256]u8) -> int {
	lines := strings.split_lines(data, context.temp_allocator)
	defer delete(lines)
	for line in lines {
		if strings.has_prefix(line, "model name\t") ||
		   strings.has_prefix(line, "model name ") ||
		   strings.has_prefix(line, "Processor\t") ||
		   strings.has_prefix(line, "Processor ") {
			colon := strings.index(line, ":")
			if colon < 0 {
				continue
			}
			name := strings.trim_space(line[colon + 1:])
			src := transmute([]u8) name
			m := min(len(src), len(out))
			copy(out[:m], src[:m])
			return m
		}
	}
	return 0
}

@(private = "file")
cpu_topology_from_cpuinfo :: proc(data: string, rep: ^Hardware_Report) {
	max_phys := -1
	cores := -1
	sibs := -1
	lines := strings.split_lines(data, context.temp_allocator)
	defer delete(lines)
	for line in lines {
		if strings.has_prefix(line, "physical id\t") || strings.has_prefix(line, "physical id ") {
			colon := strings.index(line, ":")
			if colon < 0 {
				continue
			}
			v, ok := strconv.parse_int(strings.trim_space(line[colon + 1:]), 10)
			if ok && v > max_phys {
				max_phys = v
			}
		}
		if strings.has_prefix(line, "cpu cores\t") || strings.has_prefix(line, "cpu cores ") {
			colon := strings.index(line, ":")
			if colon >= 0 {
				if v, ok := strconv.parse_int(strings.trim_space(line[colon + 1:]), 10); ok {
					cores = v
				}
			}
		}
		if strings.has_prefix(line, "siblings\t") || strings.has_prefix(line, "siblings ") {
			colon := strings.index(line, ":")
			if colon >= 0 {
				if v, ok := strconv.parse_int(strings.trim_space(line[colon + 1:]), 10); ok {
					sibs = v
				}
			}
		}
	}
	if max_phys >= 0 {
		rep.cpu_physical_packages = max_phys + 1
	}
	if cores > 0 {
		rep.cpu_cores_per_package = cores
	}
	if sibs > 0 {
		rep.cpu_siblings_per_cpu = sibs
	}
}

@(private = "file")
nvidia_proc_gpus_append :: proc(rep: ^Hardware_Report) {
	d, err := os.open("/proc/driver/nvidia/gpus")
	if err != os.ERROR_NONE {
		return
	}
	defer os.close(d)
	infos, e2 := os.read_dir(d, context.temp_allocator)
	if e2 != os.ERROR_NONE || len(infos) == 0 {
		return
	}
	defer delete(infos)
	for fi in infos {
		if !fi.is_dir {
			continue
		}
		if rep.nvidia_proc_gpu_count >= len(rep.nvidia_gpu_snippets) {
			break
		}
		pbuf: [512]u8
		pn := fmt.bprintf(pbuf[:], "/proc/driver/nvidia/gpus/%s/information", fi.name)
		ipath := string(pbuf[:pn])
		raw, ok := os.read_entire_file(ipath, context.temp_allocator)
		if !ok {
			continue
		}
		s := strings.trim_space(string(raw))
		// Pierwsza linia lub skrót do bufora
		first := s
		nl := strings.index(first, "\n")
		if nl >= 0 {
			first = first[:nl]
		}
		i := rep.nvidia_proc_gpu_count
		dst := rep.nvidia_gpu_snippets[i][:]
		src := transmute([]u8) first
		m := min(len(src), len(dst))
		copy(dst[:m], src[:m])
		rep.nvidia_gpu_snippet_lens[i] = m
		rep.nvidia_proc_gpu_count += 1
	}
}

// hardware_probe — CPU, RAM, DRM, NVIDIA proc, NVML; false tylko przy braku /proc/cpuinfo.
hardware_probe :: proc(rep: ^Hardware_Report) -> bool {
	clear(rep)

	cpu_bytes, ok_cpu := os.read_entire_file("/proc/cpuinfo", context.temp_allocator)
	if !ok_cpu {
		return false
	}
	cpu_raw := string(cpu_bytes)
	rep.logical_cores = count_cpu_processors(cpu_raw)
	rep.cpu_model_len = first_model_name(cpu_raw, &rep.cpu_model)
	cpu_topology_from_cpuinfo(cpu_raw, rep)

	if mem_bytes, ok := os.read_entire_file("/proc/meminfo", context.temp_allocator); ok {
		mem_raw := string(mem_bytes)
		rep.mem_total_kb = parse_meminfo_kb(mem_raw, "MemTotal:")
		rep.mem_available_kb = parse_meminfo_kb(mem_raw, "MemAvailable:")
		rep.mem_swap_total_kb = parse_meminfo_kb(mem_raw, "SwapTotal:")
		rep.mem_swap_free_kb = parse_meminfo_kb(mem_raw, "SwapFree:")
		rep.mem_buffers_kb = parse_meminfo_kb(mem_raw, "Buffers:")
		rep.mem_cached_kb = parse_meminfo_kb(mem_raw, "Cached:")
	}

	for i in 0 ..< 8 {
		vpath_buf: [256]u8
		dpath_buf: [256]u8
		nv := fmt.bprintf(vpath_buf[:], "/sys/class/drm/card%d/device/vendor", i)
		nd := fmt.bprintf(dpath_buf[:], "/sys/class/drm/card%d/device/device", i)
		vendor_s := string(vpath_buf[:nv])
		device_s := string(dpath_buf[:nd])
		vs, vok := os.read_entire_file(vendor_s, context.temp_allocator)
		ds, dok := os.read_entire_file(device_s, context.temp_allocator)
		if !vok && !dok {
			continue
		}
		vstr := strings.trim_space(string(vs))
		dstr := strings.trim_space(string(ds))
		if rep.gpu_count >= len(rep.gpu_lines) {
			break
		}
		gi := rep.gpu_count
		gbuf := rep.gpu_lines[gi][:]
		gn := fmt.bprintf(gbuf, "card%d vendor=%s device=%s", i, vstr, dstr)
		rep.gpu_line_lens[gi] = gn
		rep.gpu_count += 1
	}

	nvidia_proc_gpus_append(rep)
	hardware_nvml_append(rep)

	return true
}
