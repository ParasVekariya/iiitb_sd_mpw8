// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);
    wire clk;
    wire reset;
    wire din;
    wire dout;

    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;

    // IO
    assign clk = wb_clk_i;
    assign reset = wb_rst_i;
    assign din = io_in[37];
    assign dout = io_out[37];
    assign io_oeb = 0;

    // IRQ
    assign irq = 3'b000;	// Unused

    iiitb_sdMoore instance( clk, reset, din, dout);

endmodule

module iiitb_sdMoore(input clk,input reset,input din,output reg dout);

  //dout   --> for storing the output
  //din    --> for giving the inputs to thed sequence Detector
  //reset  --> for resting the detector
  //clock  --> for providing the clock to the design
  
  //Defining different steps
  parameter S0 = 3'b000;  // state Zero
  parameter S1 = 3'b001;  // state One
  parameter S2 = 3'b010;  // state OneZero
  parameter S3 = 3'b011;  // state OneZeroZero
  parameter S4 = 3'b100;  // state OneZeroZeroOne

  reg [2:0] state;  //for storing current states and moving to the next state.

  //triggering happens only at posedge of the clock or when the reset button is hit.
  always @(posedge clk or posedge reset) begin
    if(reset) begin
      dout <= 1'b0; 
      state <= S0;
    end
    else begin
      case(state)
        S0: begin
          dout <=1'b0;
          if(din)
            state <= S1;
        end
        S1: begin
          dout <= 1'b0;
          if(~din)
            state <= S2;
        end
        S2: begin
          dout <= 1'b0;
          if(~din)
            state <= S3;
          else
            state <= S1;
        end
        S3: begin
          dout <= 1'b0;
          if(din)
            state <= S4;
          else
            state <= S0;
        end
        S4: begin
          dout <= 1'b1;
          if(din)
            state <= S1;
          else
            state <= S2;
        end
      endcase
    end
  end


endmodule

`default_nettype wire
