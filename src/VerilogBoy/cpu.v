`timescale 1ns / 1ps
`default_nettype wire

module cpu(
    input clk, // Reloj maestro del sistema
    input rst, // Reset asíncrono
    output reg phi, // Reloj de fase tradicional del sistema
    output wire [1:0] ct, // Fase del ciclo de reloj interno (Dividir M-Cycles en T-Cycles)
    output reg [15:0] a, // Direcciones de memoria
    output reg [7:0] dout, // Data Out
    input [7:0] din, // Data In
    output reg rd, // Read
    output reg wr, // Write
    input [4:0] int_en, // Interrupt Enabler
    input [4:0] int_flags_in, // Flags de entrada
    output wire [4:0] int_flags_out, // Flags de salida
    input [7:0] key_in, // Entrada de los botones
    output reg done, // Bandera de estado que dice si la CPU entró en stop, halt o fault
    output wire fault // Señal de fallo
    );

    // -- Estado y control de ciclo --
    reg  [7:0]  opcode; // Instruction Register
    reg  [7:0]  cb; // Prefijo CB
    wire [2:0]  m_cycle; // Ciclo de máquina actual
    reg  [2:0]  m_cycle_early; // Ciclo de máquina adelantado (pipeline)

    // -- Comandos de la ALU --
    wire [1:0]  alu_src_a; // Multiplexor para saber de dónde sale el operando A de la ALU
    wire [2:0]  alu_src_b; // Multiplexor para saber de dónde sale el operando B de la ALU
    wire        alu_src_xchg; // Si es 1 intercambia los cables A y B al entrar a la ALU
    wire [1:0]  alu_op_prefix; // Prefijo del tipo de operación
    wire [1:0]  alu_op_src; // Subcódigo de la operación a ejecutar
    wire [1:0]  alu_dst; // Multiplexor para saber a dónde mandar el dato de la ALU

    // -- Control del PC y buses --
    wire [1:0]  pc_src; // Origen del nuevo valor del PC
    wire        pc_we; // Write Enable
    wire [2:0]  rf_wr_sel; // Selecciona el registro de 8 bits a escribir
    wire [2:0]  rf_rd_sel; // Selecciona el registro de 8 bits a leer
    wire [1:0]  rf_rdw_sel; // Selecciona el registro doble a escribir
    wire [1:0]  bus_op; // Operación del bus (00 = Idle, 01 = Fetch, 10 = Write, 11 = Read)
    wire [1:0]  db_src; // Origen de los datos que van al bus de datos
    wire [1:0]  ab_src; // Origen de la dirección que va al bus de direcciones
    wire [1:0]  ct_op; // Control del contador de ciclos temporales

    // -- Flags, energía e interrupciones --
    wire        flags_we; // Write Enable para el registro F
    wire [1:0]  flags_pattern; // Define las banderas que se modificarán en ese ciclo
    wire        high_mask; // Máscara 0xFF00 para leer/escribir rápido en la RAM de página cero / IO
    wire        next; // Señal de que la instrucción ya terminó
    wire        stop; // Flag de la instrucción STOP
    wire        halt; // Flag de la instrucción HALT
    reg         wake; // Despierta al CPU de HALT/STOP
    reg         int_dispatch; // Salta a un vector de interrupción
    wire        int_master_en; // Interrupt Master Enable (IME)
    wire        int_ack; // La interrupción ya fue atendida

    // -- Banco de registros -- 
    wire [2:0]  rf_rdn; // Índice del registro a leer 
    wire [7:0]  rf_rd; // Valor del registro leído
    reg  [7:0]  rf_rd_ex; // Buffer de lectira de registro en etapa de ejecución
    wire [1:0]  rf_rdwn; // Índice del registro de 16 bits a leer
    wire [15:0] rf_rdw; // Valor del registro de 16 bits leído
    wire [7:0]  rf_h; // Salida del registro h
    wire [7:0]  rf_l; // Salida del registro l
    wire [15:0] rf_sp; // Salida del SP
    wire [2:0]  rf_wrn; // Índice del registro a escribir
    wire [7:0]  rf_wr; // Dato que se va a escribir
    wire        rf_we; // Write Enable

    // -- Internos de la ALU --
    wire [7:0]  alu_a; // Operando A
    wire [7:0]  alu_b; // Operando B
    wire [7:0]  alu_result; // Resultado
    reg  [7:0]  alu_result_buffer; // Almacenamiento temporal del resultado
    wire [3:0]  alu_flags_in; // Banderas que entran a la ALU del registro F
    wire [3:0]  alu_flags_out; // Banderas resultantes de las operaciones
    wire [4:0]  alu_op; // Código de la operación a realizar
    wire        alu_op_signed; // Indica si deberá ser tratado como complemento a 2
    wire        alu_carry_out; // Acarreo para encadenar operaciones de 16 bits
    reg         alu_carry_out_ex; // Copia del acarreo en la etapa de ejecución
    reg         alu_carry_out_ct; // Copia del acarreo en la etapa de ciclo

    // -- Acumulador --
    wire [7:0]  acc_wr; // Dato a escribir
    wire        acc_we; // Write Enable
    wire [7:0]  acc_rd; // Dato leído del acumulador

    // -- Manejo interno del PC --
    wire [15:0] pc_rd; // Valor actual del PC
    wire [7:0]  pc_rd_b; // Lectura del byte alto o bajo del PC
    wire        pc_b_sel; // Si es 0 se lee el byte bajo, si es 1 se lee el alto
    wire [15:0] pc_wr; // Valor de 16 bits a escribir
    wire [7:0]  pc_wr_b; // Valor de 8 bits a escribir en una mitad del PC
    wire        pc_we_h; // Write Enable para byte alto
    wire        pc_we_l; // Write Enable para byte bajo

    // -- Variables temporales y buffers -- 
    wire [15:0] temp_rd; // Salida de un registro temporal 
    wire [3:0]  flags_rd; // Lectura de las flags
    wire [3:0]  flags_wr; // Escritura de las flags
    wire [7:0]  db_wr; // Dato a inyectar en el bus de datos
    wire [7:0]  db_rd; // Dato recibido desde el bus de datos
    wire        db_we; // Write Enable al bus de datos

    // Operandos inmediatos
    wire [7:0]  imm_abs; // Valor absoluto del inmediato
    wire [7:0]  imm_low; // Byte bajo del operando inmediato
    wire [7:0]  imm_ext; // Byte extendido del operando (saltos relativos con signo)

    reg  [1:0]  ct_state; // Máquina de estados principal (divide M-Cycles en T-Cycles)

    // -- Etapa de ejecución -- 
    // Se conectan con la lógica combinacional de control.v
    wire [1:0] alu_src_a_ex; // Multiplexor de la entrada A
    wire [2:0] alu_src_b_ex; // Multiplexor de la entrada B
    wire [1:0] alu_op_prefix_ex; // Familia de la operación que ejecutará la ALU
    wire [1:0] alu_op_src_ex; // Subcódigo de la familia
    wire       alu_op_signed_ex; // Avias si deberá tratarse como complemento a 2
    wire [1:0] alu_dst_ex; // Multiplexor del destino
    wire [2:0] rf_wr_sel_ex; // Register File Write Select
    wire [2:0] rf_rd_sel_ex; // Register File Read Select
    wire       flags_we_ex; // Flags Write Enable
    wire       pc_b_sel_ex; // Selector de la mitad del PC
    wire       pc_jr; // Jump Relative
    wire       pc_we_ex; // Program Counter Write Enable
    wire       pc_revert; // Ordena al PC regresar al valor de last_pc
    wire       temp_redir; // Activa la redirección hacia los registros temporales
    wire       opcode_redir; // Se usa con el prefijo CB para redigir la decodificación del byte secundario

