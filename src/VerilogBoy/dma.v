`timescale 1ns / 1ps
`default_nettype wire

module dma(
    input  wire        clk, // T-Cycles
    input  wire        rst, // Reset
    output reg         dma_rd, // DMA Read
    output reg         dma_wr, // DMA Write
    output reg  [15:0] dma_a, // Bus de direcciones
    input  wire [7:0]  dma_din, // Bus de datos entrada
    output reg  [7:0]  dma_dout, // Bus de datos salida
    input  wire        mmio_wr, // Memory Mapped IO write
    input  wire [7:0]  mmio_din, // Memory Mapped IO data in
    output wire [7:0]  mmio_dout, // Mamory Mapped IO data out
    output wire        dma_occupy_extbus, // Se pone en 1 si el origen de datos es ROM o RAM Externa
    output wire        dma_occupy_vidbus, // Se pone en 1 si los datos son de VRAM
    output wire        dma_occupy_oambus // Se pone en 1 si los datos son de OAM Ram
);

    reg        active;
    reg [7:0]  current_byte;
    reg [7:0]  value;
    reg [3:0]  start_delay;
    reg [1:0]  tick_count;

    // El registro MMIO 0xFF46 siempre devuelve el último valor escrito
    assign mmio_dout = value;

    // Lógica para bloquear los buses a la CPU
    assign dma_occupy_extbus = active & ((value <= 8'h7f) || (value >= 8'ha0));
    assign dma_occupy_vidbus = active & ((value >= 8'h80) && (value <= 8'h9f));
    assign dma_occupy_oambus = active;

    always @(posedge clk) begin
        if (rst) begin
            active       <= 1'b0;
            current_byte <= 8'h00;
            value        <= 8'h00;
            start_delay  <= 4'h0;
            tick_count   <= 2'b00;
            dma_rd       <= 1'b0;
            dma_wr       <= 1'b0;
        end else begin
            
            // dma_init
            if (mmio_wr) begin
                active       <= 1'b1;
                current_byte <= 8'h00;
                value        <= mmio_din;
                start_delay  <= 4'd8;  // 8 T-Cycles de delay de hardware
                tick_count   <= 2'b00;
                dma_rd       <= 1'b0;
                dma_wr       <= 1'b0;
            end 
            else if (active) begin
                
                if (start_delay > 0) begin
                    start_delay <= start_delay - 1'b1;
                end 
                else begin
                    // La danza CORE de 4 T-Cycles ajustada para FPGAs
                    case (tick_count)
                        2'b00: begin // Tick 0: Poner dirección de origen
                            dma_a  <= {value, current_byte}; 
                            dma_rd <= 1'b1;
                        end
                        
                        2'b01: begin // Tick 1: Esperar la latencia de la Block RAM
                            dma_rd <= 1'b0; 
                            // No hacemos NADA. Dejamos que la RAM escupa el dato.
                        end
                        
                        2'b10: begin // Tick 2: Atrapar el dato y pedir escritura a la OAM
                            dma_dout <= dma_din; // ¡Ahora sí el dato es válido!
                            dma_a    <= 16'hFE00 + {8'h00, current_byte};
                            dma_wr   <= 1'b1;
                        end
                        
                        2'b11: begin // Tick 3: Apagar escritura y evaluar fin
                            dma_wr <= 1'b0;
                            
                            if (current_byte == 8'h9F) begin
                                active <= 1'b0; // Ya copiamos los 160 bytes
                            end else begin
                                current_byte <= current_byte + 1'b1;
                            end
                        end
                    endcase

                    // Sumar tick_count (Mod 4 ya es natural al ser un reg de 2 bits)
                    tick_count <= tick_count + 1'b1;
                end
            end
        end
    end

endmodule