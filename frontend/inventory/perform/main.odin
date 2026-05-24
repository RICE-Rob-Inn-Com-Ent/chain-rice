package main

import "core:fmt"
import "core:os"
import "core:strings"

Atlas :: struct {
	touch:      [dynamic]string,
	ears:       [dynamic]string,
	eyes:       [dynamic]string,
	perception: [dynamic]string,
	motion:     [dynamic]string,
}

path_exists :: proc(path: string) -> bool {
	fi, err := os.stat(path, context.temp_allocator)
	if err == os.ERROR_NONE {
		os.file_info_delete(fi, context.temp_allocator)
	}
	return err == os.ERROR_NONE
}

append_unique :: proc(dst: ^[dynamic]string, value: string) {
	for existing in dst^ {
		if existing == value {
			return
		}
	}
	append(dst, strings.clone(value, context.allocator))
}

read_trimmed :: proc(path: string) -> (string, bool) {
	raw, err := os.read_entire_file(path, context.temp_allocator)
	if err != os.ERROR_NONE {
		return "", false
	}
	return strings.trim_space(string(raw)), true
}

scan_linux_touch :: proc(a: ^Atlas) {
	for i in 0 ..< 64 {
		p := fmt.tprintf("/sys/class/input/input%d/name", i)
		name, ok := read_trimmed(p)
		if ok && len(name) > 0 {
			append_unique(&a.touch, fmt.tprintf("sensor:%s", name))
		}
	}
	for i in 0 ..< 128 {
		event := fmt.tprintf("/dev/input/event%d", i)
		if path_exists(event) {
			append_unique(&a.touch, fmt.tprintf("input_node:event%d", i))
		}
	}
	for i in 0 ..< 128 {
		gpio := fmt.tprintf("/sys/class/gpio/gpiochip%d", i)
		if path_exists(gpio) {
			append_unique(&a.touch, fmt.tprintf("gpio:%s", gpio))
		}
	}
}

parse_asound_capture_rates :: proc(a: ^Atlas, devices: string) {
	lines := strings.split_lines(devices, context.temp_allocator)
	for line in lines {
		l := strings.to_lower(line, context.temp_allocator)
		if strings.contains(l, "capture") {
			append_unique(&a.ears, fmt.tprintf("capture:%s", strings.trim_space(line)))
		}
	}
}

scan_linux_ears :: proc(a: ^Atlas) {
	if cards, ok := read_trimmed("/proc/asound/cards"); ok && len(cards) > 0 {
		lines := strings.split_lines(cards, context.temp_allocator)
		for line in lines {
			t := strings.trim_space(line)
			if len(t) > 0 {
				append_unique(&a.ears, fmt.tprintf("card:%s", t))
			}
		}
	}
	if devices, ok := read_trimmed("/proc/asound/devices"); ok && len(devices) > 0 {
		parse_asound_capture_rates(a, devices)
	}
	for i in 0 ..< 32 {
		node := fmt.tprintf("/dev/snd/pcmC0D%dc", i)
		if path_exists(node) {
			append_unique(&a.ears, fmt.tprintf("pcm_capture:%s", node))
		}
	}
}

scan_linux_eyes :: proc(a: ^Atlas) {
	for i in 0 ..< 32 {
		camName, ok := read_trimmed(fmt.tprintf("/sys/class/video4linux/video%d/name", i))
		if ok && len(camName) > 0 {
			append_unique(&a.eyes, fmt.tprintf("camera:video%d:%s", i, camName))
		}
	}
	for i in 0 ..< 16 {
		vendor, vok := read_trimmed(fmt.tprintf("/sys/class/drm/card%d/device/vendor", i))
		device, dok := read_trimmed(fmt.tprintf("/sys/class/drm/card%d/device/device", i))
		if vok || dok {
			append_unique(&a.eyes, fmt.tprintf("gpu:card%d:vendor=%s:device=%s", i, vendor, device))
		}
	}
}

scan_linux_perception :: proc(a: ^Atlas) {
	for i in 0 ..< 32 {
		iface := fmt.tprintf("/sys/class/net/wl%d", i)
		if path_exists(iface) {
			append_unique(&a.perception, fmt.tprintf("wifi:wl%d", i))
		}
	}
	for i in 0 ..< 8 {
		hci := fmt.tprintf("/sys/class/bluetooth/hci%d", i)
		if path_exists(hci) {
			append_unique(&a.perception, fmt.tprintf("bluetooth:hci%d", i))
		}
	}
	if arp, ok := read_trimmed("/proc/net/arp"); ok && len(arp) > 0 {
		lines := strings.split_lines(arp, context.temp_allocator)
		for line, idx in lines {
			if idx == 0 {
				continue
			}
			fields := strings.fields(strings.trim_space(line), context.temp_allocator)
			if len(fields) >= 1 {
				append_unique(&a.perception, fmt.tprintf("node:%s", fields[0]))
			}
		}
	}
}

