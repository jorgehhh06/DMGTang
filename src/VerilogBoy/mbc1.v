`timescale 1ns / 1ps
`default_nettype wire

module mbc1(
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

    reg [4:0] rom_bank_lo; 
    reg [1:0] bank_hi;     
    reg       mode;        
    reg       ram_en;      

    wire [15:0] vb_addr;
    assign vb_addr[15:12] = vb_a[15:12];
    assign vb_addr[11:0]  = 12'b0; 

    wire rom_addr_en = (vb_addr >= 16'h0000) && (vb_addr <= 16'h7FFF);
    wire ram_addr_en = (vb_addr >= 16'hA000) && (vb_addr <= 16'hBFFF);
    wire rom_addr_lo = (vb_addr >= 16'h0000) && (vb_addr <= 16'h3FFF);

    assign rom_cs_n = ((rom_addr_en) & (vb_rst == 0)) ? 1'b0 : 1'b1;
    assign ram_cs_n = ((ram_addr_en) & (ram_en) & (vb_rst == 0)) ? 1'b0 : 1'b1;

    wire [4:0] actual_rom_bank_lo = (rom_bank_lo == 5'b00000) ? 5'b00001 : rom_bank_lo;
    wire [6:0] rom_bank_0 = mode ? {bank_hi, 5'b00000} : 7'b0000000;
    wire [6:0] rom_bank_1 = {bank_hi, actual_rom_bank_lo};
    wire [1:0] actual_ram_bank = mode ? bank_hi : 2'b00;

    assign rom_a[22:14] = {2'b00, (rom_addr_lo ? rom_bank_0 : rom_bank_1)};
    assign ram_a[16:13] = {2'b00, actual_ram_bank};
    
    // FIX: Lógica 100% síncrona sin edge-detectors basura
    always@(posedge vb_clk or posedge vb_rst)
    begin
        if (vb_rst) begin
            ram_en      <= 1'b0;
            rom_bank_lo <= 5'b00001;
            bank_hi     <= 2'b00;
            mode        <= 1'b0;
        end
        else if (vb_wr) begin
            case (vb_addr)
                16'h0000, 16'h1000: ram_en <= (vb_d[3:0] == 4'hA) ? 1'b1 : 1'b0;
                16'h2000, 16'h3000: rom_bank_lo <= vb_d[4:0];
                16'h4000, 16'h5000: bank_hi <= vb_d[1:0];
                16'h6000, 16'h7000: mode <= vb_d[0];
            endcase
        end
    end

endmodule