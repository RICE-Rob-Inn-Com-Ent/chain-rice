// Уніфікований API відео: декод/код/пайплайни лише через VideoConfig + VideoBackend (zero-hardcode у логіці обробки).
package video

import "core:strings"
import "core:sync"

Video_Format_Id :: enum u32 {
	Unknown = 0,
	NV12    = 1,
	RGBA8   = 2,
	YUV420P = 3,
}

// VideoFormat — опис пікселів/площин (усі числа з конфігу або з кадру, не магічні константи в декодері).
VideoFormat :: struct {
	id:              Video_Format_Id,
	width:           u32,
	height:          u32,
	stride_bytes:    u32,
	planes:          u32,
	bits_per_pixel:  u32,
}

// VideoFrame — один кадр; gpu_ptr валідний лише для zero-copy бекендів (NVCodec → CUDA/Vulkan).
VideoFrame :: struct {
	format:       VideoFormat,
	pts_ns:       i64,
	duration_ns:  i64,
	cpu_planes:   [4]rawptr,
	cpu_strides:  [4]u32,
	gpu_ptr:      u64,
	gpu_pitch:    u32,
	is_zero_copy: bool,
	user:         rawptr,
}

// VideoCodec_Id — вибір кодека з конфігу, не з #define всередині функцій.
VideoCodec_Id :: enum u32 {
	Auto   = 0,
	H264   = 1,
	HEVC   = 2,
	VP9    = 3,
	AV1    = 4,
}

// VideoConfig — єдине джерело бітрейту, роздільності, URI, кодеку (Zero-Hardcode Rule).
VideoConfig :: struct {
	width:          u32,
	height:         u32,
	bitrate_bps:    u32,
	codec:          VideoCodec_Id,
	framerate_num:  u32,
	framerate_den:  u32,
	source_uri:     string,
	rtsp_tcp_only:  bool,
	prefer_hw:      bool,
	extra_options:  string,
}

Video_Backend_Kind :: enum u8 {
	None = 0,
	NVCodec,
	FFmpeg,
	GStreamer,
}

// VideoBackend — таблиця віртуальних методів (інтерфейс без ОО-підкласів).
VideoBackend :: struct {
	user:                    rawptr,
	name:                    proc(user: rawptr) -> string,
	init:                    proc(user: rawptr, cfg: ^VideoConfig) -> bool,
	shutdown:                proc(user: rawptr),
	decode_next_frame:       proc(user: rawptr, out: ^VideoFrame) -> bool,
	encode_submit_frame:     proc(user: rawptr, frame: ^VideoFrame) -> bool,
	export_gpu_handle:       proc(user: rawptr, frame: ^VideoFrame) -> u64,
}

MAX_VIDEO_BACKENDS :: 8
_backend_mutex: sync.Mutex
_backends:      [MAX_VIDEO_BACKENDS]VideoBackend
_backend_count: int

video_register_backend :: proc(b: VideoBackend) -> bool {
	sync.mutex_lock(&_backend_mutex)
	defer sync.mutex_unlock(&_backend_mutex)
	if _backend_count >= MAX_VIDEO_BACKENDS {
		return false
	}
	_backends[_backend_count] = b
	_backend_count += 1
	return true
}

video_backend_count :: proc() -> int {
	sync.mutex_lock(&_backend_mutex)
	defer sync.mutex_unlock(&_backend_mutex)
	return _backend_count
}

video_backend_at :: proc(i: int) -> (VideoBackend, bool) {
	sync.mutex_lock(&_backend_mutex)
	defer sync.mutex_unlock(&_backend_mutex)
	if i < 0 || i >= _backend_count {
		return {}, false
	}
	return _backends[i], true
}

// video_select_backend_kind — евристика: NVCodec за наявності GPU (NVML/NVDEC), інакше GStreamer для URI з префіксами стріму, інакше FFmpeg.
video_select_backend_kind :: proc(cfg: ^VideoConfig) -> Video_Backend_Kind {
	if cfg.prefer_hw && nvcodec_system_gpu_decode_available() {
		return .NVCodec
	}
	u := strings.to_lower(cfg.source_uri, context.temp_allocator)
	defer delete(u)
	if strings.has_prefix(u, "rtsp://") ||
	   strings.has_prefix(u, "rtsps://") ||
	   strings.has_prefix(u, "udp://") ||
	   strings.has_prefix(u, "tcp://") ||
	   strings.has_prefix(u, "srt://") {
		return .GStreamer
	}
	return .FFmpeg
}

// video_backend_default_for_config — повертає таблицю методів для обраного kind (потрібні відповідні *_backend_table у модулях).
video_backend_default_for_config :: proc(kind: Video_Backend_Kind) -> (VideoBackend, bool) {
	switch kind {
	case .NVCodec:
		return nvcodec_backend_table(), true
	case .FFmpeg:
		return ffmpeg_backend_table(), true
	case .GStreamer:
		return gstreamer_video_backend_table(), true
	case:
		return {}, false
	}
}

// video_auto_init_backend — реєстрація + init одним викликом для швидкого старту.
video_auto_init_backend :: proc(cfg: ^VideoConfig) -> (VideoBackend, bool) {
	kind := video_select_backend_kind(cfg)
	b, ok := video_backend_default_for_config(kind)
	if !ok {
		return {}, false
	}
	if b.init != nil && !b.init(b.user, cfg) {
		return {}, false
	}
	return b, true
}

// video_config_from_uri — заповнює лише URI; решта полів — нуль (клієнт задає width/height/codec окремо).
video_config_from_uri :: proc(uri: string) -> VideoConfig {
	return VideoConfig{source_uri = strings.clone(uri, context.allocator)}
}

video_config_free :: proc(cfg: ^VideoConfig) {
	delete(cfg.source_uri)
	delete(cfg.extra_options)
}

// video_frame_reset — очистка посилань без free GPU (віддає бекенд).
video_frame_reset :: proc(f: ^VideoFrame) {
	f^ = {}
}

@(private = "file")
_dummy_name :: proc(user: rawptr) -> string {
	return "none"
}

// video_backend_stub — порожній бекенд для тестів.
video_backend_stub :: proc() -> VideoBackend {
	return VideoBackend{name = _dummy_name}
}
