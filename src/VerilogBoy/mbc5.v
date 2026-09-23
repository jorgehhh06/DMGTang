`timescale 1ns / 1ps
`default_nettype wire

module mbc5(
    input vb_clk,
    input [15:12] vb_a,
    input [7:0] vb_d,
    input vb_wr,
    input vb_rd,
    input vb_rst,
    output [22:14] rom_a,
    output [16:13] ram_a,
    output rom_cs_n,
    output ram_cs_n
);

    reg [8:0] rom_bank;
    reg [3:0] ram_bank;
    reg ram_en = 1'b0; 

    wire rom_addr_en; 
    wire ram_addr_en; 
    wire rom_addr_lo; 

    wire [15:0] vb_addr;

    assign vb_addr[15:12] = vb_a[15:12];
    assign vb_addr[11:0] = 12'b0;

    assign rom_addr_en =  (vb_addr >= 16'h0000)&(vb_addr <= 16'h7FFF); 
    assign ram_addr_en =  (vb_addr >= 16'hA000)&(vb_addr <= 16'hBFFF); 
    assign rom_addr_lo =  (vb_addr >= 16'h0000)&(vb_addr <= 16'h3FFF); 

    assign rom_cs_n = ((rom_addr_en) & (vb_rst == 0)) ? 1'b0 : 1'b1; 
    assign ram_cs_n = ((ram_addr_en) & (ram_en) & (vb_rst == 0)) ? 1'b0 : 1'b1; 

    assign rom_a[22:14] = rom_addr_lo ? 9'b0 : rom_bank[8:0];
    assign ram_a[16:13] = ram_bank[3:0];
    
    always@(posedge vb_clk or posedge vb_rst)
    begin
        if (vb_rst) begin
            rom_bank[8:0] <= 9'b000000001;
            ram_bank[3:0] <= 4'b0000;
            ram_en <= 1'b0;
        end
        else if (vb_wr) begin
            case (vb_addr)
                16'h0000, 16'h1000: ram_en <= (vb_d[3:0] == 4'hA) ? 1'b1 : 1'b0;
                16'h2000: rom_bank[7:0] <= vb_d[7:0];
                16'h3000: rom_bank[8] <= vb_d[0];
                16'h4000, 16'h5000: ram_bank[3:0] <= vb_d[3:0];
            endcase
        end
    end

endmodule