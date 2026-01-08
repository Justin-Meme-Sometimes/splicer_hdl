// module for FIFO queue 
module FIFO #(parameter WIDTH=32, DEPTH=4) (
    input logic                  clock, reset_n,
    input logic [WIDTH-1:0]      data_in,
    input     logic            we, re,
    
    output logic [WIDTH-1:0]     data_out,
    output  logic                full, empty);
  
    logic [DEPTH-1:0][WIDTH-1:0] Q;
  
    logic [15:0]    we_ptr, 
                    re_ptr; 
  
    logic [15:0]      count;
  
    // determine when queue empty/full
    assign empty = (count == 'd0);
    assign full = (count == DEPTH); 
  
    // implement combinational read 
    always_comb begin
      if (re && (!empty))
        data_out = Q[re_ptr];
    end 
  
    always_ff @(posedge clock, negedge reset_n) begin
      if (~reset_n) begin
        count <= 'd0;
        re_ptr <= 'd0;
        we_ptr <= 'd0;
        Q[we_ptr] <= Q[we_ptr];
        // data_out <= data_out;
      end
      else if (we & re && (!empty)) begin // implement concurrent re/we
          Q[we_ptr] <= data_in;
          we_ptr <= we_ptr + 1'd1;
          re_ptr <= re_ptr + 1'd1;
          count <= count;
          // data_out <= data_out;
        end 
      else if (we && (!full)) begin  // implement sequential writes
          Q[we_ptr] <= data_in;
          we_ptr <= we_ptr + 1'd1;
          count <= count + 1'd1;
          re_ptr <= re_ptr;
          // data_out <= data_out;
        end
      else if (re && (!empty)) begin // implement sequential queue removals
          re_ptr <= re_ptr + 1'd1;
          count <= count - 1'd1;
          Q[we_ptr] <= Q[we_ptr];
          we_ptr <= we_ptr;
          // data_out <= Q[re_ptr];
        end 
    end
  
  endmodule : FIFO