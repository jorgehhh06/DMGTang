module gw_gao(
    clk,
    loading,
    loading_r,
    \loader_addr_mem[21] ,
    \loader_addr_mem[20] ,
    \loader_addr_mem[19] ,
    \loader_addr_mem[18] ,
    \loader_addr_mem[17] ,
    \loader_addr_mem[16] ,
    \loader_addr_mem[15] ,
    \loader_addr_mem[14] ,
    \loader_addr_mem[13] ,
    \loader_addr_mem[12] ,
    \loader_addr_mem[11] ,
    \loader_addr_mem[10] ,
    \loader_addr_mem[9] ,
    \loader_addr_mem[8] ,
    \loader_addr_mem[7] ,
    \loader_addr_mem[6] ,
    \loader_addr_mem[5] ,
    \loader_addr_mem[4] ,
    \loader_addr_mem[3] ,
    \loader_addr_mem[2] ,
    \loader_addr_mem[1] ,
    \loader_addr_mem[0] ,
    loader_write_mem,
    \loader_write_data_mem[7] ,
    \loader_write_data_mem[6] ,
    \loader_write_data_mem[5] ,
    \loader_write_data_mem[4] ,
    \loader_write_data_mem[3] ,
    \loader_write_data_mem[2] ,
    \loader_write_data_mem[1] ,
    \loader_write_data_mem[0] ,
    \loader_do[7] ,
    \loader_do[6] ,
    \loader_do[5] ,
    \loader_do[4] ,
    \loader_do[3] ,
    \loader_do[2] ,
    \loader_do[1] ,
    \loader_do[0] ,
    loader_do_valid,
    \iosys/rom_do_buf[31] ,
    \iosys/rom_do_buf[30] ,
    \iosys/rom_do_buf[29] ,
    \iosys/rom_do_buf[28] ,
    \iosys/rom_do_buf[27] ,
    \iosys/rom_do_buf[26] ,
    \iosys/rom_do_buf[25] ,
    \iosys/rom_do_buf[24] ,
    \iosys/rom_do_buf[23] ,
    \iosys/rom_do_buf[22] ,
    \iosys/rom_do_buf[21] ,
    \iosys/rom_do_buf[20] ,
    \iosys/rom_do_buf[19] ,
    \iosys/rom_do_buf[18] ,
    \iosys/rom_do_buf[17] ,
    \iosys/rom_do_buf[16] ,
    \iosys/rom_do_buf[15] ,
    \iosys/rom_do_buf[14] ,
    \iosys/rom_do_buf[13] ,
    \iosys/rom_do_buf[12] ,
    \iosys/rom_do_buf[11] ,
    \iosys/rom_do_buf[10] ,
    \iosys/rom_do_buf[9] ,
    \iosys/rom_do_buf[8] ,
    \nes/cpu/A[15] ,
    \nes/cpu/A[14] ,
    \nes/cpu/A[13] ,
    \nes/cpu/A[12] ,
    \nes/cpu/A[11] ,
    \nes/cpu/A[10] ,
    \nes/cpu/A[9] ,
    \nes/cpu/A[8] ,
    \nes/cpu/A[7] ,
    \nes/cpu/A[6] ,
    \nes/cpu/A[5] ,
    \nes/cpu/A[4] ,
    \nes/cpu/A[3] ,
    \nes/cpu/A[2] ,
    \nes/cpu/A[1] ,
    \nes/cpu/A[0] ,
    \nes/cpu/MCycle[2] ,
    \nes/cpu/MCycle[1] ,
    \nes/cpu/MCycle[0] ,
    \nes/cpu/DI[7] ,
    \nes/cpu/DI[6] ,
    \nes/cpu/DI[5] ,
    \nes/cpu/DI[4] ,
    \nes/cpu/DI[3] ,
    \nes/cpu/DI[2] ,
    \nes/cpu/DI[1] ,
    \nes/cpu/DI[0] ,
    \nes/cpu/DO[7] ,
    \nes/cpu/DO[6] ,
    \nes/cpu/DO[5] ,
    \nes/cpu/DO[4] ,
    \nes/cpu/DO[3] ,
    \nes/cpu/DO[2] ,
    \nes/cpu/DO[1] ,
    \nes/cpu/DO[0] ,
    \sdram/cycle[11] ,
    \sdram/cycle[10] ,
    \sdram/cycle[9] ,
    \sdram/cycle[8] ,
    \sdram/cycle[7] ,
    \sdram/cycle[6] ,
    \sdram/cycle[5] ,
    \sdram/cycle[4] ,
    \sdram/cycle[3] ,
    \sdram/cycle[2] ,
    \sdram/cycle[1] ,
    \sdram/cycle[0] ,
    \nes/prg_allow ,
    \nes/prg_read ,
    \loader/ines[4][7] ,
    \loader/ines[4][6] ,
    \loader/ines[4][5] ,
    \loader/ines[4][4] ,
    \loader/ines[4][3] ,
    \loader/ines[4][2] ,
    \loader/ines[4][1] ,
    \loader/ines[4][0] ,
    \loader/ines[5][7] ,
    \loader/ines[5][6] ,
    \loader/ines[5][5] ,
    \loader/ines[5][4] ,
    \loader/ines[5][3] ,
    \loader/ines[5][2] ,
    \loader/ines[5][1] ,
    \loader/ines[5][0] ,
    \rv_addr_Z[9] ,
    \rv_addr_Z[8] ,
    \rv_addr_Z[7] ,
    \rv_addr_Z[6] ,
    \rv_addr_Z[5] ,
    \rv_addr_Z[4] ,
    \rv_addr_Z[3] ,
    \rv_addr_Z[2] ,
    rv_valid_Z,
    \flash_wstrb[3] ,
    \flash_wstrb[2] ,
    \flash_wstrb[1] ,
    \flash_wstrb[0] ,
    \rv_dout_Z[15] ,
    \rv_dout_Z[14] ,
    \rv_dout_Z[13] ,
    \rv_dout_Z[12] ,
    \rv_dout_Z[11] ,
    \rv_dout_Z[10] ,
    \rv_dout_Z[9] ,
    \rv_dout_Z[8] ,
    \rv_dout_Z[7] ,
    \rv_dout_Z[6] ,
    \rv_dout_Z[5] ,
    \rv_dout_Z[4] ,
    \rv_dout_Z[3] ,
    \rv_dout_Z[2] ,
    \rv_dout_Z[1] ,
    \rv_dout_Z[0] ,
    \rv_wdata_Z[15] ,
    \rv_wdata_Z[14] ,
    \rv_wdata_Z[13] ,
    \rv_wdata_Z[12] ,
    \rv_wdata_Z[11] ,
    \rv_wdata_Z[10] ,
    \rv_wdata_Z[9] ,
    \rv_wdata_Z[8] ,
    \rv_wdata_Z[7] ,
    \rv_wdata_Z[6] ,
    \rv_wdata_Z[5] ,
    \rv_wdata_Z[4] ,
    \rv_wdata_Z[3] ,
    \rv_wdata_Z[2] ,
    \rv_wdata_Z[1] ,
    \rv_wdata_Z[0] ,
    rv_req,
    rv_req_ack_Z,
    \rv_ds[1] ,
    \rv_ds[0] ,
    rv_word,
    O_sdram_cs_n,
    O_sdram_ras_n,
    O_sdram_cas_n,
    O_sdram_wen_n,
    \O_sdram_addr[10] ,
    \O_sdram_addr[9] ,
    \O_sdram_addr[8] ,
    \O_sdram_addr[7] ,
    \O_sdram_addr[6] ,
    \O_sdram_addr[5] ,
    \O_sdram_addr[4] ,
    \O_sdram_addr[3] ,
    \O_sdram_addr[2] ,
    \O_sdram_addr[1] ,
    \O_sdram_addr[0] ,
    \IO_sdram_dq[31] ,
    \IO_sdram_dq[30] ,
    \IO_sdram_dq[29] ,
    \IO_sdram_dq[28] ,
    \IO_sdram_dq[27] ,
    \IO_sdram_dq[26] ,
    \IO_sdram_dq[25] ,
    \IO_sdram_dq[24] ,
    \IO_sdram_dq[23] ,
    \IO_sdram_dq[22] ,
    \IO_sdram_dq[21] ,
    \IO_sdram_dq[20] ,
    \IO_sdram_dq[19] ,
    \IO_sdram_dq[18] ,
    \IO_sdram_dq[17] ,
    \IO_sdram_dq[16] ,
    \IO_sdram_dq[15] ,
    \IO_sdram_dq[14] ,
    \IO_sdram_dq[13] ,
    \IO_sdram_dq[12] ,
    \IO_sdram_dq[11] ,
    \IO_sdram_dq[10] ,
    \IO_sdram_dq[9] ,
    \IO_sdram_dq[8] ,
    \IO_sdram_dq[7] ,
    \IO_sdram_dq[6] ,
    \IO_sdram_dq[5] ,
    \IO_sdram_dq[4] ,
    \IO_sdram_dq[3] ,
    \IO_sdram_dq[2] ,
    \IO_sdram_dq[1] ,
    \IO_sdram_dq[0] ,
    \O_sdram_ba[1] ,
    \O_sdram_ba[0] ,
    \O_sdram_dqm[3] ,
    \O_sdram_dqm[2] ,
    \O_sdram_dqm[1] ,
    \O_sdram_dqm[0] ,
    \iosys/flash_loaded ,
    fclk,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input clk;
input loading;
input loading_r;
input \loader_addr_mem[21] ;
input \loader_addr_mem[20] ;
input \loader_addr_mem[19] ;
input \loader_addr_mem[18] ;
input \loader_addr_mem[17] ;
input \loader_addr_mem[16] ;
input \loader_addr_mem[15] ;
input \loader_addr_mem[14] ;
input \loader_addr_mem[13] ;
input \loader_addr_mem[12] ;
input \loader_addr_mem[11] ;
input \loader_addr_mem[10] ;
input \loader_addr_mem[9] ;
input \loader_addr_mem[8] ;
input \loader_addr_mem[7] ;
input \loader_addr_mem[6] ;
input \loader_addr_mem[5] ;
input \loader_addr_mem[4] ;
input \loader_addr_mem[3] ;
input \loader_addr_mem[2] ;
input \loader_addr_mem[1] ;
input \loader_addr_mem[0] ;
input loader_write_mem;
input \loader_write_data_mem[7] ;
input \loader_write_data_mem[6] ;
input \loader_write_data_mem[5] ;
input \loader_write_data_mem[4] ;
input \loader_write_data_mem[3] ;
input \loader_write_data_mem[2] ;
input \loader_write_data_mem[1] ;
input \loader_write_data_mem[0] ;
input \loader_do[7] ;
input \loader_do[6] ;
input \loader_do[5] ;
input \loader_do[4] ;
input \loader_do[3] ;
input \loader_do[2] ;
input \loader_do[1] ;
input \loader_do[0] ;
input loader_do_valid;
input \iosys/rom_do_buf[31] ;
input \iosys/rom_do_buf[30] ;
input \iosys/rom_do_buf[29] ;
input \iosys/rom_do_buf[28] ;
input \iosys/rom_do_buf[27] ;
input \iosys/rom_do_buf[26] ;
input \iosys/rom_do_buf[25] ;
input \iosys/rom_do_buf[24] ;
input \iosys/rom_do_buf[23] ;
input \iosys/rom_do_buf[22] ;
input \iosys/rom_do_buf[21] ;
input \iosys/rom_do_buf[20] ;
input \iosys/rom_do_buf[19] ;
input \iosys/rom_do_buf[18] ;
input \iosys/rom_do_buf[17] ;
input \iosys/rom_do_buf[16] ;
input \iosys/rom_do_buf[15] ;
input \iosys/rom_do_buf[14] ;
input \iosys/rom_do_buf[13] ;
input \iosys/rom_do_buf[12] ;
input \iosys/rom_do_buf[11] ;
input \iosys/rom_do_buf[10] ;
input \iosys/rom_do_buf[9] ;
input \iosys/rom_do_buf[8] ;
input \nes/cpu/A[15] ;
input \nes/cpu/A[14] ;
input \nes/cpu/A[13] ;
input \nes/cpu/A[12] ;
input \nes/cpu/A[11] ;
input \nes/cpu/A[10] ;
input \nes/cpu/A[9] ;
input \nes/cpu/A[8] ;
input \nes/cpu/A[7] ;
input \nes/cpu/A[6] ;
input \nes/cpu/A[5] ;
input \nes/cpu/A[4] ;
input \nes/cpu/A[3] ;
input \nes/cpu/A[2] ;
input \nes/cpu/A[1] ;
input \nes/cpu/A[0] ;
input \nes/cpu/MCycle[2] ;
input \nes/cpu/MCycle[1] ;
input \nes/cpu/MCycle[0] ;
input \nes/cpu/DI[7] ;
input \nes/cpu/DI[6] ;
input \nes/cpu/DI[5] ;
input \nes/cpu/DI[4] ;
input \nes/cpu/DI[3] ;
input \nes/cpu/DI[2] ;
input \nes/cpu/DI[1] ;
input \nes/cpu/DI[0] ;
input \nes/cpu/DO[7] ;
input \nes/cpu/DO[6] ;
input \nes/cpu/DO[5] ;
input \nes/cpu/DO[4] ;
input \nes/cpu/DO[3] ;
input \nes/cpu/DO[2] ;
input \nes/cpu/DO[1] ;
input \nes/cpu/DO[0] ;
input \sdram/cycle[11] ;
input \sdram/cycle[10] ;
input \sdram/cycle[9] ;
input \sdram/cycle[8] ;
input \sdram/cycle[7] ;
input \sdram/cycle[6] ;
input \sdram/cycle[5] ;
input \sdram/cycle[4] ;
input \sdram/cycle[3] ;
input \sdram/cycle[2] ;
input \sdram/cycle[1] ;
input \sdram/cycle[0] ;
input \nes/prg_allow ;
input \nes/prg_read ;
input \loader/ines[4][7] ;
input \loader/ines[4][6] ;
input \loader/ines[4][5] ;
input \loader/ines[4][4] ;
input \loader/ines[4][3] ;
input \loader/ines[4][2] ;
input \loader/ines[4][1] ;
input \loader/ines[4][0] ;
input \loader/ines[5][7] ;
input \loader/ines[5][6] ;
input \loader/ines[5][5] ;
input \loader/ines[5][4] ;
input \loader/ines[5][3] ;
input \loader/ines[5][2] ;
input \loader/ines[5][1] ;
input \loader/ines[5][0] ;
input \rv_addr_Z[9] ;
input \rv_addr_Z[8] ;
input \rv_addr_Z[7] ;
input \rv_addr_Z[6] ;
input \rv_addr_Z[5] ;
input \rv_addr_Z[4] ;
input \rv_addr_Z[3] ;
input \rv_addr_Z[2] ;
input rv_valid_Z;
input \flash_wstrb[3] ;
input \flash_wstrb[2] ;
input \flash_wstrb[1] ;
input \flash_wstrb[0] ;
input \rv_dout_Z[15] ;
input \rv_dout_Z[14] ;
input \rv_dout_Z[13] ;
input \rv_dout_Z[12] ;
input \rv_dout_Z[11] ;
input \rv_dout_Z[10] ;
input \rv_dout_Z[9] ;
input \rv_dout_Z[8] ;
input \rv_dout_Z[7] ;
input \rv_dout_Z[6] ;
input \rv_dout_Z[5] ;
input \rv_dout_Z[4] ;
input \rv_dout_Z[3] ;
input \rv_dout_Z[2] ;
input \rv_dout_Z[1] ;
input \rv_dout_Z[0] ;
input \rv_wdata_Z[15] ;
input \rv_wdata_Z[14] ;
input \rv_wdata_Z[13] ;
input \rv_wdata_Z[12] ;
input \rv_wdata_Z[11] ;
input \rv_wdata_Z[10] ;
input \rv_wdata_Z[9] ;
input \rv_wdata_Z[8] ;
input \rv_wdata_Z[7] ;
input \rv_wdata_Z[6] ;
input \rv_wdata_Z[5] ;
input \rv_wdata_Z[4] ;
input \rv_wdata_Z[3] ;
input \rv_wdata_Z[2] ;
input \rv_wdata_Z[1] ;
input \rv_wdata_Z[0] ;
input rv_req;
input rv_req_ack_Z;
input \rv_ds[1] ;
input \rv_ds[0] ;
input rv_word;
input O_sdram_cs_n;
input O_sdram_ras_n;
input O_sdram_cas_n;
input O_sdram_wen_n;
input \O_sdram_addr[10] ;
input \O_sdram_addr[9] ;
input \O_sdram_addr[8] ;
input \O_sdram_addr[7] ;
input \O_sdram_addr[6] ;
input \O_sdram_addr[5] ;
input \O_sdram_addr[4] ;
input \O_sdram_addr[3] ;
input \O_sdram_addr[2] ;
input \O_sdram_addr[1] ;
input \O_sdram_addr[0] ;
input \IO_sdram_dq[31] ;
input \IO_sdram_dq[30] ;
input \IO_sdram_dq[29] ;
input \IO_sdram_dq[28] ;
input \IO_sdram_dq[27] ;
input \IO_sdram_dq[26] ;
input \IO_sdram_dq[25] ;
input \IO_sdram_dq[24] ;
input \IO_sdram_dq[23] ;
input \IO_sdram_dq[22] ;
input \IO_sdram_dq[21] ;
input \IO_sdram_dq[20] ;
input \IO_sdram_dq[19] ;
input \IO_sdram_dq[18] ;
input \IO_sdram_dq[17] ;
input \IO_sdram_dq[16] ;
input \IO_sdram_dq[15] ;
input \IO_sdram_dq[14] ;
input \IO_sdram_dq[13] ;
input \IO_sdram_dq[12] ;
input \IO_sdram_dq[11] ;
input \IO_sdram_dq[10] ;
input \IO_sdram_dq[9] ;
input \IO_sdram_dq[8] ;
input \IO_sdram_dq[7] ;
input \IO_sdram_dq[6] ;
input \IO_sdram_dq[5] ;
input \IO_sdram_dq[4] ;
input \IO_sdram_dq[3] ;
input \IO_sdram_dq[2] ;
input \IO_sdram_dq[1] ;
input \IO_sdram_dq[0] ;
input \O_sdram_ba[1] ;
input \O_sdram_ba[0] ;
input \O_sdram_dqm[3] ;
input \O_sdram_dqm[2] ;
input \O_sdram_dqm[1] ;
input \O_sdram_dqm[0] ;
input \iosys/flash_loaded ;
input fclk;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire clk;
wire loading;
wire loading_r;
wire \loader_addr_mem[21] ;
wire \loader_addr_mem[20] ;
wire \loader_addr_mem[19] ;
wire \loader_addr_mem[18] ;
wire \loader_addr_mem[17] ;
wire \loader_addr_mem[16] ;
wire \loader_addr_mem[15] ;
wire \loader_addr_mem[14] ;
wire \loader_addr_mem[13] ;
wire \loader_addr_mem[12] ;
wire \loader_addr_mem[11] ;
wire \loader_addr_mem[10] ;
wire \loader_addr_mem[9] ;
wire \loader_addr_mem[8] ;
wire \loader_addr_mem[7] ;
wire \loader_addr_mem[6] ;
wire \loader_addr_mem[5] ;
wire \loader_addr_mem[4] ;
wire \loader_addr_mem[3] ;
wire \loader_addr_mem[2] ;
wire \loader_addr_mem[1] ;
wire \loader_addr_mem[0] ;
wire loader_write_mem;
wire \loader_write_data_mem[7] ;
wire \loader_write_data_mem[6] ;
wire \loader_write_data_mem[5] ;
wire \loader_write_data_mem[4] ;
wire \loader_write_data_mem[3] ;
wire \loader_write_data_mem[2] ;
wire \loader_write_data_mem[1] ;
wire \loader_write_data_mem[0] ;
wire \loader_do[7] ;
wire \loader_do[6] ;
wire \loader_do[5] ;
wire \loader_do[4] ;
wire \loader_do[3] ;
wire \loader_do[2] ;
wire \loader_do[1] ;
wire \loader_do[0] ;
wire loader_do_valid;
wire \iosys/rom_do_buf[31] ;
wire \iosys/rom_do_buf[30] ;
wire \iosys/rom_do_buf[29] ;
wire \iosys/rom_do_buf[28] ;
wire \iosys/rom_do_buf[27] ;
wire \iosys/rom_do_buf[26] ;
wire \iosys/rom_do_buf[25] ;
wire \iosys/rom_do_buf[24] ;
wire \iosys/rom_do_buf[23] ;
wire \iosys/rom_do_buf[22] ;
wire \iosys/rom_do_buf[21] ;
wire \iosys/rom_do_buf[20] ;
wire \iosys/rom_do_buf[19] ;
wire \iosys/rom_do_buf[18] ;
wire \iosys/rom_do_buf[17] ;
wire \iosys/rom_do_buf[16] ;
wire \iosys/rom_do_buf[15] ;
wire \iosys/rom_do_buf[14] ;
wire \iosys/rom_do_buf[13] ;
wire \iosys/rom_do_buf[12] ;
wire \iosys/rom_do_buf[11] ;
wire \iosys/rom_do_buf[10] ;
wire \iosys/rom_do_buf[9] ;
wire \iosys/rom_do_buf[8] ;
wire \nes/cpu/A[15] ;
wire \nes/cpu/A[14] ;
wire \nes/cpu/A[13] ;
wire \nes/cpu/A[12] ;
wire \nes/cpu/A[11] ;
wire \nes/cpu/A[10] ;
wire \nes/cpu/A[9] ;
wire \nes/cpu/A[8] ;
wire \nes/cpu/A[7] ;
wire \nes/cpu/A[6] ;
wire \nes/cpu/A[5] ;
wire \nes/cpu/A[4] ;
wire \nes/cpu/A[3] ;
wire \nes/cpu/A[2] ;
wire \nes/cpu/A[1] ;
wire \nes/cpu/A[0] ;
wire \nes/cpu/MCycle[2] ;
wire \nes/cpu/MCycle[1] ;
wire \nes/cpu/MCycle[0] ;
wire \nes/cpu/DI[7] ;
wire \nes/cpu/DI[6] ;
wire \nes/cpu/DI[5] ;
wire \nes/cpu/DI[4] ;
wire \nes/cpu/DI[3] ;
wire \nes/cpu/DI[2] ;
wire \nes/cpu/DI[1] ;
wire \nes/cpu/DI[0] ;
wire \nes/cpu/DO[7] ;
wire \nes/cpu/DO[6] ;
wire \nes/cpu/DO[5] ;
wire \nes/cpu/DO[4] ;
wire \nes/cpu/DO[3] ;
wire \nes/cpu/DO[2] ;
wire \nes/cpu/DO[1] ;
wire \nes/cpu/DO[0] ;
wire \sdram/cycle[11] ;
wire \sdram/cycle[10] ;
wire \sdram/cycle[9] ;
wire \sdram/cycle[8] ;
wire \sdram/cycle[7] ;
wire \sdram/cycle[6] ;
wire \sdram/cycle[5] ;
wire \sdram/cycle[4] ;
wire \sdram/cycle[3] ;
wire \sdram/cycle[2] ;
wire \sdram/cycle[1] ;
wire \sdram/cycle[0] ;
wire \nes/prg_allow ;
wire \nes/prg_read ;
wire \loader/ines[4][7] ;
wire \loader/ines[4][6] ;
wire \loader/ines[4][5] ;
wire \loader/ines[4][4] ;
wire \loader/ines[4][3] ;
wire \loader/ines[4][2] ;
wire \loader/ines[4][1] ;
wire \loader/ines[4][0] ;
wire \loader/ines[5][7] ;
wire \loader/ines[5][6] ;
wire \loader/ines[5][5] ;
wire \loader/ines[5][4] ;
wire \loader/ines[5][3] ;
wire \loader/ines[5][2] ;
wire \loader/ines[5][1] ;
wire \loader/ines[5][0] ;
wire \rv_addr_Z[9] ;
wire \rv_addr_Z[8] ;
wire \rv_addr_Z[7] ;
wire \rv_addr_Z[6] ;
wire \rv_addr_Z[5] ;
wire \rv_addr_Z[4] ;
wire \rv_addr_Z[3] ;
wire \rv_addr_Z[2] ;
wire rv_valid_Z;
wire \flash_wstrb[3] ;
wire \flash_wstrb[2] ;
wire \flash_wstrb[1] ;
wire \flash_wstrb[0] ;
wire \rv_dout_Z[15] ;
wire \rv_dout_Z[14] ;
wire \rv_dout_Z[13] ;
wire \rv_dout_Z[12] ;
wire \rv_dout_Z[11] ;
wire \rv_dout_Z[10] ;
wire \rv_dout_Z[9] ;
wire \rv_dout_Z[8] ;
wire \rv_dout_Z[7] ;
wire \rv_dout_Z[6] ;
wire \rv_dout_Z[5] ;
wire \rv_dout_Z[4] ;
wire \rv_dout_Z[3] ;
wire \rv_dout_Z[2] ;
wire \rv_dout_Z[1] ;
wire \rv_dout_Z[0] ;
wire \rv_wdata_Z[15] ;
wire \rv_wdata_Z[14] ;
wire \rv_wdata_Z[13] ;
wire \rv_wdata_Z[12] ;
wire \rv_wdata_Z[11] ;
wire \rv_wdata_Z[10] ;
wire \rv_wdata_Z[9] ;
wire \rv_wdata_Z[8] ;
wire \rv_wdata_Z[7] ;
wire \rv_wdata_Z[6] ;
wire \rv_wdata_Z[5] ;
wire \rv_wdata_Z[4] ;
wire \rv_wdata_Z[3] ;
wire \rv_wdata_Z[2] ;
wire \rv_wdata_Z[1] ;
wire \rv_wdata_Z[0] ;
wire rv_req;
wire rv_req_ack_Z;
wire \rv_ds[1] ;
wire \rv_ds[0] ;
wire rv_word;
wire O_sdram_cs_n;
wire O_sdram_ras_n;
wire O_sdram_cas_n;
wire O_sdram_wen_n;
wire \O_sdram_addr[10] ;
wire \O_sdram_addr[9] ;
wire \O_sdram_addr[8] ;
wire \O_sdram_addr[7] ;
wire \O_sdram_addr[6] ;
wire \O_sdram_addr[5] ;
wire \O_sdram_addr[4] ;
wire \O_sdram_addr[3] ;
wire \O_sdram_addr[2] ;
wire \O_sdram_addr[1] ;
wire \O_sdram_addr[0] ;
wire \IO_sdram_dq[31] ;
wire \IO_sdram_dq[30] ;
wire \IO_sdram_dq[29] ;
wire \IO_sdram_dq[28] ;
wire \IO_sdram_dq[27] ;
wire \IO_sdram_dq[26] ;
wire \IO_sdram_dq[25] ;
wire \IO_sdram_dq[24] ;
wire \IO_sdram_dq[23] ;
wire \IO_sdram_dq[22] ;
wire \IO_sdram_dq[21] ;
wire \IO_sdram_dq[20] ;
wire \IO_sdram_dq[19] ;
wire \IO_sdram_dq[18] ;
wire \IO_sdram_dq[17] ;
wire \IO_sdram_dq[16] ;
wire \IO_sdram_dq[15] ;
wire \IO_sdram_dq[14] ;
wire \IO_sdram_dq[13] ;
wire \IO_sdram_dq[12] ;
wire \IO_sdram_dq[11] ;
wire \IO_sdram_dq[10] ;
wire \IO_sdram_dq[9] ;
wire \IO_sdram_dq[8] ;
wire \IO_sdram_dq[7] ;
wire \IO_sdram_dq[6] ;
wire \IO_sdram_dq[5] ;
wire \IO_sdram_dq[4] ;
wire \IO_sdram_dq[3] ;
wire \IO_sdram_dq[2] ;
wire \IO_sdram_dq[1] ;
wire \IO_sdram_dq[0] ;
wire \O_sdram_ba[1] ;
wire \O_sdram_ba[0] ;
wire \O_sdram_dqm[3] ;
wire \O_sdram_dqm[2] ;
wire \O_sdram_dqm[1] ;
wire \O_sdram_dqm[0] ;
wire \iosys/flash_loaded ;
wire fclk;
wire tms_pad_i;
wire tck_pad_i;
wire tdi_pad_i;
wire tdo_pad_o;
wire tms_i_c;
wire tck_i_c;
wire tdi_i_c;
wire tdo_o_c;
wire [9:0] control0;
wire gao_jtag_tck;
wire gao_jtag_reset;
wire run_test_idle_er1;
wire run_test_idle_er2;
wire shift_dr_capture_dr;
wire update_dr;
wire pause_dr;
wire enable_er1;
wire enable_er2;
wire gao_jtag_tdi;
wire tdo_er1;

IBUF tms_ibuf (
    .I(tms_pad_i),
    .O(tms_i_c)
);

IBUF tck_ibuf (
    .I(tck_pad_i),
    .O(tck_i_c)
);

IBUF tdi_ibuf (
    .I(tdi_pad_i),
    .O(tdi_i_c)
);

OBUF tdo_obuf (
    .I(tdo_o_c),
    .O(tdo_pad_o)
);

GW_JTAG  u_gw_jtag(
    .tms_pad_i(tms_i_c),
    .tck_pad_i(tck_i_c),
    .tdi_pad_i(tdi_i_c),
    .tdo_pad_o(tdo_o_c),
    .tck_o(gao_jtag_tck),
    .test_logic_reset_o(gao_jtag_reset),
    .run_test_idle_er1_o(run_test_idle_er1),
    .run_test_idle_er2_o(run_test_idle_er2),
    .shift_dr_capture_dr_o(shift_dr_capture_dr),
    .update_dr_o(update_dr),
    .pause_dr_o(pause_dr),
    .enable_er1_o(enable_er1),
    .enable_er2_o(enable_er2),
    .tdi_o(gao_jtag_tdi),
    .tdo_er1_i(tdo_er1),
    .tdo_er2_i(1'b0)
);

gw_con_top  u_icon_top(
    .tck_i(gao_jtag_tck),
    .tdi_i(gao_jtag_tdi),
    .tdo_o(tdo_er1),
    .rst_i(gao_jtag_reset),
    .control0(control0[9:0]),
    .enable_i(enable_er1),
    .shift_dr_capture_dr_i(shift_dr_capture_dr),
    .update_dr_i(update_dr)
);

ao_top_0  u_la0_top(
    .control(control0[9:0]),
    .trig0_i(loader_do_valid),
    .trig1_i({loading,loading_r}),
    .trig2_i(rv_valid_Z),
    .trig3_i(\iosys/flash_loaded ),
    .data_i({clk,loading,loading_r,\loader_addr_mem[21] ,\loader_addr_mem[20] ,\loader_addr_mem[19] ,\loader_addr_mem[18] ,\loader_addr_mem[17] ,\loader_addr_mem[16] ,\loader_addr_mem[15] ,\loader_addr_mem[14] ,\loader_addr_mem[13] ,\loader_addr_mem[12] ,\loader_addr_mem[11] ,\loader_addr_mem[10] ,\loader_addr_mem[9] ,\loader_addr_mem[8] ,\loader_addr_mem[7] ,\loader_addr_mem[6] ,\loader_addr_mem[5] ,\loader_addr_mem[4] ,\loader_addr_mem[3] ,\loader_addr_mem[2] ,\loader_addr_mem[1] ,\loader_addr_mem[0] ,loader_write_mem,\loader_write_data_mem[7] ,\loader_write_data_mem[6] ,\loader_write_data_mem[5] ,\loader_write_data_mem[4] ,\loader_write_data_mem[3] ,\loader_write_data_mem[2] ,\loader_write_data_mem[1] ,\loader_write_data_mem[0] ,\loader_do[7] ,\loader_do[6] ,\loader_do[5] ,\loader_do[4] ,\loader_do[3] ,\loader_do[2] ,\loader_do[1] ,\loader_do[0] ,loader_do_valid,\iosys/rom_do_buf[31] ,\iosys/rom_do_buf[30] ,\iosys/rom_do_buf[29] ,\iosys/rom_do_buf[28] ,\iosys/rom_do_buf[27] ,\iosys/rom_do_buf[26] ,\iosys/rom_do_buf[25] ,\iosys/rom_do_buf[24] ,\iosys/rom_do_buf[23] ,\iosys/rom_do_buf[22] ,\iosys/rom_do_buf[21] ,\iosys/rom_do_buf[20] ,\iosys/rom_do_buf[19] ,\iosys/rom_do_buf[18] ,\iosys/rom_do_buf[17] ,\iosys/rom_do_buf[16] ,\iosys/rom_do_buf[15] ,\iosys/rom_do_buf[14] ,\iosys/rom_do_buf[13] ,\iosys/rom_do_buf[12] ,\iosys/rom_do_buf[11] ,\iosys/rom_do_buf[10] ,\iosys/rom_do_buf[9] ,\iosys/rom_do_buf[8] ,\nes/cpu/A[15] ,\nes/cpu/A[14] ,\nes/cpu/A[13] ,\nes/cpu/A[12] ,\nes/cpu/A[11] ,\nes/cpu/A[10] ,\nes/cpu/A[9] ,\nes/cpu/A[8] ,\nes/cpu/A[7] ,\nes/cpu/A[6] ,\nes/cpu/A[5] ,\nes/cpu/A[4] ,\nes/cpu/A[3] ,\nes/cpu/A[2] ,\nes/cpu/A[1] ,\nes/cpu/A[0] ,\nes/cpu/MCycle[2] ,\nes/cpu/MCycle[1] ,\nes/cpu/MCycle[0] ,\nes/cpu/DI[7] ,\nes/cpu/DI[6] ,\nes/cpu/DI[5] ,\nes/cpu/DI[4] ,\nes/cpu/DI[3] ,\nes/cpu/DI[2] ,\nes/cpu/DI[1] ,\nes/cpu/DI[0] ,\nes/cpu/DO[7] ,\nes/cpu/DO[6] ,\nes/cpu/DO[5] ,\nes/cpu/DO[4] ,\nes/cpu/DO[3] ,\nes/cpu/DO[2] ,\nes/cpu/DO[1] ,\nes/cpu/DO[0] ,\sdram/cycle[11] ,\sdram/cycle[10] ,\sdram/cycle[9] ,\sdram/cycle[8] ,\sdram/cycle[7] ,\sdram/cycle[6] ,\sdram/cycle[5] ,\sdram/cycle[4] ,\sdram/cycle[3] ,\sdram/cycle[2] ,\sdram/cycle[1] ,\sdram/cycle[0] ,\nes/prg_allow ,\nes/prg_read ,\loader/ines[4][7] ,\loader/ines[4][6] ,\loader/ines[4][5] ,\loader/ines[4][4] ,\loader/ines[4][3] ,\loader/ines[4][2] ,\loader/ines[4][1] ,\loader/ines[4][0] ,\loader/ines[5][7] ,\loader/ines[5][6] ,\loader/ines[5][5] ,\loader/ines[5][4] ,\loader/ines[5][3] ,\loader/ines[5][2] ,\loader/ines[5][1] ,\loader/ines[5][0] ,\rv_addr_Z[9] ,\rv_addr_Z[8] ,\rv_addr_Z[7] ,\rv_addr_Z[6] ,\rv_addr_Z[5] ,\rv_addr_Z[4] ,\rv_addr_Z[3] ,\rv_addr_Z[2] ,rv_valid_Z,\flash_wstrb[3] ,\flash_wstrb[2] ,\flash_wstrb[1] ,\flash_wstrb[0] ,\rv_dout_Z[15] ,\rv_dout_Z[14] ,\rv_dout_Z[13] ,\rv_dout_Z[12] ,\rv_dout_Z[11] ,\rv_dout_Z[10] ,\rv_dout_Z[9] ,\rv_dout_Z[8] ,\rv_dout_Z[7] ,\rv_dout_Z[6] ,\rv_dout_Z[5] ,\rv_dout_Z[4] ,\rv_dout_Z[3] ,\rv_dout_Z[2] ,\rv_dout_Z[1] ,\rv_dout_Z[0] ,\rv_wdata_Z[15] ,\rv_wdata_Z[14] ,\rv_wdata_Z[13] ,\rv_wdata_Z[12] ,\rv_wdata_Z[11] ,\rv_wdata_Z[10] ,\rv_wdata_Z[9] ,\rv_wdata_Z[8] ,\rv_wdata_Z[7] ,\rv_wdata_Z[6] ,\rv_wdata_Z[5] ,\rv_wdata_Z[4] ,\rv_wdata_Z[3] ,\rv_wdata_Z[2] ,\rv_wdata_Z[1] ,\rv_wdata_Z[0] ,rv_req,rv_req_ack_Z,\rv_ds[1] ,\rv_ds[0] ,rv_word,O_sdram_cs_n,O_sdram_ras_n,O_sdram_cas_n,O_sdram_wen_n,\O_sdram_addr[10] ,\O_sdram_addr[9] ,\O_sdram_addr[8] ,\O_sdram_addr[7] ,\O_sdram_addr[6] ,\O_sdram_addr[5] ,\O_sdram_addr[4] ,\O_sdram_addr[3] ,\O_sdram_addr[2] ,\O_sdram_addr[1] ,\O_sdram_addr[0] ,\IO_sdram_dq[31] ,\IO_sdram_dq[30] ,\IO_sdram_dq[29] ,\IO_sdram_dq[28] ,\IO_sdram_dq[27] ,\IO_sdram_dq[26] ,\IO_sdram_dq[25] ,\IO_sdram_dq[24] ,\IO_sdram_dq[23] ,\IO_sdram_dq[22] ,\IO_sdram_dq[21] ,\IO_sdram_dq[20] ,\IO_sdram_dq[19] ,\IO_sdram_dq[18] ,\IO_sdram_dq[17] ,\IO_sdram_dq[16] ,\IO_sdram_dq[15] ,\IO_sdram_dq[14] ,\IO_sdram_dq[13] ,\IO_sdram_dq[12] ,\IO_sdram_dq[11] ,\IO_sdram_dq[10] ,\IO_sdram_dq[9] ,\IO_sdram_dq[8] ,\IO_sdram_dq[7] ,\IO_sdram_dq[6] ,\IO_sdram_dq[5] ,\IO_sdram_dq[4] ,\IO_sdram_dq[3] ,\IO_sdram_dq[2] ,\IO_sdram_dq[1] ,\IO_sdram_dq[0] ,\O_sdram_ba[1] ,\O_sdram_ba[0] ,\O_sdram_dqm[3] ,\O_sdram_dqm[2] ,\O_sdram_dqm[1] ,\O_sdram_dqm[0] }),
    .clk_i(fclk)
);

endmodule
