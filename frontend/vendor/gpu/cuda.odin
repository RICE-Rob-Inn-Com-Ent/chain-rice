package gpu
// TODO:
// [ ] cuInit, cuCtxCreate, streams, cuLaunchKernel — https://docs.nvidia.com/cuda/cuda-driver-api/
//

import "core:c"

when ODIN_OS == .Linux {
	foreign import libcuda {
		"lib/libcuda.so",
	}
} else when ODIN_OS == .Darwin {
	foreign import libcuda {
		"lib/libcuda.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import libcuda {
		"lib/cuda.lib",
	}
}

CUdevice :: distinct c.int
CUcontext :: distinct rawptr
CUmodule :: distinct rawptr
CUfunction :: distinct rawptr
CUstream :: distinct rawptr
CUevent :: distinct rawptr
CUdeviceptr :: distinct u64
CUarray :: distinct rawptr
CUtexref :: distinct rawptr

CUresult :: enum c.int {
	SUCCESS                              = 0,
	ERROR_INVALID_VALUE                  = 1,
	ERROR_OUT_OF_MEMORY                  = 2,
	ERROR_NOT_INITIALIZED                = 3,
	ERROR_DEINITIALIZED                  = 4,
	ERROR_PROFILER_DISABLED              = 5,
	ERROR_PROFILER_NOT_INITIALIZED       = 6,
	ERROR_PROFILER_ALREADY_STARTED         = 7,
	ERROR_PROFILER_ALREADY_STOPPED         = 8,
	ERROR_NO_DEVICE                      = 100,
	ERROR_INVALID_DEVICE                 = 101,
	ERROR_INVALID_IMAGE                  = 200,
	ERROR_INVALID_CONTEXT                = 201,
	ERROR_CONTEXT_ALREADY_CURRENT        = 202,
	ERROR_MAP_FAILED                     = 205,
	ERROR_UNMAP_FAILED                   = 206,
	ERROR_ARRAY_IS_MAPPED                = 207,
	ERROR_ALREADY_MAPPED                 = 208,
	ERROR_NO_BINARY_FOR_GPU              = 209,
	ERROR_ALREADY_ACQUIRED               = 210,
	ERROR_NOT_MAPPED                     = 211,
	ERROR_NOT_MAPPED_AS_ARRAY            = 212,
	ERROR_NOT_MAPPED_AS_POINTER          = 213,
	ERROR_ECC_UNCORRECTABLE              = 214,
	ERROR_UNSUPPORTED_LIMIT              = 215,
	ERROR_CONTEXT_ALREADY_IN_USE         = 216,
	ERROR_PEER_ACCESS_UNSUPPORTED        = 217,
	ERROR_INVALID_PTX                    = 218,
	ERROR_INVALID_GRAPHICS_CONTEXT       = 219,
	ERROR_NVLINK_UNCORRECTABLE           = 220,
	ERROR_JIT_COMPILER_NOT_FOUND         = 221,
	ERROR_UNSUPPORTED_PTX_VERSION        = 222,
	ERROR_JIT_COMPILATION_DISABLED       = 223,
	ERROR_UNSUPPORTED_EXEC_AFFINITY      = 224,
	ERROR_UNSUPPORTED_DEVSIDE_SYNC       = 225,
	ERROR_INVALID_SOURCE                 = 300,
	ERROR_FILE_NOT_FOUND                 = 301,
	ERROR_SHARED_OBJECT_SYMBOL_NOT_FOUND = 302,
	ERROR_SHARED_OBJECT_INIT_FAILED      = 303,
	ERROR_OPERATING_SYSTEM               = 304,
	ERROR_INVALID_HANDLE                 = 400,
	ERROR_ILLEGAL_STATE                  = 401,
	ERROR_NOT_FOUND                      = 500,
	ERROR_NOT_READY                      = 600,
	ERROR_LAUNCH_FAILED                  = 700,
	ERROR_LAUNCH_OUT_OF_RESOURCES        = 701,
	ERROR_LAUNCH_TIMEOUT                 = 702,
	ERROR_LAUNCH_INCOMPATIBLE_TEXTURING  = 703,
	ERROR_PEER_ACCESS_ALREADY_ENABLED    = 704,
	ERROR_PEER_ACCESS_NOT_ENABLED        = 705,
	ERROR_PRIMARY_CONTEXT_ACTIVE           = 708,
	ERROR_CONTEXT_IS_DESTROYED             = 709,
	ERROR_UNKNOWN                          = 999,
}

