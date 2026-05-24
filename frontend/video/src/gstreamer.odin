package video
// TODO:
// [ ] RICE_GSTREAMER_PIPELINE; rtmpsink/hlssink — https://gstreamer.freedesktop.org/documentation/
//

import "core:c"
import "core:fmt"
import "core:strings"

when ODIN_OS == .Linux {
	foreign import libgst {
		"lib/libgstreamer-1.0.so",
	}
	foreign import libgstaudio {
		"lib/libgstaudio-1.0.so",
	}
	foreign import libgstvideo {
		"lib/libgstvideo-1.0.so",
	}
} else when ODIN_OS == .Darwin {
	foreign import libgst {
		"lib/libgstreamer-1.0.dylib",
	}
	foreign import libgstaudio {
		"lib/libgstaudio-1.0.dylib",
	}
	foreign import libgstvideo {
		"lib/libgstvideo-1.0.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import libgst {
		"lib/gstreamer-1.0.lib",
	}
	foreign import libgstaudio {
		"lib/gstaudio-1.0.lib",
	}
	foreign import libgstvideo {
		"lib/gstvideo-1.0.lib",
	}
}

GstElement :: distinct rawptr
GstPipeline :: distinct rawptr
GstBus :: distinct rawptr
GstMessage :: distinct rawptr
GstPad :: distinct rawptr
GstCaps :: distinct rawptr
GstBuffer :: distinct rawptr
GstSample :: distinct rawptr
GstClock :: distinct rawptr
GstEvent :: distinct rawptr
GstQuery :: distinct rawptr

GstState :: enum c.int {
	VOID_PENDING = 0,
	NULL_        = 1,
	READY        = 2,
	PAUSED       = 3,
	PLAYING      = 4,
}

GstStateChangeReturn :: enum c.int {
	FAILURE    = 0,
	SUCCESS    = 1,
	ASYNC      = 2,
	NO_PREROLL = 3,
}

GstMessageType :: enum c.int {
	UNKNOWN       = 0,
	EOS           = 1,
	ERROR         = 2,
	WARNING       = 3,
	STATE_CHANGED = 7,
}

GST_STATE_NULL :: GstState : .NULL_
GST_STATE_READY :: GstState : .READY
GST_STATE_PAUSED :: GstState : .PAUSED
GST_STATE_PLAYING :: GstState : .PLAYING

GST_MESSAGE_ERROR :: GstMessageType : .ERROR
GST_MESSAGE_WARNING :: GstMessageType : .WARNING
GST_MESSAGE_EOS :: GstMessageType : .EOS
GST_MESSAGE_STATE_CHANGED :: GstMessageType : .STATE_CHANGED

GstVideoInfo :: struct {
	finfo: [4]u8,
	width: u32,
	height: u32,
}

GstVideoFrame :: struct {
	info: GstVideoInfo,
	buffer: GstBuffer,
	flags: u32,
}

GstVideoFormat :: enum c.int {
	UNKNOWN = 0,
	ENCODED = 1,
	I420 = 2,
	YV12 = 3,
	NV12 = 4,
	RGBA = 5,
}

GST_VIDEO_FORMAT_RGBA :: GstVideoFormat : .RGBA
GST_VIDEO_FORMAT_NV12 :: GstVideoFormat : .NV12
GST_VIDEO_FORMAT_YV12 :: GstVideoFormat : .YV12
GST_VIDEO_FORMAT_I420 :: GstVideoFormat : .I420

