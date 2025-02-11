// Copyright 2022 Silicon Labs, Inc.
// Copyright 2022 OpenHW Group
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://solderpad.org/licenses/
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0


`default_nettype  none


module uvmt_cv32e40x_rvfi_assert
  import cv32e40x_pkg::*;
  import uvm_pkg::*;
  import uvma_rvfi_pkg::*;
  import uvme_cv32e40x_pkg::*;
#(
  parameter logic  CLIC,
  parameter int    CLIC_ID_WIDTH
)(
  input wire  clk_i,
  input wire  rst_ni,

  input wire             rvfi_valid,
  input wire [ 4:0]      rvfi_rs1_addr,
  input wire [ 4:0]      rvfi_rs2_addr,
  input wire [31:0]      rvfi_rs1_rdata,
  input wire [31:0]      rvfi_rs2_rdata,
  input wire [ 2:0]      rvfi_dbg,
  input wire [31:0]      rvfi_csr_dcsr_rdata,
  input wire rvfi_trap_t rvfi_trap,
  input wire rvfi_intr_t rvfi_intr,
  input wire [31:0]      rvfi_csr_mcause_wdata,
  input wire [31:0]      rvfi_csr_mcause_wmask,
  input wire             rvfi_dbg_mode,
  //TODO:INFO:silabs-robin should replace the above with the interface

  uvma_rvfi_instr_if_t  rvfi_if,

  input wire  writebuf_valid_i,
  input wire  writebuf_ready_o,

  uvmt_cv32e40x_support_logic_module_o_if_t  support_if
);

  default clocking @(posedge clk_i); endclocking
  default disable iff !rst_ni;

  string info_tag = "CV32E40X_RVFI_ASSERT";


  // Helper signals

  logic  was_rvfi_dbg_mode;
  always @(posedge clk_i, negedge rst_ni) begin
    if (rst_ni == 0) begin
      was_rvfi_dbg_mode <= 0;
    end else if (rvfi_valid) begin
      was_rvfi_dbg_mode <= rvfi_dbg_mode;
    end
  end


  // rs1/rs2 reset values

  property p_rs_resetvalue (addr, rdata);
    $past(rst_ni == 0)  ##0
    (rvfi_valid [->1])  ##0
    addr
    |->
    (rdata == 0);  // TODO:ropeders use "RF_REG_RV"
  endproperty : p_rs_resetvalue

  a_rs1_resetvalue: assert property (
    p_rs_resetvalue(rvfi_rs1_addr, rvfi_rs1_rdata)
  ) else `uvm_error(info_tag, "unexpected 'rs1' reset value");

  a_rs2_resetvalue: assert property (
    p_rs_resetvalue(rvfi_rs2_addr, rvfi_rs2_rdata)
  ) else `uvm_error(info_tag, "unexpected 'rs2' reset value");


  // RVFI debug cause matches dcsr debug cause

  a_dbg_cause_general: assert property (
    rvfi_valid  &&
    rvfi_dbg    &&
    !was_rvfi_dbg_mode
    |->
    (rvfi_dbg == rvfi_csr_dcsr_rdata[8:6])
  ) else `uvm_error(info_tag, "'rvfi_dbg' did not match 'dcsr.cause'");

  property  p_dbg_cause_n (n);
    rvfi_valid          &&
    rvfi_dbg            &&
    !was_rvfi_dbg_mode  &&
    (rvfi_csr_dcsr_rdata[8:6] == n)
    |->
    (rvfi_dbg == n);
  endproperty : p_dbg_cause_n

  a_dbg_cause_ebreak: assert property (
    p_dbg_cause_n(1)
  ) else `uvm_error(info_tag, "'rvfi_dbg' did not match 'dcsr.cause'");

  a_dbg_cause_trigger: assert property (
    p_dbg_cause_n(2)
  ) else `uvm_error(info_tag, "'rvfi_dbg' did not match 'dcsr.cause'");

  a_dbg_cause_haltreq: assert property (
    p_dbg_cause_n(3)
  ) else `uvm_error(info_tag, "'rvfi_dbg' did not match 'dcsr.cause'");

  a_dbg_cause_step: assert property (
    p_dbg_cause_n(4)
  ) else `uvm_error(info_tag, "'rvfi_dbg' did not match 'dcsr.cause'");


  // RVFI exception cause matches "mcause"

  wire logic [10:0]  rvfi_mcause_exccode;
  assign rvfi_mcause_exccode = (rvfi_csr_mcause_wdata & rvfi_csr_mcause_wmask);

  a_exc_cause: assert property (
    rvfi_valid           &&
    rvfi_trap.exception  &&
    !rvfi_dbg_mode
    |->
    (rvfi_trap.exception_cause == rvfi_mcause_exccode)
  ) else `uvm_error(info_tag, "'exception_cause' must match 'mcause'");


  // RVFI exception clears 'mcause.interrupt'

  a_exc_mcause: assert property (
    rvfi_valid  &&
    rvfi_trap.exception  &&
    !rvfi_dbg_mode
    |->
    (rvfi_csr_mcause_wmask[31] == 1'b 1)  &&
    (rvfi_csr_mcause_wdata[31] == 1'b 0)
  ) else `uvm_error(info_tag, "exceptions clear 'mcause.interrupt'");


  // RVFI interrupt cause matches legal causes

  if (!CLIC) begin: gen_legal_cause_clint
    a_irq_cause_clint: assert property (
      rvfi_valid  &&
      rvfi_intr.interrupt
      |->
      (rvfi_intr.cause inside {3, 7, 11, [16:31], [1024:1027]})
    ) else `uvm_error(info_tag, "unexpected interrupt cause");
  end : gen_legal_cause_clint

  if (CLIC) begin: gen_legal_cause_clic
    localparam logic [31:0]  MAX_CLIC_ID = 2**CLIC_ID_WIDTH - 1;

    a_irq_cause_clic: assert property (
      rvfi_valid  &&
      rvfi_intr.interrupt
      |->
      (rvfi_intr.cause inside {[0:MAX_CLIC_ID], [1024:1027]})
    ) else `uvm_error(info_tag, "unexpected interrupt cause");
  end : gen_legal_cause_clic


  // Reported interrupts are not made up

  a_intr_count: assert property (
    support_if.cnt_rvfi_irqs <= support_if.cnt_irq_ack
    //Note: This is not comprehensive proof
  ) else `uvm_error(info_tag, "rvfi_intr.interrupt over-reported");


  // Exceptions/Interrupts/Debugs have a cause

  a_exceptions_cause: assert property (
    rvfi_valid  &&
    rvfi_trap.exception
    |->
    rvfi_trap.exception_cause
  ) else `uvm_error(info_tag, "rvfi_trap exceptions must have a cause");

  if (!CLIC) begin: gen_clint_cause
    a_interrupts_cause: assert property (
      rvfi_valid  &&
      rvfi_intr
      |->
      rvfi_intr.cause
    ) else `uvm_error(info_tag, "rvfi_intr interrupts must have a cause");
  end : gen_clint_cause

  a_debug_cause: assert property (
    rvfi_valid  &&
    rvfi_trap.debug
    |->
    rvfi_trap.debug_cause
  ) else `uvm_error(info_tag, "rvfi_trap debugs must have a cause");


  // Synchronous handler had synchronous cause

  property p_sync_cause;
    logic  exception;
    (rvfi_valid, exception = rvfi_trap.exception)
    ##1
    (rvfi_valid [->1])
    |->
    (rvfi_intr.exception == exception)  ||
    rvfi_intr.interrupt
    ;
  endproperty : p_sync_cause

  a_sync_cause: assert property (
    p_sync_cause
  ) else `uvm_error(info_tag, "rvfi_intr.exception can't happen unannounced");


  // Trap handler is either sync/async

  a_handler_sync_or_async: assert property (
    rvfi_valid
    |->
    !(rvfi_intr.exception && rvfi_intr.interrupt)
  ) else `uvm_error(info_tag, "ambiguous handler cause");


  // Mem accesses reflect actual bus

  var logic [31:0] writebuf_req_count_c;
  var logic [31:0] rvfi_mem_count_c;
  var logic [31:0] writebuf_req_count_n;
  var logic [31:0] rvfi_mem_count_n;
  var logic [31:0] rvfi_mem_new;

  a_obi_vs_rvfi: assert property (
    writebuf_req_count_c >= rvfi_mem_count_c
  ) else `uvm_error(info_tag, "rvfi should not report bus transactions that didn't happen");

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (rst_ni == 0) begin
      writebuf_req_count_c <= 0;
      rvfi_mem_count_c     <= 0;
    end else begin
      if (writebuf_req_count_n > writebuf_req_count_c) begin
        writebuf_req_count_c <= writebuf_req_count_n;
      end

      if (rvfi_mem_count_n > rvfi_mem_count_c) begin
        rvfi_mem_count_c <= rvfi_mem_count_n;
      end
    end
  end

  always_comb begin
    writebuf_req_count_n = writebuf_req_count_c;
    if (writebuf_valid_i && writebuf_ready_o) begin
      writebuf_req_count_n = writebuf_req_count_c + 1;
    end

    rvfi_mem_new = 0;
    for (int i = 0; i < NMEM; i++) begin
      rvfi_mem_new += |rvfi_if.rvfi_mem_wmask[i*XLEN/8+:XLEN/8] && rvfi_if.rvfi_valid;
      rvfi_mem_new += |rvfi_if.rvfi_mem_rmask[i*XLEN/8+:XLEN/8] && rvfi_if.rvfi_valid;
    end
    rvfi_mem_count_n = rvfi_mem_count_c + rvfi_mem_new;
  end


endmodule : uvmt_cv32e40x_rvfi_assert


`default_nettype  wire
