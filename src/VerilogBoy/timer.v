/*
Timer del Game Boy DMG-01, módulo basado en mi emulador de software del sistema
*/

`timescale 1ns / 1ps
`default_nettype wire

module timer(
    input  wire clk,           // Reloj base (T-Cycles)
    input  wire [1:0] ct,      // Fase del M-Cycle
    input  wire rst,           // Reset del sistema
    input  wire [15:0] a,      // Bus de direcciones
    output reg  [7:0] dout,    // Bus de datos de salida
    input  wire [7:0] din,     // Bus de datos de entrada
    input  wire rd,            // Señal de lectura
    input  wire wr,            // Señal de escritura
    output reg  int_tim_req,   // Petición de interrupción
    input  wire int_tim_ack    // Reconocimiento de interrupción de la CPU
);

    // -- Registros --

    // Actúa como el System Counter de 16 bits, incrementando cada T-Cycle
    // Solo los 8 bits superiores del registro DIV están expuestos a memoria
    // DIV incrementa en 1 cada T-Cycle
    reg [15:0] div;

    reg [7:0]  tima; // Lanza interrupción de TIMER al desbordarse
    reg [7:0]  tma; // Valor al que regresa TIMA tras overflow
    reg [7:0]  tac; // Controla el TIMER
    // Bit 2 de TAC es el Timer Enable, los bits 0 y 1 determinan el bit de DIV a mirar

    // Estado para el retraso de hardware
    reg        tima_overflowing;
    reg [2:0]  overflow_delay; 
    
    // Registro para detectar el flanco de bajada
    reg        prev_signal;

    // -- Lógica combinacional --
    
    // getTimeMultiplexerSignal
    reg selected_bit;

    always @(*) begin
        case(tac[1:0])
            2'b00: selected_bit = div[9]; // 4096 Hz
            2'b01: selected_bit = div[3]; // 262144 Hz
            2'b10: selected_bit = div[5]; // 65536 Hz
            2'b11: selected_bit = div[7]; // 16384 Hz
            default: selected_bit = div[9];
        endcase
    end

    // current_signal = Timer Enable (Bit 2) AND el bit del multiplexor
    wire current_signal = tac[2] & selected_bit;

   
    // bus_read();
    // En cuanto cambie el bus de direcciones
    always @(*) begin
        case(a)
            16'hFF04: dout = div[15:8]; // Solo los 8 bits superiores expuestos
            16'hFF05: dout = tima;
            16'hFF06: dout = tma;
            16'hFF07: dout = tac;
            default:  dout = 8'hFF;     // Open bus behavior
        endcase
    end

    // -- Lógica secuencial --
    // Todo lo que está aquí adentro sucede simultáneamente en cada T-Cycle.
    // timer_tick() es equivalente a always @(posedge clk)
    always @(posedge clk) begin
        if (rst) begin
            // Reset de todo el sistema
            div <= 16'h0000; // Originalmente tenías AC00, puedes ponerlo aquí si quieres
            tima <= 8'h00;
            tma <= 8'h00;
            tac <= 8'h00;
            tima_overflowing <= 1'b0;
            overflow_delay <= 3'd0;
            int_tim_req <= 1'b0;
            prev_signal <= 1'b0;
        end else begin
            
            // Avanzar el System Counter (Siempre pasa)
            div <= div + 1'b1;

            // Actualizar la memoria del Flanco de Bajada
            prev_signal <= current_signal;

            // Manejo de la confirmación de interrupción
            if (int_tim_ack) begin
                int_tim_req <= 1'b0;
            end

            // Manejo del retraso de Overflow (4 T-Cycles)
            if (tima_overflowing) begin
                if (overflow_delay == 3'd3) begin
                    tima <= tma;                   // Regresa a TMA
                    int_tim_req <= 1'b1;           // Dispara interrupción
                    tima_overflowing <= 1'b0;      // Termina el estado
                    overflow_delay <= 3'd0;
                end else begin
                    overflow_delay <= overflow_delay + 1'b1;
                end
            end

            // Detección de Flanco de Bajada y Overflow
            // Si el ciclo pasado era 1 y en este momento es 0
            if (prev_signal == 1'b1 && current_signal == 1'b0) begin
                if (tima == 8'hFF) begin
                    tima <= 8'h00;
                    tima_overflowing <= 1'b1;
                    overflow_delay <= 3'd0;
                end else begin
                    tima <= tima + 1'b1;
                end
            end

            // timer_write ()
            // Las ponemos al final del bloque para que "sobrescriban" cualquier 
            // incremento automático de este mismo ciclo.
            if (wr) begin
                case(a)
                    16'hFF04: begin
                        div <= 16'h0000;
                    end
                    16'hFF05: begin
                        // Si la CPU escribe en TIMA mientras está desbordándose (Obscure Behavior)
                        if (tima_overflowing) begin
                            tima_overflowing <= 1'b0;
                            overflow_delay <= 3'd0;
                        end
                        tima <= din;
                    end
                    16'hFF06: begin
                        tma <= din;
                    end
                    16'hFF07: begin
                        tac <= din;
                    end
                endcase
            end

        end
    end

endmodule