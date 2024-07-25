module CPU (
    input clk,
    input reset,
    input [18:0] instruction, 
    input [15:0] data_in,     
    output reg [15:0] data_out, 
    output reg [15:0] address,  
    output reg mem_read,       
    output reg mem_write       
);

    // Register file
    reg [15:0] registers [0:15]; 

    // Pipeline registers
    reg [18:0] IF_ID_instruction;
    reg [15:0] ID_EX_A, ID_EX_B;
    reg [3:0] ID_EX_opcode;
    reg [3:0] EX_MEM_dest;
    reg [15:0] EX_MEM_result;
    reg [15:0] MEM_WB_result;
    reg [3:0] MEM_WB_dest;

    // Instruction fields
    wire [3:0] opcode = instruction[18:15];
    wire [3:0] rs = instruction[14:11];
    wire [3:0] rt = instruction[10:7];
    wire [3:0] rd = instruction[6:3];
    wire [2:0] func = instruction[2:0];
    wire [11:0] addr = instruction[14:3]; // 12-bit address for control flow instructions

    // ALU
    reg [15:0] ALU_result;
    always @(*) begin
        case (ID_EX_opcode)
            4'b0000: ALU_result = ID_EX_A + ID_EX_B;    // ADD
            4'b0001: ALU_result = ID_EX_A - ID_EX_B;    // SUB
            4'b0010: ALU_result = ID_EX_A * ID_EX_B;    // MUL
            4'b0011: ALU_result = ID_EX_A / ID_EX_B;    // DIV
            4'b0100: ALU_result = ID_EX_A + 1;          // INC
            4'b0101: ALU_result = ID_EX_A - 1;          // DEC
            4'b0110: ALU_result = ID_EX_A & ID_EX_B;    // AND
            4'b0111: ALU_result = ID_EX_A | ID_EX_B;    // OR
            4'b1000: ALU_result = ID_EX_A ^ ID_EX_B;    // XOR
            4'b1001: ALU_result = ~ID_EX_A;             // NOT
            default: ALU_result = 16'b0; 
        endcase
    end

    // Program Counter
    reg [15:0] PC;

    // Pipeline stages
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset pipeline registers and program counter
            IF_ID_instruction <= 19'b0;
            ID_EX_A <= 16'b0;
            ID_EX_B <= 16'b0;
            ID_EX_opcode <= 4'b0;
            EX_MEM_dest <= 4'b0;
            EX_MEM_result <= 16'b0;
            MEM_WB_result <= 16'b0;
            MEM_WB_dest <= 4'b0;
            PC <= 16'b0;
        end else begin
            // Fetch stage
            IF_ID_instruction <= instruction;

            // Decode stage
            ID_EX_A <= registers[rs];
            ID_EX_B <= registers[rt];
            ID_EX_opcode <= opcode;

            // Execute stage
            EX_MEM_result <= ALU_result;
            EX_MEM_dest <= rd;

            // Memory stage
            if (opcode == 4'b1010) begin // LOAD
                mem_read <= 1;
                address <= ALU_result;
            end else if (opcode == 4'b1011) begin // STORE
                mem_write <= 1;
                address <= ALU_result;
                data_out <= registers[rt];
            end else begin
                mem_read <= 0;
                mem_write <= 0;
            end

            // Control flow instructions
            case (opcode)
                4'b1100: PC <= addr; // JMP
                4'b1101: if (registers[rs] == registers[rt]) PC <= addr; // BEQ
                4'b1110: if (registers[rs] != registers[rt]) PC <= addr; // BNE
                4'b1111: begin // CALL
                    registers[15] <= PC + 1; // Store return address in r15
                    PC <= addr;
                end
                default: PC <= PC + 1; // Increment PC by 1 for other instructions
            endcase

            // Write-back stage
            if (opcode != 4'b1011) begin // Not STORE
                registers[MEM_WB_dest] <= MEM_WB_result;
            end
            MEM_WB_result <= EX_MEM_result;
            MEM_WB_dest <= EX_MEM_dest;
        end
    end
endmodule
