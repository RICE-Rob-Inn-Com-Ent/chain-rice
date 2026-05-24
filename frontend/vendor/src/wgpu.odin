package vendor
// TODO:
// [ ] wgpuCreateInstance; RICE_RENDER backend vulkan/metal/dx12/webgl/auto — https://wgpu.rs/doc/wgpu/
// [ ] requestAdapter HighPerformance; requestDevice features/limits
// [ ] pipeline shaders from RICE_SHADER_DIR .spv
// [ ] AI GPU nvml.odin; optional WebGL fallback when SAGE busy
//

when ODIN_OS == .Linux {
	// Prefer system wgpu-native; override with RICE_WGPU_LIB or vendor/lib copy if needed.
	foreign import libwgpu {
		"system:wgpu_native",
	}
} else when ODIN_OS == .Darwin {
	foreign import libwgpu {
		"lib/libwgpu.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import libwgpu {
		"lib/wgpu.dll",
	}
}

WGPUInstance :: distinct rawptr
WGPUAdapter :: distinct rawptr
WGPUDevice :: distinct rawptr
WGPUQueue :: distinct rawptr
WGPUSurface :: distinct rawptr
WGPUBuffer :: distinct rawptr
WGPUTexture :: distinct rawptr
WGPUShaderModule :: distinct rawptr
WGPURenderPipeline :: distinct rawptr
WGPUComputePipeline :: distinct rawptr
WGPUBindGroup :: distinct rawptr
WGPUCommandEncoder :: distinct rawptr
WGPUCommandBuffer :: distinct rawptr
WGPURenderPassEncoder :: distinct rawptr
WGPUComputePassEncoder :: distinct rawptr
WGPUSwapChain :: distinct rawptr
WGPUBindGroupLayout :: distinct rawptr
WGPUPipelineLayout :: distinct rawptr
WGPUSampler :: distinct rawptr
WGPUQuerySet :: distinct rawptr

WGPUTextureFormat :: enum u32 {
	Undefined                = 0x00000000,
	R8Unorm                  = 0x00000001,
	R8Snorm                  = 0x00000002,
	R8Uint                   = 0x00000003,
	R8Sint                   = 0x00000004,
	R16Uint                  = 0x00000005,
	R16Sint                  = 0x00000006,
	R16Float                 = 0x00000007,
	RG8Unorm                 = 0x00000008,
	RG8Snorm                 = 0x00000009,
	RG8Uint                  = 0x0000000A,
	RG8Sint                  = 0x0000000B,
	R32Uint                  = 0x0000000C,
	R32Sint                  = 0x0000000D,
	R32Float                 = 0x0000000E,
	RG16Uint                 = 0x0000000F,
	RG16Sint                 = 0x00000010,
	RG16Float                = 0x00000011,
	RGBA8Unorm               = 0x00000012,
	RGBA8UnormSrgb           = 0x00000013,
	RGBA8Snorm               = 0x00000014,
	RGBA8Uint                = 0x00000015,
	RGBA8Sint                = 0x00000016,
	BGRA8Unorm               = 0x00000017,
	BGRA8UnormSrgb           = 0x00000018,
	RGB10A2Uint              = 0x00000019,
	RGB10A2Unorm             = 0x0000001A,
	RG11B10Ufloat            = 0x0000001B,
	RGB9E5Ufloat             = 0x0000001C,
	RG32Uint                 = 0x0000001D,
	RG32Sint                 = 0x0000001E,
	RG32Float                = 0x0000001F,
	RGBA16Uint               = 0x00000020,
	RGBA16Sint               = 0x00000021,
	RGBA16Float              = 0x00000022,
	RGBA32Uint               = 0x00000023,
	RGBA32Sint               = 0x00000024,
	RGBA32Float              = 0x00000025,
	Stencil8                 = 0x00000026,
	Depth16Unorm             = 0x00000027,
	Depth24Plus              = 0x00000028,
	Depth24PlusStencil8      = 0x00000029,
	Depth32Float             = 0x0000002A,
	Depth32FloatStencil8     = 0x0000002B,
}

WGPUBufferUsage :: enum u32 {
	None      = 0x0000,
	MapRead   = 0x0001,
	MapWrite  = 0x0002,
	CopySrc   = 0x0004,
	CopyDst   = 0x0008,
	Index     = 0x0010,
	Vertex    = 0x0020,
	Uniform   = 0x0040,
	Storage   = 0x0080,
	Indirect  = 0x0100,
	QueryResolve = 0x0200,
}

WGPUShaderStage :: enum u32 {
	None      = 0x0000,
	Vertex    = 0x0001,
	Fragment  = 0x0002,
	Compute   = 0x0004,
}

