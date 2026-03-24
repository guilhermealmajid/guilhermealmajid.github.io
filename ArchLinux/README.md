sudo mkdir -p ~/backup-nvidia-ok
sudo cp /etc/X11/xorg.conf.d/10-nvidia.conf ~/backup-nvidia-ok/
sudo cp /etc/environment ~/backup-nvidia-ok/
sudo cp /etc/default/grub ~/backup-nvidia-ok/


local/egl-gbm 1.1.3-1
    The GBM EGL external platform library
local/egl-wayland 4:1.1.21-1
    EGLStream-based Wayland external platform
local/egl-wayland2 1.0.1-1
    EGLStream-based Wayland external platform (2)
local/egl-x11 1.0.5-1
    NVIDIA XLib and XCB EGL Platform Library
local/libva-nvidia-driver 0.0.16-1
    VA-API implementation that uses NVDEC as a backend
local/libvdpau 1.5-4
    Nvidia VDPAU library
local/libxnvctrl 590.48.01-1
    NVIDIA NV-CONTROL X extension
local/linux-firmware-nvidia 20260309-1
    Firmware files for Linux - Firmware for NVIDIA GPUs and SoCs
local/nvidia-open-dkms 590.48.01-4
    NVIDIA open kernel modules - module sources
local/nvidia-prime 1.0-5
    NVIDIA Prime Render Offload configuration and utilities
local/nvidia-settings 590.48.01-1
    Tool for configuring the NVIDIA graphics driver
local/nvidia-utils 590.48.01-4
    NVIDIA drivers utilities

