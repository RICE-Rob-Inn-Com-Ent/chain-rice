package video
// TODO:
// [ ] avformat/avcodec decode/encode; RICE_VIDEO_CODEC; hw CUDA/VAAPI — https://ffmpeg.org/documentation.html
//

import "core:c"

when ODIN_OS == .Linux {
	foreign import libavcodec {
		"lib/libavcodec.so",
	}
	foreign import libavformat {
		"lib/libavformat.so",
	}
	foreign import libavutil {
		"lib/libavutil.so",
	}
	foreign import libswscale {
		"lib/libswscale.so",
	}
	foreign import libswresample {
		"lib/libswresample.so",
	}
} else when ODIN_OS == .Darwin {
	foreign import libavcodec {
		"lib/libavcodec.dylib",
	}
	foreign import libavformat {
		"lib/libavformat.dylib",
	}
	foreign import libavutil {
		"lib/libavutil.dylib",
	}
	foreign import libswscale {
		"lib/libswscale.dylib",
	}
	foreign import libswresample {
		"lib/libswresample.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import libavcodec {
		"lib/avcodec.lib",
	}
	foreign import libavformat {
		"lib/avformat.lib",
	}
	foreign import libavutil {
		"lib/avutil.lib",
	}
	foreign import libswscale {
		"lib/swscale.lib",
	}
	foreign import libswresample {
		"lib/swresample.lib",
	}
}

AVFormatContext :: distinct rawptr
AVCodecContext :: distinct rawptr
AVCodec :: distinct rawptr
AVStream :: distinct rawptr
AVPacket :: distinct rawptr
AVFrame :: distinct rawptr
AVRational :: struct {
	num: i32,
	den: i32,
}
AVDictionary :: distinct rawptr
SwsContext :: distinct rawptr
SwrContext :: distinct rawptr

AVPixelFormat :: enum c.int {
	YUV420P = 0,
	RGB24 = 2,
	RGBA = 26,
}

AVCodecID :: enum c.int {
	NONE = 0,
	H264 = 27,
	HEVC = 173,
	VP9 = 167,
	AV1 = 225,
}

AVMediaType :: enum c.int {
	UNKNOWN = -1,
	VIDEO = 0,
	AUDIO = 1,
	DATA = 2,
}

AVMEDIA_TYPE_VIDEO :: AVMediaType : .VIDEO
AVMEDIA_TYPE_AUDIO :: AVMediaType : .AUDIO

AV_CODEC_ID_H264 :: AVCodecID : .H264
AV_CODEC_ID_H265 :: AVCodecID : .HEVC
AV_CODEC_ID_VP9 :: AVCodecID : .VP9
AV_CODEC_ID_AV1 :: AVCodecID : .AV1

AV_PIX_FMT_YUV420P :: AVPixelFormat : .YUV420P
AV_PIX_FMT_RGB24 :: AVPixelFormat : .RGB24
AV_PIX_FMT_RGBA :: AVPixelFormat : .RGBA

foreign libavformat {
	avformat_open_input :: proc(ps: ^AVFormatContext, url: cstring, fmt: rawptr, options: ^AVDictionary) -> c.int ---
	avformat_close_input :: proc(s: ^AVFormatContext) ---
	avformat_find_stream_info :: proc(s: AVFormatContext, options: ^AVDictionary) -> c.int ---
	avformat_alloc_output_context2 :: proc(ctx: ^AVFormatContext, oformat: rawptr, format_name: cstring, url: cstring) -> c.int ---
	avformat_new_stream :: proc(s: AVFormatContext, c: rawptr) -> ^AVStream ---
	avformat_write_header :: proc(s: AVFormatContext, options: ^AVDictionary) -> c.int ---
	av_write_trailer :: proc(s: AVFormatContext) -> c.int ---
	av_find_best_stream :: proc(s: AVFormatContext, type: AVMediaType, wanted_stream_nb: c.int, related_stream: c.int, decoder_ret: ^^AVCodec, flags: c.int) -> c.int ---
	av_read_frame :: proc(s: AVFormatContext, pkt: ^AVPacket) -> c.int ---
	av_seek_frame :: proc(s: AVFormatContext, stream_index: c.int, timestamp: i64, flags: c.int) -> c.int ---
}

