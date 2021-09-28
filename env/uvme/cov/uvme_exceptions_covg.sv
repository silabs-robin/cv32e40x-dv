// Copyright 2021 OpenHW Group
// Copyright 2021 Silicon Labs, Inc.
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


`uvm_analysis_imp_decl(_rvfi)


covergroup cg_exceptions
  with function sample(uvma_rvfi_instr_seq_item_c#(ILEN, XLEN) rvfi);

  `per_instance_fcov

  cp_trap : coverpoint rvfi.trap;

endgroup : cg_exceptions


class uvme_exceptions_covg extends uvm_component;

  cg_exceptions exceptions_cg;

  uvm_analysis_imp_rvfi#(uvma_rvfi_instr_seq_item_c#(ILEN, XLEN), uvme_exceptions_covg) rvfi_mon_export;

  `uvm_component_utils(uvme_exceptions_covg);

  extern function new(string name = "exceptions_covg", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern function void write_rvfi(uvma_rvfi_instr_seq_item_c#(ILEN, XLEN) trn);

endclass : uvme_exceptions_covg


function uvme_exceptions_covg::new(string name = "exceptions_covg", uvm_component parent = null);

  super.new(name, parent);

  rvfi_mon_export = new("rvfi_mon_export", this);

endfunction : new


function void uvme_exceptions_covg::build_phase(uvm_phase phase);

  super.build_phase(phase);

  exceptions_cg = new();

endfunction : build_phase


function void uvme_exceptions_covg::write_rvfi(uvma_rvfi_instr_seq_item_c#(ILEN, XLEN) trn);

  exceptions_cg.sample(trn);

endfunction : write_rvfi