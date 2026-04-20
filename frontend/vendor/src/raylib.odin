package window
// TODO:
// [ ] InitWindow RICE_TARGET_FPS; 2D/audio — https://www.raylib.com/
//

import "core:c"
import rl "vendor:raylib"

init_window :: proc(w, h: i32, title: cstring) {
	rl.InitWindow(c.int(w), c.int(h), title)
}

close_window :: proc() {
	rl.CloseWindow()
}

window_should_close :: proc() -> bool {
	return rl.WindowShouldClose()
}

begin_drawing :: proc() {
	rl.BeginDrawing()
}

end_drawing :: proc() {
	rl.EndDrawing()
}

begin_mode_2d :: proc(camera: rl.Camera2D) {
	rl.BeginMode2D(camera)
}

end_mode_2d :: proc() {
	rl.EndMode2D()
}

begin_mode_3d :: proc(camera: rl.Camera3D) {
	rl.BeginMode3D(camera)
}

end_mode_3d :: proc() {
	rl.EndMode3D()
}

begin_shader_mode :: proc(shader: rl.Shader) {
	rl.BeginShaderMode(shader)
}

end_shader_mode :: proc() {
	rl.EndShaderMode()
}

clear_background :: proc(color: rl.Color) {
	rl.ClearBackground(color)
}

draw_fps :: proc(x, y: i32) {
	rl.DrawFPS(c.int(x), c.int(y))
}

draw_text :: proc(text: cstring, x, y, size: i32, color: rl.Color) {
	rl.DrawText(text, c.int(x), c.int(y), c.int(size), color)
}

draw_rectangle :: proc(x, y, w, h: i32, color: rl.Color) {
	rl.DrawRectangle(c.int(x), c.int(y), c.int(w), c.int(h), color)
}

draw_circle :: proc(x, y: i32, radius: f32, color: rl.Color) {
	rl.DrawCircle(c.int(x), c.int(y), radius, color)
}

draw_line :: proc(x1, y1, x2, y2: i32, color: rl.Color) {
	rl.DrawLine(c.int(x1), c.int(y1), c.int(x2), c.int(y2), color)
}

load_texture :: proc(path: cstring) -> rl.Texture2D {
	return rl.LoadTexture(path)
}

unload_texture :: proc(tex: rl.Texture2D) {
	rl.UnloadTexture(tex)
}

draw_texture :: proc(tex: rl.Texture2D, x, y: i32, tint: rl.Color) {
	rl.DrawTexture(tex, c.int(x), c.int(y), tint)
}

load_shader :: proc(vs, fs: cstring) -> rl.Shader {
	return rl.LoadShader(vs, fs)
}

unload_shader :: proc(shader: rl.Shader) {
	rl.UnloadShader(shader)
}

load_model :: proc(path: cstring) -> rl.Model {
	return rl.LoadModel(path)
}

draw_model :: proc(model: rl.Model, pos: rl.Vector3, scale: f32, tint: rl.Color) {
	rl.DrawModel(model, pos, scale, tint)
}

load_sound :: proc(path: cstring) -> rl.Sound {
	return rl.LoadSound(path)
}

play_sound :: proc(sound: rl.Sound) {
	rl.PlaySound(sound)
}

stop_sound :: proc(sound: rl.Sound) {
	rl.StopSound(sound)
}

play_music_stream :: proc(music: rl.Music) {
	rl.PlayMusicStream(music)
}

update_music_stream :: proc(music: rl.Music) {
	rl.UpdateMusicStream(music)
}

get_frame_time :: proc() -> f32 {
	return rl.GetFrameTime()
}

set_target_fps :: proc(fps: i32) {
	rl.SetTargetFPS(c.int(fps))
}

is_key_pressed :: proc(key: rl.KeyboardKey) -> bool {
	return rl.IsKeyPressed(key)
}

is_mouse_button_pressed :: proc(btn: rl.MouseButton) -> bool {
	return rl.IsMouseButtonPressed(btn)
}

get_mouse_position :: proc() -> rl.Vector2 {
	return rl.GetMousePosition()
}
