package gpu
// TODO:
// [ ] nvmlInit/Shutdown; utilization temp memory power — https://docs.nvidia.com/deploy/nvml-api/
// [ ] poll RICE_GPU_POLL_INTERVAL_S; alerts RICE_GPU_MAX_TEMP_C, RICE_GPU_AI_THRESHOLD
//

import "core:c"

when ODIN_OS == .Linux {
	foreign import libnvml {
		"lib/libnvidia-ml.so",
	}
} else when ODIN_OS == .Darwin {
	foreign import libnvml {
		"lib/libnvidia-ml.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import libnvml {
		"lib/nvml.lib",
	}
}

nvmlDevice_t :: distinct rawptr

nvmlReturn_t :: enum c.int {
	SUCCESS = 0,
	ERROR_UNINITIALIZED = 1,
	ERROR_INVALID_ARGUMENT = 2,
	ERROR_NOT_SUPPORTED = 3,
	ERROR_NO_PERMISSION = 4,
	ERROR_GPU_IS_LOST = 6,
	ERROR_UNKNOWN = 999,
}

nvmlMemory_t :: struct {
	total: u64,
	free: u64,
	used: u64,
}

nvmlUtilization_t :: struct {
	gpu: u32,
	memory: u32,
}

nvmlClockType_t :: enum c.int {
	GRAPHICS = 0,
	SM = 1,
	MEM = 2,
	VIDEO = 3,
}

nvmlTemperatureSensors_t :: enum c.int {
	GPU = 0,
}

NVML_TEMPERATURE_GPU :: c.int : 0
NVML_CLOCK_GRAPHICS :: nvmlClockType_t.GRAPHICS

foreign libnvml {
	nvmlInit :: proc() -> nvmlReturn_t ---
	nvmlShutdown :: proc() -> nvmlReturn_t ---
	nvmlInitWithFlags :: proc(flags: u32) -> nvmlReturn_t ---

	nvmlDeviceGetCount :: proc(deviceCount: ^u32) -> nvmlReturn_t ---
	nvmlDeviceGetHandleByIndex :: proc(index: u32, device: ^nvmlDevice_t) -> nvmlReturn_t ---
	nvmlDeviceGetHandleBySerial :: proc(serial: cstring, device: ^nvmlDevice_t) -> nvmlReturn_t ---
	nvmlDeviceGetHandleByUUID :: proc(uuid: cstring, device: ^nvmlDevice_t) -> nvmlReturn_t ---

	nvmlDeviceGetName :: proc(device: nvmlDevice_t, name: [^]c.char, length: u32) -> nvmlReturn_t ---
	nvmlDeviceGetSerial :: proc(device: nvmlDevice_t, serial: [^]c.char, length: u32) -> nvmlReturn_t ---
	nvmlDeviceGetUUID :: proc(device: nvmlDevice_t, uuid: [^]c.char, length: u32) -> nvmlReturn_t ---

	nvmlDeviceGetTemperature :: proc(device: nvmlDevice_t, sensorType: nvmlTemperatureSensors_t, temp: ^u32) -> nvmlReturn_t ---
	nvmlDeviceGetPowerUsage :: proc(device: nvmlDevice_t, power: ^u32) -> nvmlReturn_t ---

	nvmlDeviceGetUtilizationRates :: proc(device: nvmlDevice_t, utilization: ^nvmlUtilization_t) -> nvmlReturn_t ---
	nvmlDeviceGetMemoryInfo :: proc(device: nvmlDevice_t, memory: ^nvmlMemory_t) -> nvmlReturn_t ---

	nvmlDeviceGetClockInfo :: proc(device: nvmlDevice_t, type: nvmlClockType_t, clock: ^u32) -> nvmlReturn_t ---
	nvmlDeviceGetMaxClockInfo :: proc(device: nvmlDevice_t, type: nvmlClockType_t, clock: ^u32) -> nvmlReturn_t ---

	nvmlDeviceGetFanSpeed :: proc(device: nvmlDevice_t, speed: ^u32) -> nvmlReturn_t ---
	nvmlDeviceGetPerformanceState :: proc(device: nvmlDevice_t, pState: ^i32) -> nvmlReturn_t ---

	nvmlDeviceGetComputeRunningProcesses :: proc(device: nvmlDevice_t, infoCount: ^u32, infos: rawptr) -> nvmlReturn_t ---
	nvmlDeviceGetGraphicsRunningProcesses :: proc(device: nvmlDevice_t, infoCount: ^u32, infos: rawptr) -> nvmlReturn_t ---

	nvmlDeviceGetTotalEnergyConsumption :: proc(device: nvmlDevice_t, energy: ^u64) -> nvmlReturn_t ---

	nvmlDeviceGetNvLinkState :: proc(device: nvmlDevice_t, link: u32, isActive: ^bool) -> nvmlReturn_t ---
	nvmlDeviceGetNvLinkCapability :: proc(device: nvmlDevice_t, link: u32, capability: u32, capResult: ^u32) -> nvmlReturn_t ---

	nvmlSystemGetDriverVersion :: proc(version: [^]c.char, length: u32) -> nvmlReturn_t ---
	nvmlSystemGetNVMLVersion :: proc(version: [^]c.char, length: u32) -> nvmlReturn_t ---
}
