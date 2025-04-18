# AuV2-SLI

This repository serves a structured light illumination (SLI) system orchestrated by an FPGA controller. The system is based on the Alchitry Au V2 board, which is powered by an Artix-7 FPGA. The board is extended with an Hd V2 board that has two HDMI shields and a Br V2 board for GPIO connections with external DB9 camera modules following a 4-line protocol.

In this project, the FPGA can:
- Take HDMI video input from a host PC and output HDMI video to a DLP projector, triggering the camera when the top-left pixel changes.
- Replace the HDMI input frames with locally generated SLI patterns that vary in spatial frequency and temporal frequency.
- Synchronize the projection and capture of each frame by interacting with the camera modules through the GPIO pins via the 4-line protocol.
- When the HDMI input cable is unplugged, the FPGA will be driven by the local oscillator clock instead of the HDMI Rx clock, dedicated to the local pattern generation mode only.

The phase images captured by the camera modules are sent to the host PC through USB, and a host Qt program will complete the 3-D reconstruction. The system can scan 1280x720 resolution at 120FPS.

## How to configure the bitstream?

1. Download and install the latest version of [AlchitryLab v2](https://alchitry.com/alchitry-labs/).
2. Download `Bitstream\Au2_SLI.bin` and power the board via USB.
3. Open Alchitry Loader in AlchitryLab v2, and program the board using the flash memory option.

## Tips for setting FPS and resoultion for HDMI Input
The HDMI input should be automtcially conifgured after it reads the EDID from the FPGA. To confirm it in Windows, go to **System > Display > Advanced Settings > Sletect Display "Qishi-SLI"**. The display info should be similar to the screenshot below.
![Screenshot 2025-04-17 201139](https://github.com/user-attachments/assets/5b7a5cb5-8982-4aa2-bfc6-cf27cb00fb06)


The **Active Signal Mode** is the actual setting of the HDMI signal, if it is not matching the desired resolution and FPS, please go to **System > Display > Advanced Settings > Adapter Properties > List All Modes** to manually set the correct mode.

## Specifications of FPGA Controller Modes

### 1. Pass-through with Top-Left Pixel Detection
- The FPGA functions as an HDMI pass-through capable of **720p@120Hz**. The PC is responsible for playing back the SLI patterns.
- The FPGA reads the **top-left pixel (TLP)** value of each frame.
- If the current frame has a different TLP value from the previous frame, the FPGA sends a pulse to trigger the camera shutter during the next VSYNC period.
- The host PC waits for confirmation that the camera is ready before playing the next frame.

### 2. Pass-through with SLI Pattern Generation
- The FPGA replaces the input HDMI frames with locally generated SLI patterns. If the HDMI input is absent, it simply creates the pattern locally. 
- The current pattern is a 24-frame sequence, where each row of a frame contains identical pixel values corresponding to the row index.
- The start frame is defined by a **Look-Up Table (LUT)**, and subsequent frames are derived by modifying the spatial and temporal frequencies of the first frame.
- For top-down scanning, `indexMapping.m` maps the combination of a pixel’s row index and frame index to an index in the start frame LUT. This MATLAB script outputs the `indexMap.coe` that initializes a read-only memory (ROM) module on the FPGA to store the mapping.
- For side-to-side scanning, `indexMappingV.m` maps the combination of a pixel’s column index and frame index to an index in the start frame LUT. This MATLAB script outputs the `indexMapV.coe` that initializes a read-only memory (ROM) module on the FPGA to store the mapping.
- The start frame LUTs for both scanning orientations are defined in `LUT2coe.m`, which outputs `LUT.coe` and `LUT_V.coe` so that they can be hardcoded through read-only memory (ROM) modules.
- The FPGA increments the frame index and triggers the camera on VSYNC, as long as the camera signals that it is ready (by sending a rising edge).
### 3. Offline Mode
When the HDMI input is absent, the FPGA enters offline mode. This mode is similar to Mode #2, but the pattern is generated using the local oscillator clock. The pattern is projected at a fixed resolution of 1280x720 at 120Hz.
## GPIO pin assignments
| Camera Interface  | FPGA Pins | DB9 Pins | Purpose                                         | I/O (from FPGA's POV)             |
|------------|-----------|----------|-------------------------------------------------|-----------------------------------|
| Line 1 (Cam1)    | A23     | 5        | Trigger the camera                              | Output                            |
| Line 2  (Cam1)     | A35     | 9        | Mode (1 local patterns, 0 pass-through)     | Input                             |
| Line 3  (Cam1)      | A29     | 4        | First frame of the pattern                      | Output                            |
| Line 4  (Cam1)     | A17     | 8        | Camera is ready for the next trigger            | Input                             |
| Line 1 (Cam2)    | A24     | 6        | Trigger the camera                              | Output                            |
| Line 2  (Cam2)     | A36     | 2        | Mode (1 local patterns, 0 pass-through)     | Input                             |
| Line 3  (Cam2)      | A30    | 3        | First frame of the pattern                      | Output                            |
| Line 4  (Cam2)     | A18     | 7        | Camera is ready for the next trigger            | Input                             |
| GND        | G     | 1        | Ground                                          | -                                 |




| Other  Signals |  FPGA Pins | Function                            |
|------------|----------|----------------------------------------|
|3.3V  |  V+ / DN /2.5 (Ctrl Bank)    | 3.3 V reference  |
|5V  |  R  (Ctrl Bank)   |  5 V reference |
| SW[3]          |A12     | Enable (1) / Disable(0) the Red channel        |
| SW[2]           |A11     | Enable (1) / Disable(0) the  Green channel      |
| SW[1]           |A6     | Enable (1) / Disable(0) the  Blue channel       |
|SW[0]          |A5     | 0 for vertical stripes, 1 for horizontal stripes |
## Directory Structure
<pre>
├── README.md           # Overview of the repository  
├── Au2_SLI.zip   # Archive of the source Vivado 2024.1 project  
├── Bitsrteam/          # Final bitstream files  
├── Matlab/             # .m scripts and output files  
├── src_1/              # Source HDLand Matlab code  
└── constr_1/           #  Xlinx Design Constarint  
</pre>

## Licensing

Building an HDMI pass-through is a foundational element of this project. For this, I adapted the design by [hamsternz](https://github.com/hamsternz/Artix-7-HDMI-processing/tree/master) (MIT License).
