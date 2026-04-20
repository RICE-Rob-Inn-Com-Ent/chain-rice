// Wnętrze czarnej skrzynki — sieć: WiFi, Bluetooth, „sniffing” gniazd (/proc/net), drony, heurystyka kamer IP (Linux).
package bard_inventory

import "core:fmt"
import "core:os"
import "core:strings"

// Network_Report — obserwacja bez libpcap.
Network_Report :: struct {
	tcp_socket_rows:         int,
	udp_socket_rows:         int,
	tcp_listen_rows:         int,
	tcp_established_rows:    int,
	wlan_iface_names:        [16][48]u8,
	wlan_iface_name_lens:    [16]int,
	wlan_count:              int,
	bluetooth_hci_count:     int,
	drone_hint_udp_hits:     int,
	drone_hint_udp6_hits:    int,
	ip_camera_tcp_hints:     int,
	ip_camera_udp_hints:     int,
}

@(private = "file")
count_data_lines :: proc(path: string) -> int {
	raw, ok := os.read_entire_file(path, context.temp_allocator)
	if !ok {
		return 0
	}
	s := string(raw)
	lines := strings.split_lines(s, context.temp_allocator)
	defer delete(lines)
	if len(lines) <= 1 {
		return 0
	}
	return max(0, len(lines) - 1)
}

@(private = "file")
hex_byte_value :: proc(c: u8) -> (u8, bool) {
	switch c {
	case '0' ..= '9':
		return c - '0', true
	case 'a' ..= 'f':
		return 10 + (c - 'a'), true
	case 'A' ..= 'F':
		return 10 + (c - 'A'), true
	}
	return 0, false
}

@(private = "file")
local_port_from_address_field :: proc(addr: string) -> (u16, bool) {
	colon := strings.index(addr, ":")
	if colon < 0 || colon + 1 >= len(addr) {
		return 0, false
	}
	ph := addr[colon + 1:]
	if len(ph) < 1 || len(ph) > 4 {
		return 0, false
	}
	port: u16 = 0
	for i in 0 ..< len(ph) {
		v, ok := hex_byte_value(ph[i])
		if !ok {
			return 0, false
		}
		port = port * 16 + u16(v)
	}
	return port, true
}

@(private = "file")
local_port_from_proc_net_row :: proc(line: string) -> (u16, bool) {
	fields := strings.fields(line)
	defer delete(fields)
	if len(fields) < 2 {
		return 0, false
	}
	return local_port_from_address_field(fields[1])
}

@(private = "file")
remote_port_from_proc_net_row :: proc(line: string) -> (u16, bool) {
	fields := strings.fields(line)
	defer delete(fields)
	if len(fields) < 3 {
		return 0, false
	}
	return local_port_from_address_field(fields[2])
}

@(private = "file")
tcp_state_from_row :: proc(line: string) -> (string, bool) {
	fields := strings.fields(line)
	defer delete(fields)
	if len(fields) < 4 {
		return "", false
	}
	return fields[3], true
}

@(private = "file")
scan_tcp_socket_states :: proc(path: string) -> (listen_n: int, est_n: int) {
	raw, ok := os.read_entire_file(path, context.temp_allocator)
	if !ok {
		return 0, 0
	}
	s := string(raw)
	lines := strings.split_lines(s, context.temp_allocator)
	defer delete(lines)
	ln, en := 0, 0
	for line, idx in lines {
		if idx == 0 || len(line) < 10 {
			continue
		}
		tl := strings.trim_space(line)
		if len(tl) < 1 || tl[0] < '0' || tl[0] > '9' {
			continue
		}
		st, ok2 := tcp_state_from_row(tl)
		if !ok2 {
			continue
		}
		switch st {
		case "0A", "0a":
			ln += 1
		case "01":
			en += 1
		}
	}
	return ln, en
}

@(private = "file")
drone_related_udp_port :: proc(port: u16) -> bool {
	switch port {
	case 14550, 14551, 14552, 14553, 5777, 5888, 8899:
		return true
	}
	return false
}

@(private = "file")
ip_camera_related_port :: proc(port: u16) -> bool {
	switch port {
	case 80, 443, 554, 556, 800, 8000, 8080, 8443, 8554, 8555, 7070, 37777, 8900, 9999, 5544:
		return true
	}
	return false
}

