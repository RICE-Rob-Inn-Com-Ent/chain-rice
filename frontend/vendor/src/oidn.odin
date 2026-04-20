package vision
// TODO:
// [ ] oidn device RICE_OIDN_DEVICE; RT filter — https://www.openimagedenoise.org/
//

import "core:c"

when ODIN_OS == .Linux {
	foreign import liboidn {
		"lib/libOpenImageDenoise.so",
	}
} else when ODIN_OS == .Darwin {
	foreign import liboidn {
		"lib/libOpenImageDenoise.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import liboidn {
		"lib/OpenImageDenoise.lib",
	}
}

OIDNDevice :: distinct rawptr
OIDNFilter :: distinct rawptr
OIDNBuffer :: distinct rawptr

OIDNDeviceType :: enum c.int {
	DEFAULT = 0,
	CPU = 1,
	SYCL = 2,
	CUDA = 3,
	HIP = 4,
	METAL = 5,
}

OIDNFormat :: enum c.int {
	UNDEFINED = 0,
	FLOAT = 1,
	FLOAT2 = 2,
	FLOAT3 = 3,
	FLOAT4 = 4,
}

OIDNAccess :: enum c.int {
	READ = 0,
	WRITE = 1,
	READ_WRITE = 2,
}

OIDNQuality :: enum c.int {
	DEFAULT = 0,
	BALANCED = 1,
	HIGH = 2,
}

OIDN_DEVICE_TYPE_DEFAULT :: OIDNDeviceType : .DEFAULT
OIDN_DEVICE_TYPE_CPU :: OIDNDeviceType : .CPU
OIDN_DEVICE_TYPE_SYCL :: OIDNDeviceType : .SYCL
OIDN_DEVICE_TYPE_CUDA :: OIDNDeviceType : .CUDA
OIDN_DEVICE_TYPE_HIP :: OIDNDeviceType : .HIP
OIDN_DEVICE_TYPE_METAL :: OIDNDeviceType : .METAL

OIDN_QUALITY_DEFAULT :: OIDNQuality : .DEFAULT
OIDN_QUALITY_BALANCED :: OIDNQuality : .BALANCED
OIDN_QUALITY_HIGH :: OIDNQuality : .HIGH

OIDN_FORMAT_UNDEFINED :: OIDNFormat : .UNDEFINED
OIDN_FORMAT_FLOAT :: OIDNFormat : .FLOAT
OIDN_FORMAT_FLOAT2 :: OIDNFormat : .FLOAT2
OIDN_FORMAT_FLOAT3 :: OIDNFormat : .FLOAT3
OIDN_FORMAT_FLOAT4 :: OIDNFormat : .FLOAT4

foreign liboidn {
	oidnNewDevice :: proc(type: OIDNDeviceType) -> OIDNDevice ---
	oidnReleaseDevice :: proc(device: OIDNDevice) ---
	oidnCommitDevice :: proc(device: OIDNDevice) ---

	oidnGetDeviceError :: proc(device: OIDNDevice, message: ^cstring) -> i32 ---
	oidnSetDeviceInt :: proc(device: OIDNDevice, name: cstring, value: i32) ---

	oidnNewBuffer :: proc(device: OIDNDevice, byteSize: u64) -> OIDNBuffer ---
	oidnReleaseBuffer :: proc(buffer: OIDNBuffer) ---

	oidnNewSharedBuffer :: proc(device: OIDNDevice, ptr: rawptr, byteSize: u64) -> OIDNBuffer ---
	oidnGetBufferData :: proc(buffer: OIDNBuffer) -> rawptr ---

	oidnNewFilter :: proc(device: OIDNDevice, type: cstring) -> OIDNFilter ---
	oidnReleaseFilter :: proc(filter: OIDNFilter) ---
	oidnCommitFilter :: proc(filter: OIDNFilter) ---

	oidnSetFilterImage :: proc(filter: OIDNFilter, name: cstring, image: OIDNBuffer, format: OIDNFormat, width: u64, height: u64, byteOffset: u64, pixelStride: u64, rowStride: u64) ---
	oidnSetFilterFloat :: proc(filter: OIDNFilter, name: cstring, value: f32) ---
	oidnSetFilter1b :: proc(filter: OIDNFilter, name: cstring, value: bool) ---
	oidnSetSharedFilterImage :: proc(filter: OIDNFilter, name: cstring, ptr: rawptr, format: OIDNFormat, width: u64, height: u64, byteOffset: u64, pixelStride: u64, rowStride: u64) ---
	oidnSetFilterInt :: proc(filter: OIDNFilter, name: cstring, value: i32) ---

	oidnExecuteFilter :: proc(filter: OIDNFilter) ---
	oidnExecuteFilterAsync :: proc(filter: OIDNFilter) ---

	oidnGetFilterError :: proc(filter: OIDNFilter, message: ^cstring) -> i32 ---
	oidnResetFilterError :: proc(filter: OIDNFilter) ---
}
