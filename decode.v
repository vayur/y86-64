// Clocked register with enable signal and synchronous reset
 // Default width is 8, but can be overriden
 module cenrreg(out, in, enable, reset, resetval, clock);
 parameter width = 8;
 input enable,reset,clock;
 input [width-1:0] in,resetval;
 output [width-1:0] out;
 reg [width-1:0] out;
 always @(posedge clock) 
    begin
    if (reset)
        out <= resetval;
    else if (enable)
        out <= in;
    end
 endmodule
 // Pipeline register. Uses reset signal to inject bubble
 // When bubbling, must specify value that will be loaded
 module preg(out, in, stall, bubble, bubbleval, clock);

 parameter width = 8;
 output [width-1:0] out;
 input stall, bubble,clock;
 input [width-1:0] in,bubbleval;
 cenrreg #(width) r(out, in, ~stall, bubble, bubbleval, clock);
 endmodule


 // Register file
 module regfile(dstE, valE, dstM, valM, srcA, valA, srcB, valB, reset, clock, rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r10, r11, r12, r13, r14);
output [63:0] valB,valA,rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r10, r11, r12, r13, r14;
 input [ 3:0] srcB,srcA,dstE,dstM;
 input [63:0] valE,valM;
 input clock,reset; // Set registers to 0
 // Define names for registers used in HCL code

parameter RRNONE = 4'b1111,R14 = 4'b1110,R13 = 4'b1101,R12 = 4'b1100,R11 = 4'b1011,R10 = 4'b1010,R9 = 4'b1001,R8 = 4'b1000,RRDI = 4'b0111,RRSI = 4'b0110,RRBP = 4'b0101,RRSP = 4'b0100,RRBX = 4'b0011,RRDX = 4'b0010,RRAX = 4'b0000,RRCX = 4'b0001;

 
 // Input write controls for each register
 wire rax_iw, rcx_iw, rdx_iw, rbx_iw, rsp_iw, rbp_iw, rsi_iw, rdi_iw, r8_iw, r9_iw, r10_iw, r11_iw, r12_iw, r13_iw, r14_iw;
// Input data for each register
 wire [63:0] rax_id, rcx_id, rdx_id, rbx_id, rsp_id, rbp_id, rsi_id, rdi_id, r8_id, r9_id, r10_id, r11_id, r12_id, r13_id, r14_id;

 // Implement with clocked registers
 reg temp = 1'b0;
 cenrreg #(64) a(r8, r8_id, r8_iw, temp, 64'b0, clock);
 cenrreg #(64) b(r9, r9_id, r9_iw, temp, 64'b0, clock);
 cenrreg #(64) c(r14, r14_id, r14_iw, temp, 64'b0, clock);
 cenrreg #(64) d(rdx, rdx_id, rdx_iw, temp, 64'b0, clock);
 cenrreg #(64) e(rbx, rbx_id, rbx_iw, temp, 64'b0, clock);
 cenrreg #(64) f(rsp, rsp_id, rsp_iw, temp, 64'b0, clock);
 cenrreg #(64) g(r12, r12_id, r12_iw, temp, 64'b0, clock);
 cenrreg #(64) h(r13, r13_id, r13_iw, temp, 64'b0, clock);
 cenrreg #(64) i(rax, rax_id, rax_iw, temp, 64'b0, clock);
 cenrreg #(64) j(rcx, rcx_id, rcx_iw, temp, 64'b0, clock);
 cenrreg #(64) k(rbp, rbp_id, rbp_iw, temp, 64'b0, clock);
 cenrreg #(64) l(rsi, rsi_id, rsi_iw, temp, 64'b0, clock);
 cenrreg #(64) m(rdi, rdi_id, rdi_iw, temp, 64'b0, clock);
 cenrreg #(64) n(r10, r10_id, r10_iw, temp, 64'b0, clock);
 cenrreg #(64) o(r11, r11_id, r11_iw, temp, 64'b0, clock);

 // Reads occur like combinational logic
 assign valA =
 srcA == RRAX ? rax : srcA == RRCX ? rcx : srcA == RRDX ? rdx : srcA == RRBX ? rbx : srcA == RRSP ? rsp : srcA == RRBP ? rbp : srcA == RRSI ? rsi : srcA == RRDI ? rdi : srcA == R8 ? r8 : srcA == R9 ? r9 : srcA == R10 ? r10 : srcA == R11 ? r11 : srcA == R12 ? r12 : srcA == R13 ? r13 : srcA == R14 ? r14 : 0;

 assign valB =
 srcB == RRAX ? rax : srcB == RRCX ? rcx : srcB == RRDX ? rdx : srcB == RRBX ? rbx : srcB == RRSP ? rsp : srcB == RRBP ? rbp : srcB == RRSI ? rsi : srcB == RRDI ? rdi : srcB == R8 ? r8 : srcB == R9 ? r9 : srcB == R10 ? r10 : srcB == R11 ? r11 : srcB == R12 ? r12 : srcB == R13 ? r13 : srcB == R14 ? r14 : 0;


 assign rdi_id = dstM == RRDI ? valM : valE;
 assign r8_id = dstM == R8 ? valM : valE;
 assign rcx_id = dstM == RRCX ? valM : valE;
 assign rax_iw = dstM == RRAX | dstE == RRAX;
 assign r13_iw = dstM == R13 | dstE == R13;
 assign rax_id = dstM == RRAX ? valM : valE;
 assign rbp_id = dstM == RRBP ? valM : valE;
 assign r13_id = dstM == R13 ? valM : valE;
 assign r9_id = dstM == R9 ? valM : valE;
 assign r12_id = dstM == R12 ? valM : valE;
 assign rsi_id = dstM == RRSI ? valM : valE;
 assign r11_id = dstM == R11 ? valM : valE;
 assign rdx_id = dstM == RRDX ? valM : valE;
 assign r10_id = dstM == R10 ? valM : valE;
 assign rsp_id = dstM == RRSP ? valM : valE;
 assign rbx_id = dstM == RRBX ? valM : valE;
 assign r14_id = dstM == R14 ? valM : valE;
 assign rbp_iw = dstM == RRBP | dstE == RRBP;
 assign rdx_iw = dstM == RRDX | dstE == RRDX;
 assign r9_iw = dstM == R9 | dstE == R9;
 assign rcx_iw = dstM == RRCX | dstE == RRCX;
 assign rsi_iw = dstM == RRSI | dstE == RRSI;
 assign rbx_iw = dstM == RRBX | dstE == RRBX;
 assign rsp_iw = dstM == RRSP | dstE == RRSP;
 assign r10_iw = dstM == R10 | dstE == R10;
 assign r11_iw = dstM == R11 | dstE == R11;
 assign rdi_iw = dstM == RRDI | dstE == RRDI;
 assign r8_iw = dstM == R8 | dstE == R8;
 assign r14_iw = dstM == R14 | dstE == R14;
 assign r12_iw = dstM == R12 | dstE == R12;

 endmodule