foreign libcuda {
	cuInit :: proc(Flags: u32) -> CUresult ---
	cuDriverGetVersion :: proc(driverVersion: ^i32) -> CUresult ---

	cuDeviceGet :: proc(device: ^CUdevice, ordinal: c.int) -> CUresult ---
	cuDeviceGetCount :: proc(count: ^c.int) -> CUresult ---
	cuDeviceGetName :: proc(name: [^]c.char, len: c.int, dev: CUdevice) -> CUresult ---
	cuDeviceGetAttribute :: proc(pi: ^c.int, attrib: c.int, dev: CUdevice) -> CUresult ---
	cuDeviceTotalMem :: proc(bytes: ^u64, dev: CUdevice) -> CUresult ---

	cuCtxCreate :: proc(pctx: ^CUcontext, flags: u32, dev: CUdevice) -> CUresult ---
	cuCtxDestroy :: proc(ctx: CUcontext) -> CUresult ---
	cuCtxSynchronize :: proc() -> CUresult ---

	cuMemAlloc :: proc(dptr: ^CUdeviceptr, bytesize: u64) -> CUresult ---
	cuMemFree :: proc(dptr: CUdeviceptr) -> CUresult ---
	cuMemAllocHost :: proc(pp: ^rawptr, bytesize: u64) -> CUresult ---
	cuMemFreeHost :: proc(p: rawptr) -> CUresult ---

	cuMemcpyHtoD :: proc(dstDevice: CUdeviceptr, srcHost: rawptr, ByteCount: u64) -> CUresult ---
	cuMemcpyDtoH :: proc(dstHost: rawptr, srcDevice: CUdeviceptr, ByteCount: u64) -> CUresult ---
	cuMemcpyDtoD :: proc(dstDevice: CUdeviceptr, srcDevice: CUdeviceptr, ByteCount: u64) -> CUresult ---

	cuMemcpyHtoDAsync :: proc(dstDevice: CUdeviceptr, srcHost: rawptr, ByteCount: u64, hStream: CUstream) -> CUresult ---
	cuMemcpyDtoHAsync :: proc(dstHost: rawptr, srcDevice: CUdeviceptr, ByteCount: u64, hStream: CUstream) -> CUresult ---

	cuLaunchKernel :: proc(
		f: CUfunction,
		gridDimX: u32,
		gridDimY: u32,
		gridDimZ: u32,
		blockDimX: u32,
		blockDimY: u32,
		blockDimZ: u32,
		sharedMemBytes: u32,
		hStream: CUstream,
		kernelParams: ^rawptr,
		extra: ^rawptr,
	) -> CUresult ---

	cuFuncSetCacheConfig :: proc(hfunc: CUfunction, config: c.int) -> CUresult ---

	cuModuleLoad :: proc(module: ^CUmodule, fname: cstring) -> CUresult ---
	cuModuleLoadData :: proc(module: ^CUmodule, image: rawptr) -> CUresult ---
	cuModuleUnload :: proc(hmod: CUmodule) -> CUresult ---

	cuModuleGetFunction :: proc(hfunc: ^CUfunction, hmod: CUmodule, name: cstring) -> CUresult ---
	cuModuleGetGlobal :: proc(dptr: ^CUdeviceptr, bytes: ^u64, hmod: CUmodule, name: cstring) -> CUresult ---

	cuStreamCreate :: proc(phStream: ^CUstream, Flags: u32) -> CUresult ---
	cuStreamDestroy :: proc(hStream: CUstream) -> CUresult ---
	cuStreamSynchronize :: proc(hStream: CUstream) -> CUresult ---

	cuEventCreate :: proc(phEvent: ^CUevent, Flags: u32) -> CUresult ---
	cuEventDestroy :: proc(hEvent: CUevent) -> CUresult ---
	cuEventRecord :: proc(hEvent: CUevent, hStream: CUstream) -> CUresult ---
	cuEventSynchronize :: proc(hEvent: CUevent) -> CUresult ---
	cuEventElapsedTime :: proc(pMilliseconds: ^f32, hStart: CUevent, hEnd: CUevent) -> CUresult ---
}
