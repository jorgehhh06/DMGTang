`timescale 1ns / 1ps
`default_nettype wire
module alu(
    input [7:0] alu_b,
    input [7:0] alu_a,
    input [2:0] alu_bit_index,
    output reg [7:0] alu_result,
    input [3:0] alu_flags_in,
    output reg [3:0] alu_flags_out,
    input [4:0] alu_op,
    input is_fast_rot // Flag para detectar rotaciones rápidas
    );

    // -- Códigos de operaciones (bits de control) --
    localparam OP_ADD = 5'b00000; // ADD
    localparam OP_ADC = 5'b00001; // ADD con Carry
    localparam OP_SUB = 5'b00010; // Substract
    localparam OP_SBC = 5'b00011; // Substract con Carry
    localparam OP_AND = 5'b00100; // AND
    localparam OP_XOR = 5'b00101; // XOR
    localparam OP_OR  = 5'b00110; // OR
    localparam OP_CP  = 5'b00111; // Compare
    localparam OP_RLC = 5'b01000; // Rotate Left Circular
    localparam OP_RRC = 5'b01001; // Rotate Right Circular
    localparam OP_RL  = 5'b01010; // Rotate Left
    localparam OP_RR  = 5'b01011; // Rotate Right
    localparam OP_SLA = 5'b01100; // Shift Left Arithmetic
    localparam OP_SRA = 5'b01101; // Shif Right Arithmetic
    localparam OP_SWAP= 5'b01110; // Swap Nibbles
    localparam OP_SRL = 5'b01111; // Shift Right Logical
    localparam OP_LF  = 5'b10000; // Load Flags
    localparam OP_SF  = 5'b10010; // Store / Set Flags
    localparam OP_DAA = 5'b10100; // Decimal Adjust Acumulator
    localparam OP_CPL = 5'b10101; // Complemento a 1
    localparam OP_SCF = 5'b10110; // Set Carry Flag
    localparam OP_CCF = 5'b10111;  // Complement Carry Flag
    localparam OP_BIT = 5'b11101; // Checa el bit n a través de la Zero Flag
    localparam OP_RES = 5'b11110; // Apaga el bit n
    localparam OP_SET = 5'b11111; // Enciende el bit n

    // -- Códigos de cada flag en el registro F --
    localparam F_Z = 2'd3; // Zero Flag
    localparam F_N = 2'd2; // Negative Flag
    localparam F_H = 2'd1; // Half-Carry Flag
    localparam F_C = 2'd0; // Carry Flag

    // 9 bits para el DAA
    reg [8:0] intermediate_result1, intermediate_result2; // Auxiliares para operaciones
    // 5 bits para manejar el carry y half-carry
    reg [4:0] result_low; // Nibble bajo del resultado
    reg [4:0] result_high; // Nibble alto del resultado
    wire [2:0] bit_index; // Apunta a un bit de un byte
    reg carry; // Buffer temporal antes de hacer operaciones aritméticas
 
    assign bit_index = alu_bit_index;

    // -- Registros auxiliares para DAA --
    reg [7:0] u_daa;
    reg fc;

    // -- Lógica combinacional --
    always@(*) begin
        // Todo se pone en 0
        u_daa = 8'b0;
        fc = 1'b0;
        alu_flags_out = 4'h0;
        carry = 1'b0;
        result_low = 5'd0;
        result_high = 5'd0;
        intermediate_result1 = 9'd0;
        intermediate_result2 = 9'd0;

        // -- Multiplexor de decodificación de operaciones --
        case (alu_op)
            // ADD y ADD con Carry
            OP_ADD, OP_ADC: begin
                carry = (alu_op == OP_ADC) ? alu_flags_in[F_C] : 1'b0; // Lo que se va a sumar si es ADD o ADC
                // Se opera el nibble bajo
                // Se alinean físicamente el tamaño de los buses antes de sumarlos
                // Concatenación con zero-padding
                result_low = {1'b0, alu_a[3:0]} + {1'b0, alu_b[3:0]} + {4'b0, carry};
                // Se aprovecha el registro de 5 bits para poner el Half-Carry
                alu_flags_out[F_H] = result_low[4];

                // Se opera en nibble alto de la suma
                result_high = {1'b0, alu_a[7:4]} + {1'b0, alu_b[7:4]} + {4'b0, result_low[4]};
                alu_flags_out[F_C] = result_high[4]; // El bit 4 del nibble superior es la Carry Flag
                // Se concatenan los resultados quitando la Carry y Half-Carry flags
                alu_result = {result_high[3:0], result_low[3:0]};
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0; // Zero Flag
                alu_flags_out[F_N] = 1'b0; // Negative flag se apaga
            end
            OP_SUB, OP_SBC, OP_CP: begin
                alu_flags_out[F_N] = 1'b1; // Negative flag se enciende
                carry = (alu_op == OP_SBC) ? alu_flags_in[F_C] : 1'b0; // Lo que se va a restar so es SBC

                // Se complementa a 2 el valor a restar + carry
                result_low = {1'b0, alu_a[3:0]} + ~({1'b0, alu_b[3:0]} + {4'b0, carry}) + 5'b1;
                // El bit 4 del nibble bajo es la Half-Carry Flag
                alu_flags_out[F_H] = result_low[4];
                // Se resta el nibble alto
                result_high = {1'b0, alu_a[7:4]} + ~({1'b0, alu_b[7:4]}) + {4'b0, ~result_low[4]};
                // Bit 4 del nibble alto es la carry flag
                alu_flags_out[F_C] = result_high[4];
                // CP no puede modificar el registro A
                alu_result = (alu_op == OP_CP) ? (alu_a[7:0]) : {result_high[3:0], result_low[3:0]};
                alu_flags_out[F_Z] = ({result_high[3:0], result_low[3:0]} == 8'd0) ? 1'b1 : 1'b0;
            end
            OP_AND: begin
                // Operador a nivel de bits &
                alu_result = alu_a & alu_b;
                // Actualización de flags según la documentación
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
                alu_flags_out[F_N] = 1'b0;
                alu_flags_out[F_H] = 1'b1;
                alu_flags_out[F_C] = 1'b0;
            end
            OP_OR: begin
                // Operador a nivel de bits |
                alu_result = alu_a | alu_b;
                // Actualización de flags según la documentación
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
                alu_flags_out[F_N] = 1'b0;
                alu_flags_out[F_H] = 1'b0;
                alu_flags_out[F_C] = 1'b0;
            end
            OP_XOR: begin
                // Operador a nivel de bits ^
                alu_result = alu_a ^ alu_b;
                // Actualización de flags según la documentación
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
                alu_flags_out[F_N] = 1'b0;
                alu_flags_out[F_H] = 1'b0;
                alu_flags_out[F_C] = 1'b0;
            end
            OP_DAA: begin
                // Primera condición (Nibble bajo)
                if (alu_flags_in[F_H] || (~alu_flags_in[F_N] && alu_a[3:0] > 4'd9)) begin
                    u_daa = 8'd6;
                end
                
                // Segunda condición (Nibble alto / Valor completo)
                if (alu_flags_in[F_C] || (~alu_flags_in[F_N] && alu_a > 8'h99)) begin
                    u_daa = u_daa | 8'h60; // Verilog clásico: A = A | B
                    fc = 1'b1;
                end
                
                // Operación aritmética usando el bus de salida alu_result
                if (alu_flags_in[F_N] == 1'b1) begin
                    alu_result = alu_a - u_daa; // Si la última instrucción fue una resta
                end else begin
                    alu_result = alu_a + u_daa; // Si la última instrucción fue una suma
                end
                
                // Actualización de flags
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
                alu_flags_out[F_N] = alu_flags_in[F_N];
                alu_flags_out[F_H] = 1'b0;
                alu_flags_out[F_C] = fc;
            end
            OP_CPL: begin
                // Operador a nivel de bits ~
                alu_result = ~alu_a;
                // Actualización de flags según la documentación
                alu_flags_out[F_Z] = alu_flags_in[F_Z];
                alu_flags_out[F_N] = 1'b1;
                alu_flags_out[F_H] = 1'b1;
                alu_flags_out[F_C] = alu_flags_in[F_C];
            end
            OP_CCF: begin
                alu_result = alu_a;
                // Invertir la flag de Carry
                alu_flags_out[F_C] = ~alu_flags_in[F_C];
                // Resto de las flags
                alu_flags_out[F_Z] = alu_flags_in[F_Z];
                alu_flags_out[F_N] = 1'b0;
                alu_flags_out[F_H] = 1'b0;
            end
            OP_SCF: begin
                alu_result = alu_a;
                // Esta operación solo actualiza flags, pone la Carry flag en 1
                alu_flags_out[F_Z] = alu_flags_in[F_Z];
                alu_flags_out[F_N] = 1'b0;
                alu_flags_out[F_H] = 1'b0;
                alu_flags_out[F_C] = 1'b1;
            end
            OP_RLC: begin
                alu_result[0] = alu_a[7]; // El bit 7 pasa a ser el bit 0
                alu_result[7:1] = alu_a[6:0]; // Se hace el resto del shift
                // Actualización de flags
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1: 1'b0; 
                alu_flags_out[F_N] = 1'b0;
                alu_flags_out[F_H] = 1'b0;
                alu_flags_out[F_C] = alu_a[7]; // El bit desbordado se va al Carry
            end
            OP_RL: begin
                alu_result[0] = alu_flags_in[F_C]; // El Carry se convierte en el bit 0
                alu_result[7:1] = alu_a[6:0]; // El resto de la rotación
                // Actualización de flags
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1: 1'b0;
                alu_flags_out[F_N] = 1'b0;
                alu_flags_out[F_H] = 1'b0;
                alu_flags_out[F_C] = alu_a[7]; // El término desbordado de la rotación es el carry
            end
            OP_RRC: begin
                alu_result[7] = alu_a[0]; // Bit 0 se convierte en el bit 7
                alu_result[6:0] = alu_a[7:1]; // El resto de la rotación
                // Flags según la documentación
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1: 1'b0;
                alu_flags_out[F_N] = 1'b0;
                alu_flags_out[F_H] = 1'b0;
                alu_flags_out[F_C] = alu_a[0]; // El bit desbordado se va al Carry
                
            end
            OP_RR: begin
                alu_result[7] = alu_flags_in[F_C]; // El carry se vuelve el bit 7
                alu_result[6:0] = alu_a[7:1]; // Resto de la rotación
                // Actualización de flags
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1: 1'b0;
                alu_flags_out[F_N] = 1'b0;
                alu_flags_out[F_H] = 1'b0;
                alu_flags_out[F_C] = alu_a[0];
            end
            OP_SLA: begin
                alu_result[7:1] = alu_a[6:0]; // Se hace la rotación
                alu_result[0] = 1'b0; // El bit 0 se borra
                // Actualización de flags
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
                alu_flags_out[F_N] = 1'b0;
                alu_flags_out[F_H] = 1'b0;
                alu_flags_out[F_C] = alu_a[7]; // Bit 7 es el carry
            end
            OP_SRA: begin
                alu_result[7] = alu_a[7]; // Se conserva el signo
                alu_result[6:0] = alu_a[7:1]; // El resto de la rotación
                // Flags
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
                alu_flags_out[F_N] = 1'b0;
                alu_flags_out[F_H] = 1'b0;
                alu_flags_out[F_C] = alu_a[0]; // Bit 0 es el Carry
            end
            OP_SRL: begin
                alu_result[7] = 1'b0; // Se borra el bit 7
                alu_result[6:0] = alu_a[7:1]; // Se hace la rotación
                // Flags
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'b1 : 1'b0;
                alu_flags_out[F_N] = 1'b0;
                alu_flags_out[F_H] = 1'b0;
                alu_flags_out[F_C] = alu_a[0]; // Bit 0 es el Carry
            end
            OP_BIT: begin
                alu_result = alu_a;
                // Actualización de flags
                alu_flags_out[F_Z] = ~alu_a[bit_index];
                alu_flags_out[F_N] = 1'b0;
                alu_flags_out[F_H] = 1'b1;
                alu_flags_out[F_C] = alu_flags_in[F_C];
            end
            OP_SET: begin
                alu_result = alu_a;
                alu_result[bit_index] = 1'b1; // Se enciende el bit indicado
                // Flags sin modificar
                alu_flags_out = alu_flags_in;
            end
            OP_RES: begin
                alu_result = alu_a;
                alu_result[bit_index] = 1'b0; // Se apaga el bit indicado
                // Flags sin modificar
                alu_flags_out = alu_flags_in;
            end
            OP_SWAP: begin
                alu_result = {alu_a[3:0], alu_a[7:4]}; // Se concatena con los nibbles intercambiados
                // Flags
                alu_flags_out[F_Z] = (alu_result == 8'd0) ? 1'd1: 1'd0;
                alu_flags_out[F_N] = 1'b0;
                alu_flags_out[F_H] = 1'b0;
                alu_flags_out[F_C] = 1'b0;
            end
            OP_SF: begin
                alu_flags_out = alu_b[7:4];
                alu_result = alu_a;
            end
            OP_LF: begin
                alu_result = {alu_flags_in, 4'b0}; // El nibble inferior del registro F siempre es 0
                alu_flags_out = alu_flags_in;
            end
            default: begin
                alu_result = alu_b;
                alu_flags_out = alu_flags_in;
            end
        endcase
    end

endmodule