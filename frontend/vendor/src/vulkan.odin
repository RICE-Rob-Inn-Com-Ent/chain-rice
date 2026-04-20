package gpu
// TODO:
// [ ] vkCreateInstance; app version RICE_APP_VERSION — https://docs.vulkan.org/spec/latest/chapters/initialization.html
// [ ] enumerate devices discrete>integrated>virtual; expose VRAM/queues/extensions
// [ ] compute queue VK_QUEUE_COMPUTE_BIT for SAGE
// [ ] swapchain surface GLFW/SDL3; RICE_RENDER_FORMAT
// [ ] sync semaphores/fences; RICE_FRAMES_IN_FLIGHT default 2
//

import vk "vendor:vulkan"
import "core:dynlib"

when ODIN_OS == .Linux {
	VULKAN_LOADER :: "libvulkan.so.1"
} else when ODIN_OS == .Darwin {
	VULKAN_LOADER :: "libvulkan.dylib"
} else when ODIN_OS == .Windows {
	VULKAN_LOADER :: "vulkan-1.dll"
}

_vulkan_lib: dynlib.Library
_vulkan_loaded: bool

init_vulkan_loader :: proc() -> bool {
	if _vulkan_loaded {
		return true
	}
	lib, ok := dynlib.load_library(VULKAN_LOADER)
	if !ok {
		return false
	}
	addr, ok2 := dynlib.symbol_address(lib, "vkGetInstanceProcAddr")
	if !ok2 {
		dynlib.unload_library(lib)
		return false
	}
	vk.load_proc_addresses_global(addr)
	_vulkan_lib = lib
	_vulkan_loaded = true
	return true
}

create_instance :: proc(app_name: cstring) -> (vk.Instance, vk.Result) {
	if !init_vulkan_loader() {
		return nil, vk.Result.ERROR_UNKNOWN
	}
	app_info := vk.ApplicationInfo {
		sType                   = vk.StructureType.APPLICATION_INFO,
		pApplicationName        = app_name,
		applicationVersion      = vk.MAKE_VERSION(1, 0, 0),
		pEngineName             = "rice",
		engineVersion           = vk.MAKE_VERSION(1, 0, 0),
		apiVersion              = vk.API_VERSION_1_0,
	}
	when ODIN_OS == .Linux {
		inst_exts := [2]cstring{vk.KHR_SURFACE_EXTENSION_NAME, vk.KHR_XCB_SURFACE_EXTENSION_NAME}
		create_info := vk.InstanceCreateInfo {
			sType                   = vk.StructureType.INSTANCE_CREATE_INFO,
			pApplicationInfo        = &app_info,
			enabledLayerCount       = 0,
			enabledExtensionCount   = 2,
			ppEnabledExtensionNames = raw_data(inst_exts[:]),
		}
		instance: vk.Instance
		res := vk.CreateInstance(&create_info, nil, &instance)
		if res != .SUCCESS {
			return nil, res
		}
		vk.load_proc_addresses_instance(instance)
		return instance, .SUCCESS
	} else when ODIN_OS == .Darwin {
		inst_exts := [2]cstring{vk.KHR_SURFACE_EXTENSION_NAME, vk.EXT_METAL_SURFACE_EXTENSION_NAME}
		create_info := vk.InstanceCreateInfo {
			sType                   = vk.StructureType.INSTANCE_CREATE_INFO,
			pApplicationInfo        = &app_info,
			enabledLayerCount       = 0,
			enabledExtensionCount   = 2,
			ppEnabledExtensionNames = raw_data(inst_exts[:]),
		}
		instance: vk.Instance
		res := vk.CreateInstance(&create_info, nil, &instance)
		if res != .SUCCESS {
			return nil, res
		}
		vk.load_proc_addresses_instance(instance)
		return instance, .SUCCESS
	} else when ODIN_OS == .Windows {
		inst_exts := [2]cstring{vk.KHR_SURFACE_EXTENSION_NAME, vk.KHR_WIN32_SURFACE_EXTENSION_NAME}
		create_info := vk.InstanceCreateInfo {
			sType                   = vk.StructureType.INSTANCE_CREATE_INFO,
			pApplicationInfo        = &app_info,
			enabledLayerCount       = 0,
			enabledExtensionCount   = 2,
			ppEnabledExtensionNames = raw_data(inst_exts[:]),
		}
		instance: vk.Instance
		res := vk.CreateInstance(&create_info, nil, &instance)
		if res != .SUCCESS {
			return nil, res
		}
		vk.load_proc_addresses_instance(instance)
		return instance, .SUCCESS
	} else {
		create_info := vk.InstanceCreateInfo {
			sType                   = vk.StructureType.INSTANCE_CREATE_INFO,
			pApplicationInfo        = &app_info,
			enabledLayerCount       = 0,
			enabledExtensionCount   = 0,
		}
		instance: vk.Instance
		res := vk.CreateInstance(&create_info, nil, &instance)
		if res != .SUCCESS {
			return nil, res
		}
		vk.load_proc_addresses_instance(instance)
		return instance, .SUCCESS
	}
}

