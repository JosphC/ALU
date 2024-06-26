module Lshift #(parameter WIDTH=32)(
  input [WIDTH-1:0] data_in,       
    input [5:0] shift_amount,   
    input load,                 
  output reg [WIDTH-1:0] data_out  
);

  reg [WIDTH-1:0] shifted_data;  
integer i;
always @* begin
    if (load) begin
        shifted_data = data_in;
        for (i = 0; i < shift_amount; i = i + 1) begin
            shifted_data = {shifted_data[30:0], 1'b0}; 
        end
    end
end

always @* begin
    data_out = shifted_data;
end

endmodule