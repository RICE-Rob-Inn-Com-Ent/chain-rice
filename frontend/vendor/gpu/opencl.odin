package gpu
// TODO:
// [ ] cl platforms/devices; clEnqueueNDRangeKernel AMD/Intel fallback — https://www.khronos.org/opencl/
//

import "core:c"

when ODIN_OS == .Linux {
	foreign import libopencl {
		"lib/libOpenCL.so",
	}
} else when ODIN_OS == .Darwin {
	foreign import libopencl {
		"lib/libOpenCL.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import libopencl {
		"lib/OpenCL.lib",
	}
}

cl_platform_id :: distinct rawptr
cl_device_id :: distinct rawptr
cl_context :: distinct rawptr
cl_command_queue :: distinct rawptr
cl_program :: distinct rawptr
cl_kernel :: distinct rawptr
cl_mem :: distinct rawptr
cl_event :: distinct rawptr
cl_sampler :: distinct rawptr

CL_DEVICE_TYPE_GPU :: u64 : 1 << 2
CL_DEVICE_TYPE_CPU :: u64 : 1 << 1
CL_DEVICE_TYPE_ALL :: u64 : 0xFFFFFFFF

cl_int :: i32

CL_Error :: enum i32 {
	SUCCESS = 0,
	DEVICE_NOT_FOUND = -1,
	DEVICE_NOT_AVAILABLE = -2,
	COMPILER_NOT_AVAILABLE = -3,
	MEM_OBJECT_ALLOCATION_FAILURE = -4,
	OUT_OF_RESOURCES = -5,
	OUT_OF_HOST_MEMORY = -6,
	PROFILING_INFO_NOT_AVAILABLE = -7,
	MEM_COPY_OVERLAP = -8,
	IMAGE_FORMAT_MISMATCH = -9,
	IMAGE_FORMAT_NOT_SUPPORTED = -10,
	BUILD_PROGRAM_FAILURE = -11,
	MAP_FAILURE = -12,
	INVALID_VALUE = -30,
	INVALID_DEVICE_TYPE = -31,
	INVALID_PLATFORM = -32,
	INVALID_DEVICE = -33,
	INVALID_CONTEXT = -34,
	INVALID_QUEUE_PROPERTIES = -35,
	INVALID_COMMAND_QUEUE = -36,
	INVALID_HOST_PTR = -37,
	INVALID_MEM_OBJECT = -38,
	INVALID_IMAGE_FORMAT_DESCRIPTOR = -39,
	INVALID_IMAGE_SIZE = -40,
	INVALID_SAMPLER = -41,
	INVALID_BINARY = -42,
	INVALID_BUILD_OPTIONS = -43,
	INVALID_PROGRAM = -44,
	INVALID_PROGRAM_EXECUTABLE = -45,
	INVALID_KERNEL_NAME = -46,
	INVALID_KERNEL_DEFINITION = -47,
	INVALID_KERNEL = -48,
	INVALID_ARG_INDEX = -49,
	INVALID_ARG_VALUE = -50,
	INVALID_ARG_SIZE = -51,
	INVALID_KERNEL_ARGS = -52,
	INVALID_WORK_DIMENSION = -53,
	INVALID_WORK_GROUP_SIZE = -54,
	INVALID_WORK_ITEM_SIZE = -55,
	INVALID_GLOBAL_OFFSET = -56,
	INVALID_EVENT_WAIT_LIST = -57,
	INVALID_EVENT = -58,
	INVALID_OPERATION = -59,
	INVALID_GL_OBJECT = -60,
	INVALID_BUFFER_SIZE = -61,
	INVALID_MIP_LEVEL = -62,
	INVALID_GLOBAL_WORK_SIZE = -63,
}

