module proggram(out, in, stall, bubbleval, clock);

 parameter width = 8;
 output reg [width-1:0] out;
 input [width-1:0] in,bubbleval;
 input stall,clock;

 initial 
 begin 
     out <= bubbleval;
 end
 always @(posedge clock) 
    begin
    if (!stall)
        out <= in;
    end
 endmodule

// Execute Stage

// ALU
module alu(aluA, aluB, alucom, value_e, new_cc);
output [ 2:0] new_cc; // New values for ZF, SF, OF
output [63:0] value_e; // Data Output
input [63:0] aluA, aluB; // Data inputs
input [ 3:0] alucom; // ALU function



parameter ALUADD = 4'b0000,ALUSUB = 4'b0001,ALUXOR = 4'b0011,ALUAND = 4'b0010;
assign new_cc[0] = // OF
    alucom == ALUADD ? (aluA[63] == aluB[63]) & (aluA[63] != value_e[63]) : alucom == ALUSUB ? (~aluA[63] == aluB[63]) & (aluB[63] != value_e[63]) : 0;
assign new_cc[1] = value_e[63]; // SF
assign new_cc[2] = (value_e == 0); // ZF
assign value_e =
    alucom == ALUSUB ? aluB - aluA : alucom == ALUAND ? aluB & aluA : alucom == ALUXOR ? aluB ^ aluA : aluB + aluA;


endmodule

// Condition code register
module cc(cc, new_cc, set_cc, reset, clock);
input [2:0] new_cc;
input set_cc,clock,reset;
output[2:0] cc;
proggram #(3) c(cc, new_cc, ~set_cc, 3'b100, clock);
endmodule

// branch condition logic
module cond(icom, cc, Cnd);
input [3:0] icom;
input [2:0] cc;
wire of = cc[0];
wire sf = cc[1];
wire zf = cc[2];
output Cnd;


// Jump & move conditions.
parameter C_LE = 4'b0001,C_NE = 4'b0100,C_GE = 4'b0101,C_G = 4'b0110,C_E = 4'b0011,C_YES = 4'b0000,C_L = 4'b0010;

assign Cnd =
(icom == C_E & zf) | // ==
(icom == C_YES) | //
(icom == C_L & (sf^of)) | // <
(icom == C_G & (~sf^of)&~zf) |  // >
(icom == C_GE & (~sf^of)) | // >=
(icom == C_NE & ~zf) | // !=
(icom == C_LE & ((sf^of)|zf));  // <=
endmodule