scan_linux_motion :: proc(a: ^Atlas) {
	for i in 0 ..< 128 {
		ttyUSB := fmt.tprintf("/dev/ttyUSB%d", i)
		ttyACM := fmt.tprintf("/dev/ttyACM%d", i)
		if path_exists(ttyUSB) {
			append_unique(&a.motion, fmt.tprintf("serial:%s", ttyUSB))
		}
		if path_exists(ttyACM) {
			append_unique(&a.motion, fmt.tprintf("serial:%s", ttyACM))
		}
	}
	for i in 0 ..< 32 {
		pwm := fmt.tprintf("/sys/class/pwm/pwmchip%d", i)
		if path_exists(pwm) {
			append_unique(&a.motion, fmt.tprintf("pwm:%s", pwm))
		}
	}
}

scan_linux :: proc(a: ^Atlas) {
	scan_linux_touch(a)
	scan_linux_ears(a)
	scan_linux_eyes(a)
	scan_linux_perception(a)
	scan_linux_motion(a)
}

scan_windows :: proc(a: ^Atlas) {
	append_unique(&a.touch, "touch:windows-pnp-enumeration-todo")
	append_unique(&a.ears, "ears:windows-audio-enumeration-todo")
	append_unique(&a.eyes, "eyes:windows-display-camera-enumeration-todo")
	append_unique(&a.perception, "perception:windows-wifi-bluetooth-enumeration-todo")
	append_unique(&a.motion, "motion:windows-actuator-enumeration-todo")
}

append_section :: proc(sb: ^strings.Builder, title: string, values: []string) {
	fmt.sbprintf(sb, "[%s]\n", title)
	for value, i in values {
		fmt.sbprintf(sb, "%d=%q\n", i, value)
	}
	fmt.sbprintf(sb, "count=%d\n\n", len(values))
}

emit_driver_record :: proc(sb: ^strings.Builder, idx: ^int, kind, value: string) {
	fmt.sbprintf(sb, "%d=id:%s:%s status=resolved source=perform-scan\n", idx^, kind, value)
	idx^ += 1
}

serialize_atlas :: proc(a: ^Atlas, out_path: string) -> bool {
	sb: strings.Builder
	strings.builder_init(&sb, context.temp_allocator)
	defer strings.builder_destroy(&sb)

	fmt.sbprintf(&sb, "schema=atlas.sys.v2\n")
	fmt.sbprintf(&sb, "format=manifest\n")
	fmt.sbprintf(&sb, "os=%s\n\n", runtime_os_name())

	append_section(&sb, "Touch", a.touch[:])
	append_section(&sb, "Ears", a.ears[:])
	append_section(&sb, "Eyes", a.eyes[:])
	append_section(&sb, "Perception", a.perception[:])
	append_section(&sb, "Motion", a.motion[:])

	// Driver resolution roll-up (atlas.sys.v2 — see infra/out/cue/atlas_schema.cue).
	fmt.sbprintf(&sb, "[drivers]\n")
	driver_idx := 0
	for t in a.touch {
		emit_driver_record(&sb, &driver_idx, "touch", t)
	}
	for e in a.ears {
		emit_driver_record(&sb, &driver_idx, "audio", e)
	}
	for e in a.eyes {
		emit_driver_record(&sb, &driver_idx, "video", e)
	}
	for p in a.perception {
		emit_driver_record(&sb, &driver_idx, "perception", p)
	}
	for m in a.motion {
		emit_driver_record(&sb, &driver_idx, "motion", m)
	}
	if driver_idx == 0 {
		fmt.sbprintf(&sb, "0=id:platform:host status=skipped_builtin source=perform-scan\n")
		driver_idx = 1
	}
	fmt.sbprintf(&sb, "count=%d\n\n", driver_idx)

	text := strings.to_string(sb)
	return os.write_entire_file_from_string(out_path, text) == os.ERROR_NONE
}

runtime_os_name :: proc() -> string {
	when ODIN_OS == .Linux {
		return "linux"
	}
	when ODIN_OS == .Windows {
		return "windows"
	}
	return "unknown"
}

atlas_output_path :: proc() -> string {
	if raw := os.get_env_alloc("RICE_ATLAS_OUT", context.temp_allocator); len(raw) > 0 {
		return raw
	}
	if cfg := #config(RICE_ATLAS_OUT, ""); len(cfg) > 0 {
		return cfg
	}
	return "atlas.sys"
}

main :: proc() {
	a := Atlas{}
	when ODIN_OS == .Linux {
		scan_linux(&a)
	}
	when ODIN_OS == .Windows {
		scan_windows(&a)
	}
	out := atlas_output_path()
	if !serialize_atlas(&a, out) {
		fmt.eprintf("failed writing atlas.sys to %s\n", out)
		os.exit(1)
	}
	fmt.printf("atlas.sys generated at %s\n", out)
	fmt.printf("touch=%d ears=%d eyes=%d perception=%d motion=%d\n",
		len(a.touch), len(a.ears), len(a.eyes), len(a.perception), len(a.motion))
}