// -- El módulo control para la decodificación de instrucciones --
    control control(
        .clk(clk), // Reloj maestro
        .rst(rst), // Señal de reset
        .opcode_early(opcode), // Instrucción recién leída
        .cb(cb), // Prefijo CB
        .imm(imm_low), // Valor numérico inmediato
        .m_cycle_early(m_cycle_early), // Ciclo actual
        .ct_state(ct_state), // Estado de la FSM
        .f_z(flags_rd[3]), // Zero Flag
        .f_c(flags_rd[0]), // Carry Flag
        .alu_src_a(alu_src_a_ex), // Operando A
        .alu_src_b(alu_src_b_ex), // Operando B
        .alu_src_xchg(alu_src_xchg), // Operación de la ALU
        .alu_op_prefix(alu_op_prefix_ex), // 
        .alu_op_src(alu_op_src_ex),
        .alu_op_signed(alu_op_signed_ex),
        .alu_dst(alu_dst_ex),
        .pc_src(pc_src),
        .pc_we(pc_we_ex),
        .pc_b_sel(pc_b_sel_ex),
        .pc_jr(pc_jr),
        .pc_revert(pc_revert),
        .rf_wr_sel(rf_wr_sel_ex),
        .rf_rd_sel(rf_rd_sel_ex),
        .rf_rdw_sel(rf_rdw_sel),
        .temp_redir(temp_redir),
        .opcode_redir(opcode_redir),
        .bus_op(bus_op),
        .db_src(db_src),
        .ab_src(ab_src),
        .ct_op(ct_op),
        .flags_we(flags_we_ex),
        .flags_pattern(flags_pattern),
        .high_mask(high_mask),
        .int_master_en(int_master_en),
        .int_dispatch(int_dispatch),
        .int_ack(int_ack),
        .next(next),
        .stop(stop),
        .halt(halt),
        .wake(wake),
        .fault(fault)
    );
    
    // -- Bandera para señal de paro --
    always @(posedge clk) begin
        done <= stop | halt | fault; 
    end

    // Halt solo se puede despertar si hay una interrupción pendiente
    // Stop se puede despertar si hay una interrupción pendiente o si se presiona una tecla
    // En cualquier otro caso el procesador corre normal (vale 0)
    wire wake_comb = 
        (halt) ? ((int_flags_in & int_en) != 0) : (
        (stop) ? (((int_flags_in & int_en) != 0) || (key_in != 0)) : 
        (1'b0));
    reg wake_delay; // Despertar debe estar atrasado 1 M-Cycle
    always @(posedge clk) begin
        if (ct_state == 2'b10) begin // El despertar se evalúa en el estado 10 de la FSM
            // Si el procesador corre normal, wake_delay vale 0
            wake_delay <= wake_comb; 
            // Si wake_delay empieza siendo 1 (retraso) se pasa a wake
            wake <= wake_delay;
        end
    end

    // Los bits altos del opcode son usados por la ALU
    wire [7:3] current_opcode;

    // Data Bus Buffer
    reg [7:0] db_wr_buffer; // Almacena temporalmente los datos que van hacia el bus
    reg [7:0] db_rd_buffer; // Almacena temporalmente los datos que vienen del bus
    
    always @(posedge clk) begin
        if (db_we) // Si está permitido escribir en el bus de datos
            db_wr_buffer <= alu_result; // Se recoge el dato de la ALU en el flanco de subida
    end
    assign db_rd = db_rd_buffer; // Conecta la salida del bus con su buffer

    // -- Arbitraje de bus --
    // Configura la salida de lectura del bus con un multiplexor
    // Si db_src es 00, se conecta al acumulador
    // Si db_src es 01, se conecta el resultado respaldado de la ALU
    // Si db_src es 10, se contecta el banco de registros de la ejecución
    // Si db_src es 11, conecta el buffer interno de escritura
    // Si ninguna condición de cumple, se mandan 0's
    assign db_wr = (
        (db_src == 2'b00) ? (acc_rd) : (
        (db_src == 2'b01) ? (alu_result_buffer) : (
        (db_src == 2'b10) ? (rf_rd_ex) : (
        (db_src == 2'b11) ? (db_wr_buffer) : (8'b0)))));
    assign db_we = (alu_dst == 2'b11);
    
    // Multiplexor del bus de direcciones
    wire [15:0] ab_wr;
    // 00 - Selecciona el PC
    // 01 - Registros temporales / High RAM
    // 10 - Banco de registros dobles
    // 11 - Stack Pointer
    assign ab_wr = (
        (ab_src == 2'b00) ? (pc_rd) : (
        (ab_src == 2'b01) ? ((high_mask) ? ({8'hFF, temp_rd[7:0]}) : (temp_rd)) : (
        (ab_src == 2'b10) ? ((high_mask) ? ({8'hFF, rf_rdw[7:0]}) : (rf_rdw)) : (
        (ab_src == 2'b11) ? (rf_sp) : (16'b0)))));

    // La interrupción puede dispararse si el registro IF (int_flags_in) tiene interrupciones pendientes
    // Si el registro IE (int_en) tiene una interrupción configurada que esté pendiente por atender
    // El IME (int_master_en) está actio
    wire [4:0] int_flags_masked = int_flags_in & int_en & {5{int_master_en}};
    // Se busca la bandera que la disparó y la apaga con una máscara binaria, dejando intacto el resto
    wire [4:0] int_flags_out_cleared = 
        (int_flags_masked[0]) ? (int_flags_in & 5'b11110) : (
        (int_flags_masked[1]) ? (int_flags_in & 5'b11101) : (
        (int_flags_masked[2]) ? (int_flags_in & 5'b11011) : (
        (int_flags_masked[3]) ? (int_flags_in & 5'b10111) : (
        (int_flags_masked[4]) ? (int_flags_in & 5'b01111) : (
            int_flags_in
        )))));

    // Si el procesador decidió atender una interrupción y tiene permiso para escribir en el PC (vector de interrupción)
    // Se actualiza las flags en base a la máscara binaria, si no, se queda igual
    assign int_flags_out = 
        ((int_dispatch)&&(pc_we)) ? (int_flags_out_cleared) : (int_flags_in);

    // -- Regisiter file --
    wire [7:0] rf_rd_raw; // Atrapa la lectura en crudo del banco de registros
    regfile regfile(
        .clk(clk), // Señal de reloj maestro
        .rst(rst), // Reset
        .rdn(rf_rdn), // Índice de 3 bits que indica qué registro leer
        .rd(rf_rd_raw), // El valor del registro leído se guarda aquí
        .rdwn(rf_rdwn), // Selector de registros dobles
        .rdw(rf_rdw), // Almacenamiento del registro doble
        .h(rf_h), // Registro H
        .l(rf_l), // Registro L
        .sp(rf_sp), // Stack Pointer
        .wrn(rf_wrn), // A qué registro escribir
        .wr(rf_wr), // Dato que se va a guardar
        .we(rf_we) // Register File Write Enable
    );
    assign rf_wr = alu_result; // Conecta la entrada de escritura al resultad de la ALU
    // Si el destino es el banco de registros y no estamos en modo de redirección temporal
    // Se asigna el write enable al banco de registros
    assign rf_we = (alu_dst == 2'b10) && (!temp_redir);
    assign rf_wrn = rf_wr_sel; // Índice del registro a leer
    assign rf_rdn = rf_rd_sel; // Cuál banco de registro se desea leer en ese ciclo
    assign rf_rdwn = rf_rdw_sel; // Selector de registros dobles
    
    // Multiplexor de lectura para la salida del banco de registros 
    assign rf_rd = (!temp_redir) ? (rf_rd_raw) : ((rf_rd_sel[0]) ? (temp_rd[7:0]) : (temp_rd[15:8]));

    always@(posedge clk) begin
        if (rst) // Si llega señal de reset en el flanco de subida
            rf_rd_ex <= 8'b0; // Se limpia el buffer
        else
            if (ct_state == 2'b00) // Al inicio de la FSM de T-Cycles y en el flanco de subida
                rf_rd_ex <= rf_rd_raw; // Se guarda el dato del buffer
    end

    // Register A
    reg [15:0] imm_reg; // Guarda datos inmediatos que vienen de la ROM
    reg [7:0] acc_internal; // Acumulador (Registro A)
    
    always @(posedge clk) begin
        if (rst) acc_internal <= 8'h00; // Se limpia el acumulador en el flanco de subida en caso de reset
        else if (acc_we) acc_internal <= acc_wr; // Si hay permiso de escritura, se toma el dato del buffer
    end
    // Conecta el valor del acumulador hacia una salida de lectura para que otros componentes lo puedan usar
    assign acc_rd = acc_internal;
    
    // Con un multiplexor se decide el origen del dato
    // Si el procesador está haciendo una lectura específica desde el bus de datos
    // Toma el registro inmediato, en otro caso toma el resultado que va saliendo de la ALU
    assign acc_wr = ((db_src == 2'b00) && (bus_op == 2'b11)) ? (imm_reg[7:0]) : (alu_result);
    // Se permite cambiar el valor del acumulador si el resultado de la ALU debe guardarse en el acumulador
    // O si se está cargando un valor inmediato directamente desde la memoria hacia el acumulador
    assign acc_we = ((alu_dst == 2'b00) || ((db_src == 2'b00) && (bus_op == 2'b11)));
    
    // -- Halt Bug --

    reg halt_bug; // Flag de Halt Bug
    // Flah de interrupción pendiente
    wire pending_interrupt = ((int_flags_in & int_en) != 0);

    always @(posedge clk) begin
        if (rst) begin
            halt_bug <= 1'b0; // Reset
        end else begin
            // Activar halt bug si entra en halt con IME=0 y hay una interrupción pendiente
            if (halt && !int_master_en && pending_interrupt) begin
                halt_bug <= 1'b1;
            end
            
            // Apagar halt bug al terminar el ciclo de fetch (ct_state == 3)
            if (halt_bug && ct_state == 2'b11) begin
                halt_bug <= 1'b0;
            end
        end
    end

    // Register PC
    reg [15:0] pc; // Program Counter
    reg [15:0] last_pc; // Valor anterior del PC
    assign pc_rd = pc; // Conecta el valor del PC al resto del procesador
    // La ALU al ser de 8 bits, el PC de 16 bits se debe partir en dos partes con little endian
    assign pc_rd_b = (pc_b_sel == 1'b0) ? (pc[7:0]) : (pc[15:8]);
    // La ALU hace los cálculos de + 1 o desfases
    assign pc_wr_b = alu_result; // El resultado de la ALU como una de las mitades del PC
    // Multiplexor para el nuevo valor del PC
    // 00 - Registro doble
    // 01 - Dirección fija de vectores
    // 10 - Registros temporales
    // 11 - Ceros
    assign pc_wr = (
        (pc_src == 2'b00) ? (rf_rdw) : (
        (pc_src == 2'b01) ? ({10'b00, opcode[5:3], 3'b000}) : (
        (pc_src == 2'b10) ? (temp_rd) : (
        (pc_src == 2'b11) ? (16'b0) : (16'b0)))));
        
    // Multiplexor combinacional de vectores de interrupción
    wire [15:0] pc_int = 
        (int_flags_masked[0]) ? (16'h0040) : ( // VBlank
        (int_flags_masked[1]) ? (16'h0048) : ( // LCD STAT
        (int_flags_masked[2]) ? (16'h0050) : ( // Timer
        (int_flags_masked[3]) ? (16'h0058) : ( // Serial
        (int_flags_masked[4]) ? (16'h0060) : ( // Joypad
            16'h0000
        )))));

    // Filtros para bloquear el PC si hay Halt Bug
    assign pc_we_l = ((alu_dst == 2'b01) && (pc_b_sel == 1'b0) && !halt_bug) ? (1'b1) : (1'b0);
    assign pc_we_h = ((alu_dst == 2'b01) && (pc_b_sel == 1'b1) && !halt_bug) ? (1'b1) : (1'b0);
    
    // Actualización física del PC con el reloj
    always @(posedge clk) begin
        if (rst) // El reinicio del PC
            pc <= 16'h0000;
        else begin
            if (pc_we_l) begin // Escritura del byte bajo 
                pc[7:0] <= pc_wr_b; // Se guarda el resultado de la ALU en el byte bajo (PC + 1)
                last_pc[7:0] <= pc[7:0]; // Guarda el valor viejo
            end
            else if (pc_we_h) begin // Escritura del byte alto
                pc[15:8] <= pc_wr_b; // Propagar el acarreo al byte alto
                last_pc[15:8] <= pc[15:8]; // Valor viejo
            end
            else if (pc_revert) // Si la operación de modificación del PC debe abortarse (salto condicional z.B.)
                pc <= last_pc;
            else if (pc_we)
                if (int_dispatch) // ¿La reescritura fue por una interrupción?
                    pc <= pc_int; // Toma el vector de interrupción de arriba
                else begin // Carga la nueva dirección del PC de registros o memoria
                    pc <= pc_wr;
                    last_pc <= pc;
                end
        end
    end

    // Los opcodes para suma del SP
    wire is_sp_add = (opcode == 8'hE8 || opcode == 8'hF8);
    
    // Se guarda el valor viejo del SP al inicio del ciclo antes de que la ALU lo sume en dos pasos
    reg [15:0] sp_orig;
    always @(posedge clk) begin
        if (m_cycle == 3'd0) sp_orig <= rf_sp; 
    end

    // Registro F
    reg [3:0] flags; // Nibble superior
    always @(posedge clk) begin
        if (rst)
            flags <= 4'b0000; // Se limpian al reset
        else if (flags_we) begin // Write Enable
            if (is_sp_add) begin // Las operaciones del SP tienen manejo de flags distinto
                // Banderas para ADD SP, e8 (0xE8) y LD HL, SP+e8 (0xF8)
                flags[3] <= 1'b0; // Z
                flags[2] <= 1'b0; // N
                // Se suman 5 bits, el 5to bit es el Half-Carry
                flags[1] <= (({1'b0, sp_orig[3:0]} + {1'b0, imm_low[3:0]}) > 5'h0F) ? 1'b1 : 1'b0; // H
                // Se suman 9 bits, el 9no bit es el Carry
                flags[0] <= (({1'b0, sp_orig[7:0]} + {1'b0, imm_low[7:0]}) > 9'hFF) ? 1'b1 : 1'b0; // C
            end else if (flags_pattern == 2'b00) // Actualización total
                flags[3:0] <= flags_wr[3:0]; // Se actualizan las 4 flags
            else if (flags_pattern == 2'b01) // Actualización parcial inferior
                flags[2:0] <= {1'b0, flags_wr[1:0]}; // Se escriben los bits inferiores
            else if (flags_pattern == 2'b10) // Enmasacaramiento de bits altos
                flags[3:0] <= {2'b0, flags_wr[1:0]}; // Apaga los dos bits superiores y actualiza los dos inferiores
            else if (flags_pattern == 2'b11) // Conservación del Carry
                flags[3:1] <= flags_wr[3:1]; // Actualiza las 3 flags superiores y protege el carry
        end
    end
    assign flags_rd = flags; // Lectura de flags 
    assign flags_wr = alu_flags_out; // Escritura de flags
    
    // ALU
    wire [2:0] alu_op_mux; // La operación a realizar en la ALU
    wire [7:0] alu_a_pre; // Operando A preliminar
    wire [7:0] alu_b_pre; // Operando B preliminar

    // -- Instancia del módulo de la ALU --
    alu alu(
        .alu_a(alu_a),
        .alu_b(alu_b),
        .alu_bit_index(imm_reg[5:3]),
        .alu_result(alu_result),
        .alu_flags_in(alu_flags_in),
        .alu_flags_out(alu_flags_out),
        .alu_op(alu_op)
);

    // -- Multiplexor para obtener el dato del operando A --
    assign alu_a_pre = (
        (alu_src_a == 2'b00) ? (acc_rd) : (
        (alu_src_a == 2'b01) ? (pc_rd_b) : (
        (alu_src_a == 2'b10) ? (rf_rd) : (
        (alu_src_a == 2'b11) ? (db_rd) : (8'b0)))));

    // -- Multiplexor para obtener el dato del operando B --
    assign alu_b_pre = (
        (alu_src_b == 3'b000) ? (acc_rd) : (
        (alu_src_b == 3'b001) ? ({7'b0, alu_carry_out}) : (
        (alu_src_b == 3'b010) ? (8'd0) : (
        (alu_src_b == 3'b011) ? (8'd1) : (
        (alu_src_b == 3'b100) ? (rf_h) : (
        (alu_src_b == 3'b101) ? (rf_l) : (
        (alu_src_b == 3'b110) ? (imm_abs) : (
        (alu_src_b == 3'b111) ? ((pc_b_sel) ? (imm_low) : (imm_ext)) : (8'b0))))))))); 

    // Si la flag exchange está activada, el operando a y b cambian valores
    assign alu_a = (alu_src_xchg) ? (alu_b_pre) : (alu_a_pre);
    assign alu_b = (alu_src_xchg) ? (alu_a_pre) : (alu_b_pre);

    // Se combina la operación de la ALU con parte del opcode para obtener la operación completa
    assign alu_op_mux = (
        (alu_op_src == 2'b00) ? (current_opcode[5:3]) : (
        (alu_op_src == 2'b01) ? ({1'b1, current_opcode[7:6]}) : (
        (alu_op_src == 2'b10) ? ((alu_op_signed) ? (3'b001) : (3'b000)) : (
        (alu_op_src == 2'b11) ? ((alu_op_signed) ? (3'b011) : (3'b010)) : (3'b0)))));
    // Datos para la ALU
    assign alu_flags_in = flags_rd;
    assign alu_op = {alu_op_prefix, alu_op_mux};
    // Si el prefijo es CB, se guarda el segundo byte de decodificación(imm_reg)
    assign current_opcode[7:3] = (opcode_redir) ? (imm_reg[7:3]) : (opcode[7:3]);

    // CT FSM
    wire [1:0] ct_next_state;

    // Calcula el siguiente paso de la FSM
    assign ct_next_state = ct_state + 2'b01;
    always @(posedge clk) begin // En cada flanco de subida
        if (rst)
            ct_state <= 2'b00; // Reset
        else
            ct_state <= ct_next_state; // Se actualiza el siguiente estado
    end

    assign ct = ct_state; // Permite saber a los demás componentes el estado

    assign temp_rd = imm_reg; // Lectura de registro temporal
    assign imm_low = imm_reg[7:0]; // Extracción del byte bajo
    assign imm_ext = {8{imm_reg[7]}}; // Extensión de signo
    // Calcula el valor absoluto
    assign imm_abs = (imm_reg[7]) ? (~imm_reg[7:0] + 1'b1) : (imm_reg[7:0]);

    // Secuenciador de instrucciones de bus
    always @(posedge clk) begin
        if (rst) begin // Valores por defecto
            a <= 16'b0;
            rd <= 1'b0;
            wr <= 1'b0;
            phi <= 1;
            opcode <= 8'b0;
            imm_reg <= 16'b0;
            db_rd_buffer <= 8'b0;
            dout <= 8'b0;
            int_dispatch <= 1'b0;
            alu_result_buffer <= 8'b0;
        end
        else begin // Guarda datos crudos en el registro de valores inmediatos si la redirección temporal 
            //está activa y no estemos en medio de un ciclo de lectura de bus
            if ((alu_dst == 2'b10) && temp_redir && !(ct_state == 2'b10 && bus_op == 2'b11))
                if (rf_wr_sel[0]) imm_reg[7:0] <= rf_wr;
                else imm_reg[15:8] <= rf_wr;

            case (ct_state) // FSM de T-Cycles a M-Cycles
            2'b00: begin // Primer estado
                // Poner la dirección en el bus 
                a <= ab_wr;
                // Si el procesador está haciendo un Fetch de instrucción (bus_op == 01) o una lectura de datos
                rd <= ((bus_op == 2'b01)||(bus_op == 2'b11)) ? (1'b1) : (1'b0); // Disparar la lectura
                wr <= 0; // Se apaga la escritura
                phi <= 1; // Se pone en alto la señal del reloj de fase tradicional para sincronización
                // Respaldo del resultado de la ALU
                alu_result_buffer <= alu_result;
            end
            2'b01: begin // Segundo estado (IDLE)
                // Lectura en proceso
            end
            2'b10: begin // Tercer estado
                if (bus_op == 2'b10) begin // Si la órden es escribir
                    // Ciclo de escritura
                    wr <= 1; // Pone la flag en 1
                    dout <= db_wr; // Actualiza el dato
                end
                else if (bus_op == 2'b01) begin // Si la órden es fetch
                    // Instruction Fetch Cycle
                    wr <= 0; // Quita permiso de escribir
                    opcode <= din; // Trae el dato
                end
                else if (bus_op == 2'b11) begin // Si la órden es leer datos extra
                    // Se quita el permiso de escribir y mete el dato leído en un buffer
                    wr <= 0;
                    db_rd_buffer <= din;
                    // Si se trata de una instrucción extendida de prefijo 0xCB
                    // El dato que sigue es la verdadera instrucción
                    if ((opcode == 8'hCB) && (m_cycle == 0)) cb <= din[7:0];
                    // La lectura del número de 16 bits se hace en 2 M-Cycles
                    if (m_cycle == 3'd0) imm_reg[7:0] <= din;
                    else if (m_cycle == 3'd1) imm_reg[15:8] <= din; 
                end
                // Cierra los permisos
                else begin
                    wr <= 0;
                end
                rd <= 0;
                phi <= 0;

                // Bloque de interrupciones
                // Si se encuentra en un estado seguro y hay interrupciones sin atender, se pone la flag de interrupción pendiente
                if ((!int_dispatch) && (int_flags_masked != 0) && (int_master_en) && ((bus_op == 2'b01) || (halt == 1'b1)))
                    int_dispatch <= 1'b1;
                else if ((int_dispatch) && (int_ack)) begin
                    int_dispatch <= 1'b0;
                end
            end
            2'b11: begin // Cuarto estado
                // Estado de limpieza
                rd <= 0;
                wr <= 0;
                dout <= 8'b0;
            end
            endcase
        end
    end

    // CT - FSM / Instruction Execution
    reg  [1:0] alu_src_a_ct;
    reg  [2:0] alu_src_b_ct;
    wire [1:0] alu_op_prefix_ct = 2'b00;
    reg  [1:0] alu_op_src_ct;
    reg  [1:0] alu_dst_ct;
    reg  [2:0] rf_wr_sel_ct;
    reg  [2:0] rf_rd_sel_ct;
    reg        pc_b_sel_ct; 
      
    // -- Lógica Combinacional de Mantenimiento Interno --
    // Este bloque multiplexa en el tiempo a la ALU para realizar sumas de punteros (PC o SP)
    // en segundo plano mientras el bus de datos espera a la memoria.
    always @(*) begin
        // Por default, apagar las entradas y no alterar registros
        alu_src_a_ct = 2'b00;  // Operando A desconectado
        alu_src_b_ct = 3'b010; // Operando B forzado a 0 constante
        alu_op_src_ct = 2'b10; // Operación por defecto (Suma)
        alu_dst_ct = 2'b00;    // Destino temporal hacia el Acumulador
        rf_wr_sel_ct = 3'b000;
        rf_rd_sel_ct = 3'b000;
        pc_b_sel_ct = 1'b0;

        // FSM anidada: Evalúa el ciclo temporal actual (T-Cycle)
        case (ct_state)
        2'b00: begin
            // T-Cycle 0: Fase de ejecución.
            // En este M-Cycle la ALU está enfocada 100% en el módulo de control principal (control.v).
            // Este bloque no toma el control de los buses.
        end
        2'b01: begin
            // T-Cycle 1: Cálculos del byte bajo (Bits 0-7)
            // Empieza a calcular operaciones de 16 bits en dos pasos.
            case (ct_op) // Evalúa qué operación secundaria se solicitó
            2'b00: begin
                // Estado inactivo, no hay punteros que actualizar.
            end
            2'b01: begin
                // Operación: Calcular PC bajo + 1
                pc_b_sel_ct = 1'b0; // Selecciona la mitad baja del Program Counter
                alu_src_a_ct = 2'b01;  // Inyecta el byte del PC a la entrada A
                alu_src_b_ct = (pc_jr) ? (3'b110) : (3'b011); // Si es salto inyecta inmediato, si no, un 1 constante
                alu_op_src_ct = (pc_jr) ? (imm_low[7] ? 2'b11 : 2'b10) : 2'b10; // Suma (o resta si es salto negativo)
                alu_dst_ct = 2'b01;    // Enruta el resultado de regreso a la mitad baja del PC
            end
            2'b10: begin
                // Operación: Calcular SP bajo - 1
                rf_rd_sel_ct = 3'b111; // Lee la mitad baja del Stack Pointer
                rf_wr_sel_ct = 3'b111; // Apunta la escritura a la mitad baja del SP
                alu_src_a_ct = 2'b10;  // Inyecta el registro a la entrada A
                alu_src_b_ct = 3'b011; // Inyecta un 1 constante a la entrada B
                alu_op_src_ct = 2'b11; // Configura la ALU en modo Resta (SUB)
                alu_dst_ct = 2'b10;    // Enruta el resultado de regreso al banco de registros
            end
            2'b11: begin
                // Operación: Calcular SP bajo + 1
                rf_rd_sel_ct = 3'b111; // Lee la mitad baja del SP
                rf_wr_sel_ct = 3'b111; // Apunta la escritura al SP
                alu_src_a_ct = 2'b10;  // Inyecta el registro a la entrada A
                alu_src_b_ct = 3'b011; // Inyecta un 1 constante a la entrada B
                alu_op_src_ct = 2'b10; // Configura la ALU en modo Suma (ADD)
                alu_dst_ct = 2'b10;    // Enruta el resultado al banco de registros
            end
            endcase
        end
        2'b10: begin
            // T-Cycle 2: Cálculos del byte alto (Bits 8-15)
            // Completa las operaciones de 16 bits propagando el acarreo del T-Cycle 1.
            case (ct_op)
            2'b00: begin
                // Estado inactivo, no hacer nada.
            end
            2'b01: begin
                // Operación: Calcular PC alto + acarreo
                pc_b_sel_ct = 1'b1; // Selecciona la mitad alta del Program Counter
                alu_src_a_ct = 2'b01;  // Inyecta el byte alto del PC a la entrada A
                alu_src_b_ct = 3'b001; // Inyecta la bandera de Carry a la entrada B
                alu_op_src_ct = (pc_jr) ? (imm_low[7] ? 2'b11 : 2'b10) : 2'b10; // Resuelve con signo o como suma normal
                alu_dst_ct = 2'b01;    // Retorna el resultado a la mitad alta del PC
            end
            2'b10: begin
                // Operación: Calcular SP alto - acarreo
                rf_rd_sel_ct = 3'b110; // Lee la mitad alta del Stack Pointer
                rf_wr_sel_ct = 3'b110; // Apunta la escritura a la mitad alta del SP
                alu_src_a_ct = 2'b10;  // Inyecta el registro a la entrada A
                alu_src_b_ct = 3'b001; // Inyecta el Carry a la entrada B
                alu_op_src_ct = 2'b11; // Configura la ALU en modo Resta (SUB)
                alu_dst_ct = 2'b10;    // Retorna el resultado al banco de registros
            end
            2'b11: begin
                // Operación: Calcular SP alto + acarreo
                rf_rd_sel_ct = 3'b110; // Lee la mitad alta del Stack Pointer
                rf_wr_sel_ct = 3'b110; // Apunta al SP
                alu_src_a_ct = 2'b10;  // Inyecta el registro
                alu_src_b_ct = 3'b001; // Inyecta el Carry
                alu_op_src_ct = 2'b10; // Suma (ADD)
                alu_dst_ct = 2'b10;    // Retorna al banco
            end
            endcase
        end
        2'b11: begin
            // T-Cycle 3: Estado de reposo y seguridad
            // La ALU se desconecta apuntando su salida al bus inactivo para evitar sobrescribir datos.
            alu_dst_ct = 2'b11;
        end
        endcase
    end

    // Estos cables deciden quién tiene el control físico de la ALU en cada instante.
    // Si estamos en el T-Cycle 0 (ct_state == 2'b00), el control lo tiene el decodificador
    // principal de instrucciones (señales _ex). En cualquier otro T-Cycle, el control 
    // pasa a la FSM de mantenimiento interno (señales _ct) para actualizar punteros.
    assign alu_src_a = (ct_state == 2'b00) ? (alu_src_a_ex) : (alu_src_a_ct);
    assign alu_src_b = (ct_state == 2'b00) ? (alu_src_b_ex) : (alu_src_b_ct);
    assign alu_op_prefix = (ct_state == 2'b00) ? (alu_op_prefix_ex) : (alu_op_prefix_ct);
    assign alu_op_src = (ct_state == 2'b00) ? (alu_op_src_ex) : (alu_op_src_ct);
    // Las operaciones de mantenimiento interno nunca usan aritmética con signo.
    assign alu_op_signed = (ct_state == 2'b00) ? (alu_op_signed_ex) : (1'b0);
    
    assign alu_dst = (ct_state == 2'b00) ? (alu_dst_ex) : (alu_dst_ct);
    assign rf_wr_sel = (ct_state == 2'b00) ? (rf_wr_sel_ex) : (rf_wr_sel_ct);
    assign rf_rd_sel = (ct_state == 2'b00) ? (rf_rd_sel_ex) : (rf_rd_sel_ct);
    
    // Solo la instrucción principal puede modificar las banderas directamente.
    assign flags_we = (ct_state == 2'b00) ? (flags_we_ex) : (1'b0);
    assign pc_b_sel = (ct_state == 2'b00) ? (pc_b_sel_ex) : (pc_b_sel_ct);
    assign pc_we = (ct_state == 2'b00) ? (pc_we_ex) : (1'b0);
    assign alu_carry_out = (ct_state == 2'b00) ? (alu_carry_out_ex) : (alu_carry_out_ct);

    // -- Máquina de estados de ejecución y pipeline
    reg  [2:0] ex_state; // Estado actual
    wire [2:0] ex_next_state; // Estado siguiente

    // Si el módulo de control activa 'next', avanza al siguiente paso. 
    // Si no, la instrucción terminó y regresa al M-Cycle 0.
    assign ex_next_state = (next) ? (ex_state + 3'd1) : (3'd0);

    always @(posedge clk) begin
        if (rst) begin // Reinicio de la FSM
            ex_state <= 3'd0;
            m_cycle_early <= 3'd0;
            alu_carry_out_ex <= 1'b0;
            alu_carry_out_ct <= 1'b0;
        end
        else begin
            // Respaldo constante del acarreo para las operaciones de mantenimiento interno
            alu_carry_out_ct <= alu_flags_out[0];
            if (ct_state == 2'b11) begin
                // El M-Cycle solo avanza físicamente al estado 
                // siguiente justo cuando termina el último T-Cycle (T3 -> 11) del reloj
                ex_state <= ex_next_state;
            end
            else if (ct_state == 2'b10) begin
                // Pipeline: Un pulso antes (en T2 -> 10), pre-carga el siguiente 
                // M-Cycle hacia el decodificador para que la lógica combinacional gane tiempo.
                m_cycle_early <= ex_next_state;
            end
            else if (ct_state == 2'b00) begin
                // Respaldo de banderas en T0
                alu_carry_out_ex <= alu_flags_out[0];
            end
        end
    end

    assign m_cycle = ex_state;

endmodule