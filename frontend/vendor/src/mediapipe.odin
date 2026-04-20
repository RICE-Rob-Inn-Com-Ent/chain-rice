package vision
// TODO:
// [ ] RICE_MEDIAPIPE_GRAPH; pose/hands/face → NATS vision.* — https://developers.google.com/mediapipe
//

import "core:c"

when ODIN_OS == .Linux {
	foreign import libmediapipe {
		"lib/libmediapipe.so",
	}
} else when ODIN_OS == .Darwin {
	foreign import libmediapipe {
		"lib/libmediapipe.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import libmediapipe {
		"lib/mediapipe.lib",
	}
}

MpGraph :: distinct rawptr
MpPacket :: distinct rawptr
MpTimestamp :: distinct u64

MpLandmark :: struct {
	x: f32,
	y: f32,
	z: f32,
	visibility: f32,
}

MpNormalizedLandmark :: struct {
	x: f32,
	y: f32,
	z: f32,
}

MpDetection :: struct {
	score: f32,
}

MpFaceGeometry :: struct {
	_data: rawptr,
}

MpClassification :: struct {
	label: cstring,
	score: f32,
}

foreign libmediapipe {
	mp_create_graph :: proc(config_text: cstring) -> MpGraph ---
	mp_destroy_graph :: proc(graph: MpGraph) ---

	mp_start_run :: proc(graph: MpGraph) -> i32 ---
	mp_stop_run :: proc(graph: MpGraph) -> i32 ---
	mp_wait_until_done :: proc(graph: MpGraph) -> i32 ---

	mp_add_packet_to_input_stream :: proc(graph: MpGraph, stream: cstring, packet: MpPacket) -> i32 ---

	mp_get_output_packet :: proc(graph: MpGraph, stream: cstring, packet: ^MpPacket) -> i32 ---
	mp_poll_packet :: proc(graph: MpGraph, stream: cstring, packet: ^MpPacket) -> i32 ---

	mp_create_image_packet :: proc(data: rawptr, width: i32, height: i32, format: i32) -> MpPacket ---
	mp_create_matrix_packet :: proc(data: rawptr, rows: i32, cols: i32) -> MpPacket ---

	mp_packet_get_image :: proc(packet: MpPacket, out_data: ^rawptr, w: ^i32, h: ^i32) -> i32 ---
	mp_packet_get_landmark_list :: proc(packet: MpPacket, out: ^rawptr, count: ^i32) -> i32 ---
	mp_packet_get_normalized_landmark_list :: proc(packet: MpPacket, out: ^rawptr, count: ^i32) -> i32 ---
	mp_packet_get_detection_list :: proc(packet: MpPacket, out: ^rawptr, count: ^i32) -> i32 ---
	mp_packet_get_classification_list :: proc(packet: MpPacket, out: ^rawptr, count: ^i32) -> i32 ---

	mp_create_face_mesh_graph :: proc() -> MpGraph ---
	mp_create_hand_tracking_graph :: proc() -> MpGraph ---
	mp_create_pose_tracking_graph :: proc() -> MpGraph ---
	mp_create_iris_tracking_graph :: proc() -> MpGraph ---
	mp_create_face_detection_graph :: proc() -> MpGraph ---
	mp_create_holistic_graph :: proc() -> MpGraph ---

	mp_landmark_x :: proc(lm: ^MpLandmark) -> f32 ---
	mp_landmark_y :: proc(lm: ^MpLandmark) -> f32 ---
	mp_landmark_z :: proc(lm: ^MpLandmark) -> f32 ---
	mp_landmark_visibility :: proc(lm: ^MpLandmark) -> f32 ---

	mp_normalized_landmark_x :: proc(lm: ^MpNormalizedLandmark) -> f32 ---
	mp_normalized_landmark_y :: proc(lm: ^MpNormalizedLandmark) -> f32 ---
}
