`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Simple Testbench for Splicer module
//////////////////////////////////////////////////////////////////////////////////

module splicer_tb();
    // Parameters
    parameter DATA_WIDTH = 48;
    parameter FRAME_WIDTH = 10;
    parameter FRAME_HEIGHT = 10;
    parameter END_OF_LINE = 10;
    parameter CLK_PERIOD = 10;
    
    // Testbench signals
    logic aclk;
    logic aresetn;
    
    // AXI4-Stream Slave Interface (input)
    logic [DATA_WIDTH-1:0] s_axis_tdata;
    logic s_axis_tvalid;
    logic s_axis_tuser;
    logic s_axis_tready;
    logic s_axis_tlast;
    
    // AXI4-Stream Master Interface (output)
    logic [DATA_WIDTH-1:0] m_axis_tdata;
    logic m_axis_tvalid;
    logic m_axis_tready;
    logic m_axis_tuser;
    logic m_axis_tlast;
    int i;
    int end_of_frame;

    
    // Instantiate the splicer
    splicer #(
        .DATA_WIDTH(DATA_WIDTH),
        .FRAME_WIDTH(FRAME_WIDTH),
        .FRAME_HEIGHT(FRAME_HEIGHT)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tuser(s_axis_tuser),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tuser(m_axis_tuser),
        .m_axis_tlast(m_axis_tlast)
    );
    
    // Clock generation
    initial begin
        aclk = 0;
        forever #10 aclk = ~aclk;
    end
    
    // Main test
    initial begin
        $display("Starting Splicer Testbench...\n");
        
        // Initialize
        aresetn <= 0;
        @(posedge aclk);
        aresetn <= 1;
        @(posedge aclk);
        s_axis_tdata <= '0;
        end_of_frame = (FRAME_WIDTH * FRAME_HEIGHT)/2;
        s_axis_tvalid <= 0;
        s_axis_tready <= 1;
        s_axis_tuser <= 0;
        s_axis_tlast <= 0;
        m_axis_tready <= 1;
        @(posedge aclk);
        // Send some pixel data
        $display("Sending pixel data...");
        
        // Send 10 pixel pairs
        for (i = 0; i < end_of_frame; i++) begin
            s_axis_tdata <= $urandom() | ($urandom() << 16) | ($urandom() << 32);
            s_axis_tvalid  <= 1;
            s_axis_tuser <= (i == 0) ? 1 : 0;  // SOF on first
            s_axis_tlast <=  (i == end_of_frame) ? 1 : 0;  // EOL on last
            @(posedge aclk);
            // s_axis_tvalid <= 0;
            // s_axis_tuser <= 0;
            // s_axis_tlast <= 0;
        end
        
        s_axis_tvalid <= 0;
        
        // Wait and observ
        for(int i = 0; i < 20; i++) begin
            @(posedge aclk);
        end
        
        $display("Test complete.\n");
        $finish;
    end
    
    // Monitor outputs
    always @(posedge aclk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            $display("OUT: Data=0x%h, TUSER=%b, TLAST=%b", 
                     m_axis_tdata, m_axis_tuser, m_axis_tlast);
        end
    end
    
    // Timeout
    // initial begin
    //     for(int i = 0; i < 1000; i++) begin
    //         @(posedge aclk);
    //     end
    //     $display("Timeout!");
    //     $finish;
    // end
    
endmodule