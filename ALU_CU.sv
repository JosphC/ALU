`include "divider.sv"
`include "multiplier.sv"
`include "parallel_adder.sv"
`include "AND_gate.sv"
`include "OR_gate.sv"
`include "NOT_gate.sv"
`include "Rshift.sv"
`include "Lshift.sv"
`include "subtractor.sv"
`include "adder.sv"


typedef enum bit[3:0] {
    //fsm signals
    NOP  = 4'b0000, // no operation
    // for combinatorial modules (all except mult and div)
    // there is necessary 4 clocks (which simulates mult and div)
    RD1  = 4'b0001, // read first number from ibus (for operations except mult and div)
    RD2  = 4'b0010, // read second number from ibus
    //op signals
    ADD  = 4'b0011,
    SUB  = 4'b0100,
    SHR  = 4'b0101,
    SHL  = 4'b0110,
    AND  = 4'b0111,
    OR   = 4'b1000,
    NEG  = 4'b1001,
    MUL  = 4'b1010,
    DIV  = 4'b1011
}op_e;

module alu_control_unit (
    input       clk, rst_b,
    input  op_e opcode,
    output reg  csum, csub, cdiv, cshr, 
                cshl, cand, cor, cmul, cneg,
    output reg  rd1, rd2
);
    op_e state, next;

    always @(posedge clk, negedge rst_b) begin
        if(!rst_b) state <= NOP;
        else       state <= next;
    end

    always @* begin
        next = NOP;
        case(state)
            NOP           : if     (opcode == NOP)   next = NOP;
                            else if(opcode == MUL) 
                            begin 
                                                     next = opcode; 
                                                     cmul = 1'b1; 
                            end
                            else if(opcode == DIV)   
                            begin                    next = opcode;  
                                                     cdiv = 1'b1; 
                            end

                            else                     
                            begin 
                                                     next = RD1; 
                                                     rd1 = 1'b1; // we activate read first ibus based on next state
                                                                 // to accelerate with one clock read from ibus
                            end

            RD1           : begin 
                                                     next = RD2; 
                                                     rd2 = 1'b1; // we do the same here
                                                                 // so if it is not mult or div operation, then we know it is a simple
                                                                 // one so we can read the values no matter what operation we will perform
                            end

            RD2           : if    ((opcode >= ADD &&
                                    opcode <= NEG))  next = opcode;
                            else                     next = NOP;

            ADD, SUB,
            SHR, SHL, 
            AND, OR,  NEG,
          	MUL, DIV:                          next = NOP;
        endcase

    end

    always @(posedge clk, negedge rst_b) begin
        { cor,  csum, csub, cdiv, cshr,
          cshl, cand, cmul, cneg, rd1, rd2 } <= 11'b0;

        case(next) 
            ADD : csum        <= 1'b1;
            SUB : csub        <= 1'b1;
            SHR : cshr        <= 1'b1;
            SHL : cshl        <= 1'b1;
            AND : cand        <= 1'b1;
            OR  : cor         <= 1'b1;
            NEG : cneg        <= 1'b1;
        endcase
    end
endmodule


module alu #(parameter WIDTH=32)(
    input                  clk, rst_b,
    input  wire[WIDTH-1:0] ibus,
    input  op_e            opcode,
    output wire [WIDTH-1:0] obus,
    output reg             fin
);

    reg csum, csub, cdiv, cshr,
        cshl, cand, cor,  cmul, cneg, rd1, rd2;
    
    reg fmul, fdiv;

    assign fin = (fmul | fdiv | csum | csub | cshr | cshl | cand | cor | cneg );


    reg [WIDTH:0] A, B;
  wire [WIDTH:0] R;



    always @(posedge clk) begin
        if(rd1)      A <= ibus;
        else if(rd2) B <= ibus;
    end


  
  assign obus = (csum | csub | cshr | cshl | cand | cor | cneg) ? R[WIDTH-1:0] : {WIDTH{1'bz}};
  

    alu_control_unit alu_cntrl(.clk,  .rst_b, .opcode, .rd1, .rd2,
                               .csum, .csub,  .cdiv, .cshr, 
                               .cshl, .cand,  .cor,  .cmul, .cneg);

    mult #(WIDTH) mul_unit(.clk, .rst_b, .bgn(cmul), .ibus, .obus, .fin(fmul));
    div  #(WIDTH) div_unit(.clk, .rst_b, .bgn(cdiv), .ibus, .obus, .fin(fdiv));
  	parallel_adder sum_unit(.a(A), .b(B), .cin(1'b0), .cout(), .load(csum), .sum(R));
  
  CSelA #(WIDTH) add_unit( .a(A[WIDTH-1:0]), .b(B[WIDTH-1:0]), .cin(1'b0), .load(csum), .sum(R[WIDTH-1:0]), .cout(), .overflow());
  
  BCD_sub #(WIDTH) sub_unit ( .x(A[WIDTH-1:0]), .y(B[WIDTH-1:0]), .load(csub), .borrow(), .diff(two));
  
    Rshift #(WIDTH) shr_unit ( .data_in(A[WIDTH-1:0]), .shift_amount(6'd4), .load(cshr), .data_out(R[WIDTH-1:0]));
  
    Lshift #(WIDTH) shl_unit ( .data_in(A[WIDTH-1:0]), .shift_amount(6'd4), .load(cshl), .data_out(R[WIDTH-1:0])); 
  
    AND_gate #(WIDTH) and_unit( .A(A[WIDTH-1:0]), .B(B[WIDTH-1:0]), .load(cand), .Out(R[WIDTH-1:0]));
  
  OR_gate #(WIDTH) or_unit( .A(A[WIDTH-1:0]), .B(B[WIDTH-1:0]), .load(cor), .Out(R[WIDTH-1:0]));
  
  NOT_gate #(WIDTH) neg_unit( .A(A[WIDTH-1:0]), .load(cneg), .Out(R[WIDTH-1:0]));


endmodule


  
