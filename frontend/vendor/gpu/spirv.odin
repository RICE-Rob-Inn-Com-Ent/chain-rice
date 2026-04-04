package gpu
// TODO:
// [ ] load .spv from RICE_SHADER_DIR; validate magic; hot reload inotify — https://github.com/KhronosGroup/SPIRV-Tools
//

import "core:c"

foreign import libspirv "lib/libSPIRV-Tools.a"

SpvContext :: distinct rawptr
SpvBinary :: distinct rawptr
SpvText :: distinct rawptr

SpvTargetEnv :: distinct c.int

SPV_TARGET_ENV_VULKAN_1_0 :: SpvTargetEnv : 0
SPV_TARGET_ENV_VULKAN_1_1 :: SpvTargetEnv : 1
SPV_TARGET_ENV_VULKAN_1_2 :: SpvTargetEnv : 2
SPV_TARGET_ENV_VULKAN_1_3 :: SpvTargetEnv : 3

foreign libspirv {
	spvContextCreate :: proc(env: SpvTargetEnv) -> SpvContext ---
	spvContextDestroy :: proc(ctx: SpvContext) ---

	spvTextToBinary :: proc(
		ctx: SpvContext,
		code: cstring,
		len: u32,
		binary: ^SpvBinary,
		diag: rawptr,
	) -> i32 ---

	spvBinaryToText :: proc(
		ctx: SpvContext,
		binary: SpvBinary,
		options: u32,
		text: ^SpvText,
		diag: rawptr,
	) -> i32 ---

	spvValidate :: proc(ctx: SpvContext, binary: SpvBinary, diag: rawptr) -> i32 ---
	spvValidateBinary :: proc(binary: SpvBinary, diag: rawptr) -> i32 ---

	spvOptimize :: proc(ctx: SpvContext, binary: SpvBinary, optimized: ^SpvBinary) -> i32 ---

	spvOptimizerCreate :: proc(env: SpvTargetEnv) -> rawptr ---
	spvOptimizerDestroy :: proc(opt: rawptr) ---
	spvOptimizerRegisterPerformancePasses :: proc(opt: rawptr) ---
	spvOptimizerRegisterSizePasses :: proc(opt: rawptr) ---
	spvOptimizerRun :: proc(opt: rawptr, binary: SpvBinary, optimized: ^SpvBinary) -> i32 ---
}