select_physical_device :: proc(instance: vk.Instance) -> (vk.PhysicalDevice, vk.Result) {
	count: u32
	res := vk.EnumeratePhysicalDevices(instance, &count, nil)
	if res != .SUCCESS {
		return nil, res
	}
	if count == 0 {
		return nil, vk.Result.ERROR_UNKNOWN
	}
	devices := make([]vk.PhysicalDevice, count)
	defer delete(devices)
	res = vk.EnumeratePhysicalDevices(instance, &count, raw_data(devices))
	if res != .SUCCESS {
		return nil, res
	}
	return devices[0], .SUCCESS
}

create_logical_device :: proc(pdev: vk.PhysicalDevice) -> (vk.Device, vk.Result) {
	qf_count: u32
	vk.GetPhysicalDeviceQueueFamilyProperties(pdev, &qf_count, nil)
	if qf_count == 0 {
		return nil, vk.Result.ERROR_UNKNOWN
	}
	props := make([]vk.QueueFamilyProperties, qf_count)
	defer delete(props)
	vk.GetPhysicalDeviceQueueFamilyProperties(pdev, &qf_count, raw_data(props))
	graphics_idx: u32 = 0
	found := false
	for i in 0 ..< qf_count {
		if .GRAPHICS_BIT in props[i].queueFlags {
			graphics_idx = u32(i)
			found = true
			break
		}
	}
	if !found {
		return nil, vk.Result.ERROR_UNKNOWN
	}
	prio := f32(1)
	queue_info := vk.DeviceQueueCreateInfo {
		sType            = vk.StructureType.DEVICE_QUEUE_CREATE_INFO,
		queueFamilyIndex = graphics_idx,
		queueCount       = 1,
		pQueuePriorities = &prio,
	}
	dev_exts := [1]cstring{vk.KHR_SWAPCHAIN_EXTENSION_NAME}
	device_info := vk.DeviceCreateInfo {
		sType                   = vk.StructureType.DEVICE_CREATE_INFO,
		queueCreateInfoCount    = 1,
		pQueueCreateInfos       = &queue_info,
		enabledExtensionCount   = 1,
		ppEnabledExtensionNames = raw_data(dev_exts[:]),
		enabledLayerCount       = 0,
	}
	device: vk.Device
	res := vk.CreateDevice(pdev, &device_info, nil, &device)
	if res != .SUCCESS {
		return nil, res
	}
	vk.load_proc_addresses_device(device)
	return device, .SUCCESS
}

