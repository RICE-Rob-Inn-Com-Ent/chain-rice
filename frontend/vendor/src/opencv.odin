package vision
// TODO:
// [ ] capture RICE_CAMERA_INDEX; SIFT/ORB/FAST — https://docs.opencv.org/
//

import "core:c"

when ODIN_OS == .Linux {
	foreign import libopencv_core {
		"lib/libopencv_core.so",
	}
	foreign import libopencv_imgproc {
		"lib/libopencv_imgproc.so",
	}
	foreign import libopencv_videoio {
		"lib/libopencv_videoio.so",
	}
	foreign import libopencv_objdetect {
		"lib/libopencv_objdetect.so",
	}
} else when ODIN_OS == .Darwin {
	foreign import libopencv_core {
		"lib/libopencv_core.dylib",
	}
	foreign import libopencv_imgproc {
		"lib/libopencv_imgproc.dylib",
	}
	foreign import libopencv_videoio {
		"lib/libopencv_videoio.dylib",
	}
	foreign import libopencv_objdetect {
		"lib/libopencv_objdetect.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import libopencv_core {
		"lib/opencv_world.lib",
	}
	foreign import libopencv_imgproc {
		"lib/opencv_world.lib",
	}
	foreign import libopencv_videoio {
		"lib/opencv_world.lib",
	}
	foreign import libopencv_objdetect {
		"lib/opencv_world.lib",
	}
}

Mat :: distinct rawptr
VideoCapture :: distinct rawptr
CascadeClassifier :: distinct rawptr
Point2f :: struct {
	x: f32,
	y: f32,
}
Rect :: struct {
	x: i32,
	y: i32,
	width: i32,
	height: i32,
}
Scalar :: struct {
	val: [4]f64,
}
Size :: struct {
	width: i32,
	height: i32,
}

COLOR_BGR2GRAY :: i32 : 6
COLOR_BGR2RGB :: i32 : 4
COLOR_BGR2HSV :: i32 : 40

CAP_PROP_FPS :: i32 : 5
CAP_PROP_FRAME_WIDTH :: i32 : 3
CAP_PROP_FRAME_HEIGHT :: i32 : 4

foreign libopencv_core {
	Mat_create :: proc(rows: c.int, cols: c.int, type: c.int) -> Mat ---
	Mat_release :: proc(m: ^Mat) ---
	Mat_clone :: proc(m: Mat) -> Mat ---
	Mat_copyTo :: proc(m: Mat, dst: Mat) ---

	Mat_rows :: proc(m: Mat) -> c.int ---
	Mat_cols :: proc(m: Mat) -> c.int ---
	Mat_channels :: proc(m: Mat) -> c.int ---
	Mat_type :: proc(m: Mat) -> c.int ---
	Mat_data :: proc(m: Mat) -> rawptr ---

	Mat_at_f32 :: proc(m: Mat, row: c.int, col: c.int) -> ^f32 ---
	Mat_at_u8 :: proc(m: Mat, row: c.int, col: c.int) -> ^u8 ---
	Mat_set_f32 :: proc(m: Mat, row: c.int, col: c.int, v: f32) ---
	Mat_set_u8 :: proc(m: Mat, row: c.int, col: c.int, v: u8) ---

	imshow :: proc(winname: cstring, mat: Mat) ---
	waitKey :: proc(delay: c.int) -> c.int ---
	destroyAllWindows :: proc() ---
}

