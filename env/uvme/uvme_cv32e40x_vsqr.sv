// Copyright 2020 OpenHW Group
// Copyright 2020 Datum Technology Corporation
// Copyright 2020 Silicon Labs, Inc.
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


`ifndef __UVME_CV32E40X_VSQR_SV__
`define __UVME_CV32E40X_VSQR_SV__


/**
 * Component on which all CV32E40X virtual sequences are run.
 */
class uvme_cv32e40x_vsqr_c extends uvm_sequencer#(
   .REQ(uvm_sequence_item),
   .RSP(uvm_sequence_item)
);

   // Objects
   uvme_cv32e40x_cfg_c    cfg;
   uvme_cv32e40x_cntxt_c  cntxt;

   // Sequencer handles
   uvma_clknrst_sqr_c    clknrst_sequencer;
   uvma_interrupt_sqr_c  interrupt_sequencer;
   uvma_clic_sqr_c       clic_sequencer;
   uvma_debug_sqr_c      debug_sequencer;
   uvma_obi_memory_sqr_c#(
     .AUSER_WIDTH(ENV_PARAM_INSTR_AUSER_WIDTH),
     .WUSER_WIDTH(ENV_PARAM_INSTR_WUSER_WIDTH),
     .RUSER_WIDTH(ENV_PARAM_INSTR_RUSER_WIDTH),
     .ADDR_WIDTH(ENV_PARAM_INSTR_ADDR_WIDTH),
     .DATA_WIDTH(ENV_PARAM_INSTR_DATA_WIDTH),
     .ID_WIDTH(ENV_PARAM_INSTR_ID_WIDTH),
     .ACHK_WIDTH(ENV_PARAM_INSTR_ACHK_WIDTH),
     .RCHK_WIDTH(ENV_PARAM_INSTR_RCHK_WIDTH)
   ) obi_memory_instr_sequencer;
   uvma_obi_memory_sqr_c#(
     .AUSER_WIDTH(ENV_PARAM_DATA_AUSER_WIDTH),
     .WUSER_WIDTH(ENV_PARAM_DATA_WUSER_WIDTH),
     .RUSER_WIDTH(ENV_PARAM_DATA_RUSER_WIDTH),
     .ADDR_WIDTH(ENV_PARAM_DATA_ADDR_WIDTH),
     .DATA_WIDTH(ENV_PARAM_DATA_DATA_WIDTH),
     .ID_WIDTH(ENV_PARAM_DATA_ID_WIDTH),
     .ACHK_WIDTH(ENV_PARAM_DATA_ACHK_WIDTH),
     .RCHK_WIDTH(ENV_PARAM_DATA_RCHK_WIDTH)
   ) obi_memory_data_sequencer ;

   `uvm_component_utils_begin(uvme_cv32e40x_vsqr_c)
      `uvm_field_object(cfg  , UVM_DEFAULT)
      `uvm_field_object(cntxt, UVM_DEFAULT)
   `uvm_component_utils_end

   /**
    * Default constructor.
    */
   extern function new(string name="uvme_cv32e40x_sqr", uvm_component parent=null);

   /**
    * Ensures cfg & cntxt handles are not null.
    */
   extern virtual function void build_phase(uvm_phase phase);

endclass : uvme_cv32e40x_vsqr_c


function uvme_cv32e40x_vsqr_c::new(string name="uvme_cv32e40x_sqr", uvm_component parent=null);

   super.new(name, parent);

endfunction : new


function void uvme_cv32e40x_vsqr_c::build_phase(uvm_phase phase);

   super.build_phase(phase);

   void'(uvm_config_db#(uvme_cv32e40x_cfg_c)::get(this, "", "cfg", cfg));
   if (!cfg) begin
      `uvm_fatal("CFG", "Configuration handle is null")
   end

   void'(uvm_config_db#(uvme_cv32e40x_cntxt_c)::get(this, "", "cntxt", cntxt));
   if (!cntxt) begin
      `uvm_fatal("CNTXT", "Context handle is null")
   end

endfunction : build_phase


`endif // __UVME_CV32E40X_VSQR_SV__
