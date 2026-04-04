package gpu
// TODO:
// [ ] vmaCreateAllocator; RICE_VMA_STRATEGY; budget RICE_VMA_BUDGET_THRESHOLD — https://gpuopen-librariesandsdks.github.io/VulkanMemoryAllocator/html/
//

import "core:c"

foreign import libvma "lib/libvma.a"

VmaAllocator :: distinct rawptr
VmaAllocation :: distinct rawptr
VmaPool :: distinct rawptr

VmaMemoryUsage :: enum c.int {
	UNKNOWN      = 0,
	GPU_ONLY     = 1,
	CPU_ONLY     = 2,
	CPU_TO_GPU   = 3,
	GPU_TO_CPU   = 4,
	AUTO         = 5,
}

VmaAllocatorCreateInfo :: struct {
	flags:                          u32,
	physicalDevice:                 rawptr,
	device:                         rawptr,
	preferredLargeHeapBlockSize:    u64,
	pAllocationCallbacks:           rawptr,
	pDeviceMemoryCallbacks:         rawptr,
	pHeapSizeLimit:                 rawptr,
	pVulkanFunctions:               rawptr,
	instance:                       rawptr,
	vulkanApiVersion:               u32,
}

VmaAllocationCreateInfo :: struct {
	flags:          u32,
	usage:          VmaMemoryUsage,
	requiredFlags:  u32,
	preferredFlags: u32,
	memoryTypeBits: u32,
	pool:           VmaPool,
	pUserData:      rawptr,
	priority:       f32,
}

VmaAllocationInfo :: struct {
	memoryType:      u32,
	deviceMemory:    rawptr,
	offset:          u64,
	size:            u64,
	pMappedData:     rawptr,
	pUserData:       rawptr,
	pName:           cstring,
}

foreign libvma {
	vmaCreateAllocator :: proc(pCreateInfo: ^VmaAllocatorCreateInfo, pAllocator: ^VmaAllocator) -> i32 ---
	vmaDestroyAllocator :: proc(allocator: VmaAllocator) ---

	vmaCreateBuffer :: proc(
		allocator: VmaAllocator,
		pBufferCreateInfo: rawptr,
		pAllocationCreateInfo: ^VmaAllocationCreateInfo,
		pBuffer: ^rawptr,
		pAllocation: ^VmaAllocation,
		pAllocationInfo: ^VmaAllocationInfo,
	) -> i32 ---

	vmaDestroyBuffer :: proc(allocator: VmaAllocator, buffer: rawptr, allocation: VmaAllocation) ---

	vmaCreateImage :: proc(
		allocator: VmaAllocator,
		pImageCreateInfo: rawptr,
		pAllocationCreateInfo: ^VmaAllocationCreateInfo,
		pImage: ^rawptr,
		pAllocation: ^VmaAllocation,
		pAllocationInfo: ^VmaAllocationInfo,
	) -> i32 ---

	vmaDestroyImage :: proc(allocator: VmaAllocator, image: rawptr, allocation: VmaAllocation) ---

	vmaAllocateMemory :: proc(
		allocator: VmaAllocator,
		pVkMemoryRequirements: rawptr,
		pCreateInfo: ^VmaAllocationCreateInfo,
		pAllocation: ^VmaAllocation,
		pAllocationInfo: ^VmaAllocationInfo,
	) -> i32 ---

	vmaFreeMemory :: proc(allocator: VmaAllocator, allocation: VmaAllocation) ---

	vmaMapMemory :: proc(allocator: VmaAllocator, allocation: VmaAllocation, ppData: ^rawptr) -> i32 ---
	vmaUnmapMemory :: proc(allocator: VmaAllocator, allocation: VmaAllocation) ---

	vmaFlushAllocation :: proc(allocator: VmaAllocator, allocation: VmaAllocation, offset: u64, size: u64) -> i32 ---
	vmaInvalidateAllocation :: proc(allocator: VmaAllocator, allocation: VmaAllocation, offset: u64, size: u64) -> i32 ---

	vmaCreatePool :: proc(allocator: VmaAllocator, pCreateInfo: rawptr, pPool: ^VmaPool) -> i32 ---
	vmaDestroyPool :: proc(allocator: VmaAllocator, pool: VmaPool) ---

	vmaGetAllocationInfo :: proc(allocator: VmaAllocator, allocation: VmaAllocation, pAllocationInfo: ^VmaAllocationInfo) ---
	vmaSetAllocationUserData :: proc(allocator: VmaAllocator, allocation: VmaAllocation, pUserData: rawptr) ---

	vmaCalculatePoolStatistics :: proc(allocator: VmaAllocator, pool: VmaPool, pStats: rawptr) ---
	vmaPrintDetailedMap :: proc(allocator: VmaAllocator, file: rawptr) ---
}
