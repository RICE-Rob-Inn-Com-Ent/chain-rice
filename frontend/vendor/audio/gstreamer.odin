package audio
// TODO:
// [ ] gst pipeline audio src/sink appsink — https://gstreamer.freedesktop.org/documentation/
//

import "core:c"

when ODIN_OS == .Linux {
	foreign import libgst {
		"lib/libgstreamer-1.0.so",
	}
	foreign import libgstaudio {
		"lib/libgstaudio-1.0.so",
	}
} else when ODIN_OS == .Darwin {
	foreign import libgst {
		"lib/libgstreamer-1.0.dylib",
	}
	foreign import libgstaudio {
		"lib/libgstaudio-1.0.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import libgst {
		"lib/gstreamer-1.0.lib",
	}
	foreign import libgstaudio {
		"lib/gstaudio-1.0.lib",
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
	INFO          = 4,
	TAG           = 5,
	BUFFERING     = 6,
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
	gst_bin_iterate_elements :: proc(bin: GstElement) -> rawptr ---

	gst_bus_get :: proc(element: GstElement) -> GstBus ---
	gst_bus_timed_pop_filtered :: proc(bus: GstBus, timeout: u64, types: u32) -> GstMessage ---

	gst_bus_add_watch :: proc(bus: GstBus, func: rawptr, user_data: rawptr) -> u32 ---
	gst_bus_remove_watch :: proc(bus: GstBus, watch_id: u32) -> bool ---

	gst_message_parse_error :: proc(message: GstMessage, gerror: ^rawptr, debug: ^cstring) ---
	gst_message_parse_warning :: proc(message: GstMessage, gerror: ^rawptr, debug: ^cstring) ---
	gst_message_parse_state_changed :: proc(message: GstMessage, oldstate: ^GstState, newstate: ^GstState, pending: ^GstState) ---

	gst_object_ref :: proc(object: rawptr) -> rawptr ---
	gst_object_unref :: proc(object: rawptr) ---
	gst_object_set_name :: proc(object: rawptr, name: cstring) -> bool ---

	gst_caps_from_string :: proc(string: cstring) -> GstCaps ---
	gst_caps_new_any :: proc() -> GstCaps ---
	gst_caps_unref :: proc(caps: GstCaps) ---

	gst_pad_get_current_caps :: proc(pad: GstPad) -> GstCaps ---
	gst_pad_link :: proc(srcpad: GstPad, sinkpad: GstPad) -> i32 ---
}

foreign libgstaudio {}

gst_element_link_many :: proc(elements: []GstElement) -> bool {
	if len(elements) < 2 {
		return true
	}
	for i in 0 ..< len(elements) - 1 {
		if !gst_element_link(elements[i], elements[i + 1]) {
			return false
		}
	}
	return true
}

gst_bin_add_many :: proc(bin: GstElement, elements: []GstElement) -> bool {
	for e in elements {
		if !gst_bin_add(bin, e) {
			return false
		}
	}
	return true
}
