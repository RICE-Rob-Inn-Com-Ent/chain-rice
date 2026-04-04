package gpu
// TODO:
// [ ] OptiX raygen/miss/closest-hit; RICE_OPTIX_DENOISE — https://raytracing-docs.nvidia.com/optix7guide/index.html
//

import "core:c"

when ODIN_OS == .Linux {
	foreign import liboptix {
		"lib/liboptix.so",
	}
} else when ODIN_OS == .Darwin {
	foreign import liboptix {
		"lib/liboptix.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import liboptix {
		"lib/optix.lib",
	}
}

OptixDeviceContext :: distinct rawptr
OptixPipeline :: distinct rawptr
OptixModule :: distinct rawptr
OptixProgramGroup :: distinct rawptr
OptixShaderBindingTable :: struct {
	raygenRecord: rawptr,
	hitgroupRecord: rawptr,
	missRecord: rawptr,
	callableRecordBase: rawptr,
	callableRecordStrideInBytes: u64,
	callableRecordCount: u32,
}

OptixAccelBufferSizes :: struct {
	outputSizeInBytes: u64,
	tempSizeInBytes: u64,
	compactSizeInBytes: u64,
}

OptixBuildInput :: struct {
	type: u32,
	u: rawptr,
}

OptixAccelBuildOptions :: struct {
	buildFlags: u32,
	operation: u32,
	motionOptions: rawptr,
}

OptixRayFlags :: enum u32 {
	NONE                = 0,
	TERMINATE_ON_FIRST_HIT = 1,
	ENFORCE_ANYHIT      = 2,
	DISABLE_ANYHIT      = 4,
	CULL_BACK_FACING_TRIANGLES = 8,
	CULL_FRONT_FACING_TRIANGLES = 16,
	CULL_DISABLE        = 32,
}

OptixPrimitiveType :: enum u32 {
	CUSTOM = 0,
	CURVE = 1,
	TRIANGLE = 2,
	SPHERE = 3,
}

foreign liboptix {
	optixInit :: proc() -> i32 ---
	optixDeviceContextCreate :: proc(cudaContext: rawptr, options: rawptr, context: ^OptixDeviceContext) -> i32 ---
	optixDeviceContextDestroy :: proc(context: OptixDeviceContext) ---

	optixModuleCreate :: proc(context: OptixDeviceContext, moduleCompileOptions: rawptr, pipelineCompileOptions: rawptr, input: cstring, inputSize: u64, ptxName: cstring, module: ^OptixModule) -> i32 ---
	optixModuleDestroy :: proc(module: OptixModule) ---

	optixProgramGroupCreate :: proc(
		context: OptixDeviceContext,
		programDescriptions: rawptr,
		numProgramGroups: u32,
		programGroupOptions: rawptr,
		options: rawptr,
		programGroups: ^OptixProgramGroup,
	) -> i32 ---

	optixProgramGroupDestroy :: proc(programGroup: OptixProgramGroup) ---

	optixPipelineCreate :: proc(
		context: OptixDeviceContext,
		programGroups: ^OptixProgramGroup,
		numProgramGroups: u32,
		pipelineCompileOptions: rawptr,
		pipelineLinkOptions: rawptr,
		pipeline: ^OptixPipeline,
	) -> i32 ---

	optixPipelineDestroy :: proc(pipeline: OptixPipeline) ---
	optixPipelineSetStackSize :: proc(pipeline: OptixPipeline, directCallableStackSizeFromTraversal: u32, directCallableStackSizeFromState: u32, continuationStackSize: u32, maxTraversableGraphDepth: u32) -> i32 ---

	optixAccelComputeMemoryUsage :: proc(
		context: OptixDeviceContext,
		accelOptions: rawptr,
		buildInputs: ^OptixBuildInput,
		numBuildInputs: u32,
		bufferSizes: ^OptixAccelBufferSizes,
	) -> i32 ---

	optixAccelBuild :: proc(
		context: OptixDeviceContext,
		stream: rawptr,
		accelOptions: rawptr,
		buildInputs: ^OptixBuildInput,
		numBuildInputs: u32,
		tempBuffer: rawptr,
		tempBufferSizeInBytes: u64,
		outputBuffer: rawptr,
		outputBufferSizeInBytes: u64,
		compactedSizeOut: ^u64,
		emittedProperty: rawptr,
		numEmittedProperties: u32,
	) -> i32 ---

	optixAccelCompact :: proc(
		context: OptixDeviceContext,
		stream: rawptr,
		accelHandle: rawptr,
		outputBuffer: rawptr,
		outputBufferSizeInBytes: u64,
		compactedAccelHandle: ^rawptr,
	) -> i32 ---

	optixLaunch :: proc(
		pipeline: OptixPipeline,
		stream: rawptr,
		imageWidth: u32,
		imageHeight: u32,
		imageDepth: u32,
		sbt: ^OptixShaderBindingTable,
	) -> i32 ---

	optixSbtRecordPackHeader :: proc(programGroup: OptixProgramGroup, sbtRecordHeader: rawptr) -> i32 ---
}
