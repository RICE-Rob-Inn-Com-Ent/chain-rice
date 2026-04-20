package audio
// TODO:
// [ ] ma_engine_init; RICE_AUDIO_SAMPLE_RATE, RICE_AUDIO_CHANNELS; enumerate devices — https://miniaud.io/docs/
// [ ] playback/capture; RICE_AUDIO=wasapi|coreaudio|pipewire|alsa|auto
//

import "core:c"

foreign import libminiaudio "lib/libminiaudio.a"

ma_engine :: distinct rawptr
ma_device :: distinct rawptr
ma_context :: distinct rawptr
ma_sound :: distinct rawptr
ma_sound_group :: distinct rawptr
ma_decoder :: distinct rawptr
ma_encoder :: distinct rawptr
ma_noise :: distinct rawptr
ma_waveform :: distinct rawptr

ma_engine_config :: struct {
	channels: u32,
	sampleRate: u32,
	noAutoStart: bool,
	noAutoStop: bool,
}

ma_device_config :: struct {
	deviceType: u32,
	sampleRate: u32,
	periodSizeInFrames: u32,
	periods: u32,
}

ma_context_config :: struct {
	threadPriority: i32,
}

ma_format :: enum c.int {
	unknown = 0,
	f32 = 1,
	s16 = 2,
	s24 = 3,
	s32 = 4,
	u8 = 5,
}

ma_device_type :: enum c.int {
	playback = 1,
	capture = 2,
	duplex = 3,
}

ma_channel_mix_mode :: enum c.int {
	planar = 0,
	interleaved = 1,
}

ma_attenuation_model :: enum c.int {
	none = 0,
	inverse = 1,
	linear = 2,
	exponential = 3,
}

foreign libminiaudio {
	ma_engine_init :: proc(pConfig: ^ma_engine_config, pEngine: ^ma_engine) -> c.int ---
	ma_engine_uninit :: proc(pEngine: ma_engine) ---
	ma_engine_start :: proc(pEngine: ma_engine) -> c.int ---
	ma_engine_stop :: proc(pEngine: ma_engine) -> c.int ---

	ma_engine_play_sound :: proc(pEngine: ma_engine, pSound: ma_sound) -> c.int ---
	ma_engine_get_time :: proc(pEngine: ma_engine) -> u64 ---

	ma_engine_set_volume :: proc(pEngine: ma_engine, volume: f32) ---
	ma_engine_get_volume :: proc(pEngine: ma_engine) -> f32 ---

	ma_sound_init_from_file :: proc(pEngine: ma_engine, pFilePath: cstring, flags: u32, pGroup: ma_sound_group, pSound: ^ma_sound) -> c.int ---
	ma_sound_init_from_data_source :: proc(pEngine: ma_engine, pDataSource: rawptr, flags: u32, pGroup: ma_sound_group, pSound: ^ma_sound) -> c.int ---

	ma_sound_uninit :: proc(pSound: ma_sound) ---
	ma_sound_start :: proc(pSound: ma_sound) -> c.int ---
	ma_sound_stop :: proc(pSound: ma_sound) -> c.int ---
	ma_sound_is_playing :: proc(pSound: ma_sound) -> bool ---

	ma_sound_set_volume :: proc(pSound: ma_sound, volume: f32) ---
	ma_sound_get_volume :: proc(pSound: ma_sound) -> f32 ---

	ma_sound_set_pitch :: proc(pSound: ma_sound, pitch: f32) ---
	ma_sound_set_looping :: proc(pSound: ma_sound, looping: bool) ---

	ma_sound_set_position :: proc(pSound: ma_sound, x: f32, y: f32, z: f32) ---
	ma_sound_set_velocity :: proc(pSound: ma_sound, x: f32, y: f32, z: f32) ---

	ma_sound_set_attenuation_model :: proc(pSound: ma_sound, model: ma_attenuation_model) ---
	ma_sound_set_rolloff :: proc(pSound: ma_sound, rolloff: f32) ---

	ma_device_init :: proc(pContext: ma_context, pConfig: ^ma_device_config, pDevice: ^ma_device) -> c.int ---
	ma_device_uninit :: proc(pDevice: ma_device) ---
	ma_device_start :: proc(pDevice: ma_device) -> c.int ---
	ma_device_stop :: proc(pDevice: ma_device) -> c.int ---

	ma_device_set_master_volume :: proc(pDevice: ma_device, volume: f32) ---
	ma_device_get_master_volume :: proc(pDevice: ma_device) -> f32 ---

	ma_decoder_init_file :: proc(pDecoder: ^ma_decoder, pFilePath: cstring, pConfig: rawptr) -> c.int ---
	ma_decoder_uninit :: proc(pDecoder: ma_decoder) ---
	ma_decoder_read_pcm_frames :: proc(pDecoder: ma_decoder, pFramesOut: rawptr, frameCount: u64, framesRead: ^u64) -> c.int ---

	ma_noise_init :: proc(pNoise: ^ma_noise, format: ma_format, channels: u32, type: u32, amplitude: f64, seed: i32) -> c.int ---
	ma_waveform_init :: proc(pWaveform: ^ma_waveform, format: ma_format, channels: u32, sampleRate: u32, type: u32, amplitude: f64, frequency: f64) -> c.int ---
}
