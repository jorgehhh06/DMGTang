//
// GBTang top level - VerilogBoy Edition (SDRAM RAW PULSE STRETCHER FINAL)
//

import configPackage::*;

module gbtang_top (
    input sys_clk,

    // Button S1 and pin 48 are both resets
    input s1,
    input reset2,

    // UART
    input UART_RXD,
    output UART_TXD,

    // LEDs
    output [1:0] led,

    // SDRAM - Tang SDRAM pmod 1.2 for primer 25k, on-chip 32-bit 8MB SDRAM for nano 20k
    output O_sdram_clk,
    output O_sdram_cke,
    output O_sdram_cs_n,            
    output O_sdram_cas_n,           
    output O_sdram_ras_n,           
    output O_sdram_wen_n,           
    inout [SDRAM_DATA_WIDTH-1:0] IO_sdram_dq,      
    output [SDRAM_ROW_WIDTH-1:0] O_sdram_addr,     
    output [1:0] O_sdram_ba,        
    output [SDRAM_DATA_WIDTH/8-1:0] O_sdram_dqm,  

    // MicroSD
    output sd_clk,
    inout  sd_cmd,      
    input  sd_dat0,     
    output sd_dat1,     
    output sd_dat2,     
    output sd_dat3,     

    // SPI flash
    output flash_spi_cs_n,          
    input flash_spi_miso,           
    output flash_spi_mosi,          
    output flash_spi_clk,           
    output flash_spi_wp_n,          
    output flash_spi_hold_n,        

`ifdef CONTROLLER_SNES
    // snes controllers
    output joy1_strb,
    output joy1_clk,
    input joy1_data,
    output joy2_strb,
    output joy2_clk,
    input joy2_data,
`endif

`ifdef CONTROLLER_DS2
    // dualshock controllers
    output ds_clk,
    input ds_miso,
    output ds_mosi,
    output ds_cs,
    output ds_clk2,
    input ds_miso2,
    output ds_mosi2,
    output ds_cs2,
`endif

    // HDMI TX
    output       tmds_clk_n,
    output       tmds_clk_p,
    output [2:0] tmds_d_n,
    output [2:0] tmds_d_p
);

// Core settings
wire arm_reset = 0;
wire [1:0] system_type;
wire pal_video = 0;
wire [1:0] scanlines = 2'b0;
wire joy_swap = 0;
wire mirroring_osd = 0;
wire overscan_osd = 0;
wire famicon_kbd = 0;
wire [3:0] palette_osd = 0;
wire [2:0] diskside_osd = 0;
wire blend = 0;
wire bk_save = 0;

// HDMI / Video signals
reg reset_nes = 1;
reg clkref;
wire [5:0] color;
wire [15:0] sample;
wire [8:0] scanline;
wire [8:0] cycle;
wire [2:0] joypad_out;
wire joypad_strobe = joypad_out[0];
wire [1:0] joypad_clock;
wire [4:0] joypad1_data, joypad2_data;

wire sdram_busy;
wire [21:0] memory_addr_cpu, memory_addr_ppu;
wire memory_read_cpu, memory_read_ppu;
wire memory_write_cpu, memory_write_ppu;
wire [7:0] memory_din_cpu, memory_din_ppu;
wire [7:0] memory_dout_cpu, memory_dout_ppu;

reg [7:0] joypad_bits, joypad_bits2;
reg [1:0] last_joypad_clock;
wire [31:0] dbgadr;
wire [1:0] dbgctr;

wire [1:0] nes_ce;

wire loading;                 
wire [7:0] loader_do;
wire loader_do_valid;

// iosys softcore
wire        rv_valid;
reg         rv_ready;
wire [22:0] rv_addr;
wire [31:0] rv_wdata;
wire [3:0]  rv_wstrb;
reg  [15:0] rv_dout0;
wire [31:0] rv_rdata = {rv_dout, rv_dout0};
reg         rv_valid_r;
reg         rv_word;            
reg         rv_req;
wire        rv_req_ack;
wire [15:0] rv_dout;
reg [1:0]   rv_ds;
reg         rv_new_req;

// Controller
wire [7:0] joy_rx[0:1], joy_rx2[0:1];     
wire [7:0] usb_btn, usb_btn2;
wire usb_btn_x, usb_btn_y, usb_btn_x2, usb_btn_y2;
wire usb_conerr, usb_conerr2;
wire auto_a, auto_b, auto_a2, auto_b2;

wor [11:0] joy1_btns, joy2_btns;    

