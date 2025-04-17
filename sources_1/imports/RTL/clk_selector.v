`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Qishi Hu
//  
// Create Date: 01/08/2025 04:30:30 PM
// Design Name: 
// Module Name: clk_selector
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Orinally created to detect wether hmdi input is plugged and select clock source accrodinhly.
//  However, even unpluged, we can still detect tmds_clk using a counter and a LED, this weird ghost clock 
//    can also be slowed down when the shield is plugged and the cable is not connected to any video source
// Such a weird phenomeon make me decide to create a sperate Vivado project for the offline version of SLI_CAM
// where only local on-board clock is utilized.
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module clk_selector (
    input rx, tmds_clk,
    input hdmi_clk, hdmi_clk1, hdmi_clk5, vsync,
    input clk125, clk625, clk10,  
    output reg sel,
    output oclk, oclk1, oclk5
);

    reg [24:0] count = 0;  // check period 
    reg [21:0] cnt =0;
    always@(posedge tmds_clk) begin
        cnt<=cnt+1'b1;
    end
    reg rec;  reg flag= 1'b0;
   always@(posedge clk10) begin
        rec<= cnt[21];
        count<= count+1'b1;
        if(count==0) flag=1'b0;
        else if(~count[24])  begin //detction stage
            if(cnt[21]!=rec) flag<=1'b1;
        end
        else begin //decision stage
            if(flag) sel<=1'b1;
            else sel<=1'b0;
        end
        
   end
    

   
    BUFGMUX mux (
    .O(oclk),  // Output clock
    .I0(clk125),    // Input clock 1
    .I1(hdmi_clk),    // Input clock 2
    .S(sel)    // Select signal
    );
    
    BUFGMUX mux_x1 (
    .O(oclk1),  // Output clock
    .I0(clk125),    // Input clock 1
    .I1(hdmi_clk1),    // Input clock 2
    .S(sel)    // Select signal
    );
    
    BUFGMUX mux_x5 (
    .O(oclk5),  // Output clock
    .I0(clk625),    // Input clock 1
    .I1(hdmi_clk5),    // Input clock 2
    .S(sel)    // Select signal
    );

endmodule
