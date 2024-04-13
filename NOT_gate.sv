module NOT_gate #(parameter WIDTH=32)(
  input [WIDTH-1:0] A,   
    input load,       
  output [WIDTH-1:0] Out 
);

  reg [WIDTH-1:0] not_result;

always @* begin
    if (load) begin
        not_result = ~A;
    end
end

assign Out = not_result;

endmodule
