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
