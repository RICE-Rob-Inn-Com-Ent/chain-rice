package vision
// TODO:
// [ ] OrtSession RICE_ONNX_MODEL_PATH; CUDA/TensorRT EP flags — https://onnxruntime.ai/docs/
//

import "core:c"

when ODIN_OS == .Linux {
	foreign import libonnx {
		"lib/libonnxruntime.so",
	}
} else when ODIN_OS == .Darwin {
	foreign import libonnx {
		"lib/libonnxruntime.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import libonnx {
		"lib/onnxruntime.lib",
	}
}

OrtEnv :: distinct rawptr
OrtSession :: distinct rawptr
OrtSessionOptions :: distinct rawptr
OrtRunOptions :: distinct rawptr
OrtValue :: distinct rawptr
OrtTensorTypeAndShapeInfo :: distinct rawptr
OrtAllocator :: distinct rawptr
OrtMemoryInfo :: distinct rawptr
OrtIoBinding :: distinct rawptr
OrtModelMetadata :: distinct rawptr

foreign libonnx {
	OrtCreateEnv :: proc(logging_level: c.int, logid: cstring, out_: ^OrtEnv) -> rawptr ---
	OrtReleaseEnv :: proc(env: OrtEnv) ---

	OrtCreateSessionOptions :: proc(options: ^OrtSessionOptions) -> rawptr ---
	OrtReleaseSessionOptions :: proc(options: OrtSessionOptions) ---

	OrtSetIntraOpNumThreads :: proc(options: OrtSessionOptions, intra_op_num_threads: c.int) -> rawptr ---
	OrtSetInterOpNumThreads :: proc(options: OrtSessionOptions, inter_op_num_threads: c.int) -> rawptr ---

	OrtSessionOptionsAppendExecutionProvider_CUDA :: proc(options: OrtSessionOptions, device_id: c.int) -> rawptr ---
	OrtSessionOptionsAppendExecutionProvider_TensorRT :: proc(options: OrtSessionOptions, device_id: c.int) -> rawptr ---

	OrtCreateSession :: proc(env: OrtEnv, model_path: cstring, options: OrtSessionOptions, out_: ^OrtSession) -> rawptr ---
	OrtReleaseSession :: proc(session: OrtSession) ---

	OrtCreateTensorWithDataAsOrtValue :: proc(info: OrtMemoryInfo, p_data: rawptr, p_data_len: u64, shape: ^i64, shape_len: u64, type: c.int, out_: ^OrtValue) -> rawptr ---
	OrtCreateTensorAsOrtValue :: proc(allocator: OrtAllocator, shape: ^i64, shape_len: u64, type: c.int, out_: ^OrtValue) -> rawptr ---

	OrtRun :: proc(session: OrtSession, run_options: OrtRunOptions, input_names: [^]cstring, inputs: [^]OrtValue, input_len: u64, output_names: [^]cstring, output_len: u64, outputs: [^]OrtValue) -> rawptr ---
	OrtRunWithBinding :: proc(session: OrtSession, run_options: OrtRunOptions, binding: OrtIoBinding) -> rawptr ---

	OrtGetTensorMutableData :: proc(value: OrtValue, out_: ^rawptr) -> rawptr ---
	OrtGetTensorTypeAndShape :: proc(value: OrtValue, out_: ^OrtTensorTypeAndShapeInfo) -> rawptr ---

	OrtGetDimensionsCount :: proc(info: OrtTensorTypeAndShapeInfo, out_: ^u64) -> rawptr ---
	OrtGetDimensions :: proc(info: OrtTensorTypeAndShapeInfo, dim_values: [^]i64, dim_values_length: u64) -> rawptr ---

	OrtSessionGetInputCount :: proc(session: OrtSession, out_: ^u64) -> rawptr ---
	OrtSessionGetOutputCount :: proc(session: OrtSession, out_: ^u64) -> rawptr ---

	OrtSessionGetInputName :: proc(session: OrtSession, index: u64, allocator: OrtAllocator, value: ^cstring) -> rawptr ---
	OrtSessionGetOutputName :: proc(session: OrtSession, index: u64, allocator: OrtAllocator, value: ^cstring) -> rawptr ---

	OrtGetErrorCode :: proc(status: rawptr) -> c.int ---
	OrtGetErrorMessage :: proc(status: rawptr) -> cstring ---
	OrtReleaseStatus :: proc(status: rawptr) ---

	OrtCreateIoBinding :: proc(session: OrtSession, out_: ^OrtIoBinding) -> rawptr ---
	OrtReleaseIoBinding :: proc(binding: OrtIoBinding) ---

	OrtBindInput :: proc(binding: OrtIoBinding, name: cstring, value: OrtValue) -> rawptr ---
	OrtBindOutput :: proc(binding: OrtIoBinding, name: cstring, value: OrtValue) -> rawptr ---
	OrtBindOutputToDevice :: proc(binding: OrtIoBinding, name: cstring, mem_info: OrtMemoryInfo) -> rawptr ---
}