WGPUInstanceDescriptor :: struct {}
WGPURequestAdapterOptions :: struct {}
WGPUAdapterProperties :: struct {}
WGPUDeviceDescriptor :: struct {}
WGPUBufferDescriptor :: struct {}
WGPUTextureDescriptor :: struct {}
WGPUShaderModuleDescriptor :: struct {}
WGPURenderPipelineDescriptor :: struct {}
WGPUComputePipelineDescriptor :: struct {}
WGPUBindGroupDescriptor :: struct {}
WGPUCommandEncoderDescriptor :: struct {}
WGPUSurfaceConfiguration :: struct {}
WGPUSurfaceTexture :: struct {
	texture: WGPUTexture,
	suboptimal: bool,
}

foreign libwgpu {
	wgpuCreateInstance :: proc(descriptor: ^WGPUInstanceDescriptor) -> WGPUInstance ---
	wgpuInstanceRequestAdapter :: proc(
		instance: WGPUInstance,
		options: ^WGPURequestAdapterOptions,
		callback: rawptr,
		userdata: rawptr,
	) ---

	wgpuAdapterRequestDevice :: proc(
		adapter: WGPUAdapter,
		descriptor: ^WGPUDeviceDescriptor,
		callback: rawptr,
		userdata: rawptr,
	) ---
	wgpuAdapterGetProperties :: proc(adapter: WGPUAdapter, properties: ^WGPUAdapterProperties) ---

	wgpuDeviceCreateBuffer :: proc(device: WGPUDevice, descriptor: ^WGPUBufferDescriptor) -> WGPUBuffer ---
	wgpuDeviceCreateTexture :: proc(device: WGPUDevice, descriptor: ^WGPUTextureDescriptor) -> WGPUTexture ---
	wgpuDeviceCreateShaderModule :: proc(device: WGPUDevice, descriptor: ^WGPUShaderModuleDescriptor) -> WGPUShaderModule ---
	wgpuDeviceCreateRenderPipeline :: proc(device: WGPUDevice, descriptor: ^WGPURenderPipelineDescriptor) -> WGPURenderPipeline ---
	wgpuDeviceCreateComputePipeline :: proc(device: WGPUDevice, descriptor: ^WGPUComputePipelineDescriptor) -> WGPUComputePipeline ---
	wgpuDeviceCreateBindGroup :: proc(device: WGPUDevice, descriptor: ^WGPUBindGroupDescriptor) -> WGPUBindGroup ---
	wgpuDeviceCreateCommandEncoder :: proc(device: WGPUDevice, descriptor: ^WGPUCommandEncoderDescriptor) -> WGPUCommandEncoder ---
	wgpuDeviceGetQueue :: proc(device: WGPUDevice) -> WGPUQueue ---

	wgpuQueueSubmit :: proc(queue: WGPUQueue, commandCount: u32, commands: [^]WGPUCommandBuffer) ---
	wgpuQueueWriteBuffer :: proc(queue: WGPUQueue, buffer: WGPUBuffer, bufferOffset: u64, data: rawptr, size: u64) ---
	wgpuQueueWriteTexture :: proc(queue: WGPUQueue, destination: rawptr, data: rawptr, dataSize: u64, dataLayout: rawptr, writeSize: rawptr) ---

	wgpuSurfaceGetCurrentTexture :: proc(surface: WGPUSurface, surfaceTexture: ^WGPUSurfaceTexture) ---
	wgpuSurfaceConfigure :: proc(surface: WGPUSurface, config: ^WGPUSurfaceConfiguration) ---
	wgpuSurfacePresent :: proc(surface: WGPUSurface) -> u32 ---

	wgpuRenderPassEncoderSetPipeline :: proc(pass: WGPURenderPassEncoder, pipeline: WGPURenderPipeline) ---
	wgpuRenderPassEncoderDraw :: proc(pass: WGPURenderPassEncoder, vertexCount: u32, instanceCount: u32, firstVertex: u32, firstInstance: u32) ---
	wgpuRenderPassEncoderSetVertexBuffer :: proc(pass: WGPURenderPassEncoder, slot: u32, buffer: WGPUBuffer, offset: u64, size: u64) ---
	wgpuRenderPassEncoderSetIndexBuffer :: proc(pass: WGPURenderPassEncoder, buffer: WGPUBuffer, format: u32, offset: u64, size: u64) ---

	wgpuComputePassEncoderSetPipeline :: proc(pass: WGPUComputePassEncoder, pipeline: WGPUComputePipeline) ---
	wgpuComputePassEncoderDispatchWorkgroups :: proc(pass: WGPUComputePassEncoder, x: u32, y: u32, z: u32) ---

	wgpuBufferMapAsync :: proc(buffer: WGPUBuffer, mode: u32, offset: u64, size: u64, callback: rawptr, userdata: rawptr) ---
	wgpuBufferGetMappedRange :: proc(buffer: WGPUBuffer, offset: u64, size: u64) -> rawptr ---
	wgpuBufferUnmap :: proc(buffer: WGPUBuffer) ---
}

// vendor_wgpu_create_instance — мінімальна ініціалізація WebGPU instance (wgpu-native).
vendor_wgpu_create_instance :: proc() -> WGPUInstance {
	desc: WGPUInstanceDescriptor
	return wgpuCreateInstance(&desc)
}

