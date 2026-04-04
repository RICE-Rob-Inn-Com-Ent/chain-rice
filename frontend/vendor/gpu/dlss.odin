package gpu
// TODO:
// [ ] NGX Init; RICE_DLSS_MODE Quality|Balanced|Performance|UltraPerformance
//

import "core:c"

when ODIN_OS == .Linux {
	foreign import libdlss {
		"lib/libsl.interposer.so",
	}
} else when ODIN_OS == .Darwin {
	foreign import libdlss {
		"lib/libsl.interposer.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import libdlss {
		"lib/sl.interposer.dll",
	}
}

SLFeature :: distinct u32
SLResult :: enum i32 {
	OK = 0,
	FAIL = 1,
	NOT_SUPPORTED = 2,
}
SLContext :: distinct rawptr
SLFrameToken :: distinct rawptr

SLDLSSOptions :: struct {
	mode: u32,
	outputWidth: u32,
	outputHeight: u32,
	sharpness: f32,
}

SLDLSSState :: struct {
	estimatedVRAMUsageInBytes: u64,
}

SL_FEATURE_DLSS :: SLFeature(0)
SL_FEATURE_DLSS_G :: SLFeature(1)
SL_FEATURE_REFLEX :: SLFeature(2)

SLDLSSMode :: enum u32 {
	DLAA = 0,
	QUALITY = 1,
	BALANCED = 2,
	PERFORMANCE = 3,
	ULTRA_PERFORMANCE = 4,
}

foreign libdlss {
	slInit :: proc(flags: u32, appId: u32) -> SLResult ---
	slShutdown :: proc() ---

	slIsFeatureSupported :: proc(feature: SLFeature) -> bool ---
	slIsFeatureLoaded :: proc(feature: SLFeature) -> bool ---

	slSetFeatureConstants :: proc(feature: SLFeature, constants: rawptr) -> SLResult ---
	slGetFeatureConstants :: proc(feature: SLFeature, constants: rawptr) -> SLResult ---

	slEvaluateFeature :: proc(cmdList: rawptr, frame: ^SLFrameToken, feature: SLFeature, options: rawptr) -> SLResult ---
	slFreeResources :: proc(feature: SLFeature) -> SLResult ---

	slGetNativeInterface :: proc(name: cstring) -> rawptr ---

	slSetTag :: proc(tag: rawptr, data: rawptr, size: u64) -> SLResult ---
	slGetTag :: proc(tag: rawptr, data: rawptr, size: u64) -> SLResult ---

	slFrameTokenGetIndex :: proc(token: SLFrameToken) -> u32 ---
}
