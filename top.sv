// `timescale 1ns / 1ps
// //////////////////////////////////////////////////////////////////////////////////
// // Company: 
// // Engineer: 
// // 
// // Create Date: 10/24/2025
// // Design Name: Splicer Top
// // Module Name: top_splicer
// // Target Devices: ZCU104 (XCZU7EV-2FFVC1156)
// // Description: Synthesis top-level wrapper for the splicer pipeline
// // 
// //////////////////////////////////////////////////////////////////////////////////

// module top_splicer #(
//     parameter DATA_WIDTH  = 48,
//     parameter FRAME_WIDTH = 64,
//     parameter FRAME_HEIGHT = 48
// )(
//     input  logic                   aclk,
//     input  logic                   aresetn,

//     // AXI4-Stream slave interface (input)
//     input  logic [DATA_WIDTH-1:0]  s_axis_tdata,
//     input  logic                   s_axis_tvalid,
//     input  logic                   s_axis_tuser,
//     input  logic                   s_axis_tlast,
//     output logic                   s_axis_tready,

//     // AXI4-Stream master interface (output)
//     output logic [DATA_WIDTH-1:0]  m_axis_tdata,
//     output logic                   m_axis_tvalid,
//     output logic                   m_axis_tuser,
//     output logic                   m_axis_tlast,
//     input  logic                   m_axis_tready
// );

//     // ===========================================================
//     // Instance of core splicer module
//     // ===========================================================
//     splicer #(
//         .DATA_WIDTH(DATA_WIDTH),
//         .FRAME_WIDTH(FRAME_WIDTH),
//         .FRAME_HEIGHT(FRAME_HEIGHT)
//     ) u_splicer (
//         .aclk(aclk),
//         .aresetn(aresetn),

//         .s_axis_tdata(s_axis_tdata),
//         .s_axis_tvalid(s_axis_tvalid),
//         .s_axis_tuser(s_axis_tuser),
//         .s_axis_tready(s_axis_tready),
//         .s_axis_tlast(s_axis_tlast),

//         .m_axis_tdata(m_axis_tdata),
//         .m_axis_tvalid(m_axis_tvalid),
//         .m_axis_tready(m_axis_tready),
//         .m_axis_tuser(m_axis_tuser),
//         .m_axis_tlast(m_axis_tlast)
//     );

// endmodule