create_swapchain :: proc(
	physical_device: vk.PhysicalDevice,
	device: vk.Device,
	surface: vk.SurfaceKHR,
) -> (
	vk.SwapchainKHR,
	vk.Result,
) {
	cap: vk.SurfaceCapabilitiesKHR
	res := vk.GetPhysicalDeviceSurfaceCapabilitiesKHR(physical_device, surface, &cap)
	if res != .SUCCESS {
		return nil, res
	}
	fmt_count: u32
	vk.GetPhysicalDeviceSurfaceFormatsKHR(physical_device, surface, &fmt_count, nil)
	if fmt_count == 0 {
		return nil, vk.Result.ERROR_UNKNOWN
	}
	formats := make([]vk.SurfaceFormatKHR, fmt_count)
	defer delete(formats)
	res = vk.GetPhysicalDeviceSurfaceFormatsKHR(physical_device, surface, &fmt_count, raw_data(formats))
	if res != .SUCCESS {
		return nil, res
	}
	present_modes_count: u32
	vk.GetPhysicalDeviceSurfacePresentModesKHR(physical_device, surface, &present_modes_count, nil)
	present_modes := make([]vk.PresentModeKHR, present_modes_count)
	defer delete(present_modes)
	res = vk.GetPhysicalDeviceSurfacePresentModesKHR(physical_device, surface, &present_modes_count, raw_data(present_modes))
	if res != .SUCCESS {
		return nil, res
	}
	if present_modes_count == 0 {
		return nil, vk.Result.ERROR_UNKNOWN
	}
	image_extent := cap.currentExtent
	if image_extent.width == ~u32(0) {
		image_extent.width = 1280
		image_extent.height = 720
		if image_extent.width < cap.minImageExtent.width {
			image_extent.width = cap.minImageExtent.width
		}
		if image_extent.height < cap.minImageExtent.height {
			image_extent.height = cap.minImageExtent.height
		}
		if image_extent.width > cap.maxImageExtent.width {
			image_extent.width = cap.maxImageExtent.width
		}
		if image_extent.height > cap.maxImageExtent.height {
			image_extent.height = cap.maxImageExtent.height
		}
	}
	surf_fmt := formats[0]
	min_ic := cap.minImageCount
	if cap.maxImageCount > 0 && min_ic < cap.maxImageCount {
		min_ic += 1
	}
	create_info := vk.SwapchainCreateInfoKHR {
		sType                 = vk.StructureType.SWAPCHAIN_CREATE_INFO_KHR,
		surface               = surface,
		minImageCount         = min_ic,
		imageFormat           = surf_fmt.format,
		imageColorSpace       = surf_fmt.colorSpace,
		imageExtent           = image_extent,
		imageArrayLayers      = 1,
		imageUsage            = {.COLOR_ATTACHMENT_BIT},
		imageSharingMode      = vk.SharingMode.EXCLUSIVE,
		preTransform          = cap.currentTransform,
		compositeAlpha        = {.OPAQUE_BIT_KHR},
		presentMode           = present_modes[0],
		clipped               = true,
		oldSwapchain          = nil,
	}
	swapchain: vk.SwapchainKHR
	res = vk.CreateSwapchainKHR(device, &create_info, nil, &swapchain)
	return swapchain, res
}

create_render_pass :: proc(device: vk.Device, format: vk.Format) -> (vk.RenderPass, vk.Result) {
	color_attachment := vk.AttachmentDescription {
		flags          = {},
		format         = format,
		samples        = {._1},
		loadOp         = vk.AttachmentLoadOp.CLEAR,
		storeOp        = vk.AttachmentStoreOp.STORE,
		stencilLoadOp  = vk.AttachmentLoadOp.DONT_CARE,
		stencilStoreOp = vk.AttachmentStoreOp.DONT_CARE,
		initialLayout  = vk.ImageLayout.UNDEFINED,
		finalLayout    = vk.ImageLayout.PRESENT_SRC_KHR,
	}
	color_ref := vk.AttachmentReference {
		attachment = 0,
		layout     = vk.ImageLayout.COLOR_ATTACHMENT_OPTIMAL,
	}
	subpass := vk.SubpassDescription {
		flags                = {},
		pipelineBindPoint    = vk.PipelineBindPoint.GRAPHICS,
		colorAttachmentCount = 1,
		pColorAttachments    = &color_ref,
	}
	dep := vk.SubpassDependency {
		srcSubpass    = vk.SUBPASS_EXTERNAL,
		dstSubpass    = 0,
		srcStageMask  = {.TOP_OF_PIPE_BIT},
		dstStageMask  = {.COLOR_ATTACHMENT_OUTPUT_BIT},
		srcAccessMask = {},
		dstAccessMask = {.COLOR_ATTACHMENT_WRITE_BIT},
	}
	rp_info := vk.RenderPassCreateInfo {
		sType           = vk.StructureType.RENDER_PASS_CREATE_INFO,
		attachmentCount = 1,
		pAttachments    = &color_attachment,
		subpassCount    = 1,
		pSubpasses      = &subpass,
		dependencyCount = 1,
		pDependencies   = &dep,
	}
	rp: vk.RenderPass
	res := vk.CreateRenderPass(device, &rp_info, nil, &rp)
	return rp, res
}