// Loader
wire [21:0] loader_addr;
wire [7:0] loader_write_data;
reg loading_r;
always @(posedge clk) loading_r <= loading;
wire loader_reset = loading & ~loading_r;
wire loader_write;
wire [63:0] loader_flags;
reg  [63:0] mapper_flags;
wire loader_done, loader_fail;
wire loader_busy, loaded;

wire type_nes = 1'b0;  
wire type_bios = 1'b0; 
wire is_bios = 0;      
wire type_fds = 1'b0;  
wire type_nsf = 1'b0;  
wire type_raw = 1'b1;

wire int_audio;         
wire ext_audio;

///////////////////////////
// Clocks
///////////////////////////

wire clk;       
wire fclk;      
wire hclk;      
wire hclk5;     
wire clk27;     
wire clk_usb;   

reg sys_resetn = 0;
reg [7:0] reset_cnt = 255;      
always @(posedge clk) begin
    reset_cnt <= reset_cnt == 0 ? 0 : reset_cnt - 1;
    if (reset_cnt == 0)
        sys_resetn <= ~(joy1_btns[5] && joy1_btns[3]);    
end

`ifndef VERILATOR

`ifdef PRIMER
gowin_pll_27 pll_27 (.clkin(sys_clk), .clkout0(clk27));        
gowin_pll_gb pll_gb (.clkin(sys_clk), .clkout0(clk), .clkout1(fclk), .clkout2(O_sdram_clk));
`else
assign clk27 = sys_clk;        
gowin_pll_gb pll_gb(.clkin(sys_clk), .clkoutd3(clk), .clkout(fclk), .clkoutp(O_sdram_clk));
`endif  

gowin_pll_hdmi pll_hdmi (
    .clkin(clk27),
    .clkout(hclk5)
);

CLKDIV #(.DIV_MODE(5)) div5 (
    .CLKOUT(hclk),
    .HCLKIN(hclk5),
    .RESETN(sys_resetn),
    .CALIB(1'b0)
);

`else   // verilator
assign clk = sys_clk;
assign fclk = sys_clk;
`endif  // verilator

wire [31:0] status;
wire [7:0] GB_memory_din_cpu;
wire [7:0] GB_cheats_otuput_data_test;
wire GB_top_cheats_stb;

// Este es nuestro SNIFFER que robará el tipo de cartucho en pleno vuelo
reg [7:0] gb_cart_type = 8'h00;


// ==================================================================== //
// --- ZONA FRANKENSTEIN: INSTANCIACIÓN DE VERILOGBOY ---
// ==================================================================== //

reg [2:0] gb_clk_cnt;
reg gb_clk;
always @(posedge clk) begin
    gb_clk_cnt <= (gb_clk_cnt == 4) ? 0 : gb_clk_cnt + 1;
    gb_clk <= (gb_clk_cnt < 2);
end

wire [7:0] gb_joystick = {
    joy1_btns[5], // Abajo
    joy1_btns[4], // Arriba
    joy1_btns[6], // Izquierda
    joy1_btns[7], // Derecha
    joy1_btns[3], // Start
    joy1_btns[2], // Select
    joy1_btns[8], // A o B
    joy1_btns[0]  // A o B
};

wire boy_phi;
wire [15:0] boy_a;
wire [7:0] boy_dout;
wire boy_wr;
wire boy_rd;
wire boy_hs;
wire boy_vs;
wire boy_cpl;
wire [1:0] boy_pixel;
wire boy_valid;
wire [15:0] boy_left;
wire [15:0] boy_right;
wire boy_done;
wire boy_fault;

wire [7:0] cpu_data_to_core;

boy verilogboy_core (
    .rst(reset_nes),       
    .clk(gb_clk),          
    .phi(boy_phi),
    .a(boy_a),
    .dout(boy_dout),
    .din(cpu_data_to_core), 
    .wr(boy_wr),
    .rd(boy_rd),
    .key(gb_joystick),
    .hs(boy_hs),
    .vs(boy_vs),
    .cpl(boy_cpl),
    .pixel(boy_pixel),
    .valid(boy_valid),
    .left(boy_left),
    .right(boy_right),
    .done(boy_done),
    .fault(boy_fault)
);


// ====================================================================
// 4. Conexión a la Memoria SDRAM (MULTIMAPPER DE BLARGG)
// ====================================================================

wire [22:14] mbc1_rom_a, mbc5_rom_a;
wire [16:13] mbc1_ram_a, mbc5_ram_a; 
wire mbc1_cs, mbc5_cs;
wire mbc1_ram_cs, mbc5_ram_cs;