foreign libgst {
	gst_init :: proc(argc: ^c.int, argv: ^[^]cstring) ---
	gst_deinit :: proc() ---
	gst_version :: proc(major: ^u32, minor: ^u32, micro: ^u32, nano: ^u32) ---

	gst_element_factory_make :: proc(factoryname: cstring, name: cstring) -> GstElement ---
	gst_element_factory_find :: proc(name: cstring) -> rawptr ---

	gst_pipeline_new :: proc(name: cstring) -> GstPipeline ---
	gst_parse_launch :: proc(pipeline_description: cstring, error: ^rawptr) -> GstElement ---

	gst_element_link :: proc(src: GstElement, dest: GstElement) -> bool ---
	gst_element_unlink :: proc(src: GstElement, dest: GstElement) ---

	gst_element_set_state :: proc(element: GstElement, state: GstState) -> GstStateChangeReturn ---
	gst_element_get_state :: proc(element: GstElement, state: ^GstState, pending: ^GstState, timeout: u64) -> GstStateChangeReturn ---

	gst_element_send_event :: proc(element: GstElement, event: GstEvent) -> bool ---
	gst_element_query :: proc(element: GstElement, query: GstQuery) -> bool ---

	gst_bin_add :: proc(bin: GstElement, element: GstElement) -> bool ---
	gst_bin_remove :: proc(bin: GstElement, element: GstElement) -> bool ---

	gst_bin_get_by_name :: proc(bin: GstElement, name: cstring) -> GstElement ---
	gst_bus_get :: proc(element: GstElement) -> GstBus ---
	gst_bus_timed_pop_filtered :: proc(bus: GstBus, timeout: u64, types: u32) -> GstMessage ---

	gst_message_parse_error :: proc(message: GstMessage, gerror: ^rawptr, debug: ^cstring) ---
	gst_message_parse_warning :: proc(message: GstMessage, gerror: ^rawptr, debug: ^cstring) ---
	gst_message_parse_state_changed :: proc(message: GstMessage, oldstate: ^GstState, newstate: ^GstState, pending: ^GstState) ---

	gst_object_ref :: proc(object: rawptr) -> rawptr ---
	gst_object_unref :: proc(object: rawptr) ---
	gst_caps_from_string :: proc(string: cstring) -> GstCaps ---
	gst_caps_unref :: proc(caps: GstCaps) ---

	gst_pad_get_current_caps :: proc(pad: GstPad) -> GstCaps ---
	gst_pad_link :: proc(srcpad: GstPad, sinkpad: GstPad) -> i32 ---
}

foreign libgstvideo {
	gst_video_info_init :: proc(info: ^GstVideoInfo) ---
	gst_video_info_from_caps :: proc(info: ^GstVideoInfo, caps: GstCaps) -> bool ---

	gst_video_frame_map :: proc(frame: ^GstVideoFrame, info: ^GstVideoInfo, buffer: GstBuffer, flags: u32) -> bool ---
	gst_video_frame_unmap :: proc(frame: ^GstVideoFrame) ---

	gst_video_format_to_string :: proc(format: GstVideoFormat) -> cstring ---
	gst_video_format_from_string :: proc(format: cstring) -> GstVideoFormat ---
}

foreign libgstaudio {}

make_element_videosrc :: proc(name: cstring) -> GstElement {
	return gst_element_factory_make("videotestsrc", name)
}

make_element_videosink :: proc(name: cstring) -> GstElement {
	return gst_element_factory_make("autovideosink", name)
}

make_element_videoconvert :: proc(name: cstring) -> GstElement {
	return gst_element_factory_make("videoconvert", name)
}

make_element_appsrc :: proc(name: cstring) -> GstElement {
	return gst_element_factory_make("appsrc", name)
}

make_element_appsink :: proc(name: cstring) -> GstElement {
	return gst_element_factory_make("appsink", name)
}

make_element_queue :: proc(name: cstring) -> GstElement {
	return gst_element_factory_make("queue", name)
}

make_element_tee :: proc(name: cstring) -> GstElement {
	return gst_element_factory_make("tee", name)
}

make_element_filesrc :: proc(name: cstring) -> GstElement {
	return gst_element_factory_make("filesrc", name)
}

make_element_filesink :: proc(name: cstring) -> GstElement {
	return gst_element_factory_make("filesink", name)
}