foreign libopencv_imgproc {
	cvtColor :: proc(src: Mat, dst: Mat, code: c.int, dstCn: c.int) ---
	resize :: proc(src: Mat, dst: Mat, dsize: Size, fx: f64, fy: f64, interpolation: c.int) ---
	flip :: proc(src: Mat, dst: Mat, flipCode: c.int) ---
	rotate :: proc(src: Mat, dst: Mat, rotateCode: c.int) ---
	transpose :: proc(src: Mat, dst: Mat) ---

	GaussianBlur :: proc(src: Mat, dst: Mat, ksize: Size, sigmaX: f64, sigmaY: f64, borderType: c.int) ---
	medianBlur :: proc(src: Mat, dst: Mat, ksize: c.int) ---
	bilateralFilter :: proc(src: Mat, dst: Mat, d: c.int, sigmaColor: f64, sigmaSpace: f64, borderType: c.int) ---

	Canny :: proc(src: Mat, dst: Mat, threshold1: f64, threshold2: f64, apertureSize: c.int, L2gradient: bool) ---
	Sobel :: proc(src: Mat, dst: Mat, ddepth: c.int, dx: c.int, dy: c.int, ksize: c.int, scale: f64, delta: f64, borderType: c.int) ---
	Laplacian :: proc(src: Mat, dst: Mat, ddepth: c.int, ksize: c.int, scale: f64, delta: f64, borderType: c.int) ---

	threshold :: proc(src: Mat, dst: Mat, thresh: f64, maxval: f64, type: c.int) -> f64 ---
	adaptiveThreshold :: proc(src: Mat, dst: Mat, maxValue: f64, adaptiveMethod: c.int, thresholdType: c.int, blockSize: c.int, C: f64) ---

	dilate :: proc(src: Mat, dst: Mat, kernel: Mat, anchor: Point2f, iterations: c.int, borderType: c.int, borderValue: Scalar) ---
	erode :: proc(src: Mat, dst: Mat, kernel: Mat, anchor: Point2f, iterations: c.int, borderType: c.int, borderValue: Scalar) ---
	morphologyEx :: proc(src: Mat, dst: Mat, op: c.int, kernel: Mat, anchor: Point2f, iterations: c.int, borderType: c.int, borderValue: Scalar) ---

	findContours :: proc(image: Mat, contours: rawptr, hierarchy: Mat, mode: c.int, method: c.int, offset: Point2f) ---
	drawContours :: proc(image: Mat, contours: rawptr, contourIdx: c.int, color: Scalar, thickness: c.int, lineType: c.int, hierarchy: Mat, maxLevel: c.int, offset: Point2f) ---
	contourArea :: proc(contour: rawptr, oriented: bool) -> f64 ---
	boundingRect :: proc(points: rawptr) -> Rect ---

	HoughCircles :: proc(image: Mat, circles: Mat, method: c.int, dp: f64, minDist: f64, param1: f64, param2: f64, minRadius: c.int, maxRadius: c.int) ---
	HoughLines :: proc(image: Mat, lines: Mat, rho: f64, theta: f64, threshold: c.int, srn: f64, stn: f64, min_theta: f64, max_theta: f64) ---

	matchTemplate :: proc(image: Mat, templ: Mat, result: Mat, method: c.int) ---
	minMaxLoc :: proc(src: Mat, minVal: ^f64, maxVal: ^f64, minLoc: rawptr, maxLoc: rawptr, mask: Mat) ---
}

foreign libopencv_videoio {
	VideoCapture_open :: proc(vc: VideoCapture, filename: cstring) -> bool ---
	VideoCapture_openIndex :: proc(vc: VideoCapture, index: c.int) -> bool ---
	VideoCapture_read :: proc(vc: VideoCapture, frame: Mat) -> bool ---
	VideoCapture_release :: proc(vc: VideoCapture) ---
	VideoCapture_isOpened :: proc(vc: VideoCapture) -> bool ---
	VideoCapture_get :: proc(vc: VideoCapture, propId: c.int) -> f64 ---
	VideoCapture_set :: proc(vc: VideoCapture, propId: c.int, value: f64) -> bool ---
}

foreign libopencv_objdetect {
	CascadeClassifier_load :: proc(cc: CascadeClassifier, filename: cstring) -> bool ---
	CascadeClassifier_detectMultiScale :: proc(cc: CascadeClassifier, image: Mat, objects: rawptr, scaleFactor: f64, minNeighbors: c.int, flags: c.int, minSize: Size, maxSize: Size) ---
}
