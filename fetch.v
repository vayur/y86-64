module InstructionMemory(f_pc,f_ibyte,f_ibytes,imem_error);
    input [63:0] f_pc;
    output reg[7:0] f_ibyte;
    output reg[71:0] f_ibytes;
    output reg imem_error;

    reg [7:0] instruction_mem [2047:0];

    initial 
        begin
            $readmemh("./rom.mem", instruction_mem);
            $display("init");
        end
    always @(f_pc)
    begin
        $display(instruction_mem[f_pc]);
        f_ibyte <= instruction_mem[f_pc];
        f_ibytes[71:64] <= instruction_mem[f_pc+1];
        f_ibytes[63:56] <= instruction_mem[f_pc+2];
        f_ibytes[55:48] <= instruction_mem[f_pc+3];
        f_ibytes[47:40] <= instruction_mem[f_pc+4];
        f_ibytes[39:32] <= instruction_mem[f_pc+5];
        f_ibytes[31:24] <= instruction_mem[f_pc+6];
        f_ibytes[23:16] <= instruction_mem[f_pc+7];
        f_ibytes[15:8] <= instruction_mem[f_pc+8];
        f_ibytes[7:0] <= instruction_mem[f_pc+9];

        imem_error <= (f_pc < 64'd0 || f_pc > 64'd2047 ) ? 1'b1:1'b0;
     
    end

endmodule
// Split instruction byte into icode and ifun fields 
module split(ibyte, icode, ifun);
input [7:0] ibyte;
output [3:0] icode,ifun;
assign icode = ibyte[7:4],ifun = ibyte[3:0];
endmodule

// Extract immediate word from 9 bytes of instruction
module align(ibytes, need_regids, rA, rB, valC);
input [71:0] ibytes;
input need_regids;
output [ 3:0] rA,rB;
output [63:0] valC;
assign rA = ibytes[71:68],rB = ibytes[67:64],valC = need_regids ? ibytes[63:0] : ibytes[71:8];
endmodule

// PC incrementer
module pc_increment(pc, need_regids, need_valC, valP);
input [63:0] pc;
input need_regids, need_valC;
output [63:0] valP;
assign valP = pc + 1 + 8*need_valC + need_regids;
endmodule