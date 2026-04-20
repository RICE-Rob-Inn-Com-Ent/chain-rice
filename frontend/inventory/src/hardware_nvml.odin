// Opcjonalny NVML (libnvidia-ml.so) — liczba urządzeń i nazwa; bez linkowania statycznego (dynlib).
package bard_inventory

import "core:c"
import "core:dynlib"
import "core:fmt"
import "core:strings"

when ODIN_OS == .Linux {
	NVML_LIB :: "libnvidia-ml.so.1"
} else {
	NVML_LIB :: ""
}

NVML_SUCCESS :: c.int(0)

nvmlReturn_t :: c.int
nvmlDevice_t :: rawptr

nvmlInit_v2_t :: proc() -> nvmlReturn_t
nvmlShutdown_t :: proc() -> nvmlReturn_t
nvmlDeviceGetCount_t :: proc(count: ^c.uint) -> nvmlReturn_t
nvmlDeviceGetHandleByIndex_v2_t :: proc(index: c.uint, device: ^nvmlDevice_t) -> nvmlReturn_t
nvmlDeviceGetName_t :: proc(device: nvmlDevice_t, name: [^]c.char, length: c.uint) -> nvmlReturn_t

@(private = "file")
nvml_string_trim_null :: proc(s: string) -> string {
	idx := strings.index_byte(s, 0)
	if idx >= 0 {
		return s[:idx]
	}
	return s
}

// hardware_nvml_append — dopisuje NVML do raportu; przy braku biblioteki zostawia nvml_ok == false.
hardware_nvml_append :: proc(rep: ^Hardware_Report) {
	when ODIN_OS != .Linux {
		return
	}
	if len(NVML_LIB) == 0 {
		return
	}
	lib, ok := dynlib.load_library(NVML_LIB)
	if !ok {
		return
	}
	defer dynlib.unload_library(lib)

	p_init, ok_i := dynlib.symbol_address(lib, "nvmlInit_v2")
	p_shutdown, ok_s := dynlib.symbol_address(lib, "nvmlShutdown")
	p_count, ok_c := dynlib.symbol_address(lib, "nvmlDeviceGetCount")
	p_handle, ok_h := dynlib.symbol_address(lib, "nvmlDeviceGetHandleByIndex_v2")
	p_name, ok_n := dynlib.symbol_address(lib, "nvmlDeviceGetName")
	if !ok_i || !ok_s || !ok_c || !ok_h || !ok_n {
		return
	}

	init := cast(nvmlInit_v2_t)p_init
	shutdown := cast(nvmlShutdown_t)p_shutdown
	get_count := cast(nvmlDeviceGetCount_t)p_count
	get_handle := cast(nvmlDeviceGetHandleByIndex_v2_t)p_handle
	get_name := cast(nvmlDeviceGetName_t)p_name

	if init() != NVML_SUCCESS {
		return
	}
	defer shutdown()

	cnt: c.uint
	if get_count(&cnt) != NVML_SUCCESS {
		return
	}
	rep.nvml_ok = true
	rep.nvml_device_count = int(cnt)
	max_dev := min(int(cnt), len(rep.nvml_device_names))
	for i in 0 ..< max_dev {
		dev: nvmlDevice_t
		if get_handle(c.uint(i), &dev) != NVML_SUCCESS {
			continue
		}
		buf: [96]c.char
		if get_name(dev, cast([^]c.char)&buf[0], c.uint(len(buf))) != NVML_SUCCESS {
			continue
		}
		odin_name := cstring(&buf[0])
		s := string(odin_name)
		s = nvml_string_trim_null(s)
		dst := rep.nvml_device_names[i][:]
		src := transmute([]u8) s
		n := min(len(src), len(dst))
		copy(dst[:n], src[:n])
		rep.nvml_device_name_lens[i] = n
	}
}
