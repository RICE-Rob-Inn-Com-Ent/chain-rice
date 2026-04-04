package window
// TODO:
// [ ] SDL3 Vulkan window; gamepad → NATS input.gamepad.*; audio fallback — https://wiki.libsdl.org/SDL3/FrontPage
//

import "core:c"

when ODIN_OS == .Linux {
	foreign import libsdl3 {
		"lib/libSDL3.so",
	}
} else when ODIN_OS == .Darwin {
	foreign import libsdl3 {
		"lib/libSDL3.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import libsdl3 {
		"lib/SDL3.dll",
	}
}

SDL_Window :: distinct rawptr
SDL_Renderer :: distinct rawptr
SDL_Surface :: distinct rawptr
SDL_Texture :: distinct rawptr
SDL_Event :: struct {
	type: u32,
	_: [128]u8,
}
SDL_KeyboardEvent :: struct {
	type: u32,
	timestamp: u32,
	windowID: u32,
	repeat: u8,
	_: [3]u8,
	keysym: u32,
}
SDL_MouseMotionEvent :: struct {
	type: u32,
	timestamp: u32,
	windowID: u32,
	which: u32,
	state: u32,
	x: f32,
	y: f32,
	xrel: f32,
	yrel: f32,
}
SDL_MouseButtonEvent :: struct {
	type: u32,
	timestamp: u32,
	windowID: u32,
	which: u32,
	button: u8,
	state: u8,
	clicks: u8,
	_: u8,
	x: f32,
	y: f32,
}
SDL_MouseWheelEvent :: struct {
	type: u32,
	timestamp: u32,
	windowID: u32,
	which: u32,
	x: f32,
	y: f32,
}
SDL_GamepadEvent :: struct {
	type: u32,
	timestamp: u32,
	which: u32,
}
SDL_TouchFingerEvent :: struct {
	type: u32,
	timestamp: u32,
	touchId: u64,
	fingerId: u64,
	x: f32,
	y: f32,
	dx: f32,
	dy: f32,
	pressure: f32,
}
SDL_AudioSpec :: struct {
	freq: c.int,
	format: u16,
	channels: u8,
	silence: u8,
	samples: u16,
	padding: u16,
	size: u32,
	callback: rawptr,
	userdata: rawptr,
}
SDL_AudioStream :: distinct rawptr

SDL_INIT_VIDEO :: u32 : 0x00000020
SDL_INIT_AUDIO :: u32 : 0x00000010
SDL_INIT_GAMEPAD :: u32 : 0x00002000

SDL_WINDOW_FULLSCREEN :: u64 : 0x00000001
SDL_WINDOW_RESIZABLE :: u64 : 0x00000020
SDL_WINDOW_VULKAN :: u64 : 0x10000000

SDL_Keycode :: distinct i32
SDL_Scancode :: distinct i32

foreign libsdl3 {
	SDL_Init :: proc(flags: u32) -> bool ---
	SDL_Quit :: proc() ---
	SDL_InitSubSystem :: proc(flags: u32) -> bool ---
	SDL_QuitSubSystem :: proc(flags: u32) ---

	SDL_CreateWindow :: proc(title: cstring, w: c.int, h: c.int, flags: u64) -> SDL_Window ---
	SDL_DestroyWindow :: proc(window: SDL_Window) ---

	SDL_CreateRenderer :: proc(window: SDL_Window, name: cstring) -> SDL_Renderer ---
	SDL_DestroyRenderer :: proc(renderer: SDL_Renderer) ---

	SDL_RenderClear :: proc(renderer: SDL_Renderer) -> bool ---
	SDL_RenderPresent :: proc(renderer: SDL_Renderer) ---
	SDL_SetRenderDrawColor :: proc(renderer: SDL_Renderer, r: u8, g: u8, b: u8, a: u8) -> bool ---

	SDL_RenderRect :: proc(renderer: SDL_Renderer, rect: rawptr) -> bool ---
	SDL_RenderFillRect :: proc(renderer: SDL_Renderer, rect: rawptr) -> bool ---
	SDL_RenderLine :: proc(renderer: SDL_Renderer, x1: f32, y1: f32, x2: f32, y2: f32) -> bool ---

	SDL_RenderTexture :: proc(renderer: SDL_Renderer, texture: SDL_Texture, srcrect: rawptr, dstrect: rawptr) -> bool ---
	SDL_RenderTextureRotated :: proc(renderer: SDL_Renderer, texture: SDL_Texture, srcrect: rawptr, dstrect: rawptr, angle: f64, center: rawptr, flip: u32) -> bool ---

	SDL_CreateTexture :: proc(renderer: SDL_Renderer, format: u32, access: c.int, w: c.int, h: c.int) -> SDL_Texture ---
	SDL_DestroyTexture :: proc(texture: SDL_Texture) ---
	SDL_UpdateTexture :: proc(texture: SDL_Texture, rect: rawptr, pixels: rawptr, pitch: c.int) -> bool ---

	SDL_PollEvent :: proc(event: ^SDL_Event) -> bool ---
	SDL_WaitEvent :: proc(event: ^SDL_Event) -> bool ---
	SDL_PushEvent :: proc(event: ^SDL_Event) -> bool ---

	SDL_GetKeyboardState :: proc(numkeys: ^c.int) -> [^]u8 ---
	SDL_GetMouseState :: proc(x: ^f32, y: ^f32) -> u32 ---
	SDL_GetRelativeMouseState :: proc(x: ^f32, y: ^f32) -> u32 ---

	SDL_Vulkan_CreateSurface :: proc(window: SDL_Window, instance: rawptr, surface: ^rawptr) -> bool ---
	SDL_Vulkan_GetInstanceExtensions :: proc(window: SDL_Window, count: ^u32, names: rawptr) -> bool ---

	SDL_GetWindowSurface :: proc(window: SDL_Window) -> SDL_Surface ---
	SDL_UpdateWindowSurface :: proc(window: SDL_Window) -> bool ---

	SDL_SetWindowTitle :: proc(window: SDL_Window, title: cstring) ---
	SDL_SetWindowSize :: proc(window: SDL_Window, w: c.int, h: c.int) ---
	SDL_SetWindowFullscreen :: proc(window: SDL_Window, fullscreen: bool) ---
	SDL_GetWindowSize :: proc(window: SDL_Window, w: ^c.int, h: ^c.int) ---
	SDL_GetWindowPosition :: proc(window: SDL_Window, x: ^c.int, y: ^c.int) ---

	SDL_ShowCursor :: proc(show: bool) ---
	SDL_SetRelativeMouseMode :: proc(enabled: bool) -> bool ---

	SDL_GetTicks :: proc() -> u64 ---
	SDL_Delay :: proc(ms: u32) ---
	SDL_GetPerformanceCounter :: proc() -> u64 ---

	SDL_OpenAudioDevice :: proc(devname: cstring, iscapture: bool, desired: ^SDL_AudioSpec, obtained: ^SDL_AudioSpec, allowed_changes: u32) -> u32 ---
	SDL_CloseAudioDevice :: proc(dev: u32) ---
	SDL_PauseAudioDevice :: proc(dev: u32, pause_on: bool) ---

	SDL_OpenAudioDeviceStream :: proc(devid: u32, spec: ^SDL_AudioSpec, callback: rawptr, userdata: rawptr) -> SDL_AudioStream ---
	SDL_ResumeAudioStreamDevice :: proc(stream: SDL_AudioStream) -> bool ---
}
