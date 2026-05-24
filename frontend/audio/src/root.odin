// Диспетчер аудіо: AudioConfig, AudioBuffer (f32 interleaved), AudioDevice, мікшер, ланцюжок плагінів DSP.
package audio

import "core:strings"
import "core:sync"

// AudioConfig — частота дискретизації, канали, розмір буфера (жодних прихованих констант у бекендах).
AudioConfig :: struct {
	sample_rate_hz: u32,
	channels:        u32,
	buffer_frames:   u32,
	latency_hint_ms: u32,
	device_name:     string,
}

// AudioBuffer — f32 interleaved; len(samples) == frames * channels.
AudioBuffer :: struct {
	sample_rate_hz: u32,
	channels:       u32,
	frames:         u32,
	samples:        []f32,
	user:           rawptr,
}

// Audio_Process_Fn — вставка у ланцюжок (Ruby/SAGE live DSP): in/out можуть вказувати на той самий буфер (in-place).
Audio_Process_Fn :: #type proc(user: rawptr, in_buf: ^AudioBuffer, out_buf: ^AudioBuffer)

MAX_AUDIO_PLUGINS :: 16
MAX_MIXER_INPUTS :: 8

AudioDevice :: struct {
	user:           rawptr,
	name:           proc(user: rawptr) -> string,
	init_device:    proc(user: rawptr, cfg: ^AudioConfig) -> bool,
	shutdown:       proc(user: rawptr) -> bool,
	start:          proc(user: rawptr) -> bool,
	stop:           proc(user: rawptr) -> bool,
	read_capture:   proc(user: rawptr, out: ^AudioBuffer) -> bool,
	write_playback: proc(user: rawptr, in_buf: ^AudioBuffer) -> bool,
}

AudioMixer :: struct {
	mu:           sync.Mutex,
	cfg:          AudioConfig,
	inputs:       [MAX_MIXER_INPUTS]AudioBuffer,
	input_gains:  [MAX_MIXER_INPUTS]f32,
	input_count:  int,
	master_gain:  f32,
	plugins:      [MAX_AUDIO_PLUGINS]Audio_Process_Fn,
	plugin_user:  [MAX_AUDIO_PLUGINS]rawptr,
	plugin_count: int,
	scratch:      []f32,
}

audio_mixer_init :: proc(m: ^AudioMixer, cfg: ^AudioConfig) {
	clear(m)
	m.cfg = cfg^
	m.master_gain = 1
	n := int(cfg.buffer_frames * cfg.channels)
	if n > 0 {
		m.scratch = make([]f32, n, context.allocator)
	}
}

audio_mixer_shutdown :: proc(m: ^AudioMixer) {
	delete(m.scratch)
	clear(m)
}

audio_mixer_set_input :: proc(m: ^AudioMixer, slot: int, buf: AudioBuffer, gain: f32) -> bool {
	sync.mutex_lock(&m.mu)
	defer sync.mutex_unlock(&m.mu)
	if slot < 0 || slot >= MAX_MIXER_INPUTS {
		return false
	}
	m.inputs[slot] = buf
	m.input_gains[slot] = gain
	if slot >= m.input_count {
		m.input_count = slot + 1
	}
	return true
}

audio_mixer_add_plugin :: proc(m: ^AudioMixer, fn: Audio_Process_Fn, user: rawptr) -> bool {
	sync.mutex_lock(&m.mu)
	defer sync.mutex_unlock(&m.mu)
	if m.plugin_count >= MAX_AUDIO_PLUGINS || fn == nil {
		return false
	}
	i := m.plugin_count
	m.plugins[i] = fn
	m.plugin_user[i] = user
	m.plugin_count += 1
	return true
}

// audio_mixer_render — зведення входів у scratch, копія в out, потім плагіни (in-place на out).
audio_mixer_render :: proc(m: ^AudioMixer, out: ^AudioBuffer) {
	sync.mutex_lock(&m.mu)
	defer sync.mutex_unlock(&m.mu)
	if len(m.scratch) == 0 || out == nil || len(out.samples) == 0 {
		return
	}
	for i in 0 ..< len(m.scratch) {
		m.scratch[i] = 0
	}
	for i in 0 ..< m.input_count {
		g := m.input_gains[i]
		inb := m.inputs[i]
		if len(inb.samples) == 0 {
			continue
		}
		n := min(len(m.scratch), len(inb.samples))
		for j in 0 ..< n {
			m.scratch[j] += inb.samples[j] * g
		}
	}
	n := min(len(out.samples), len(m.scratch))
	for j in 0 ..< n {
		out.samples[j] = m.scratch[j] * m.master_gain
	}
	out.sample_rate_hz = m.cfg.sample_rate_hz
	out.channels = m.cfg.channels
	out.frames = m.cfg.buffer_frames
	for p in 0 ..< m.plugin_count {
		fn := m.plugins[p]
		if fn != nil {
			fn(m.plugin_user[p], out, out)
		}
	}
}

audio_config_clone :: proc(cfg: ^AudioConfig) -> AudioConfig {
	c := cfg^
	c.device_name = strings.clone(cfg.device_name, context.allocator)
	return c
}

audio_config_free :: proc(cfg: ^AudioConfig) {
	delete(cfg.device_name)
}
