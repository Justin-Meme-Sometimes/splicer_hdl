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
    logic[WIDTH-1:0][ROW_SIZE-1:0] Q[DEPTH];
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
        end
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

endmodule : fifo
