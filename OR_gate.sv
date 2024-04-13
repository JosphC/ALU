module OR_gate #(parameter WIDTH=32)(
  input [WIDTH-1:0] A, 
  input [WIDTH-1:0] B,  
    input load,      
  output [WIDTH-1:0] Out 
);


  reg [WIDTH-1:0] or_result;

  always @(*) begin
    if (load) begin
        or_result = A | B;
    end
end

assign Out = or_result;

endmodule
