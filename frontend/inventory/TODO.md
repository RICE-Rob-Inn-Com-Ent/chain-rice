# BARD / inventory — TODO (Black Box)

Path: custom/bard/inventory/ · Output: atlas.sys (Final manifest via atlas_generator.odin, format_version=1).
src/hardware.odin + hardware_nvml.odin

    [x] CPU: Model + Logical cores + Physical packages / Cores per package / Siblings (via cpuinfo).

    [x] RAM: MemTotal / MemAvailable / Swap / Buffers / Cached.

    [x] GPU: DRM vendor+device; NVIDIA /proc/driver/nvidia/gpus/*/information; NVML via dynlib + libnvidia-ml.so.1.

    [ ] Thermal Monitoring: /sys/class/thermal (Full zones mapping for CPU/GPU/Battery safety).

    [ ] Topology: Detailed map from /sys/devices/system/cpu/cpu*/topology (Cache levels, NUMA nodes).

    [ ] Power/Battery: /sys/class/power_supply/ (Voltage, Current, Capacity, Charging status).

src/network.odin

    [x] WiFi: List /sys/class/net (wl* + wireless/).

    [x] Bluetooth: Detect hci0..7 adapters and bonded devices.

    [x] Socket Sniffing: TCP/UDP lines (v4+v6), LISTEN / ESTABLISHED from /proc/net/tcp*.

    [x] Drones/Robotics: MAVLink-like discovery on UDP/UDP6 ports.

    [x] IP Cameras: Port heuristics (RTSP/HTTP/ONVIF-like) to identify external "eyes."

    [ ] Signal Analysis: SSID + Signal quality from /proc/net/wireless (Raw parsing).

    [ ] IoT Discovery: mDNS/ZeroConf scan for smart devices (Smart Plugs, Kitchen IoT, TV) in the local subnet.

src/peripherals.odin (The Senses & Inputs)

    [x] HID: Names from input*/name + Classes (Keyboard/Mouse/Touchpad/ACPI buttons).

    [x] Screens: DRM connectors card*-* + status (EDID parsing for resolution/refresh rate).

    [ ] Input Mapping: Map eventN → inputM for direct raw input access.

    [ ] Capabilities: ioctl EVIOCGBIT on /dev/input/event* to detect pressure sensitivity, haptics, and multi-touch.

    [ ] Audio I/O: List ALSA/PipeWire nodes (Microphones, Speakers, USB Interfaces).

src/actuators.odin (The Muscles - NEW)

    [ ] PWM/GPIO: Scan /sys/class/pwm/ and /sys/class/gpio/ (Control for servos, tail fins, drone motors).

    [ ] Serial/UART: Identify /dev/ttyUSB* and /dev/ttyACM* links to external microcontrollers (Arduino/ESP32).

    [ ] I2C/SPI: Detect active buses for deep-level sensor communication (IMUs, Altimeters, Lidars).

    [ ] Haptics/FFB: Map Force Feedback capabilities for physical response.

src/sensors_pro.odin (Advanced Perception - NEW)

    [ ] IIO Devices: Industrial I/O scan via /sys/bus/iio/devices/ (Accelerometers, Gyros, Barometers, Magnetometers).

    [ ] Vision Specs: V4L2 deep-scan (Available FPS, Resolutions, Pixel formats for connected cameras).

    [ ] SDR/Radio: Detect Software Defined Radio hardware for "hearing" the spectrum.

src/atlas_generator.odin

    [x] Final Manifest: Aggregate all sections into atlas.sys with format_version.

    [ ] Parallel Export: Generate JSON for SAGE/BARD and Binary Blobs for high-speed KING/CLERK access.

    [ ] Security: Integrity hash atlas.sys.sha256 or age signing for system-level trust.

    [ ] Virtualization: Support for Mock fixtures (Unit testing the system body without hardware).

Integration

    [ ] Main: main.odin entry point + Build scripts for target architectures (ARM64/x86_64).

    [ ] CI/CD: Automated hardware report validation in containerized environments.
