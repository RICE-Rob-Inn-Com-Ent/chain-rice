package window
// TODO:
// [ ] ImGui Vulkan; GPU/NATS/cook debug panels; RICE_ENV=development F12 — https://github.com/ocornut/imgui
//

import "core:fmt"
import imgui "vendor:imgui"

create_context :: proc() -> ^imgui.Context {
	return imgui.create_context(nil)
}

destroy_context :: proc(ctx: ^imgui.Context) {
	imgui.destroy_context(ctx)
}

get_io :: proc() -> ^imgui.IO {
	return imgui.get_io()
}

new_frame :: proc() {
	imgui.new_frame()
}

render :: proc() {
	imgui.render()
}

get_draw_data :: proc() -> ^imgui.Draw_Data {
	return imgui.get_draw_data()
}

begin :: proc(name: cstring) -> bool {
	return imgui.begin(string(name), nil, {})
}

end :: proc() {
	imgui.end()
}

begin_child :: proc(id: cstring, size: imgui.Vec2) -> bool {
	return imgui.begin_child_str(string(id), size, false, {})
}

end_child :: proc() {
	imgui.end_child()
}

text :: proc(fmt_: cstring, args: ..any) {
	s := fmt.tprintf(string(fmt_), ..args)
	imgui.text_unformatted(s)
}

text_colored :: proc(col: imgui.Vec4, fmt_: cstring) {
	imgui.text_colored(col, string(fmt_))
}

button :: proc(label: cstring) -> bool {
	return imgui.button(string(label))
}

checkbox :: proc(label: cstring, v: ^bool) -> bool {
	return imgui.checkbox(string(label), v)
}

slider_float :: proc(label: cstring, v: ^f32, min: f32, max: f32) -> bool {
	return imgui.slider_float(string(label), v, min, max)
}

slider_int :: proc(label: cstring, v: ^i32, min: i32, max: i32) -> bool {
	return imgui.slider_int(string(label), v, min, max)
}

input_text :: proc(label: cstring, buf: []u8) -> bool {
	return imgui.input_text(string(label), buf)
}

input_float :: proc(label: cstring, v: ^f32) -> bool {
	return imgui.input_float(string(label), v)
}

combo :: proc(label: cstring, current: ^i32, items: []cstring) -> bool {
	assert(len(items) <= 32)
	str_buf: [32]string
	for it, i in items {
		str_buf[i] = string(it)
	}
	return imgui.combo_str_arr(string(label), current, str_buf[:len(items)])
}

color_edit4 :: proc(label: cstring, col: ^[4]f32) -> bool {
	return imgui.color_edit4(string(label), col^)
}

plot_lines :: proc(label: cstring, values: []f32) {
	if len(values) == 0 {
		return
	}
	imgui.plot_lines_float_ptr(string(label), raw_data(values), i32(len(values)))
}

plot_histogram :: proc(label: cstring, values: []f32) {
	if len(values) == 0 {
		return
	}
	imgui.plot_histogram_float_ptr(string(label), raw_data(values), i32(len(values)))
}

begin_menu_bar :: proc() -> bool {
	return imgui.begin_menu_bar()
}

end_menu_bar :: proc() {
	imgui.end_menu_bar()
}

begin_menu :: proc(label: cstring) -> bool {
	return imgui.begin_menu(string(label))
}

end_menu :: proc() {
	imgui.end_menu()
}

menu_item :: proc(label: cstring) -> bool {
	return imgui.menu_item_bool(string(label))
}

same_line :: proc() {
	imgui.same_line()
}

separator :: proc() {
	imgui.separator()
}

spacing :: proc() {
	imgui.spacing()
}

new_line :: proc() {
	imgui.new_line()
}

push_id :: proc(id: i32) {
	imgui.push_id_int(id)
}

pop_id :: proc() {
	imgui.pop_id()
}

set_next_window_size :: proc(size: imgui.Vec2) {
	imgui.set_next_window_size(size)
}

set_next_window_pos :: proc(pos: imgui.Vec2) {
	imgui.set_next_window_pos(pos)
}

style_colors_dark :: proc() {
	imgui.style_colors_dark(nil)
}

style_colors_light :: proc() {
	imgui.style_colors_light(nil)
}
