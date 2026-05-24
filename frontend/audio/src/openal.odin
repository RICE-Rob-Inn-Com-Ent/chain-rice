package audio
// TODO:
// [ ] alcOpenDevice; listener/source 3f; AL_EXT_EFX RICE_OPENAL_* — https://openal-soft.org/
//

import "core:c"

when ODIN_OS == .Linux {
	foreign import libopenal {
		"lib/libopenal.so",
	}
} else when ODIN_OS == .Darwin {
	foreign import libopenal {
		"lib/libopenal.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import libopenal {
		"lib/OpenAL32.lib",
	}
}

ALCdevice :: distinct rawptr
ALCcontext :: distinct rawptr
ALuint :: u32
ALint :: i32
ALfloat :: f32
ALenum :: i32
ALsizei :: distinct c.int

AL_POSITION :: i32 : 0x1004
AL_VELOCITY :: i32 : 0x1006
AL_ORIENTATION :: i32 : 0x100F
AL_GAIN :: i32 : 0x100A
AL_PITCH :: i32 : 0x1003
AL_LOOPING :: i32 : 0x1007
AL_BUFFER :: i32 : 0x1009

AL_FORMAT_MONO8 :: i32 : 0x1100
AL_FORMAT_MONO16 :: i32 : 0x1101
AL_FORMAT_STEREO8 :: i32 : 0x1102
AL_FORMAT_STEREO16 :: i32 : 0x1103

AL_INITIAL :: i32 : 0x1011
AL_PLAYING :: i32 : 0x1012
AL_PAUSED :: i32 : 0x1013
AL_STOPPED :: i32 : 0x1014

foreign libopenal {
	alcOpenDevice :: proc(devicename: cstring) -> ALCdevice ---
	alcCloseDevice :: proc(device: ALCdevice) -> bool ---

	alcCreateContext :: proc(device: ALCdevice, attrlist: [^]ALint) -> ALCcontext ---
	alcDestroyContext :: proc(context: ALCcontext) ---
	alcMakeContextCurrent :: proc(context: ALCcontext) -> bool ---
	alcGetCurrentContext :: proc() -> ALCcontext ---
	alcGetContextsDevice :: proc(context: ALCcontext) -> ALCdevice ---

	alGenBuffers :: proc(n: ALsizei, buffers: [^]ALuint) ---
	alDeleteBuffers :: proc(n: ALsizei, buffers: [^]ALuint) ---
	alIsBuffer :: proc(buffer: ALuint) -> bool ---
	alBufferData :: proc(buffer: ALuint, format: ALenum, data: rawptr, size: ALsizei, freq: ALsizei) ---

	alBufferi :: proc(buffer: ALuint, param: ALenum, value: ALint) ---
	alBufferf :: proc(buffer: ALuint, param: ALenum, value: ALfloat) ---
	alGetBufferi :: proc(buffer: ALuint, param: ALenum, value: ^ALint) ---

	alGenSources :: proc(n: ALsizei, sources: [^]ALuint) ---
	alDeleteSources :: proc(n: ALsizei, sources: [^]ALuint) ---
	alIsSource :: proc(source: ALuint) -> bool ---

	alSourcei :: proc(source: ALuint, param: ALenum, value: ALint) ---
	alSourcef :: proc(source: ALuint, param: ALenum, value: ALfloat) ---
	alSource3f :: proc(source: ALuint, param: ALenum, v1: ALfloat, v2: ALfloat, v3: ALfloat) ---
	alSourcefv :: proc(source: ALuint, param: ALenum, values: [^]ALfloat) ---
	alSourceiv :: proc(source: ALuint, param: ALenum, values: [^]ALint) ---

	alGetSourcei :: proc(source: ALuint, param: ALenum, value: ^ALint) ---
	alGetSourcef :: proc(source: ALuint, param: ALenum, value: ^ALfloat) ---
	alGetSource3f :: proc(source: ALuint, param: ALenum, v1: ^ALfloat, v2: ^ALfloat, v3: ^ALfloat) ---

	alSourcePlay :: proc(source: ALuint) ---
	alSourcePause :: proc(source: ALuint) ---
	alSourceStop :: proc(source: ALuint) ---
	alSourceRewind :: proc(source: ALuint) ---

	alSourceQueueBuffers :: proc(source: ALuint, nb: ALsizei, buffers: [^]ALuint) ---
	alSourceUnqueueBuffers :: proc(source: ALuint, nb: ALsizei, buffers: [^]ALuint) ---

	alListener3f :: proc(param: ALenum, v1: ALfloat, v2: ALfloat, v3: ALfloat) ---
	alListenerfv :: proc(param: ALenum, values: [^]ALfloat) ---
	alListenerf :: proc(param: ALenum, value: ALfloat) ---
	alListeneri :: proc(param: ALenum, value: ALint) ---

	alGetListener3f :: proc(param: ALenum, v1: ^ALfloat, v2: ^ALfloat, v3: ^ALfloat) ---
	alGetListenerf :: proc(param: ALenum, value: ^ALfloat) ---

	alEnable :: proc(capability: ALenum) ---
	alDisable :: proc(capability: ALenum) ---
	alIsEnabled :: proc(capability: ALenum) -> bool ---

	alGetError :: proc() -> ALenum ---
	alGetString :: proc(param: ALenum) -> cstring ---
}

