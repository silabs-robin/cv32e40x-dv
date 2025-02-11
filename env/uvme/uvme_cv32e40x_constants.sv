// Copyright 2020 OpenHW Group
// Copyright 2020 Datum Technology Corporation
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


`ifndef __UVME_CV32E40X_CONSTANTS_SV__
`define __UVME_CV32E40X_CONSTANTS_SV__


parameter uvme_cv32e40x_sys_default_clk_period   =  1_500; // 10ns
parameter uvme_cv32e40x_debug_default_clk_period = 10_000; // 10ns

// For RVFI/RVVI
parameter ILEN = 32;
parameter XLEN = 32;
parameter RVFI_NRET = 1;

// For OBI
parameter ENV_PARAM_INSTR_ADDR_WIDTH  = 32;
parameter ENV_PARAM_INSTR_DATA_WIDTH  = 32;
parameter ENV_PARAM_INSTR_ACHK_WIDTH  = 12;
parameter ENV_PARAM_INSTR_RCHK_WIDTH  = 5;
parameter ENV_PARAM_DATA_ADDR_WIDTH   = 32;
parameter ENV_PARAM_DATA_DATA_WIDTH   = 32;
parameter ENV_PARAM_DATA_ACHK_WIDTH   = 12;
parameter ENV_PARAM_DATA_RCHK_WIDTH   = 5;
parameter ENV_PARAM_RAM_ADDR_WIDTH    = 22;

parameter ENV_PARAM_INSTR_AUSER_WIDTH = `UVMA_OBI_MEMORY_AUSER_DEFAULT_WIDTH;
parameter ENV_PARAM_INSTR_WUSER_WIDTH = `UVMA_OBI_MEMORY_WUSER_DEFAULT_WIDTH;
parameter ENV_PARAM_INSTR_RUSER_WIDTH = `UVMA_OBI_MEMORY_RUSER_DEFAULT_WIDTH;
parameter ENV_PARAM_INSTR_ID_WIDTH    = `UVMA_OBI_MEMORY_ID_DEFAULT_WIDTH;

parameter ENV_PARAM_DATA_AUSER_WIDTH = `UVMA_OBI_MEMORY_AUSER_DEFAULT_WIDTH;
parameter ENV_PARAM_DATA_WUSER_WIDTH = `UVMA_OBI_MEMORY_WUSER_DEFAULT_WIDTH;
parameter ENV_PARAM_DATA_RUSER_WIDTH = `UVMA_OBI_MEMORY_RUSER_DEFAULT_WIDTH;
parameter ENV_PARAM_DATA_ID_WIDTH    = `UVMA_OBI_MEMORY_ID_DEFAULT_WIDTH;
// Control how often to print core scoreboard checked heartbeat messages
parameter PC_CHECKED_HEARTBEAT = 10_000;

// Map the virtual peripheral registers
parameter CV_VP_REGISTER_BASE          = 32'h0080_0000;
parameter CV_VP_REGISTER_SIZE          = 32'h0000_1000;

parameter CV_VP_VIRTUAL_PRINTER_OFFSET = 32'h0000_0000;
parameter CV_VP_RANDOM_NUM_OFFSET      = 32'h0000_0040;
parameter CV_VP_CYCLE_COUNTER_OFFSET   = 32'h0000_0080;
parameter CV_VP_STATUS_FLAGS_OFFSET    = 32'h0000_00c0;
parameter CV_VP_FENCEI_TAMPER_OFFSET   = 32'h0000_0100;
parameter CV_VP_INTR_TIMER_OFFSET      = 32'h0000_0140;
parameter CV_VP_DEBUG_CONTROL_OFFSET   = 32'h0000_0180;
parameter CV_VP_OBI_SLV_RESP_OFFSET    = 32'h0000_01c0;
parameter CV_VP_SIG_WRITER_OFFSET      = 32'h0000_0200;

parameter CV_VP_VIRTUAL_PRINTER_BASE   = CV_VP_REGISTER_BASE + CV_VP_VIRTUAL_PRINTER_OFFSET;
parameter CV_VP_RANDOM_NUM_BASE        = CV_VP_REGISTER_BASE + CV_VP_RANDOM_NUM_OFFSET;
parameter CV_VP_CYCLE_COUNTER_BASE     = CV_VP_REGISTER_BASE + CV_VP_CYCLE_COUNTER_OFFSET;
parameter CV_VP_STATUS_FLAGS_BASE      = CV_VP_REGISTER_BASE + CV_VP_STATUS_FLAGS_OFFSET;
parameter CV_VP_INTR_TIMER_BASE        = CV_VP_REGISTER_BASE + CV_VP_INTR_TIMER_OFFSET;
parameter CV_VP_DEBUG_CONTROL_BASE     = CV_VP_REGISTER_BASE + CV_VP_DEBUG_CONTROL_OFFSET;
parameter CV_VP_OBI_SLV_RESP_BASE      = CV_VP_REGISTER_BASE + CV_VP_OBI_SLV_RESP_OFFSET;
parameter CV_VP_SIG_WRITER_BASE        = CV_VP_REGISTER_BASE + CV_VP_SIG_WRITER_OFFSET;
parameter CV_VP_FENCEI_TAMPER_BASE     = CV_VP_REGISTER_BASE + CV_VP_FENCEI_TAMPER_OFFSET;

`endif // __UVME_CV32E40X_CONSTANTS_SV__



