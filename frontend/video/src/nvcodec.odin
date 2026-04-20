package video
// TODO:
// [ ] NvEnc; cuvid decode zero-copy Vulkan — https://docs.nvidia.com/video-technologies/video-codec-sdk/
//

import "core:c"

when ODIN_OS == .Linux {
	foreign import libnvenc {
		"lib/libnvidia-encode.so",
	}
	foreign import libnvdec {
		"lib/libnvcuvid.so",
	}
} else when ODIN_OS == .Darwin {
	foreign import libnvenc {
		"lib/libnvidia-encode.dylib",
	}
	foreign import libnvdec {
		"lib/libnvcuvid.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import libnvenc {
		"lib/nvEncodeAPI.lib",
	}
	foreign import libnvdec {
		"lib/nvcuvid.lib",
	}
}

NV_ENC_INITIALIZE_PARAMS :: struct {
	version: u32,
	encodeGUID: rawptr,
	presetGUID: rawptr,
	tuningInfo: u32,
	encodeWidth: u32,
	encodeHeight: u32,
	darWidth: u32,
	darHeight: u32,
	frameRateNum: u32,
	frameRateDen: u32,
	enableEncodeAsync: u32,
	enablePTD: u32,
	reportSliceOffsets: u32,
	enableSubFrameWrite: u32,
	maxEncodeWidth: u32,
	maxEncodeHeight: u32,
}

NV_ENC_CONFIG :: struct {
	version: u32,
	profileGUID: rawptr,
	gopLength: u32,
	frameIntervalP: u32,
	monoChromeEncoding: u32,
	frameFieldMode: u32,
	mvPrecision: u32,
	reserved: [256]u8,
}

NV_ENC_PIC_PARAMS :: struct {
	version: u32,
	inputBuffer: rawptr,
	bufferFmt: u32,
	inputWidth: u32,
	inputHeight: u32,
	outputBitstream: rawptr,
	encodePicFlags: u32,
	frameIdx: u32,
	inputTimeStamp: u64,
	inputSubResourceIndex: u32,
}

NV_ENC_CREATE_INPUT_BUFFER :: struct {
	version: u32,
	width: u32,
	height: u32,
	memoryHeap: u32,
	bufferFmt: u32,
}

NV_ENC_CREATE_BITSTREAM_BUFFER :: struct {
	version: u32,
	size: u32,
	memoryHeap: u32,
}

NV_ENC_LOCK_INPUT_BUFFER :: struct {
	version: u32,
	inputBuffer: rawptr,
}

NV_ENC_LOCK_BITSTREAM :: struct {
	version: u32,
	outputBitstream: rawptr,
	doNotWait: u32,
}

CUvideodecoder :: distinct rawptr
CUvideoparser :: distinct rawptr
CUvideosource :: distinct rawptr

CUVIDDECODECREATEINFO :: struct {
	CodecType: u32,
	ulWidth: u32,
	ulHeight: u32,
	ulNumDecodeSurfaces: u32,
	ulCreationFlags: u32,
	ulIntraDecodeOnly: u32,
	ulMaxWidth: u32,
	ulMaxHeight: u32,
	ulReserved1: [5]u32,
}

CUVIDPICPARAMS :: struct {
	PicWidthInMbs: u32,
	PicHeightInMbs: u32,
}

CUVIDPARSERDISPINFO :: struct {
	picture_index: i32,
	progressive_frame: i32,
	top_field_first: i32,
	repeat_first_field: i32,
}

foreign libnvenc {
	NvEncOpenEncodeSession :: proc(device: rawptr, deviceType: u32, session: ^rawptr) -> u32 ---
	NvEncOpenEncodeSessionEx :: proc(params: rawptr, session: ^rawptr) -> u32 ---
	NvEncInitializeEncoder :: proc(encoder: rawptr, initParams: ^NV_ENC_INITIALIZE_PARAMS) -> u32 ---
	NvEncDestroyEncoder :: proc(encoder: rawptr) -> u32 ---

	NvEncCreateInputBuffer :: proc(encoder: rawptr, createParams: ^NV_ENC_CREATE_INPUT_BUFFER, inputBuffer: ^rawptr) -> u32 ---
	NvEncDestroyInputBuffer :: proc(encoder: rawptr, inputBuffer: rawptr) -> u32 ---

	NvEncCreateBitstreamBuffer :: proc(encoder: rawptr, createParams: ^NV_ENC_CREATE_BITSTREAM_BUFFER, bitstreamBuffer: ^rawptr) -> u32 ---
	NvEncDestroyBitstreamBuffer :: proc(encoder: rawptr, bitstreamBuffer: rawptr) -> u32 ---

	NvEncLockInputBuffer :: proc(encoder: rawptr, lockParams: ^NV_ENC_LOCK_INPUT_BUFFER, bufferData: ^rawptr, pitch: ^u32) -> u32 ---
	NvEncUnlockInputBuffer :: proc(encoder: rawptr, inputBuffer: rawptr) -> u32 ---

	NvEncEncodePicture :: proc(encoder: rawptr, picParams: ^NV_ENC_PIC_PARAMS) -> u32 ---
	NvEncLockBitstream :: proc(encoder: rawptr, lockParams: ^NV_ENC_LOCK_BITSTREAM, bitstreamBufferPtr: ^rawptr, bitstreamSizeInBytes: ^u32) -> u32 ---
	NvEncUnlockBitstream :: proc(encoder: rawptr, bitstreamBuffer: rawptr) -> u32 ---

	NvEncGetEncodeGUIDCount :: proc(encoder: rawptr, count: ^u32) -> u32 ---
	NvEncGetEncodeGUIDs :: proc(encoder: rawptr, guids: rawptr, guidArraySize: u32, count: ^u32) -> u32 ---
	NvEncGetEncodeProfileGUIDCount :: proc(encoder: rawptr, encodeGUID: rawptr, count: ^u32) -> u32 ---
	NvEncGetEncodePresetCount :: proc(encoder: rawptr, encodeGUID: rawptr, count: ^u32) -> u32 ---
	NvEncInvalidateRefFrames :: proc(encoder: rawptr, invalidRefFrame: u64) -> u32 ---
	NvEncRegisterResource :: proc(encoder: rawptr, registerParams: rawptr) -> u32 ---
}

foreign libnvdec {
	cuvidCreateDecoder :: proc(pdci: ^CUVIDDECODECREATEINFO, pdec: ^CUvideodecoder) -> c.int ---
	cuvidDestroyDecoder :: proc(dec: CUvideodecoder) -> c.int ---

	cuvidCreateVideoParser :: proc(pcpp: rawptr, pCtx: ^CUvideoparser) -> c.int ---
	cuvidDestroyVideoParser :: proc(vidParser: CUvideoparser) -> c.int ---

	cuvidDecodePicture :: proc(dec: CUvideodecoder, picParams: ^CUVIDPICPARAMS) -> c.int ---
	cuvidMapVideoFrame :: proc(dec: CUvideodecoder, picIdx: c.int, pDevPtr: ^u64, pPitch: ^u32, params: rawptr) -> c.int ---
	cuvidUnmapVideoFrame :: proc(dec: CUvideodecoder, mappedFrame: u64) -> c.int ---

	cuvidParseVideoData :: proc(pCtx: CUvideoparser, pPacket: rawptr) -> c.int ---
	cuvidGetDecodeStatus :: proc(dec: CUvideodecoder, picIdx: c.int, pDecodeStatus: rawptr) -> c.int ---
}