create_framebuffer :: proc(
	device: vk.Device,
	render_pass: vk.RenderPass,
	attachment_view: vk.ImageView,
	width: u32,
	height: u32,
) -> (
	vk.Framebuffer,
	vk.Result,
) {
	fb_info := vk.FramebufferCreateInfo {
		sType           = vk.StructureType.FRAMEBUFFER_CREATE_INFO,
		renderPass      = render_pass,
		attachmentCount = 1,
		pAttachments    = &attachment_view,
		width           = width,
		height          = height,
		layers          = 1,
	}
	fb: vk.Framebuffer
	res := vk.CreateFramebuffer(device, &fb_info, nil, &fb)
	return fb, res
}

create_command_pool :: proc(device: vk.Device, queue_family: u32) -> (vk.CommandPool, vk.Result) {
	pool_info := vk.CommandPoolCreateInfo {
		sType            = vk.StructureType.COMMAND_POOL_CREATE_INFO,
		queueFamilyIndex = queue_family,
	}
	pool: vk.CommandPool
	res := vk.CreateCommandPool(device, &pool_info, nil, &pool)
	return pool, res
}

allocate_command_buffer :: proc(device: vk.Device, pool: vk.CommandPool) -> (vk.CommandBuffer, vk.Result) {
	alloc_info := vk.CommandBufferAllocateInfo {
		sType              = vk.StructureType.COMMAND_BUFFER_ALLOCATE_INFO,
		commandPool        = pool,
		level              = vk.CommandBufferLevel.PRIMARY,
		commandBufferCount = 1,
	}
	cmd: vk.CommandBuffer
	res := vk.AllocateCommandBuffers(device, &alloc_info, &cmd)
	return cmd, res
}

create_semaphore :: proc(device: vk.Device) -> (vk.Semaphore, vk.Result) {
	info := vk.SemaphoreCreateInfo {
		sType = vk.StructureType.SEMAPHORE_CREATE_INFO,
	}
	sem: vk.Semaphore
	res := vk.CreateSemaphore(device, &info, nil, &sem)
	return sem, res
}

create_fence :: proc(device: vk.Device) -> (vk.Fence, vk.Result) {
	info := vk.FenceCreateInfo {
		sType = vk.StructureType.FENCE_CREATE_INFO,
	}
	fence: vk.Fence
	res := vk.CreateFence(device, &info, nil, &fence)
	return fence, res
}

begin_command_buffer :: proc(cmd: vk.CommandBuffer) -> vk.Result {
	begin_info := vk.CommandBufferBeginInfo {
		sType = vk.StructureType.COMMAND_BUFFER_BEGIN_INFO,
	}
	return vk.BeginCommandBuffer(cmd, &begin_info)
}

end_command_buffer :: proc(cmd: vk.CommandBuffer) -> vk.Result {
	return vk.EndCommandBuffer(cmd)
}

submit_command_buffer :: proc(queue: vk.Queue, cmd: vk.CommandBuffer) -> vk.Result {
	submit := vk.SubmitInfo {
		sType                = vk.StructureType.SUBMIT_INFO,
		commandBufferCount   = 1,
		pCommandBuffers      = &cmd,
	}
	return vk.QueueSubmit(queue, 1, &submit, vk.Fence(0))
}
