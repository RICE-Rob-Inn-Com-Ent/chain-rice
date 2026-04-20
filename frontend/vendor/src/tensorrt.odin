package gpu
// TODO:
// [ ] TensorRT build from ONNX RICE_TENSORRT_MODEL_PATH; cache RICE_TENSORRT_CACHE_DIR — https://docs.nvidia.com/deeplearning/tensorrt/
//

import "core:c"

when ODIN_OS == .Linux {
	foreign import libnvinfer {
		"lib/libnvinfer.so",
	}
} else when ODIN_OS == .Darwin {
	foreign import libnvinfer {
		"lib/libnvinfer.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import libnvinfer {
		"lib/nvinfer.lib",
	}
}

ILogger :: distinct rawptr
IBuilder :: distinct rawptr
INetworkDefinition :: distinct rawptr
IBuilderConfig :: distinct rawptr
ICudaEngine :: distinct rawptr
IExecutionContext :: distinct rawptr
IRuntime :: distinct rawptr
ITensor :: distinct rawptr
ILayer :: distinct rawptr
IOptimizationProfile :: distinct rawptr

DataType :: enum c.int {
	FLOAT = 0,
	HALF = 1,
	INT8 = 2,
	INT32 = 3,
	BOOL = 4,
}

foreign libnvinfer {
	createInferBuilder :: proc(logger: ILogger) -> IBuilder ---
	createInferRuntime :: proc(logger: ILogger) -> IRuntime ---

	IBuilder_createNetworkV2 :: proc(builder: IBuilder, flags: u32) -> INetworkDefinition ---
	IBuilder_buildSerializedNetwork :: proc(builder: IBuilder, network: INetworkDefinition, config: IBuilderConfig) -> rawptr ---
	IBuilder_createOptimizationProfile :: proc(builder: IBuilder) -> IOptimizationProfile ---

	IRuntime_deserializeCudaEngine :: proc(runtime: IRuntime, blob: rawptr, size: u64) -> ICudaEngine ---

	ICudaEngine_createExecutionContext :: proc(engine: ICudaEngine) -> IExecutionContext ---

	ICudaEngine_getNbBindings :: proc(engine: ICudaEngine) -> i32 ---
	ICudaEngine_getBindingIndex :: proc(engine: ICudaEngine, name: cstring) -> i32 ---

	IExecutionContext_enqueueV3 :: proc(ctx: IExecutionContext, stream: rawptr) -> bool ---
	IExecutionContext_setInputTensorAddress :: proc(ctx: IExecutionContext, name: cstring, addr: rawptr) -> bool ---
	IExecutionContext_getOutputTensorAddress :: proc(ctx: IExecutionContext, name: cstring) -> rawptr ---

	INetworkDefinition_addInput :: proc(net: INetworkDefinition, name: cstring, dtype: DataType, dims: rawptr) -> ITensor ---
	INetworkDefinition_addConvolutionNd :: proc(net: INetworkDefinition, input: ITensor, nbOutputMaps: i32, kernelSize: rawptr, weights: rawptr, bias: rawptr) -> ILayer ---
	INetworkDefinition_addActivation :: proc(net: INetworkDefinition, input: ITensor, type: c.int) -> ILayer ---
	INetworkDefinition_markOutput :: proc(net: INetworkDefinition, tensor: ITensor) ---

	IBuilderConfig_setMemoryPoolLimit :: proc(config: IBuilderConfig, pool: c.int, size: u64) -> bool ---
}