foreign libopencl {
	clGetPlatformIDs :: proc(num_entries: u32, platforms: [^]cl_platform_id, num_platforms: ^u32) -> cl_int ---
	clGetPlatformInfo :: proc(platform: cl_platform_id, param_name: u32, param_value_size: u64, param_value: rawptr, param_value_size_ret: ^u64) -> cl_int ---

	clGetDeviceIDs :: proc(platform: cl_platform_id, device_type: u64, num_entries: u32, devices: [^]cl_device_id, num_devices: ^u32) -> cl_int ---
	clGetDeviceInfo :: proc(device: cl_device_id, param_name: u32, param_value_size: u64, param_value: rawptr, param_value_size_ret: ^u64) -> cl_int ---

	clCreateContext :: proc(properties: [^]rawptr, num_devices: u32, devices: [^]cl_device_id, pfn_notify: rawptr, user_data: rawptr, errcode_ret: ^cl_int) -> cl_context ---
	clReleaseContext :: proc(context: cl_context) -> cl_int ---

	clCreateCommandQueueWithProperties :: proc(context: cl_context, device: cl_device_id, properties: [^]u64, errcode_ret: ^cl_int) -> cl_command_queue ---
	clReleaseCommandQueue :: proc(queue: cl_command_queue) -> cl_int ---

	clCreateBuffer :: proc(context: cl_context, flags: u64, size: u64, host_ptr: rawptr, errcode_ret: ^cl_int) -> cl_mem ---
	clReleaseMemObject :: proc(memobj: cl_mem) -> cl_int ---

	clEnqueueReadBuffer :: proc(queue: cl_command_queue, buffer: cl_mem, blocking: bool, offset: u64, size: u64, ptr: rawptr, num_events: u32, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_int ---
	clEnqueueWriteBuffer :: proc(queue: cl_command_queue, buffer: cl_mem, blocking: bool, offset: u64, size: u64, ptr: rawptr, num_events: u32, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_int ---
	clEnqueueCopyBuffer :: proc(queue: cl_command_queue, src: cl_mem, dst: cl_mem, src_offset: u64, dst_offset: u64, size: u64, num_events: u32, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_int ---

	clCreateImage :: proc(context: cl_context, flags: u64, format: rawptr, desc: rawptr, host_ptr: rawptr, errcode_ret: ^cl_int) -> cl_mem ---
	clEnqueueReadImage :: proc(queue: cl_command_queue, image: cl_mem, blocking: bool, origin: [^]u64, region: [^]u64, row_pitch: u64, slice_pitch: u64, ptr: rawptr, num_events: u32, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_int ---
	clEnqueueWriteImage :: proc(queue: cl_command_queue, image: cl_mem, blocking: bool, origin: [^]u64, region: [^]u64, row_pitch: u64, slice_pitch: u64, ptr: rawptr, num_events: u32, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_int ---

	clCreateProgramWithSource :: proc(context: cl_context, count: u32, strings: [^]cstring, lengths: [^]u64, errcode_ret: ^cl_int) -> cl_program ---
	clCreateProgramWithBinary :: proc(context: cl_context, num_devices: u32, devices: [^]cl_device_id, lengths: [^]u64, binaries: [^]rawptr, binary_status: [^]cl_int, errcode_ret: ^cl_int) -> cl_program ---
	clBuildProgram :: proc(program: cl_program, num_devices: u32, devices: [^]cl_device_id, options: cstring, pfn_notify: rawptr, user_data: rawptr) -> cl_int ---
	clGetProgramBuildInfo :: proc(program: cl_program, device: cl_device_id, param_name: u32, param_value_size: u64, param_value: rawptr, param_value_size_ret: ^u64) -> cl_int ---

	clCreateKernel :: proc(program: cl_program, kernel_name: cstring, errcode_ret: ^cl_int) -> cl_kernel ---
	clReleaseKernel :: proc(kernel: cl_kernel) -> cl_int ---

	clSetKernelArg :: proc(kernel: cl_kernel, arg_index: u32, arg_size: u64, arg_value: rawptr) -> cl_int ---
	clEnqueueNDRangeKernel :: proc(queue: cl_command_queue, kernel: cl_kernel, work_dim: u32, global_work_offset: [^]u64, global_work_size: [^]u64, local_work_size: [^]u64, num_events: u32, event_wait_list: [^]cl_event, event: ^cl_event) -> cl_int ---

	clFinish :: proc(queue: cl_command_queue) -> cl_int ---
	clFlush :: proc(queue: cl_command_queue) -> cl_int ---
	clWaitForEvents :: proc(num_events: u32, event_list: [^]cl_event) -> cl_int ---
}
