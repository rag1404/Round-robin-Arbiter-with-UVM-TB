// Code your design here
// Code your design here
module fixed_arb (input [2:0] req, output reg [2:0] grant);
  
  always @ (req)
 // case (1'b1) : 
    if (req[0])
      grant = 3'b001;
  else if (req[1])
       grant = 3'b010;
  else if (req[2])
      grant = 3'b100;
  //end
  //endcase
  
endmodule


module round_robin_arbiter (input clk,rst,[2:0] req, output [2:0] grant);
  
  logic [2:0] local_grant,raw_grant;
  logic [2:0] mask_req ;
  logic [2:0] mask;
  
  always @ (posedge clk or negedge rst) begin
    if (!rst)
      mask <= 3'b111;
    else if (grant[0])
      mask <= 3'b110;
    else if (grant[1])
      mask <= 3'b100;
    else if (grant [2])
      mask <= 3'b000;
    
  end
  
  
  assign mask_req = req & mask;
  
  fixed_arb f1(.req(mask_req),.grant(local_grant));
  fixed_arb f2(.req(req),.grant(raw_grant));
  
  assign grant = (mask == 3'b000) ? raw_grant : local_grant;
  
  
endmodule