mbc1 mapper_1 (
    .vb_clk(gb_clk), .vb_a(boy_a[15:12]), .vb_d(boy_dout),
    .vb_wr(boy_wr), .vb_rd(boy_rd), .vb_rst(reset_nes),
    .rom_a(mbc1_rom_a), .ram_a(mbc1_ram_a), 
    .rom_cs_n(mbc1_cs), .ram_cs_n(mbc1_ram_cs)
);

mbc5 mapper_5 (
    .vb_clk(gb_clk), .vb_a(boy_a[15:12]), .vb_d(boy_dout),
    .vb_wr(boy_wr), .vb_rd(boy_rd), .vb_rst(reset_nes),
    .rom_a(mbc5_rom_a), .ram_a(mbc5_ram_a), 
    .rom_cs_n(mbc5_cs), .ram_cs_n(mbc5_ram_cs)
);

// Decodificamos el verdadero header usando nuestro SNIFFER (gb_cart_type)
wire is_mbc1 = (gb_cart_type >= 8'h01 && gb_cart_type <= 8'h03);
wire is_mbc5 = (gb_cart_type >= 8'h19 && gb_cart_type <= 8'h1E) || 
               (gb_cart_type >= 8'h0F && gb_cart_type <= 8'h13) || // MBC3
               (gb_cart_type >= 8'h05 && gb_cart_type <= 8'h06);   // MBC2

