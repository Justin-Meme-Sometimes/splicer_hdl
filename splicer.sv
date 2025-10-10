`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/18/2025 12:45:45 PM
// Design Name: 
// Module Name: splicer
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


module splicer #(
    parameter DATA_WIDTH = 48,
    parameter FRAME_WIDTH = 64,
    parameter FRAME_HEIGHT = 48
)(
    input  logic                  aclk,
    input  logic                  aresetn,

    // AXI4-Stream Slave Interface (input)
    input  logic [DATA_WIDTH-1:0] s_axis_tdata,
    input  logic                  s_axis_tvalid,
    input  logic                  s_axis_tuser, //represents EOF
    output logic                  s_axis_tready,
    input  logic                  s_axis_tlast, //only represents EOL

    // AXI4-Stream Master Interface (output)
    output logic [DATA_WIDTH-1:0] m_axis_tdata,
    output logic                  m_axis_tvalid,
    input  logic                  m_axis_tready,
    output logic                  m_axis_tuser,
    output logic                  m_axis_tlast
);
    localparam FRAME_SIZE = (FRAME_WIDTH * FRAME_HEIGHT);
    logic [FRAME_SIZE-1:0][23:0] frame_buffer;
    logic [47:0] in_splicer, buffer_out;
    logic [FRAME_HEIGHT-1:0] frame_buffer_tlast;
    logic [15:0] count, col_count;
    logic done_counting, done_frame;
    logic output_fifo_empty, out_fifo_full;
    logic in_we, in_re, out_we, out_re;
    logic input_fifo_empty, input_fifo_full;
    logic stalled_out_in, stalled_out_out;
    logic started, done; //represent SOF and EOF
    logic start_counting;

    // assign R0 = s_axis_tdata[47:40];
    // assign G0 = s_axis_tdata[39:32];
    // assign B0 = s_axis_tdata[31:24];

    // assign R1 = s_axis_tdata[23:16];
    // assign G1 = s_axis_tdata[15:8];
    // assign B1 = s_axis_tdata[7:0];
    // Simple passthrough: valid when input is valid, ready when output is ready
    // always_ff @(posedge aclk) begin
    //     if (!aresetn) begin
    //         m_axis_tdata  <= '0;
    //         m_axis_tvalid <= 1'b0;
    //         m_axis_tlast  <= 1'b0;
    //     end else begin
    //         if (s_axis_tvalid && s_axis_tready) begin
    //             m_axis_tdata  <= s_axis_tdata;
    //             m_axis_tvalid <= 1'b1;
    //             //m_axis_tlast  <= s_axis_tlast;
    //         end else if (m_axis_tvalid && m_axis_tready) begin
    //             // transaction accepted by downstream, clear valid
    //             m_axis_tvalid <= 1'b0;
    //         end
    //     end
    // end


    always_ff @(posedge aclk) begin //this takes a stream for a buffer
        if(!aresetn) begin
           frame_buffer <= '{default:'0};
           count <= 0;
           col_count <= 0;
        end else begin
            if(count < FRAME_SIZE && started) begin
                count <= count + 2;
                done_counting <= 0;
            end else begin
                count <= 0;
                done_counting <= 1;
            end
            if(col_count < FRAME_WIDTH && (started || out_re)) begin
                col_count <= col_count + 2;
            end else begin
                m_axis_tlast <= 1; 
                col_count <= 0;
            end
            if(s_axis_tvalid && started && !stalled_out_out) begin
                frame_buffer[count] <=  in_splicer[23:0];
                frame_buffer[count+1] <= in_splicer[47:24];
            end
            else if(done_counting && m_axis_tready && !stalled_out_out) begin //this counts down
                buffer_out[23:0] <= frame_buffer[count];
                buffer_out[47:24] <= frame_buffer[count + 1];
            end
        end
    end

    fifo #(.WIDTH(48), .ROW_SIZE(1), .DEPTH(FRAME_SIZE*2)) input_fifo  (    .clock(aclk), 
                                                                            .reset_n(aresetn),
                                                                            .data_in(s_axis_tdata), 
                                                                            .data_out(in_splicer), 
                                                                            .we(in_we), 
                                                                            .re(in_re), 
                                                                            .full(input_fifo_full), 
                                                                            .empty(input_fifo_empty));

    fifo #(.WIDTH(48), .ROW_SIZE(1), .DEPTH(FRAME_SIZE*2)) output_fifo (    .clock(aclk), 
                                                                            .reset_n(aresetn),
                                                                            .data_in(buffer_out), 
                                                                            .data_out(m_axis_tdata), 
                                                                            .we(out_we), 
                                                                            .re(out_re), 
                                                                            .full(output_fifo_full), 
                                                                            .empty(output_fifo_empty));
    in_splcier_fsm in_fsm_1 (   .aclk(aclk), 
                                .aresetn(aresetn), 
                                .stalled_in(stalled_in), 
                                .input_fifo_empty(input_fifo_empty), 
                                .done_counting(done_counting), 
                                .stalled_out(stalled_out_in), 
                                .start_counting(start_counting), 
                                .in_re(in_re));

    out_splcier_fsm out_fsm_1 ( .aclk(aclk), 
                                .aresetn(aresetn), 
                                .output_fifo_full(output_fifo_full), 
                                .done_counting_empty(done_counting_empty), 
                                .m_axis_tready(m_axis_tready), 
                                .stalled_out(stalled_out_out), 
                                .out_re(out_re), 
                                .m_axis_tvalid(m_axis_tvalid), 
                                .m_axis_tuser(m_axis_tuser));

    s_sync_fsm sync_fsm_in (    .aclk(aclk), 
                                .aresetn(aresetn), 
                                .input_fifo_full(input_fifo_full), 
                                .s_axis_tuser(s_axis_tuser), 
                                .s_axis_tvalid(s_axis_tvalid), 
                                .done_frame(done_frame), 
                                .in_we(in_we), 
                                .stalled_in(stalled_in), 
                                .started(started), 
                                .s_axis_tready(s_axis_tready));

    m_sync_fsm sync_fsm_out (   .aclk(aclk), 
                                .aresetn(aresetn), 
                                .output_fifo_empty(output_fifo_empty), 
                                .done_counting(done_counting), 
                                .m_axis_tready(m_axis_tready), 
                                .stalled_out(stalled_out), 
                                .out_re(out_re), 
                                .m_axis_tvalid(m_axis_tvalid), 
                                .m_axis_tuser(m_axis_tuser));

    // Ready/Valid handshake
    assign s_axis_tready = m_axis_tready || !m_axis_tvalid;
    assign in_splicer = s_axis_tdata;
endmodule


module s_sync_fsm(
    input logic aclk,
    input logic aresetn,
    input logic input_fifo_full,
    input logic s_axis_tuser,
    input logic s_axis_tvalid,
    input logic done_frame,
    output logic in_we,
    output logic stalled_in,
    output logic started,
    output logic s_axis_tready);

    enum {IDLE, RECIEVING} current_state, next_state;

    always_ff @(posedge aclk) begin
        if(!aresetn) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin
        next_state = current_state;
        unique case (current_state)
            IDLE: begin
                if(s_axis_tuser && !input_fifo_full) begin
                    started = 1;
                    stalled_in = 0;
                    s_axis_tready = 1;
                    in_we = 1;
                    next_state = RECIEVING;
                end else begin
                    started = 0;
                    stalled_in = 0;
                    s_axis_tready = 0;
                    in_we = 0;
                    next_state =  IDLE;
                end
            end
            RECIEVING: begin
                if(!input_fifo_full && !done_frame) begin
                    s_axis_tready = 1;
                    stalled_in = 0;
                    started = 1;
                    in_we = 1;
                    next_state = RECIEVING;
                end else if(input_fifo_full && !done_frame) begin
                    s_axis_tready = 0;
                    stalled_in = 1;
                    started = 1;
                    in_we = 0;
                    next_state = RECIEVING;
                end else if(done_frame) begin
                    s_axis_tready = 0;
                    started = 0;
                    stalled_in = 0;
                    in_we = 0;
                    next_state = IDLE;
                end
            end        
        endcase
    end
endmodule


module m_sync_fsm(
    input logic aclk,
    input logic aresetn,
    input logic output_fifo_empty,
    input logic done_counting,
    input  logic m_axis_tready,
    output logic stalled_out,
    output logic out_re,
    output logic m_axis_tvalid,
    output logic m_axis_tuser);

    enum logic [1:0] {IDLE, SENDING} current_state, next_state;

    always_ff @(posedge aclk) begin
        if(!aresetn) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin
        next_state = current_state;
        unique case (current_state)
            IDLE: begin
                if(!output_fifo_empty && m_axis_tready) begin
                    next_state = SENDING;
                    m_axis_tuser = 1;
                    m_axis_tvalid = 1;
                    out_re = 1;
                end else begin
                    next_state = IDLE;
                    m_axis_tuser = 0;
                    m_axis_tvalid = 0;
                    out_re = 0;
                end
                stalled_out = 0;
            end
            SENDING: begin
                if(done_counting) begin //wrong
                    m_axis_tuser = 0;
                    m_axis_tvalid = 0;
                    stalled_out = 0;
                    out_re = 0;
                    next_state = IDLE;
                end else if(!output_fifo_empty && m_axis_tready) begin
                    m_axis_tuser = 0;
                    m_axis_tvalid = 1;
                    stalled_out = 0;
                    out_re = 1;
                    next_state = SENDING;
                end else if(output_fifo_empty || !m_axis_tready) begin
                    m_axis_tuser = 0;
                    m_axis_tvalid = 1;
                    stalled_out = 1;
                    out_re = 0;
                    next_state = SENDING;
                end
            end    
        endcase
    end
endmodule

module in_splcier_fsm(
    input logic aclk,
    input logic aresetn,
    input logic stalled_in,
    input logic input_fifo_empty,
    input logic done_counting,
    output logic stalled_out,
    output logic start_counting,
    output logic in_re);

    enum logic [1:0] {IDLE, SEND_FROM_FIFO} current_state, next_state;

    always_ff @(posedge aclk) begin
        if(!aresetn) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin
        next_state = current_state;
        unique case (current_state)
            IDLE: begin
                if(!input_fifo_empty) begin
                    next_state = SEND_FROM_FIFO;
                    in_re = 1;
                    start_counting = 1;
                end else begin
                    next_state = IDLE;
                    in_re = 0;
                    start_counting = 0;
                end
                stalled_out = 0;
            end
            SEND_FROM_FIFO: begin
                if(done_counting) begin
                    stalled_out = 0;
                    start_counting = 1;
                    in_re = 0;
                    next_state = IDLE;
                end else if(!input_fifo_empty && !done_counting) begin
                    stalled_out = 0;
                    start_counting = 1;
                    in_re = 1;
                    next_state = SEND_FROM_FIFO;
                end else if(input_fifo_empty || stalled_in) begin
                    stalled_out = 1;
                    in_re = 0;
                    start_counting = 1;
                    next_state = SEND_FROM_FIFO;
                end
            end    
        endcase
    end
endmodule

module out_splcier_fsm(
    input logic aclk,
    input logic aresetn,
    input logic output_fifo_full,
    input logic done_counting_full,
    input logic done_counting_empty,
    input  logic m_axis_tready,
    output logic stalled_out,
    output logic out_we,
    output logic m_axis_tvalid,
    output logic m_axis_tuser);

    enum logic [1:0] {IDLE, SEND_FROM_SPLICER} current_state, next_state;

    always_ff @(posedge aclk) begin
        if(!aresetn) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin
        next_state = current_state;
        unique case (current_state)
            IDLE: begin
                if(done_counting_full) begin
                    next_state = SEND_FROM_SPLICER;
                    // m_axis_tuser = 1;
                    // m_axis_tvalid = 1;
                    out_we = 1;
                end else begin
                    next_state = IDLE;
                    // m_axis_tuser = 0;
                    // m_axis_tvalid = 0;
                    out_we = 0;
                end
                stalled_out = 0;
            end
            SEND_FROM_SPLICER: begin
                if(done_counting_full) begin
                    // m_axis_tuser = 0;
                    // m_axis_tvalid = 0;
                    stalled_out = 0;
                    out_we = 0;
                    next_state = IDLE;
                end else if(!output_fifo_full && m_axis_tready) begin
                    // m_axis_tuser = 0;
                    // m_axis_tvalid = 1;
                    stalled_out = 0;
                    out_we = 1;
                    next_state = SEND_FROM_SPLICER;
                end else if(output_fifo_full || !m_axis_tready) begin
                    // m_axis_tuser = 0;
                    // m_axis_tvalid = 1;
                    stalled_out = 1;
                    out_we = 0;
                    next_state = SEND_FROM_SPLICER;
                end
            end    
        endcase
    end
endmodule