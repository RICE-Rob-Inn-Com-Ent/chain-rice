// Wnętrze czarnej skrzynki — HID (klawiatura, mysz, touchpad, przyciski) + złącza wyświetlaczy (DRM sysfs).
package bard_inventory

import "core:fmt"
import "core:os"
import "core:strings"

// Peripheral_Report — wejścia użytkownika i ekrany (stan złącza DRM).
Peripheral_Report :: struct {
	input_sysfs_names:     [32][128]u8,
	input_sysfs_name_lens: [32]int,
	input_sysfs_count:     int,
	dev_input_event_count: int,
	// Klasyfikacja heurystyczna po polu name z sysfs
	hid_keyboard_like:  int,
	hid_mouse_like:     int,
	hid_touchpad_like:  int,
	hid_button_like:    int,
	hid_other:          int,
	// Wyświetlacze — card*-HDMI-*, *-DP-*, *-eDP-* … + status (connected/disconnected)
	display_connector_count:   int,
	display_connector_ids:   [24][96]u8,
	display_connector_id_lens: [24]int,
	display_status_text:     [24][24]u8,
	display_status_lens:     [24]int,
}

@(private = "file")
try_add_input_name :: proc(rep: ^Peripheral_Report, name: string) -> bool {
	if rep.input_sysfs_count >= len(rep.input_sysfs_names) {
		return false
	}
	i := rep.input_sysfs_count
	buf := rep.input_sysfs_names[i][:]
	src := transmute([]u8) name
	m := min(len(src), len(buf))
	copy(buf[:m], src[:m])
	rep.input_sysfs_name_lens[i] = m
	rep.input_sysfs_count += 1
	return true
}

@(private = "file")
classify_hid_name :: proc(rep: ^Peripheral_Report, name: string) {
	l := strings.to_lower(name, context.temp_allocator)
	defer delete(l)
	if strings.contains(l, "touchpad") || strings.contains(l, "trackpad") {
		rep.hid_touchpad_like += 1
		return
	}
	if strings.contains(l, "keyboard") || strings.contains(l, "kbd") {
		rep.hid_keyboard_like += 1
		return
	}
	if strings.contains(l, "mouse") {
		rep.hid_mouse_like += 1
		return
	}
	if strings.contains(l, "power button") ||
	   strings.contains(l, "sleep button") ||
	   strings.contains(l, "gpio") ||
	   strings.contains(l, "lid switch") ||
	   (strings.contains(l, "button") && !strings.contains(l, "mouse")) {
		rep.hid_button_like += 1
		return
	}
	rep.hid_other += 1
}

@(private = "file")
try_add_display :: proc(rep: ^Peripheral_Report, id: string, status: string) -> bool {
	if rep.display_connector_count >= len(rep.display_connector_ids) {
		return false
	}
	i := rep.display_connector_count
	ib := rep.display_connector_ids[i][:]
	src := transmute([]u8) id
	m := min(len(src), len(ib))
	copy(ib[:m], src[:m])
	rep.display_connector_id_lens[i] = m
	sb := rep.display_status_text[i][:]
	ss := transmute([]u8) strings.trim_space(status)
	ms := min(len(ss), len(sb))
	copy(sb[:ms], ss[:ms])
	rep.display_status_lens[i] = ms
	rep.display_connector_count += 1
	return true
}

@(private = "file")
enumerate_drm_displays :: proc(rep: ^Peripheral_Report) {
	d, err := os.open("/sys/class/drm")
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
		nm := fi.name
		if !strings.has_prefix(nm, "card") {
			continue
		}
		if strings.index(nm, '-') < 0 {
			continue
		}
		sbuf: [256]u8
		sn := fmt.bprintf(sbuf[:], "/sys/class/drm/%s/status", nm)
		spath := string(sbuf[:sn])
		raw, ok := os.read_entire_file(spath, context.temp_allocator)
		st := "unknown"
		if ok {
			st = strings.trim_space(string(raw))
		}
		try_add_display(rep, nm, st)
	}
}

// peripherals_probe — sysfs input, /dev/input/event*, klasyfikacja HID, złącza DRM.
peripherals_probe :: proc(rep: ^Peripheral_Report) {
	clear(rep)

	for i in 0 ..< 32 {
		pbuf: [256]u8
		n := fmt.bprintf(pbuf[:], "/sys/class/input/input%d/name", i)
		path := string(pbuf[:n])
		raw, ok := os.read_entire_file(path, context.temp_allocator)
		if !ok {
			continue
		}
		nm := strings.trim_space(string(raw))
		if len(nm) > 0 {
			try_add_input_name(rep, nm)
			classify_hid_name(rep, nm)
		}
	}

	for e in 0 ..< 64 {
		evbuf: [128]u8
		en := fmt.bprintf(evbuf[:], "/dev/input/event%d", e)
		evpath := string(evbuf[:en])
		if path_exists(evpath) {
			rep.dev_input_event_count += 1
		}
	}

	enumerate_drm_displays(rep)
}