wire [22:14] rom_only_a = {8'b0, boy_a[14]};
wire [22:14] active_rom_a = is_mbc1 ? mbc1_rom_a : (is_mbc5 ? mbc5_rom_a : rom_only_a);
wire [16:13] active_ram_a = is_mbc1 ? mbc1_ram_a : (is_mbc5 ? mbc5_ram_a : 4'b0);

// Detectamos el estado de la SRAM (1 = SRAM Desactivada / Bloqueada)
wire active_ram_cs_n = is_mbc1 ? mbc1_ram_cs : (is_mbc5 ? mbc5_ram_cs : 1'b1);

wire is_rom_access = (boy_a < 16'h8000);
wire is_ram_access = (boy_a >= 16'hA000 && boy_a <= 16'hBFFF);

assign memory_addr_cpu = is_rom_access ? {active_rom_a[21:14], boy_a[13:0]} : 
                         is_ram_access ? {5'b11000, active_ram_a[16:13], boy_a[12:0]} : 
                         {6'b0, boy_a};
                         
assign memory_read_cpu = boy_rd;

// FIX DE BLARGG 1: Bloquear escrituras si el juego apagó la SRAM
assign memory_write_cpu = is_rom_access ? 1'b0 : 
                          (is_ram_access && active_ram_cs_n) ? 1'b0 : 
                          boy_wr;

assign memory_dout_cpu = boy_dout;

// FIX DE BLARGG 2: Inyectar un '0xFF' exacto si la CPU intenta leer la SRAM apagada
assign GB_top_cheats_stb = (GB_cheats_enabled)&&(GB_cheats_loaded)&&(GB_cheats_stb);
wire [7:0] filtered_din_cpu = (is_ram_access && active_ram_cs_n) ? 8'hFF : memory_din_cpu;
assign cpu_data_to_core = (!GB_top_cheats_stb ? filtered_din_cpu : GB_cheats_otuput_data);


// 5. Adaptador de Video para HDMI
reg [8:0] fake_cycle;
reg [8:0] fake_scanline;
reg old_vs;
reg old_gb_clk;

always @(posedge clk) begin
    old_vs <= boy_vs;
    old_gb_clk <= gb_clk;

    if (old_vs && !boy_vs) begin
        fake_cycle <= 0;
        fake_scanline <= 0;
        
    end else if (boy_valid && !gb_clk && old_gb_clk) begin
        if (fake_cycle == 159) begin
            fake_cycle <= 0;
            fake_scanline <= fake_scanline + 1;
        end else begin
            fake_cycle <= fake_cycle + 1;
        end
    end
end

assign cycle = fake_cycle;
assign scanline = fake_scanline;

assign color = (boy_pixel == 2'b00) ? 6'h30 : 
               (boy_pixel == 2'b01) ? 6'h20 : 
               (boy_pixel == 2'b10) ? 6'h10 : 
               (boy_pixel == 2'b11) ? 6'h0F : 
               6'h0F;

assign sample = boy_left;

assign memory_addr_ppu = 22'b0;
assign memory_write_ppu = 1'b0;
assign memory_read_ppu = 1'b0;
assign memory_dout_ppu = 8'b0;


// ====================================================================
// --- ESTIRADOR DE PULSOS Y SNIFFER DE HEADER ---
// ====================================================================

reg [21:0] raw_loader_addr;
always @(posedge clk) begin
    if (!loading) begin
        raw_loader_addr <= 22'd0;
    end else if (loader_do_valid) begin
        // ¡SNIFFER! Atrapamos el byte 0x0147 que indica el verdadero Mapper del GB
        if (raw_loader_addr == 22'h0147) begin
            gb_cart_type <= loader_do;
        end
        raw_loader_addr <= raw_loader_addr + 1'b1;
    end
end

reg raw_write_mem;
reg [7:0] raw_write_data_mem;
reg [21:0] raw_addr_mem;
reg raw_write_r;

always @(posedge clk) begin
    raw_write_mem <= 0;
    raw_write_r <= loader_do_valid;

    raw_write_mem <= loader_do_valid || raw_write_r;
    
    if (loader_do_valid) begin
        raw_addr_mem <= raw_loader_addr;
        raw_write_data_mem <= loader_do;
    end

    if (loader_done)
        mapper_flags <= loader_flags;
end

sdram_gb sdram (
    .clk(fclk), .clkref(clkref), .resetn(sys_resetn), .busy(sdram_busy),

    .SDRAM_DQ(IO_sdram_dq), .SDRAM_A(O_sdram_addr), .SDRAM_BA(O_sdram_ba), 
    .SDRAM_nCS(O_sdram_cs_n), .SDRAM_nWE(O_sdram_wen_n), .SDRAM_nRAS(O_sdram_ras_n), 
    .SDRAM_nCAS(O_sdram_cas_n), .SDRAM_CKE(O_sdram_cke), .SDRAM_DQM(O_sdram_dqm), 

    .addrA(memory_addr_ppu), .weA(memory_write_ppu), .dinA(memory_dout_ppu),
    .oeA(memory_read_ppu), .doutA(memory_din_ppu),

    .addrB(loading ? raw_addr_mem : memory_addr_cpu), 
    .weB(loading ? raw_write_mem : memory_write_cpu),
    .dinB(loading ? raw_write_data_mem : memory_dout_cpu),
    .oeB(~loading & memory_read_cpu), .doutB(memory_din_cpu),

    .rv_addr({rv_addr[20:2], rv_word}), .rv_din(rv_word ? rv_wdata[31:16] : rv_wdata[15:0]), 
    .rv_ds(rv_ds), .rv_dout(rv_dout), .rv_req(rv_req), .rv_req_ack(rv_req_ack), .rv_we(rv_wstrb != 0)
);

GameLoader loader(
    .clk(clk), .reset(~sys_resetn | loader_reset), .downloading(loading), 
    .filetype({3'b000, type_raw, type_nsf, type_fds, type_nes, type_bios}),
    .is_bios(is_bios), .invert_mirroring(1'b0),
    .indata(loader_do), .indata_clk(loader_do_valid),

    .mem_addr(loader_addr), .mem_data(loader_write_data), .mem_write(loader_write),
    .bios_download(),
    .mapper_flags(loader_flags), .busy(loader_busy), .done(loader_done),
    .error(loader_fail), .rom_loaded()
    // SE ELIMINÓ EL .o_mapper() FALSO QUE TRAICIONABA AL SISTEMA
);

assign int_audio = 1;
assign ext_audio = (mapper_flags[7:0] == 19) | (mapper_flags[7:0] == 24) | (mapper_flags[7:0] == 26);

always @(posedge clk) begin
    clkref <= ~clkref;
    if (~loading && loading_r) begin
        reset_nes <= 0;
        clkref <= 1;
    end else if (loading && ~loading_r)
        reset_nes <= 1;
    if (~sys_resetn)
        reset_nes <= 1;
end

///////////////////////////
// Peripherals
///////////////////////////

`ifdef VERILATOR
GameData game_data(
    .clk(clk), .reset(~sys_resetn), .downloading(loading), 
    .odata(loader_do), .odata_clk(loader_do_valid));
`else

wire overlay;                   
wire [10:0] overlay_x;
wire [9:0]  overlay_y;
wire [15:0] overlay_color;      

nes2hdmi u_hdmi (     
    .clk(clk), .resetn(sys_resetn),
    .color(color), .cycle(cycle), 
    .scanline(scanline), .sample(sample >> 1),
    .i_reg_aspect_ratio(GB_aspect_ratio),
    .overlay(overlay), .overlay_x(overlay_x), .overlay_y(overlay_y),
    .overlay_color(overlay_color),
    .clk_pixel(hclk), .clk_5x_pixel(hclk5),
    .tmds_clk_n(tmds_clk_n), .tmds_clk_p(tmds_clk_p),
    .tmds_d_n(tmds_d_n), .tmds_d_p(tmds_d_p)
);

localparam RV_IDLE_REQ0 = 3'd0;
localparam RV_WAIT0_REQ1 = 3'd1;
localparam RV_DATA0 = 3'd2;
localparam RV_WAIT1 = 3'd3;
localparam RV_DATA1 = 3'd4;
reg [2:0]   rvst;

always @(posedge clk) begin            
    if (~sys_resetn) begin
        rvst <= RV_IDLE_REQ0;
        rv_ready <= 0;
    end else begin
        reg write = rv_wstrb != 0;
        reg rv_new_req_t = rv_valid & ~rv_valid_r;
        if (rv_new_req_t) rv_new_req <= 1;

        rv_ready <= 0;
        rv_valid_r <= rv_valid;

        case (rvst)
        RV_IDLE_REQ0: if (rv_new_req || rv_new_req_t) begin
            rv_new_req <= 0;
            rv_req <= ~rv_req;
            if (write && rv_wstrb[1:0] == 2'b0) begin
                rv_word <= 1;
                rv_ds <= rv_wstrb[3:2];
                rvst <= RV_WAIT1;
            end else begin
                rv_word <= 0;
                if (write)
                    rv_ds <= rv_wstrb[1:0];
                else
                    rv_ds <= 2'b11;
                rvst <= RV_WAIT0_REQ1;
            end
        end

        RV_WAIT0_REQ1: begin
            if (rv_req == rv_req_ack) begin
                rv_req <= ~rv_req;      
                rv_word <= 1;
                if (write) begin
                    rvst <= RV_WAIT1;
                    if (rv_wstrb[3:2] == 2'b0) begin
                        rv_req <= rv_req;
                        rv_ready <= 1;
                        rvst <= RV_IDLE_REQ0;
                    end
                    rv_ds <= rv_wstrb[3:2];
                end else begin
                    rv_ds <= 2'b11;
                    rvst <= RV_DATA0;
                end
            end
        end

        RV_DATA0: begin
            rv_dout0 <= rv_dout;
            rvst <= RV_WAIT1;
        end
            
        RV_WAIT1: 
            if (rv_req == rv_req_ack) begin
                if (write)  begin
                    rv_ready <= 1;
                    rvst <= RV_IDLE_REQ0;
                end else
                    rvst <= RV_DATA1;
            end

        RV_DATA1: begin
            rv_ready <= 1;
            rvst <= RV_IDLE_REQ0;
        end

        default:;
        endcase
    end
end

reg GB_enhanced_APU;

iosys #(.COLOR_LOGO(15'b01000_00000_01000), .CORE_ID(3) )     
    iosys (
    .clk(clk), .hclk(hclk), .resetn(sys_resetn),

    .overlay(overlay), .overlay_x(overlay_x), .overlay_y(overlay_y),
    .overlay_color(overlay_color),
    .joy1(joy1_btns), .joy2(joy2_btns),

    .rom_loading(loading), .rom_do(loader_do), .rom_do_valid(loader_do_valid), 
    .ram_busy(sdram_busy),

    .rv_valid(rv_valid), .rv_ready(rv_ready), .rv_addr(rv_addr),
    .rv_wdata(rv_wdata), .rv_wstrb(rv_wstrb), .rv_rdata(rv_rdata),

    .flash_spi_cs_n(flash_spi_cs_n), .flash_spi_miso(flash_spi_miso),
    .flash_spi_mosi(flash_spi_mosi), .flash_spi_clk(flash_spi_clk),
    .flash_spi_wp_n(flash_spi_wp_n), .flash_spi_hold_n(flash_spi_hold_n),

    .uart_tx(UART_TXD), .uart_rx(UART_RXD),

    .sd_clk(sd_clk), .sd_cmd(sd_cmd), .sd_dat0(sd_dat0), .sd_dat1(sd_dat1),
    .sd_dat2(sd_dat2), .sd_dat3(sd_dat3),
    .o_reg_enhanced_apu(GB_enhanced_APU),
    .i_wb_ack(GB_wb_slave_ack),
    .i_wb_stall(GB_wb_slave_stall),
    .i_wb_idata(GB_wb_slave_data),
    .i_wb_err(GB_wb_slave_err),
    .o_wb_cyc(GB_wb_master_cyc),
    .o_wb_stb(GB_wb_master_stb),
    .o_wb_we(GB_wb_master_we),
    .o_wb_err(GB_wb_master_err),
    .o_wb_addr(GB_wb_slave_addr),
    .o_wb_odata(GB_wb_master_data),
    .o_wb_sel(GB_wb_master_sel),

    .o_cheats_enabled(GB_cheats_enabled),
    .o_cheats_loaded(GB_cheats_loaded),
    .o_dbg_led(),
    .o_sys_type(system_type),
    .o_reg_aspect_ratio(GB_aspect_ratio)
);

`ifdef CONTROLLER_SNES
controller_snes joy1_snes (
    .clk(clk), .resetn(sys_resetn), .buttons(joy1_btns),
    .joy_strb(joy1_strb), .joy_clk(joy1_clk), .joy_data(joy1_data)
);
controller_snes joy2_snes (
    .clk(clk), .resetn(sys_resetn), .buttons(joy2_btns),
    .joy_strb(joy2_strb), .joy_clk(joy2_clk), .joy_data(joy2_data)
);
`endif

`ifdef CONTROLLER_DS2
controller_ds2 joy1_ds2 (
    .clk(clk), .snes_buttons(joy1_btns),
    .ds_clk(ds_clk), .ds_miso(ds_miso), .ds_mosi(ds_mosi), .ds_cs(ds_cs) 
);
controller_ds2 joy2_ds2 (
   .clk(clk), .snes_buttons(joy2_btns),
   .ds_clk(ds_clk2), .ds_miso(ds_miso2), .ds_mosi(ds_mosi2), .ds_cs(ds_cs2) 
);
`endif

Autofire af_a (.clk(clk), .resetn(sys_resetn), .btn(joy1_btns[8]), .out(auto_a));
Autofire af_b (.clk(clk), .resetn(sys_resetn), .btn(joy1_btns[9]), .out(auto_b));
Autofire af_a2 (.clk(clk), .resetn(sys_resetn), .btn(joy2_btns[8]), .out(auto_a2));
Autofire af_b2 (.clk(clk), .resetn(sys_resetn), .btn(joy2_btns[9]), .out(auto_b2));

always @(posedge clk) begin
    if (joypad_strobe) begin
        joypad_bits <= {joy1_btns[7:2], joy1_btns[1] | auto_b, joy1_btns[0] | auto_a};
        joypad_bits2 <= {joy2_btns[7:2], joy2_btns[1] | auto_b2, joy2_btns[0] | auto_a2};
    end
    if (!joypad_clock[0] && last_joypad_clock[0])
        joypad_bits <= {1'b1, joypad_bits[7:1]};
    if (!joypad_clock[1] && last_joypad_clock[1])
        joypad_bits2 <= {1'b1, joypad_bits2[7:1]};
    last_joypad_clock <= joypad_clock;
end
assign joypad1_data[0] = joypad_bits[0];
assign joypad2_data[0] = joypad_bits2[0];

`endif

reg [23:0] led_cnt;
always @(posedge clk) led_cnt <= led_cnt + 1;

wire GB_wb_master_cyc;
wire GB_wb_master_stb;
wire GB_wb_master_we;
wire GB_wb_master_err;
wire [1:0] GB_wb_slave_addr;
wire [128:0] GB_wb_master_data;
wire GB_wb_slave_ack;
wire GB_wb_slave_stall;
wire GB_wb_slave_err;
wire [128:0] GB_wb_slave_data;
wire [2:0] GB_wb_slave_sel;

wire [7:0] GB_cheats_otuput_data;
wire GB_cheats_stb;
wire [23:0] GB_cheats_memory_addr_cpu;
wire GB_cheats_enabled;
wire GB_cheats_loaded;

assign GB_cheats_memory_addr_cpu = {2'b00, memory_addr_cpu};

// Dummy cheat wizard for compilation safety
assign GB_cheats_stb = 0;
assign GB_cheats_otuput_data = 8'd0;
assign GB_wb_slave_ack = 0;
assign GB_wb_slave_stall = 0;
assign GB_wb_slave_err = 0;

reg GB_aspect_ratio;
initial GB_aspect_ratio = 1'b0;

endmodule