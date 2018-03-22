/* vim: set ai et ts=4 sw=4: */

`default_nettype none

module top(
    input logic clkin,
    output logic D5,

    output logic vga_r,
    output logic vga_g,
    output logic vga_b,
    output logic vga_hs,
    output logic vga_vs,

    input logic wclk,
    input logic dc,
    input logic din,
    input logic cs
);

logic clk;

// 640x480 @ 60Hz
// 25.125 Mhz, see `icepll -i 12 -o 25`
SB_PLL40_CORE #(
    .FEEDBACK_PATH("SIMPLE"),
    .PLLOUT_SELECT("GENCLK"),
    .DIVR(4'b0000),
    .DIVF(7'b1000010),
    .DIVQ(3'b101),
    .FILTER_RANGE(3'b001),
) uut (
    .REFERENCECLK(clkin),
    .PLLOUTCORE(clk),
    .LOCK(D5), // keep this!
    .RESETB(1'b1),
    .BYPASS(1'b0)
);

parameter addr_width = 13;
logic mem [(1<<addr_width)-1:0];

logic [addr_width-1:0] raddr = 0;
logic [addr_width-1:0] waddr = 0;

always_ff @(posedge wclk) // write memory
begin
    if(cs == 0) // chip select
    begin
        if(dc) // dc = high, accept data
        begin
          mem[waddr] <= din;
          waddr <= waddr + 1;
        end // dc = low, ignore command
    end
    else
        waddr <= 0;
end

parameter h_pulse  = 96;  // h-sunc pulse width
parameter h_bp     = 48;  // back porch pulse width
parameter h_pixels = 640; // number of pixels horizontally
parameter h_fp     = 16;  // front porch pulse width
parameter h_frame  = h_pulse + h_bp + h_pixels + h_fp;

parameter v_pulse  = 2;   // v-sync pulse width
parameter v_bp     = 31;  // back porch pulse width
parameter v_pixels = 480; // number of pixels vertically
parameter v_fp     = 11;  // front porch pulse width
parameter v_frame  = v_pulse + v_bp + v_pixels + v_fp;

parameter border   = 10;
parameter h_offset = (h_pixels - (128*4))/2;
parameter v_offset = (v_pixels - (64*4))/2;

logic [addr_width-1:0] h_pos = 0;
logic [addr_width-1:0] v_pos = 0;

assign vga_hs = (h_pos < h_pixels + h_fp) ? 0 : 1;
assign vga_vs = (v_pos < v_pixels + v_fp) ? 0 : 1;

logic color = 0;
assign vga_r = color;
assign vga_g = color;
assign vga_b = color;

always_ff @(posedge clk) begin
    // update current position
    if(h_pos < h_frame - 1)
        h_pos <= h_pos + 1;
    else
    begin
        h_pos <= 0;
        if(v_pos < v_frame - 1)
            v_pos <= v_pos + 1;
        else
            v_pos <= 0;
    end

    // are we inside centered 512x256 area plus border?
    if((h_pos >= h_offset - border) &&
       (h_pos < (h_pixels - h_offset + border)) &&
       (v_pos >= v_offset - border) &&
       (v_pos < (v_pixels - v_offset + border)))
    begin
        if((h_pos >= h_offset) && (h_pos < h_pixels - h_offset) &&
           (v_pos >= v_offset) && (v_pos < v_pixels - v_offset))
        begin // inside centered area
            color <= mem[raddr];

            // addr = (X + (Y / 8) * 128)*8 + (7 - Y % 8)
            // X = (h_pos - h_offset) >> 2
            // Y = (v_pos - v_offset) >> 2
            raddr <= (
                      (
                       // X
                       ((h_pos - h_offset) >> 2) |
                       (
                          //  Y  div 8
                          ((((v_pos - v_offset) >> 2) >> 3) & 3'b111)
                          // mul 128
                          << 7
                       )
                       // mul 8 (size of byte in bits)
                      ) << 3
                        // + (7 - (Y % 8))
                     ) | (7 - (((v_pos - v_offset) >> 2) & 3'b111));
        end
        else // outside centered area, draw the border
            color <= 1;
    end
    else // everything else is black
        color <= 0;
end

endmodule