// video_gstreamer_parse_launch — рядок пайплайна ззовні (жодних захардкожених елементів усередині API).
video_gstreamer_parse_launch :: proc(pipeline_description: string) -> (GstElement, rawptr) {
	err: rawptr
	cs := strings.clone_to_cstring(pipeline_description, context.temp_allocator)
	el := gst_parse_launch(cs, &err)
	return el, err
}

Gst_Video_Backend_State :: struct {
	cfg:       VideoConfig,
	pipeline:  GstElement,
	owns_gst:  bool,
}

@(private = "file")
_gstv_name :: proc(user: rawptr) -> string {
	return "gstreamer"
}

@(private = "file")
_gstv_init :: proc(user: rawptr, cfg: ^VideoConfig) -> bool {
	s := cast(^Gst_Video_Backend_State)user
	if s == nil || cfg == nil {
		return false
	}
	s.cfg = cfg^
	s.cfg.source_uri = strings.clone(cfg.source_uri, context.allocator)
	s.cfg.extra_options = strings.clone(cfg.extra_options, context.allocator)
	argc: c.int
	gst_init(&argc, nil)
	err: rawptr
	if len(cfg.extra_options) > 0 {
		launch := strings.clone_to_cstring(cfg.extra_options, context.temp_allocator)
		s.pipeline = gst_parse_launch(launch, &err)
	} else {
		desc := gst_build_pipeline_desc_from_config(cfg)
		cs := strings.clone_to_cstring(desc, context.temp_allocator)
		s.pipeline = gst_parse_launch(cs, &err)
	}
	if s.pipeline == nil {
		return false
	}
	s.owns_gst = true
	return true
}

@(private = "file")
gst_build_pipeline_desc_from_config :: proc(cfg: ^VideoConfig) -> string {
	if len(cfg.source_uri) == 0 {
		return ""
	}
	low := strings.to_lower(cfg.source_uri, context.temp_allocator)
	defer delete(low)
	if strings.has_prefix(low, "rtsp://") || strings.has_prefix(low, "rtsps://") {
		return fmt.tprintf(
			"rtspsrc location=%s latency=0 ! decodebin ! videoconvert ! autovideosink",
			cfg.source_uri,
		)
	}
	return fmt.tprintf("filesrc location=%s ! decodebin ! videoconvert ! autovideosink", cfg.source_uri)
}

@(private = "file")
_gstv_shutdown :: proc(user: rawptr) {
	s := cast(^Gst_Video_Backend_State)user
	if s == nil {
		return
	}
	if s.pipeline != nil {
		gst_element_set_state(s.pipeline, GST_STATE_NULL)
		gst_object_unref(s.pipeline)
		s.pipeline = nil
	}
	delete(s.cfg.source_uri)
	delete(s.cfg.extra_options)
	s^ = {}
}

@(private = "file")
_gstv_decode :: proc(user: rawptr, out: ^VideoFrame) -> bool {
	_ = user
	_ = out
	return false
}

@(private = "file")
_gstv_encode :: proc(user: rawptr, frame: ^VideoFrame) -> bool {
	_ = user
	_ = frame
	return false
}

@(private = "file")
_gstv_export :: proc(user: rawptr, frame: ^VideoFrame) -> u64 {
	_ = user
	_ = frame
	return 0
}

// gstreamer_video_backend_table — складні пайплайни: або extra_options (повний рядок parse_launch), або автозбірка з source_uri.
gstreamer_video_backend_table :: proc() -> VideoBackend {
	st := new(Gst_Video_Backend_State)
	return VideoBackend {
		user = st,
		name = _gstv_name,
		init = _gstv_init,
		shutdown = _gstv_shutdown,
		decode_next_frame = _gstv_decode,
		encode_submit_frame = _gstv_encode,
		export_gpu_handle = _gstv_export,
	}
}

video_gstreamer_destroy_backend :: proc(b: VideoBackend) {
	if b.user == nil {
		return
	}
	if b.shutdown != nil {
		b.shutdown(b.user)
	}
	delete(cast(^Gst_Video_Backend_State)b.user)
}