foreign libavcodec {
	avcodec_find_decoder :: proc(id: AVCodecID) -> AVCodec ---
	avcodec_find_encoder :: proc(id: AVCodecID) -> AVCodec ---
	avcodec_alloc_context3 :: proc(codec: AVCodec) -> AVCodecContext ---
	avcodec_free_context :: proc(ctx: ^AVCodecContext) ---
	avcodec_parameters_to_context :: proc(codec_ctx: AVCodecContext, par: rawptr) -> c.int ---
	avcodec_parameters_from_context :: proc(par: rawptr, codec_ctx: AVCodecContext) -> c.int ---
	avcodec_open2 :: proc(avctx: AVCodecContext, codec: AVCodec, options: ^AVDictionary) -> c.int ---
	avcodec_close :: proc(avctx: AVCodecContext) -> c.int ---
	avcodec_send_packet :: proc(avctx: AVCodecContext, avpkt: ^AVPacket) -> c.int ---
	avcodec_receive_frame :: proc(avctx: AVCodecContext, frame: ^AVFrame) -> c.int ---
	avcodec_send_frame :: proc(avctx: AVCodecContext, frame: ^AVFrame) -> c.int ---
	avcodec_receive_packet :: proc(avctx: AVCodecContext, avpkt: ^AVPacket) -> c.int ---
	avcodec_flush_buffers :: proc(avctx: AVCodecContext) ---
}

foreign libavutil {
	av_frame_alloc :: proc() -> AVFrame ---
	av_frame_free :: proc(frame: ^AVFrame) ---
	av_frame_unref :: proc(frame: ^AVFrame) ---
	av_packet_alloc :: proc() -> AVPacket ---
	av_packet_free :: proc(pkt: ^AVPacket) ---
	av_packet_unref :: proc(pkt: ^AVPacket) ---
	av_packet_rescale_ts :: proc(pkt: AVPacket, tb_src: AVRational, tb_dst: AVRational) ---
	av_image_alloc :: proc(pointers: [^]rawptr, linesizes: [^]c.int, w: c.int, h: c.int, pix_fmt: AVPixelFormat, align: c.int) -> c.int ---
	av_image_fill_arrays :: proc(dst_data: [^]rawptr, dst_linesize: [^]c.int, src: [^]u8, pix_fmt: AVPixelFormat, width: c.int, height: c.int, align: c.int) -> c.int ---
	av_image_get_buffer_size :: proc(pix_fmt: AVPixelFormat, width: c.int, height: c.int, align: c.int) -> c.int ---
	av_malloc :: proc(size: c.uint) -> rawptr ---
	av_free :: proc(ptr: rawptr) ---
	av_dict_set :: proc(pm: ^AVDictionary, key: cstring, value: cstring, flags: c.int) -> c.int ---
	av_dict_free :: proc(m: ^AVDictionary) ---
}

foreign libswscale {
	sws_getContext :: proc(srcW: c.int, srcH: c.int, srcFormat: AVPixelFormat, dstW: c.int, dstH: c.int, dstFormat: AVPixelFormat, flags: c.int, srcFilter: rawptr, dstFilter: rawptr, param: rawptr) -> SwsContext ---
	sws_freeContext :: proc(swsContext: SwsContext) ---
	sws_scale :: proc(c: SwsContext, srcSlice: [^][^]u8, srcStride: [^]c.int, srcSliceY: c.int, srcSliceH: c.int, dst: [^][^]u8, dstStride: [^]c.int) -> c.int ---
	sws_getCachedContext :: proc(context: SwsContext, srcW: c.int, srcH: c.int, srcFormat: AVPixelFormat, dstW: c.int, dstH: c.int, dstFormat: AVPixelFormat, flags: c.int, srcFilter: rawptr, dstFilter: rawptr, param: rawptr) -> SwsContext ---
}

foreign libswresample {
	swr_alloc :: proc() -> SwrContext ---
	swr_init :: proc(s: SwrContext) -> c.int ---
	swr_free :: proc(s: ^SwrContext) ---
	swr_convert :: proc(s: SwrContext, out: [^]rawptr, out_count: c.int, in_: [^]rawptr, in_count: c.int) -> c.int ---
}