@(private = "file")
scan_udp_drone_hints_path :: proc(path: string) -> int {
	raw, ok := os.read_entire_file(path, context.temp_allocator)
	if !ok {
		return 0
	}
	s := string(raw)
	lines := strings.split_lines(s, context.temp_allocator)
	defer delete(lines)
	hits := 0
	for line, idx in lines {
		if idx == 0 || len(line) < 10 {
			continue
		}
		tl := strings.trim_space(line)
		if len(tl) < 1 || tl[0] < '0' || tl[0] > '9' {
			continue
		}
		if p, okp := local_port_from_proc_net_row(tl); okp {
			if drone_related_udp_port(p) {
				hits += 1
			}
		}
	}
	return hits
}

@(private = "file")
scan_ip_camera_hints :: proc(path: string) -> int {
	raw, ok := os.read_entire_file(path, context.temp_allocator)
	if !ok {
		return 0
	}
	s := string(raw)
	lines := strings.split_lines(s, context.temp_allocator)
	defer delete(lines)
	hits := 0
	for line, idx in lines {
		if idx == 0 || len(line) < 10 {
			continue
		}
		tl := strings.trim_space(line)
		if len(tl) < 1 || tl[0] < '0' || tl[0] > '9' {
			continue
		}
		lp, lok := local_port_from_proc_net_row(tl)
		rp, rok := remote_port_from_proc_net_row(tl)
		if lok && ip_camera_related_port(lp) {
			hits += 1
			continue
		}
		if rok && ip_camera_related_port(rp) {
			hits += 1
		}
	}
	return hits
}

@(private)
path_exists :: proc(path: string) -> bool {
	_, err := os.stat(path)
	return err == os.ERROR_NONE
}

@(private = "file")
count_bluetooth_hci :: proc() -> int {
	n := 0
	for i in 0 ..< 8 {
		pbuf: [128]u8
		nn := fmt.bprintf(pbuf[:], "/sys/class/bluetooth/hci%d", i)
		path := string(pbuf[:nn])
		if path_exists(path) {
			n += 1
		}
	}
	return n
}

@(private = "file")
wlan_name_taken :: proc(rep: ^Network_Report, name: string) -> bool {
	for i in 0 ..< rep.wlan_count {
		existing := string(rep.wlan_iface_names[i][:rep.wlan_iface_name_lens[i]])
		if existing == name {
			return true
		}
	}
	return false
}

@(private = "file")
try_add_wlan :: proc(rep: ^Network_Report, name: string) -> bool {
	if rep.wlan_count >= len(rep.wlan_iface_names) {
		return false
	}
	if wlan_name_taken(rep, name) {
		return false
	}
	i := rep.wlan_count
	buf := rep.wlan_iface_names[i][:]
	src := transmute([]u8) name
	m := min(len(src), len(buf))
	copy(buf[:m], src[:m])
	rep.wlan_iface_name_lens[i] = m
	rep.wlan_count += 1
	return true
}

@(private = "file")
discover_wifi_interfaces :: proc(rep: ^Network_Report) {
	d, err := os.open("/sys/class/net")
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
		if nm == "lo" {
			continue
		}
		if strings.has_prefix(nm, "wl") {
			try_add_wlan(rep, nm)
			continue
		}
		wpbuf: [256]u8
		wn := fmt.bprintf(wpbuf[:], "/sys/class/net/%s/wireless", nm)
		if path_exists(string(wpbuf[:wn])) {
			try_add_wlan(rep, nm)
		}
	}
}

// network_probe — wypełnia Network_Report.
network_probe :: proc(rep: ^Network_Report) {
	clear(rep)
	rep.tcp_socket_rows = count_data_lines("/proc/net/tcp")
	rep.tcp_socket_rows += count_data_lines("/proc/net/tcp6")
	rep.udp_socket_rows = count_data_lines("/proc/net/udp")
	rep.udp_socket_rows += count_data_lines("/proc/net/udp6")

	l4, e4 := scan_tcp_socket_states("/proc/net/tcp")
	l6, e6 := scan_tcp_socket_states("/proc/net/tcp6")
	rep.tcp_listen_rows = l4 + l6
	rep.tcp_established_rows = e4 + e6

	rep.drone_hint_udp_hits = scan_udp_drone_hints_path("/proc/net/udp")
	rep.drone_hint_udp6_hits = scan_udp_drone_hints_path("/proc/net/udp6")

	rep.ip_camera_tcp_hints = scan_ip_camera_hints("/proc/net/tcp")
	rep.ip_camera_tcp_hints += scan_ip_camera_hints("/proc/net/tcp6")
	rep.ip_camera_udp_hints = scan_ip_camera_hints("/proc/net/udp")
	rep.ip_camera_udp_hints += scan_ip_camera_hints("/proc/net/udp6")

	rep.bluetooth_hci_count = count_bluetooth_hci()
	discover_wifi_interfaces(rep)
}
