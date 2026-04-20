package window
// TODO:
// [ ] glfwCreateWindow RICE_APP_NAME RICE_WINDOW_*; RICE_WINDOW_MODE — https://www.glfw.org/docs/latest/
//

import "core:c"
import glfw "vendor:glfw"

init :: proc() -> bool {
	return bool(glfw.Init())
}

terminate :: proc() {
	glfw.Terminate()
}

create_window :: proc(w, h: i32, title: cstring, monitor: glfw.MonitorHandle) -> glfw.WindowHandle {
	return glfw.CreateWindow(c.int(w), c.int(h), title, monitor, nil)
}

destroy_window :: proc(window: glfw.WindowHandle) {
	glfw.DestroyWindow(window)
}

poll_events :: proc() {
	glfw.PollEvents()
}

swap_buffers :: proc(window: glfw.WindowHandle) {
	glfw.SwapBuffers(window)
}

window_should_close :: proc(window: glfw.WindowHandle) -> bool {
	return bool(glfw.WindowShouldClose(window))
}

set_window_should_close :: proc(window: glfw.WindowHandle, value: bool) {
	glfw.SetWindowShouldClose(window, value)
}

get_key :: proc(window: glfw.WindowHandle, key: i32) -> i32 {
	return i32(glfw.GetKey(window, c.int(key)))
}

get_mouse_button :: proc(window: glfw.WindowHandle, button: i32) -> i32 {
	return i32(glfw.GetMouseButton(window, c.int(button)))
}

get_cursor_pos :: proc(window: glfw.WindowHandle) -> (f64, f64) {
	return glfw.GetCursorPos(window)
}

set_cursor_pos_callback :: proc(window: glfw.WindowHandle, cb: glfw.CursorPosProc) {
	glfw.SetCursorPosCallback(window, cb)
}

set_key_callback :: proc(window: glfw.WindowHandle, cb: glfw.KeyProc) {
	glfw.SetKeyCallback(window, cb)
}

set_framebuffer_size_callback :: proc(window: glfw.WindowHandle, cb: glfw.FramebufferSizeProc) {
	glfw.SetFramebufferSizeCallback(window, cb)
}

vulkan_supported :: proc() -> bool {
	return bool(glfw.VulkanSupported())
}

get_required_instance_extensions :: proc() -> []cstring {
	return glfw.GetRequiredInstanceExtensions()
}

create_window_surface :: proc(instance: rawptr, window: glfw.WindowHandle) -> rawptr {
	surface: rawptr
	_ = glfw.CreateWindowSurface(instance, window, &surface)
	return surface
}

get_time :: proc() -> f64 {
	return glfw.GetTime()
}

set_time :: proc(time: f64) {
	glfw.SetTime(time)
}

swap_interval :: proc(interval: i32) {
	glfw.SwapInterval(c.int(interval))
}
