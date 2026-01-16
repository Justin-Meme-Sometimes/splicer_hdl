`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/19/2025 05:22:41 PM
// Design Name: 
// Module Name: fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fifo #(parameter WIDTH=32,
parameter ROW_SIZE=3,
parameter DEPTH=4) (
input logic              clock, reset_n,
input logic              [ROW_SIZE-1:0][WIDTH-1:0] data_in,
input logic              we, re,
output logic             [ROW_SIZE-1:0][WIDTH-1:0] data_out,
output logic             full, empty);

    localparam FIFO_LENGTH = $clog2(DEPTH)-1;
    (* ram_style = "block" *) logic[WIDTH-1:0][ROW_SIZE-1:0] Q[DEPTH];
    logic [FIFO_LENGTH:0] putPtr, getPtr; // pointers wrap automatically
    logic [FIFO_LENGTH:0] count;

    assign empty = (putPtr == getPtr);
    assign full  =  (putPtr[FIFO_LENGTH ^ getPtr[FIFO_LENGTH]]) && (putPtr[FIFO_LENGTH-1:0] == getPtr[FIFO_LENGTH-1:0]);

    always_comb begin
        if(!(empty)) begin
            data_out = {Q[getPtr]};
        end
    end

    always_ff @(posedge clock, negedge reset_n) begin
        if (!reset_n) begin
            count <= '0;
            getPtr <= 0;
            putPtr <= 0;
        end else begin
            if(we && re && (!empty) && (!full)) begin //we want to red and write at 
                Q[putPtr] <= data_in;                  //the same time 
                getPtr <= getPtr + 1;
                putPtr <= putPtr + 1;
            end
            else if(re && !(empty)) begin           //we just want to read and update
                getPtr <= getPtr + 1;                 //counters
                count <= count - 1;
            end
            else if (we && !(full)) begin          //we just want to read
                Q[putPtr] <= data_in;
                putPtr <= putPtr + 1;
                count <= count + 1;
            end
        end
    end

endmodule : fifo


// module for FIFO queue 
module FIFO #(parameter WIDTH=32, DEPTH=4) (
    input logic                  clock, reset_n,
    input logic [WIDTH-1:0]      data_in,
    input logic                  we, re,
    
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
      if (re && !empty) begin
        data_out = Q[re_ptr];
      end else begin
        data_out  = 0;
      end
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



