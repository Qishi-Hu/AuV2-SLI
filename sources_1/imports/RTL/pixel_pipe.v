`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Qihsi Hu
// 
// Create Date: 12/05/2024 08:04:50 PM
// Design Name: 
// Module Name: pixel_pipe
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: process 8-bit RGB pixels
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pixel_pipe(
    input clk, clk10,
    input [3:0] sw, // 3,2,1 for enable/disable RGB. 0 for vertical/horizontal strips 
    input [7:0] in_green,
    input [7:0] in_blue,
    input [7:0] in_red,
    input  in_blank,
    input  in_vsync,
    input in_hsync,

    output reg trig,
     output wire f_frm,
     input mode, rdy,
    output [7:0] out_red,
    output [7:0] out_green,
    output [7:0] out_blue,
    output  out_hsync,
    output out_vsync,
    output out_blank
    );
    parameter V=2'b01; parameter B=2'b10; parameter O=2'b11; //states for Vsync, V back porch + 1st hysnc period, others.
    reg flag=1'b0; // flag for pattern change
    reg [1:0] S, N; // for primary FSM of states V B O 
    reg [7:0] LUT [0:719]; reg [7:0] LUT_V [0:1279];
    wire [7:0] fbyte; // LUT file output bytes 

    
    
    
   // set or switch orienation (0 for H strips, and 1 for V strips)
   reg ori=1'b0;
   reg ori_reg;
   always@(posedge in_vsync) begin
        ori_reg<=ori;
        ori<= sw[0];
   end
   //
    //row index tracker
    reg [9:0] row=10'd0;  
    always@(posedge in_hsync) begin
        if(S==O) row<=row+10'd1; //exclude the first hysnc of the frame
        else row<=10'd0;
    end
    // HSYNC backporch counter
    reg [7:0] HB=8'd0;
    always@(posedge clk) begin
        if(in_hsync) HB<=8'd0;
        else if (in_blank) HB<=HB+8'd1;
        else HB<= 8'd0;
    end
    //col index tracker
    reg [10:0] col= 11'd0;
    reg in_blank_reg;
    always@(posedge clk) begin
        in_blank_reg <=in_blank;
        if(in_hsync) col<=0; //exclude the first hysnc of the frame
        else if (in_blank) begin if (HB==8'd219) col<=11'b1; else col<=11'b0; end
        else col<=col+11'd1;
    end
    //frame index counter with a slow motion feature that holds each frame for 32 frames 
    reg[1:0] frq=2'd0; reg[2:0] fra=3'd0; // spatial frquency index, frame index
    reg hold=1'b0; reg rdy_reg=0; 
    
    always@(posedge in_vsync) begin   
            rdy_reg<=rdy;   
            if(mode==1'b0) begin frq<=2'd0; fra<=3'd0; hold<=1'b1; end  
            else if (ori ^ ori_reg) begin frq<=2'd0; fra<=3'd0; hold<=1'b1; end  
            else if (rdy && ~rdy_reg) begin // increment the SLI frame on rising edge of rdy
                     fra<=fra+3'd1; hold<=1'b0;
                     if(fra==3'd7) begin
                        frq<=frq+2'd1;
                     end
            end
            else begin
                fra<=fra; hold<=1'b1; frq<=frq;
            end
    end  
      
    //index mapping; find the correspoding index in the input LUT, according to current row,frq, and fra
    wire [9:0] index;//target index
    wire [10:0] indexV;
    indexMap MAP(.a({frq,fra,row}), .qspo(index), .clk(clk));
    indexMapV MAPV(.a({frq,fra,col}), .qspo(indexV), .clk(clk));
    //top-left pixel detection
    reg [7:0] TL; //-the top left pixel of current frame
    //FSM
    always@(posedge clk) begin
        case(S) 
            V: N<= in_vsync?V:B;
            B: N<= in_blank?B:O;
            O: N<= in_vsync?V:O;
            default: N<=O; 
        endcase
    end
    //set flag: `1 - in pass-through mode when the TL pixel value changes
    //          2 -  in pattern gen mode, if the current frame is the last during a hold period
    always@(posedge clk) begin
        S<=N;
        if((S==B)&&(N==O)) begin
            if(TL==in_red) begin
                flag<= mode?  (hold==1'b0):1'b0; TL<=TL;
                end
            else begin
                flag<= mode? (hold==1'b0):1'b1 ; TL<=in_red;
                end
        end
        else begin 
            TL<=TL; flag<= 1'b0;
        end            
    end
   
    //one-hot endcoding FSM for trigger output 8.1 msec (1s/120), that is about 601425 cycles 0x925D1
    // to make life easier we use 0x80000, corresponding 7.06 msec 
    reg [2:0] D=3'b000; //D[2] is trigger ready, D[1] is flag ready waiting for Vsync, D[0] is reset state waiting for flag
    always@(posedge clk) begin
        D[0]<=flag;
        D[1]<=D[0]|(D[1]&(~in_vsync));
        D[2]<=D[1]&in_vsync;
    end
    reg [20:1] cnt=20'h00000; 
    always@(posedge clk) begin
        if (D[2])  begin
            cnt<=20'h00001; // set counter to 1 to begin exposure
            trig<=1'b1;
        end
        else if (cnt[20]) begin
            cnt<=20'h00000; // end of exposure
            trig<=1'b0;
        end
        else if (cnt==20'h00000) begin //rest
            cnt<=cnt;
            trig<=1'b0;
        end
        else begin   //exposure time
            cnt<=cnt+1;
            trig<=1'b1;
        end
    end
    assign f_frm = (fra==3'd0)&&(frq==3'b0);
    
    
    //connect the pipe
    //assign out_red =in_red; assign out_green =in_green;  assign out_blue =in_blue;
    //flashing sequence for frq==2'b11 => BWBWBWBW
    
    //buffer channel enable input
    reg en_R,en_G,en_B;
    always@(posedge in_vsync) begin
        en_R<=sw[3]; en_G<=sw[2]; en_B<=sw[1];
    end
    //get pixel values from LUT and LUT_V
    wire [7:0] pix; wire [7:0] pixV;
    LUT LUT_ins (.a(index),.spo(pix));
    LUT_V LUTV_ins (.a(indexV),.spo(pixV));
    
   assign out_red = mode? (in_blank? in_red: en_R?(frq==2'b11 ? (fra[0]?8'hFF:8'h00) : (ori?pix:pixV)  ): 8'h00 ): in_red ;  
   assign out_green = mode?  (in_blank? in_green: en_G?(frq==2'b11 ? (fra[0]?8'hFF:8'h00) : (ori?pix:pixV)  ): 8'h00 ) : in_green ; 
   assign out_blue = mode? (in_blank? in_blue: en_B?(frq==2'b11 ? (fra[0]?8'hFF:8'h00) : (ori?pix:pixV)  ): 8'h00 ):in_blue ;
    assign out_hsync =in_hsync; assign out_vsync =in_vsync;  assign out_blank =in_blank; 
endmodule
