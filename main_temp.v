`include "execute.v"
`include "fetch.v"
`include "decode.v"

`include "memory.v"

module main(clock,W_stat);

    output [2:0] W_stat;
    input clock;
    
    
    parameter IHALT = 4'b0000;
    parameter INOP = 4'b0001;
    parameter IRRMOVQ = 4'b0010;
    parameter IIRMOVQ = 4'b0011;
    parameter IRMMOVQ = 4'b0100;
    parameter IMRMOVQ = 4'b0101;
    parameter IOPQ = 4'b0110;
    parameter IJXX = 4'b0111;
    parameter ICALL = 4'b1000;
    parameter IRET = 4'b1001;
    parameter IPUSHQ = 4'b1010;
    parameter IPOPQ = 4'b1011;
    parameter IIADDQ = 4'b1100;
    parameter ILEAVE = 4'b1101;
    parameter IPOP2 = 4'b1110;
    // Function codes
    parameter FNONE = 4'b0000;
    // Jump conditions
    parameter UNCOND = 4'b0000;
    // Register IDs
    parameter RRSP = 4'b0100;
    parameter RRBP = 4'b0101;
    parameter RNONE = 4'b1111;
    // ALU operations
    parameter ALUADD = 4'b0000;
    // Status conditions
    parameter SBUB = 3'b000;
    
    parameter SAOK = 3'b001;

    parameter SHLT = 3'b010;
    parameter SADR = 3'b011;
    parameter SINS = 3'b100;

    // Fetch stage signals
    wire [63:0] f_predPC, F_predPC, f_pc,f_valC,f_valP;
    wire [ 3:0] f_ic,f_ifun,f_rA,f_rB;
    wire f_ok,imem_error,need_regids,need_valC,instr_valid,F_st, F_bubble, F_reset;
    wire [ 2:0] f_stat;
    wire [7:0] f_ibyte;
    wire[71:0] f_ibytes;
    

    //decode
    
    wire [ 3:0] D_ic,D_ifun,D_rA,D_rB,d_dstE,d_dstM, d_srcA,d_srcB;
    wire D_st , D_bubble, D_reset;
    wire [ 2:0] D_stat;
    wire [63:0] D_pc,D_valC,D_valP,d_valA,d_valB,d_rvalA,d_rvalB;

    //memory
    wire [ 2:0] m_stat,M_stat;
    wire [63:0] M_pc,M_valE,M_valA,m_valM,mem_addr,mem_data;
    wire [ 3:0] M_ic,M_ifun, M_dstE,M_dstM;
    wire M_Cnd,mem_read,mem_write, dmem_error,M_st, M_bubble,M_reset,m_ok;

    //writeback
    wire [ 2:0] W_stat;
    wire [63:0] W_pc,W_valE,W_valM,w_valE,w_valM;
    wire [ 3:0] W_ic,W_dstE,W_dstM,w_dstE,w_dstM;
    wire W_st, W_bubble, resetting;

    assign resetting = 1;
    assign D_reset = 1; 
   //execute
    wire [ 2:0] E_stat,cc,new_cc;
    wire [63:0] E_valA,E_valC,E_valB,aluA,aluB,e_valE,e_valA,E_pc;
    wire [ 3:0] E_dstE,E_dstM,E_srcA,E_srcB,E_ic,E_ifun,e_dstE,alufun;
    wire set_cc,e_Cnd,E_st, E_bubble;


    //initialising

    assign aluA =
    E_ic == IRRMOVQ ? E_valA: E_ic == IOPQ ? E_valA : E_ic == IIRMOVQ ? E_valC: E_ic == IRMMOVQ ? E_valC: E_ic == IMRMOVQ ? E_valC : E_ic ==ICALL ? -8: E_ic == IPUSHQ ? -8 : E_ic == IRET ? 8: E_ic == IPOPQ ? 8 : 0;

    assign D_st =((E_ic == IMRMOVQ | E_ic == IPOPQ) & (E_dstM == d_srcA | E_dstM == d_srcB));
    assign D_bubble =(((E_ic == IJXX) & ~e_Cnd) | (~((E_ic == IMRMOVQ | E_ic ==IPOPQ) & (E_dstM == d_srcA | E_dstM == d_srcB)) & (IRET ==D_ic | IRET == E_ic | IRET == M_ic)));
    assign E_st =0;
    assign set_cc =(((E_ic == IOPQ) & ~(m_stat == SADR | m_stat == SINS | m_stat ==SHLT)) & ~(W_stat == SADR | W_stat == SINS | W_stat == SHLT));
    
    assign E_bubble =(((E_ic == IJXX) & ~e_Cnd) | ((E_ic == IMRMOVQ | E_ic == IPOPQ) & (E_dstM == d_srcA | E_dstM == d_srcB)));
    
    assign d_srcB =
    D_ic == IOPQ ? D_rB: D_ic == IRMMOVQ ? D_rB: D_ic == IMRMOVQ ? D_rB : D_ic == IPUSHQ ? RRSP: D_ic == IPOPQ ? RRSP: D_ic == ICALL ? RRSP: D_ic== IRET ? RRSP : RNONE;
    assign d_dstM =((D_ic == IMRMOVQ | D_ic == IPOPQ) ? D_rA : RNONE);
    assign imem_error = 1'b0;
    assign dmem_error = 1'b0;
    assign aluB =
    E_ic == IRMMOVQ ? E_valB: E_ic == IMRMOVQ ? E_valB: E_ic == IOPQ ? E_valB: E_ic== ICALL ? E_valB: E_ic == IPUSHQ ? E_valB: E_ic == IRET ? E_valB: E_ic == IPOPQ ? E_valB : E_ic == IRRMOVQ ? 0: E_ic == IIRMOVQ ? 0 : 0;
    
    assign d_valB =
    d_srcB == e_dstE ? e_valE : d_srcB == M_dstM ? m_valM : d_srcB== M_dstE ? M_valE : d_srcB == W_dstM ? W_valM : d_srcB ==W_dstE ? W_valE : d_rvalB;
    assign e_valA =E_valA;
    assign e_dstE =(((E_ic == IRRMOVQ) & ~e_Cnd) ? RNONE : E_dstE);
    assign d_dstE =
    D_ic == IRRMOVQ ? D_rB: D_ic == IIRMOVQ ? D_rB : D_ic == IOPQ ? D_rB : D_ic == IPUSHQ ? RRSP: D_ic == IPOPQ ? RRSP: D_ic == ICALL ? RRSP:  D_ic== IRET ? RRSP : RNONE;
    
    assign w_dstE =W_dstE;
    assign w_valE =W_valE;
     assign d_srcA =
    D_ic == IRRMOVQ ? D_rA: D_ic == IRMMOVQ ? D_rA: D_ic == IOPQ ? D_rA: D_ic== IPUSHQ ? D_rA : D_ic == IPOPQ ? RRSP: D_ic == IRET ? RRSP :RNONE;
    
    assign w_dstM =W_dstM;
    assign w_valM =W_valM;
    assign mem_addr =
    M_ic == IRMMOVQ ? M_valE : M_ic == IPUSHQ ? M_valE : M_ic == ICALL ? M_valE : M_ic == IMRMOVQ ? M_valE : M_ic == IPOPQ ? M_valA : M_ic == IRET ? M_valA : 0;
    
    assign f_pc =(((M_ic == IJXX) & ~M_Cnd) ? M_valA : (W_ic == IRET) ? W_valM :F_predPC);
    
    assign f_stat =(imem_error ? SADR : ~instr_valid ? SINS : (f_ic == IHALT) ? SHLT :SAOK);
    assign need_regids =
    f_ic == IRRMOVQ ? 1'b1: f_ic == IOPQ ? 1'b1: f_ic == IPUSHQ ? 1'b1: f_ic ==IPOPQ ? 1'b1: f_ic == IIRMOVQ ? 1'b1: f_ic == IRMMOVQ ? 1'b1: f_ic == IMRMOVQ ? 1'b1: 1'b0;
    assign alufun =((E_ic == IOPQ) ? E_ifun : ALUADD);
    assign instr_valid = 
    f_ic == INOP ? 1'b1 : f_ic == IHALT ? 1'b1 : f_ic == IRRMOVQ ? 1'b1 : f_ic == IIRMOVQ ? 1'b1 : f_ic == IRMMOVQ ? 1'b1 : f_ic == IMRMOVQ ? 1'b1 : f_ic == IOPQ ? 1'b1 : f_ic == IJXX ? 1'b1 : f_ic == ICALL ? 1'b1 : f_ic == IRET ? 1'b1 : f_ic == IPUSHQ ? 1'b1 : f_ic == IPOPQ ? 1'b1 : 1'b0;
    assign d_valA =
    D_ic == ICALL ? D_valP: D_ic == IJXX ? D_valP : d_srcA == e_dstE ? e_valE : d_srcA == M_dstM ? m_valM : d_srcA == M_dstE ? M_valE : d_srcA == W_dstM ? W_valM : d_srcA == W_dstE ? W_valE : d_rvalA;
    
    assign need_valC =(f_ic == IIRMOVQ | f_ic == IRMMOVQ | f_ic == IMRMOVQ | f_ic== IJXX | f_ic == ICALL);
    assign f_predPC =((f_ic == IJXX | f_ic == ICALL) ? f_valC : f_valP);
    assign M_st =0;
    assign M_bubble =((m_stat == SADR | m_stat == SINS | m_stat == SHLT) | (W_stat == SADR | W_stat == SINS | W_stat == SHLT));
    assign W_st =(W_stat == SADR | W_stat == SINS | W_stat == SHLT);
    assign W_bubble =0;
   
    
    assign mem_read =(M_ic == IMRMOVQ | M_ic == IPOPQ | M_ic == IRET);
    assign mem_write =(M_ic == IRMMOVQ | M_ic == IPUSHQ | M_ic == ICALL);
    assign m_stat =(dmem_error ? SADR : M_stat);

    assign F_bubble =0;
    assign F_st =(((E_ic == IMRMOVQ | E_ic == IPOPQ) & (E_dstM == d_srcA | E_dstM == d_srcB)) | (IRET == D_ic | IRET == E_ic | IRET == M_ic));
    
    
    assign Stat =((W_stat == SBUB) ? SAOK : W_stat);


    proggram #(64) F_predPC_reg(F_predPC, f_predPC, F_st, 64'b0, clock);
    // D Register
    proggram #(64) d1(D_pc, f_pc, D_st,   64'b0, clock);
    proggram #(64) d2(D_valP, f_valP, D_st, 64'b0, clock);
    proggram #(3) d3(D_stat, f_stat, D_st,   SBUB, clock);
    proggram #(4) d4(D_ic, f_ic, D_st,   INOP, clock);
    proggram #(4) d5(D_rB, f_rB, D_st, RNONE, clock);
    proggram #(64) d6(D_valC, f_valC, D_st, 64'b0, clock);
    proggram #(4) d7(D_ifun, f_ifun, D_st, FNONE, clock);
    proggram #(4) d8(D_rA, f_rA, D_st, RNONE, clock);
    // M Register

    proggram #(3) m1(M_stat, E_stat, M_st,  SBUB, clock);
    proggram #(4) m2(M_dstE, e_dstE, M_st,  RNONE, clock);
    proggram #(1) m3(M_Cnd, e_Cnd, M_st,  1'b0, clock);
    proggram #(64) m4(M_valE, e_valE, M_st,  64'b0, clock);
    proggram #(64) m5(M_valA, e_valA, M_st,  64'b0, clock);
    proggram #(4) m6(M_dstM, E_dstM, M_st,  RNONE, clock);
    proggram #(64) m7(M_pc, E_pc, M_st,  64'b0, clock);
    proggram #(4) m8(M_ic, E_ic, M_st,  INOP, clock);
    proggram #(4) m9(M_ifun, E_ifun, M_st,  FNONE, clock);
        
        // W Register

    proggram #(4) w1(W_ic, M_ic, W_st,  INOP, clock);
    proggram #(64) w2(W_valE, M_valE, W_st,  64'b0, clock);
    proggram #(64) w3(W_valM, m_valM, W_st,  64'b0, clock);
    proggram #(3) w4(W_stat, m_stat, W_st,  SBUB, clock);
    proggram #(64) w5(W_pc, M_pc, W_st,  64'b0, clock);
    proggram #(4) w6(W_dstE, M_dstE, W_st,  RNONE, clock);
    proggram #(4) w7(W_dstM, M_dstM, W_st,  RNONE, clock);
    
    // E Register
    proggram #(4) e1(E_srcA, d_srcA, E_st,  RNONE, clock);
    proggram #(4) e2(E_srcB, d_srcB, E_st,  RNONE, clock);
    proggram #(64) e3(E_valA, d_valA, E_st,  64'b0, clock);
    proggram #(3) e4(E_stat, D_stat, E_st,  SBUB, clock);
    proggram #(64) e5(E_pc, D_pc, E_st,  64'b0, clock);
    proggram #(4) e6(E_ic, D_ic, E_st,  INOP, clock);
    proggram #(4) e7(E_ifun, D_ifun, E_st,  FNONE, clock);
    proggram #(64) e8(E_valC, D_valC, E_st,  64'b0, clock);
    proggram #(64) e9(E_valB, d_valB, E_st,  64'b0, clock);
    proggram #(4) e10(E_dstE, d_dstE, E_st,  RNONE, clock);
    proggram #(4) e11(E_dstM, d_dstM, E_st,  RNONE, clock);


    


    InstructionMemory I(f_pc,f_ibyte[7:0],f_ibytes[71:0],imem_error);

    //fetch logic
    output [63:0] rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r10, r11, r12, r13, r14;
    split split(f_ibyte[7:0], f_ic, f_ifun);
    align align(f_ibytes[71:0], need_regids, f_rA, f_rB, f_valC);
    pc_increment pci(f_pc, need_regids, need_valC, f_valP);
    

    //decode logic
    regfile regf(w_dstE, w_valE, w_dstM, w_valM, d_srcA, d_rvalA, d_srcB, d_rvalB, resetting, clock, rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8, r9, r10, r11, r12, r13, r14);
    //execute logic
    reg temp2 = 1'b0;
    cond cond_check(E_ifun, cc, e_Cnd);
    alu alu(aluA, aluB, alufun, e_valE, new_cc);
    cc ccreg(cc, new_cc,set_cc, resetting, clock);
    //memory
    data_memory d(mem_addr,M_valA,mem_read,mem_write,mem_data,dmem_error);

    always @(posedge clock) begin
         $display("%b %b %b",f_ic,f_pc,e_valE);
        end
    
endmodule