import "core:strings"

OAL_State :: struct {
	cfg:    AudioConfig,
	device: ALCdevice,
	ctx:    ALCcontext,
	inited: bool,
}

@(private = "file")
_oal_name :: proc(user: rawptr) -> string {
	return "openal"
}

@(private = "file")
_oal_init :: proc(user: rawptr, cfg: ^AudioConfig) -> bool {
	s := cast(^OAL_State)user
	if s == nil {
		return false
	}
	s.cfg = cfg^
	s.cfg.device_name = strings.clone(cfg.device_name, context.allocator)
	devname: cstring = nil
	if len(s.cfg.device_name) > 0 {
		devname = strings.clone_to_cstring(s.cfg.device_name, context.temp_allocator)
	}
	s.device = alcOpenDevice(devname)
	if s.device == nil {
		return false
	}
	attrs := [3]ALint{0x1007, ALint(cfg.sample_rate_hz), 0}
	s.ctx = alcCreateContext(s.device, raw_data(attrs[:]))
	if s.ctx == nil {
		alcCloseDevice(s.device)
		s.device = nil
		return false
	}
	if !alcMakeContextCurrent(s.ctx) {
		alcDestroyContext(s.ctx)
		alcCloseDevice(s.device)
		s.ctx = nil
		s.device = nil
		return false
	}
	s.inited = true
	return true
}

@(private = "file")
_oal_shutdown :: proc(user: rawptr) -> bool {
	s := cast(^OAL_State)user
	if s == nil {
		return true
	}
	if s.inited {
		alcMakeContextCurrent(nil)
		if s.ctx != nil {
			alcDestroyContext(s.ctx)
		}
		if s.device != nil {
			alcCloseDevice(s.device)
		}
	}
	delete(s.cfg.device_name)
	s^ = {}
	return true
}

@(private = "file")
_oal_start :: proc(user: rawptr) -> bool {
	_ = user
	return true
}

@(private = "file")
_oal_stop :: proc(user: rawptr) -> bool {
	_ = user
	return true
}

@(private = "file")
_oal_read :: proc(user: rawptr, out: ^AudioBuffer) -> bool {
	_ = user
	_ = out
	return false
}

@(private = "file")
_oal_write :: proc(user: rawptr, in_buf: ^AudioBuffer) -> bool {
	_ = user
	_ = in_buf
	return false
}

// openal_device_table — просторове аудіо: listener/source через alListener3f / alSource3f після init.
openal_device_table :: proc() -> AudioDevice {
	st := new(OAL_State)
	return AudioDevice {
		user = st,
		name = _oal_name,
		init_device = _oal_init,
		shutdown = _oal_shutdown,
		start = _oal_start,
		stop = _oal_stop,
		read_capture = _oal_read,
		write_playback = _oal_write,
	}
}

openal_spatial_set_listener :: proc(pos: [3]f32, vel: [3]f32, forward_up: [6]f32) {
	alListener3f(AL_POSITION, pos[0], pos[1], pos[2])
	alListener3f(AL_VELOCITY, vel[0], vel[1], vel[2])
	alListenerfv(AL_ORIENTATION, raw_data(forward_up[:]))
}

openal_spatial_place_source :: proc(source: ALuint, pos: [3]f32, vel: [3]f32) {
	alSource3f(source, AL_POSITION, pos[0], pos[1], pos[2])
	alSource3f(source, AL_VELOCITY, vel[0], vel[1], vel[2])
}

openal_destroy_device :: proc(d: AudioDevice) {
	if d.shutdown != nil {
		_ = d.shutdown(d.user)
	}
	delete(cast(^OAL_State)d.user)
}
