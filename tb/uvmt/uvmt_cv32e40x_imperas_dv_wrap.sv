//
// Copyright 2022 OpenHW Group
// Copyright 2022 Imperas
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
//

`ifndef __UVMT_CV32E40X_IMPERAS_DV_WRAP_SV__
`define __UVMT_CV32E40X_IMPERAS_DV_WRAP_SV__

`define DUT_PATH dut_wrap.cv32e40x_wrapper_i
`define RVFI_IF  `DUT_PATH.rvfi_instr_if_0_i

`define STRINGIFY(x) `"x`"

////////////////////////////////////////////////////////////////////////////
// Assign the rvvi CSR values from RVFI - CSR = (wdata & wmask) | (rdata & ~wmask)
////////////////////////////////////////////////////////////////////////////
`define RVVI_SET_CSR(CSR_ADDR, CSR_NAME) \
    bit csr_``CSR_NAME``_wb; \
    wire [31:0] csr_``CSR_NAME``_w; \
    wire [31:0] csr_``CSR_NAME``_r; \
    assign csr_``CSR_NAME``_w = `DUT_PATH.rvfi_csr_``CSR_NAME``_if_0_i.rvfi_csr_wdata &   `DUT_PATH.rvfi_csr_``CSR_NAME``_if_0_i.rvfi_csr_wmask; \
    assign csr_``CSR_NAME``_r = `DUT_PATH.rvfi_csr_``CSR_NAME``_if_0_i.rvfi_csr_rdata & ~(`DUT_PATH.rvfi_csr_``CSR_NAME``_if_0_i.rvfi_csr_wmask); \
    assign rvvi.csr[0][0][``CSR_ADDR]    = csr_``CSR_NAME``_w | csr_``CSR_NAME``_r; \
    assign rvvi.csr_wb[0][0][``CSR_ADDR] = csr_``CSR_NAME``_wb; \
    always @(rvvi.csr[0][0][``CSR_ADDR]) begin \
        csr_``CSR_NAME``_wb = 1; \
    end \
    always @(posedge rvvi.clk) begin \
        if (`RVFI_IF.rvfi_valid && csr_``CSR_NAME``_wb) begin \
            csr_``CSR_NAME``_wb = 0; \
        end \
    end 

////////////////////////////////////////////////////////////////////////////
// Assign the NET IRQ values from the core irq inputs
////////////////////////////////////////////////////////////////////////////
`define RVVI_SET_IRQ(IRQ_NAME, IRQ_IDX) \
    if (`DUT_PATH.irq_i[IRQ_IDX]==1 && IRQ[IRQ_IDX]==0) begin \
        void'(rvvi.net_push(`STRINGIFY(``IRQ_NAME), 1)); \
        IRQ[IRQ_IDX] = 1; \
    end

`define RVVI_CLR_IRQ(IRQ_NAME, IRQ_IDX) \
    if (`RVFI_IF.rvfi_valid && `DUT_PATH.irq_i[IRQ_IDX]==0 && IRQ[IRQ_IDX]==1) begin \
        void'(rvvi.net_push(`STRINGIFY(``IRQ_NAME), 0)); \
        IRQ[IRQ_IDX] = 0; \
    end

////////////////////////////////////////////////////////////////////////////
// CSR definitions
////////////////////////////////////////////////////////////////////////////
`define CSR_MSTATUS_ADDR       32'h300
`define CSR_MISA_ADDR          32'h301
`define CSR_MIE_ADDR           32'h304
`define CSR_MTVEC_ADDR         32'h305
`define CSR_MTVT_ADDR          32'h307 // only available when SMCLIC=1
`define CSR_MSTATUSH_ADDR      32'h310
`define CSR_MCOUNTINHIBIT_ADDR 32'h320
//[31:0] [31:0]  CSR_MHPMEVENT 32'h323..32'h33F
`define CSR_MSCRATCH_ADDR      32'h340
`define CSR_MEPC_ADDR          32'h341
`define CSR_MCAUSE_ADDR        32'h342
`define CSR_MTVAL_ADDR         32'h343
`define CSR_MIP_ADDR           32'h344
`define CSR_MNXTI_ADDR         32'h345 // only available when SMCLIC=1
`define CSR_MINTSTATUS_ADDR    32'h346 // only available when SMCLIC=1
`define CSR_MINTTHRESH_ADDR    32'h347 // only available when SMCLIC=1
`define CSR_MSCRATCHCSW_ADDR   32'h348 // only available when SMCLIC=1
`define CSR_MSCRATCHCSW1_ADDR  32'h349 // only available when SMCLIC=1
`define CSR_TSELECT_ADDR       32'h7A0 // only when DBG_NUM_TRIGGERS > 0
`define CSR_TDATA1_ADDR        32'h7A1 // only when DBG_NUM_TRIGGERS > 0
`define CSR_TDATA2_ADDR        32'h7A2 // only when DBG_NUM_TRIGGERS > 0
`define CSR_TDATA3_ADDR        32'h7A3 // only when DBG_NUM_TRIGGERS > 0
`define CSR_TINFO_ADDR         32'h7A4 // only when DBG_NUM_TRIGGERS > 0
`define CSR_TCONTROL_ADDR      32'h7A5 // only when DBG_NUM_TRIGGERS > 0
`define CSR_MCONTEXT_ADDR      32'h7A8
`define CSR_MSCONTEXT_ADDR     32'h7A9 // ???
`define CSR_SCONTEXT_ADDR      32'h7AA
`define CSR_DCSR_ADDR          32'h7B0
`define CSR_DPC_ADDR           32'h7B1
`define CSR_DSCRATCH0_ADDR     32'h7B2
`define CSR_DSCRATCH1_ADDR     32'h7B3
`define CSR_MCYCLE_ADDR        32'hB00
`define CSR_MINSTRET_ADDR      32'hB02

`define CSR_MHPMCOUNTER3_ADDR  32'hB03
`define CSR_MHPMCOUNTER4_ADDR  32'hB04
`define CSR_MHPMCOUNTER5_ADDR  32'hB05
`define CSR_MHPMCOUNTER6_ADDR  32'hB06
`define CSR_MHPMCOUNTER7_ADDR  32'hB07
`define CSR_MHPMCOUNTER8_ADDR  32'hB08
`define CSR_MHPMCOUNTER9_ADDR  32'hB09
`define CSR_MHPMCOUNTER10_ADDR 32'hB0A
`define CSR_MHPMCOUNTER11_ADDR 32'hB0B
`define CSR_MHPMCOUNTER12_ADDR 32'hB0C
`define CSR_MHPMCOUNTER13_ADDR 32'hB0D
`define CSR_MHPMCOUNTER14_ADDR 32'hB0E
`define CSR_MHPMCOUNTER15_ADDR 32'hB0F
`define CSR_MHPMCOUNTER16_ADDR 32'hB10
`define CSR_MHPMCOUNTER17_ADDR 32'hB11
`define CSR_MHPMCOUNTER18_ADDR 32'hB12
`define CSR_MHPMCOUNTER19_ADDR 32'hB13
`define CSR_MHPMCOUNTER20_ADDR 32'hB14
`define CSR_MHPMCOUNTER21_ADDR 32'hB15
`define CSR_MHPMCOUNTER22_ADDR 32'hB16
`define CSR_MHPMCOUNTER23_ADDR 32'hB17
`define CSR_MHPMCOUNTER24_ADDR 32'hB18
`define CSR_MHPMCOUNTER25_ADDR 32'hB19
`define CSR_MHPMCOUNTER26_ADDR 32'hB1A
`define CSR_MHPMCOUNTER27_ADDR 32'hB1B
`define CSR_MHPMCOUNTER28_ADDR 32'hB1C
`define CSR_MHPMCOUNTER29_ADDR 32'hB1D
`define CSR_MHPMCOUNTER30_ADDR 32'hB1E
`define CSR_MHPMCOUNTER31_ADDR 32'hB1F

`define CSR_MHPMCOUNTER3H_ADDR  32'hB83
`define CSR_MHPMCOUNTER4H_ADDR  32'hB84
`define CSR_MHPMCOUNTER5H_ADDR  32'hB85
`define CSR_MHPMCOUNTER6H_ADDR  32'hB86
`define CSR_MHPMCOUNTER7H_ADDR  32'hB87
`define CSR_MHPMCOUNTER8H_ADDR  32'hB88
`define CSR_MHPMCOUNTER9H_ADDR  32'hB89
`define CSR_MHPMCOUNTER10H_ADDR 32'hB8A
`define CSR_MHPMCOUNTER11H_ADDR 32'hB8B
`define CSR_MHPMCOUNTER12H_ADDR 32'hB8C
`define CSR_MHPMCOUNTER13H_ADDR 32'hB8D
`define CSR_MHPMCOUNTER14H_ADDR 32'hB8E
`define CSR_MHPMCOUNTER15H_ADDR 32'hB8F
`define CSR_MHPMCOUNTER16H_ADDR 32'hB90
`define CSR_MHPMCOUNTER17H_ADDR 32'hB91
`define CSR_MHPMCOUNTER18H_ADDR 32'hB92
`define CSR_MHPMCOUNTER19H_ADDR 32'hB93
`define CSR_MHPMCOUNTER20H_ADDR 32'hB94
`define CSR_MHPMCOUNTER21H_ADDR 32'hB95
`define CSR_MHPMCOUNTER22H_ADDR 32'hB96
`define CSR_MHPMCOUNTER23H_ADDR 32'hB97
`define CSR_MHPMCOUNTER24H_ADDR 32'hB98
`define CSR_MHPMCOUNTER25H_ADDR 32'hB99
`define CSR_MHPMCOUNTER26H_ADDR 32'hB9A
`define CSR_MHPMCOUNTER27H_ADDR 32'hB9B
`define CSR_MHPMCOUNTER28H_ADDR 32'hB9C
`define CSR_MHPMCOUNTER29H_ADDR 32'hB9D
`define CSR_MHPMCOUNTER30H_ADDR 32'hB9E
`define CSR_MHPMCOUNTER31H_ADDR 32'hB9F

`define CSR_MHPMEVENT3_ADDR  32'h323
`define CSR_MHPMEVENT4_ADDR  32'h324
`define CSR_MHPMEVENT5_ADDR  32'h325
`define CSR_MHPMEVENT6_ADDR  32'h326
`define CSR_MHPMEVENT7_ADDR  32'h327
`define CSR_MHPMEVENT8_ADDR  32'h328
`define CSR_MHPMEVENT9_ADDR  32'h329
`define CSR_MHPMEVENT10_ADDR 32'h32A
`define CSR_MHPMEVENT11_ADDR 32'h32B
`define CSR_MHPMEVENT12_ADDR 32'h32C
`define CSR_MHPMEVENT13_ADDR 32'h32D
`define CSR_MHPMEVENT14_ADDR 32'h32E
`define CSR_MHPMEVENT15_ADDR 32'h32F
`define CSR_MHPMEVENT16_ADDR 32'h330
`define CSR_MHPMEVENT17_ADDR 32'h331
`define CSR_MHPMEVENT18_ADDR 32'h332
`define CSR_MHPMEVENT19_ADDR 32'h333
`define CSR_MHPMEVENT20_ADDR 32'h334
`define CSR_MHPMEVENT21_ADDR 32'h335
`define CSR_MHPMEVENT22_ADDR 32'h336
`define CSR_MHPMEVENT23_ADDR 32'h337
`define CSR_MHPMEVENT24_ADDR 32'h338
`define CSR_MHPMEVENT25_ADDR 32'h339
`define CSR_MHPMEVENT26_ADDR 32'h33A
`define CSR_MHPMEVENT27_ADDR 32'h33B
`define CSR_MHPMEVENT28_ADDR 32'h33C
`define CSR_MHPMEVENT29_ADDR 32'h33D
`define CSR_MHPMEVENT30_ADDR 32'h33E
`define CSR_MHPMEVENT31_ADDR 32'h33F

`define CSR_MCYCLEH_ADDR       32'hB80
`define CSR_MINSTRETH_ADDR     32'hB82
//[31:0] [31:0]  CSR_MHPMCOUNTERH_ADDR 32'hB83..32'hB9F
`define CSR_MVENDORID_ADDR     32'hF11
`define CSR_MARCHID_ADDR       32'hF12
`define CSR_MIMPID_ADDR        32'hF13
`define CSR_MHARTID_ADDR       32'hF14
`define CSR_MCONFIGPTR_ADDR    32'hF15 // huh?
`define CSR_CYCLE_ADDR         32'hC00
`define CSR_INSTRET_ADDR       32'hC02
`define CSR_CYCLEH_ADDR        32'hC80
`define CSR_INSTRETH_ADDR      32'hC82

//[31:0]         CSR_MSECCFG_ADDR
//[31:0]         CSR_MSECCFGH_ADDR
//[15:0] [31:0]  CSR_PMPADDR_ADDR
//[ 3:0] [31:0]  CSR_PMPCFG_ADDR
//[31:0] [31:0]  CSR_HPMCOUNTERH_ADDR
//[31:0] [31:0]  CSR_HPMCOUNTER_ADDR
//[ 1:0] [31:0]  CSR_DSCRATCH_ADDR
//[ 3:0] [31:0]  CSR_TDATA_ADDR


///////////////////////////////////////////////////////////////////////////////
// Module wrapper for Imperas DV.
////////////////////////////////////////////////////////////////////////////
`define USE_IMPERASDV
`ifdef USE_IMPERASDV

module uvmt_cv32e40x_imperas_dv_wrap
  import uvm_pkg::*;
  import uvme_cv32e40x_pkg::*;
  #(
   )

   (
           rvviTrace  rvvi // RVVI SystemVerilog Interface
   );

   trace2api       #(.CMP_PC      (1),
                   .CMP_INS     (1),
                   .CMP_GPR     (1),
                   .CMP_FPR     (0),
                   .CMP_VR      (0),
                   .CMP_CSR     (1)
                   //.MISCOMPARES (1)
                   )
                   trace2api(rvvi);

   trace2log       trace2log(rvvi);

   string info_tag = "ImperasDV_wrap";

   // Make the UVM environment configuration available to the Reference Model as needed.
   uvme_cv32e40x_cfg_c  uvm_env_cfg;

   initial begin
     @(rvvi.clk);
     void'(uvm_config_db#(uvme_cv32e40x_cfg_c)::get(null, "uvm_test_top.env", "cfg", uvm_env_cfg));
     if (!uvm_env_cfg) begin
      `uvm_fatal(info_tag, "Configuration handle is null")
     end
     else begin
      `uvm_info(info_tag, $sformatf("Found UVM environment configuration handle:\n%s", uvm_env_cfg.sprint()), UVM_DEBUG)
     end
   end

   ////////////////////////////////////////////////////////////////////////////
   // Adopted from:
   // ImperasDV/examples/openhwgroup_cv32e40x/systemverilog/cv32e40x_testbench.sv
   ////////////////////////////////////////////////////////////////////////////
   assign rvvi.clk            = `RVFI_IF.clk;
   assign rvvi.valid[0][0]    = `RVFI_IF.rvfi_valid;
   assign rvvi.order[0][0]    = `RVFI_IF.rvfi_order;
   assign rvvi.insn[0][0]     = `RVFI_IF.rvfi_insn;
   assign rvvi.trap[0][0]     = `RVFI_IF.rvfi_trap;
   assign rvvi.intr[0][0]     = `RVFI_IF.rvfi_intr;
   assign rvvi.mode[0][0]     = `RVFI_IF.rvfi_mode;
   assign rvvi.ixl[0][0]      = `RVFI_IF.rvfi_ixl;
   assign rvvi.pc_rdata[0][0] = `RVFI_IF.rvfi_pc_rdata;
   assign rvvi.pc_wdata[0][0] = `RVFI_IF.rvfi_pc_wdata;

   `RVVI_SET_CSR( `CSR_MSTATUS_ADDR,       mstatus       )
   `RVVI_SET_CSR( `CSR_MISA_ADDR,          misa          )
   `RVVI_SET_CSR( `CSR_MIE_ADDR,           mie           )
   `RVVI_SET_CSR( `CSR_MTVEC_ADDR,         mtvec         )
   `RVVI_SET_CSR( `CSR_MCOUNTINHIBIT_ADDR, mcountinhibit )
   `RVVI_SET_CSR( `CSR_MSCRATCH_ADDR,      mscratch      )
   `RVVI_SET_CSR( `CSR_MEPC_ADDR,          mepc          )
   `RVVI_SET_CSR( `CSR_MCAUSE_ADDR,        mcause        )
   `RVVI_SET_CSR( `CSR_MTVAL_ADDR,         mtval         )
   `RVVI_SET_CSR( `CSR_MIP_ADDR,           mip           )
   `RVVI_SET_CSR( `CSR_MCYCLE_ADDR,        mcycle        )
   `RVVI_SET_CSR( `CSR_MINSTRET_ADDR,      minstret      )
   `RVVI_SET_CSR( `CSR_MCYCLEH_ADDR,       mcycleh       )
   `RVVI_SET_CSR( `CSR_MINSTRETH_ADDR,     minstreth     )
   `RVVI_SET_CSR( `CSR_MVENDORID_ADDR,     mvendorid     )
   `RVVI_SET_CSR( `CSR_MARCHID_ADDR,       marchid       )
   `RVVI_SET_CSR( `CSR_MIMPID_ADDR,        mimpid        )
   `RVVI_SET_CSR( `CSR_MHARTID_ADDR,       mhartid       )

   `RVVI_SET_CSR( `CSR_TSELECT_ADDR,       tselect       )
   `RVVI_SET_CSR( `CSR_DCSR_ADDR,          dcsr          )
   `RVVI_SET_CSR( `CSR_DPC_ADDR,           dpc           )
   `RVVI_SET_CSR( `CSR_DSCRATCH0_ADDR,     dscratch0     )
   `RVVI_SET_CSR( `CSR_DSCRATCH1_ADDR,     dscratch1     )
   `RVVI_SET_CSR( `CSR_TDATA1_ADDR,        tdata1        )
   `RVVI_SET_CSR( `CSR_TDATA2_ADDR,        tdata2        )
   `RVVI_SET_CSR( `CSR_TINFO_ADDR,         tinfo         )

   ////////////////////////////////////////////////////////////////////////////
   // Assign the RVVI GPR registers
   ////////////////////////////////////////////////////////////////////////////
   bit [31:0] XREG[32];
   genvar gi;
   generate
       for(gi=0; gi<32; gi++)
           assign rvvi.x_wdata[0][0][gi] = XREG[gi];
   endgenerate

   always @(*) begin
       int i;
       for (i=1; i<32; i++) begin
           XREG[i] = 32'b0;
           if (`RVFI_IF.rvfi_rd1_addr==5'(i))            // TODO: originally rvfi_rd_addr
               XREG[i] = `RVFI_IF.rvfi_rd1_wdata;        // TODO: originally rvfi_rd_wdata
       end
   end

   assign rvvi.x_wb[0][0] = 1 << `RVFI_IF.rvfi_rd1_addr; // TODO: originally rvfi_rd_addr

   ////////////////////////////////////////////////////////////////////////////
   // DEBUG REQUESTS, 
   // assert when 0->1
   // negate when posedge clk && valid=1 && debug=0
   ////////////////////////////////////////////////////////////////////////////
   bit DebugReq;
   always @(*) begin: Set_DebugReq
     if (`DUT_PATH.debug_req_i==1 && DebugReq==0) begin
         void'(rvvi.net_push("haltreq", 1));
         DebugReq = 1;
     end
   end: Set_DebugReq
   always @(posedge `RVFI_IF.clk) begin: Clr_DebugReq
       if (`RVFI_IF.rvfi_valid && `DUT_PATH.debug_req_i==0 && DebugReq==1) begin
           void'(rvvi.net_push("haltreq", 0));
           DebugReq = 0;
       end
   end: Clr_DebugReq

   ////////////////////////////////////////////////////////////////////////////
   // INTERRUPTS
   // assert when MIP or cause bit
   // negate when posedge clk && valid=1 && debug=0
   ////////////////////////////////////////////////////////////////////////////
   bit [31:0] IRQ, IRQ_NEXT;
   always @(*) begin: Set_Irq
       IRQ_NEXT = (rvvi.csr[0][0][`CSR_MIP_ADDR] | (1 << `RVFI_IF.rvfi_intr.cause[4:0]));
       if (IRQ != IRQ_NEXT) begin
           IRQ |= IRQ_NEXT;
           if (IRQ[3])  void'(rvvi.net_push("MSWInterrupt",       IRQ[ 3]));
           if (IRQ[7])  void'(rvvi.net_push("MTimerInterrupt",    IRQ[ 7]));
           if (IRQ[11]) void'(rvvi.net_push("MExternalInterrupt", IRQ[11]));
           if (IRQ[16]) void'(rvvi.net_push("LocalInterrupt0",    IRQ[16]));
           if (IRQ[17]) void'(rvvi.net_push("LocalInterrupt1",    IRQ[17]));
           if (IRQ[18]) void'(rvvi.net_push("LocalInterrupt2",    IRQ[18]));
           if (IRQ[19]) void'(rvvi.net_push("LocalInterrupt3",    IRQ[19]));
           if (IRQ[20]) void'(rvvi.net_push("LocalInterrupt4",    IRQ[20]));
           if (IRQ[21]) void'(rvvi.net_push("LocalInterrupt5",    IRQ[21]));
           if (IRQ[22]) void'(rvvi.net_push("LocalInterrupt6",    IRQ[22]));
           if (IRQ[23]) void'(rvvi.net_push("LocalInterrupt7",    IRQ[23]));
           if (IRQ[24]) void'(rvvi.net_push("LocalInterrupt8",    IRQ[24]));
           if (IRQ[25]) void'(rvvi.net_push("LocalInterrupt9",    IRQ[25]));
           if (IRQ[26]) void'(rvvi.net_push("LocalInterrupt10",   IRQ[26]));
           if (IRQ[27]) void'(rvvi.net_push("LocalInterrupt11",   IRQ[27]));
           if (IRQ[28]) void'(rvvi.net_push("LocalInterrupt12",   IRQ[28]));
           if (IRQ[29]) void'(rvvi.net_push("LocalInterrupt13",   IRQ[29]));
           if (IRQ[30]) void'(rvvi.net_push("LocalInterrupt14",   IRQ[30]));
           if (IRQ[31]) void'(rvvi.net_push("LocalInterrupt15",   IRQ[31]));
       end
   end: Set_Irq
   always @(posedge `RVFI_IF.clk) begin: Clr_Irq
       `RVVI_CLR_IRQ(MSWInterrupt,        3)
       `RVVI_CLR_IRQ(MTimerInterrupt,     7)
       `RVVI_CLR_IRQ(MExternalInterrupt, 11)
       `RVVI_CLR_IRQ(LocalInterrupt0,    16)
       `RVVI_CLR_IRQ(LocalInterrupt1,    17)
       `RVVI_CLR_IRQ(LocalInterrupt2,    18)
       `RVVI_CLR_IRQ(LocalInterrupt3,    19)
       `RVVI_CLR_IRQ(LocalInterrupt4,    20)
       `RVVI_CLR_IRQ(LocalInterrupt5,    21)
       `RVVI_CLR_IRQ(LocalInterrupt6,    22)
       `RVVI_CLR_IRQ(LocalInterrupt7,    23)
       `RVVI_CLR_IRQ(LocalInterrupt8,    24)
       `RVVI_CLR_IRQ(LocalInterrupt9,    25)
       `RVVI_CLR_IRQ(LocalInterrupt10,   26)
       `RVVI_CLR_IRQ(LocalInterrupt11,   27)
       `RVVI_CLR_IRQ(LocalInterrupt12,   28)
       `RVVI_CLR_IRQ(LocalInterrupt13,   29)
       `RVVI_CLR_IRQ(LocalInterrupt14,   30)
       `RVVI_CLR_IRQ(LocalInterrupt15,   31)
   end: Clr_Irq
   
   ////////////////////////////////////////////////////////////////////////////
   // RVFI Monitor: pass NMI Load/Store and Fetch to the ref
   ////////////////////////////////////////////////////////////////////////////
   bit InstructionBusFault;
   bit DataBusFault;
   always @(*) begin: Monitor_RVFI
       bit        trap_trap;
       bit        trap_exception;
       bit        trap_debug;
       bit [5:0]  trap_exception_cause;
       bit [2:0]  trap_debug_cause;
       bit [1:0]  trap_cause_type;
       
       bit        intr_intr;
       bit        intr_exception;
       bit        intr_interrupt;
       bit [10:0] intr_cause;
       
       bit        nmi_pending;
       bit        nmi_load_store;
       
       if (`RVFI_IF.rvfi_valid) begin
           trap_trap            = `RVFI_IF.rvfi_trap.trap;
           trap_exception       = `RVFI_IF.rvfi_trap.exception;
           trap_debug           = `RVFI_IF.rvfi_trap.debug;
           trap_exception_cause = `RVFI_IF.rvfi_trap.exception_cause;
           trap_debug_cause     = `RVFI_IF.rvfi_trap.debug_cause;
           trap_cause_type      = `RVFI_IF.rvfi_trap.cause_type;
           
           intr_intr            = `RVFI_IF.rvfi_intr.intr;
           intr_exception       = `RVFI_IF.rvfi_intr.exception;
           intr_interrupt       = `RVFI_IF.rvfi_intr.interrupt;
           intr_cause           = `RVFI_IF.rvfi_intr.cause;
           
           nmi_pending          = `RVFI_IF.rvfi_nmip[0];
           nmi_load_store       = `RVFI_IF.rvfi_nmip[1];
           
           //
           // Load Store - NMI
           //
           if (intr_intr && intr_interrupt && ((intr_cause==1024 || intr_cause==1025))) begin
               // Load / Store
               void'(rvvi.net_push("nmi_cause", intr_cause)); // Load Error = 1024, Store Error = 1025
               if (!DataBusFault) begin
                   void'(rvvi.net_push("nmi", 1));
               end
           end else begin
               if (DataBusFault) begin
                   void'(rvvi.net_push("nmi", 0));
               end
               DataBusFault = 0;
           end

           //
           //  Fetch - Exception
           //
           if (trap_trap && trap_exception && trap_exception_cause==48) begin
               if (!InstructionBusFault) begin
                   void'(rvvi.net_push("InstructionBusFault", 1));
               end
               InstructionBusFault = 1;
           end else begin
               if (InstructionBusFault) begin
                   void'(rvvi.net_push("InstructionBusFault", 0));
               end
               InstructionBusFault = 0;
           end
           
//           `uvm_info(info_tag, $sformatf("\nRVFI Valid %t", $time), UVM_INFO)
//           `uvm_info(info_tag, $sformatf("valid      = %X", `RVFI_IF.rvfi_valid), UVM_INFO)
//           `uvm_info(info_tag, $sformatf("order      = %X", `RVFI_IF.rvfi_order), UVM_INFO)
//           `uvm_info(info_tag, $sformatf("insn       = %X", `RVFI_IF.rvfi_insn), UVM_INFO)
//           `uvm_info(info_tag, $sformatf("trap       trap=%X exception=%X debug=%X exception_cause=0x%X debug_cause=0x%X cause_type=0x%X", 
//                   trap_trap, trap_exception, trap_debug, trap_exception_cause, trap_debug_cause, trap_cause_type), UVM_INFO)
//           `uvm_info(info_tag, $sformatf("halt       = %X", `RVFI_IF.rvfi_halt), UVM_INFO)
//           `uvm_info(info_tag, $sformatf("dbg        = %X", `RVFI_IF.rvfi_dbg), UVM_INFO)
//           `uvm_info(info_tag, $sformatf("dbg_mode   = %X", `RVFI_IF.rvfi_dbg_mode), UVM_INFO)
//           `uvm_info(info_tag, $sformatf("nmip       nmi=%X nmi_load0_store1=%X", `RVFI_IF.rvfi_nmip[0], `RVFI_IF.rvfi_nmip[1]), UVM_INFO)
//           `uvm_info(info_tag, $sformatf("intr       intr=%X exception=%X interrupt=%X cause=0x%X", 
//                   intr_intr, intr_exception, intr_interrupt, intr_cause), UVM_INFO)
//           `uvm_info(info_tag, $sformatf("mode       = %X", `RVFI_IF.rvfi_mode), UVM_INFO)
//           `uvm_info(info_tag, $sformatf("ixl        = %X", `RVFI_IF.rvfi_ixl), UVM_INFO)
//           `uvm_info(info_tag, $sformatf("pc_rdata   = %X", `RVFI_IF.rvfi_pc_rdata), UVM_INFO)
//           `uvm_info(info_tag, $sformatf("pc_wdata   = %X", `RVFI_IF.rvfi_pc_wdata), UVM_INFO)
       end
   end: Monitor_RVFI


  /////////////////////////////////////////////////////////////////////////////
  // REF control
  /////////////////////////////////////////////////////////////////////////////
  task ref_init;
    string test_program_elf;
    reg [31:0] hart_id;

    // Initialize REF and load the test-program into it's memory (do this before initializing the DUT).
    // TODO: is this the best place for this?
    if (!rvviVersionCheck(`RVVI_API_VERSION)) begin
      `uvm_fatal(info_tag, $sformatf("Expecting RVVI API version %0d.", `RVVI_API_VERSION))
    end
    // Test-program must have been compiled before we got here...
    if ($value$plusargs("elf_file=%s", test_program_elf)) begin
      `uvm_info(info_tag, $sformatf("ImperasDV loading test_program %0s", test_program_elf), UVM_NONE)
      //if (!rvviRefInit(test_program_elf, "openhwgroup.ovpworld.org", "CV32E40X_V0.2.0", 0, `RVVI_TRUE)) begin
      if (!rvviRefInit(test_program_elf, "openhwgroup.ovpworld.org", "CV32E40X", 0)) begin
        `uvm_fatal(info_tag, "rvviRefInit failed")
      end
      else begin
        `uvm_info(info_tag, "rvviRefInit() succeed", UVM_NONE)
      end
    end
    else begin
      `uvm_fatal(info_tag, "No test_program specified")
    end

    hart_id = 32'h0000_0000;

    void'(rvviRefCsrSetVolatile(hart_id, `CSR_CYCLE_ADDR        ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_CYCLEH_ADDR       ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_INSTRET_ADDR      ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_INSTRETH_ADDR     ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MCYCLE_ADDR       ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MCYCLEH_ADDR      ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MINSTRET_ADDR     ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MINSTRETH_ADDR    ));

    // TODO: deal with the MHPMCOUNTER CSRs properly.
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER3_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER3H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT3_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER4_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER4H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT4_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER5_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER5H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT5_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER6_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER6H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT6_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER7_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER7H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT7_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER8_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER8H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT8_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER9_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER9H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT9_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER10_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER10H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT10_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER11_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER11H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT11_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER12_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER12H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT12_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER13_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER13H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT13_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER14_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER14H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT14_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER15_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER15H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT15_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER16_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER16H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT16_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER17_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER17H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT17_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER18_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER18H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT18_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER19_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER19H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT19_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER20_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER20H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT20_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER21_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER21H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT21_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER22_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER22H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT22_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER23_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER23H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT23_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER24_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER24H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT24_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER25_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER25H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT25_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER26_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER26H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT26_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER27_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER27H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT27_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER28_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER28H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT28_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER29_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER29H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT29_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER30_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER30H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT30_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER31_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id, `CSR_MHPMCOUNTER31H_ADDR ));
    void'(rvviRefCsrSetVolatile(hart_id,   `CSR_MHPMEVENT31_ADDR ));

    // Mask out pending bits, due to interrupts showing as pending
    // and enabled but not taken immediately due to instructions 
    // in-flight, eg Load/Store
    rvviRefCsrCompareEnable(hart_id, `CSR_MIP_ADDR, `RVVI_FALSE);
    rvviRefCsrCompareMask(hart_id,   `CSR_DCSR_ADDR, ~('h8));
            
    // define asynchronous grouping
    // Interrupts
    rvviRefNetGroupSet(rvviRefNetIndexGet("MSWInterrupt"),        1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("MTimerInterrupt"),     1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("MExternalInterrupt"),  1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("LocalInterrupt0"),     1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("LocalInterrupt1"),     1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("LocalInterrupt2"),     1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("LocalInterrupt3"),     1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("LocalInterrupt4"),     1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("LocalInterrupt5"),     1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("LocalInterrupt6"),     1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("LocalInterrupt7"),     1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("LocalInterrupt8"),     1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("LocalInterrupt9"),     1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("LocalInterrupt10"),    1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("LocalInterrupt11"),    1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("LocalInterrupt12"),    1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("LocalInterrupt13"),    1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("LocalInterrupt14"),    1);
    rvviRefNetGroupSet(rvviRefNetIndexGet("LocalInterrupt15"),    1);

    // NMI
    rvviRefNetGroupSet(rvviRefNetIndexGet("nmi"),                 2);
    rvviRefNetGroupSet(rvviRefNetIndexGet("nmi_cause"),           2);
    rvviRefNetGroupSet(rvviRefNetIndexGet("InstructionBusFault"), 2);

    // Debug
    rvviRefNetGroupSet(rvviRefNetIndexGet("haltreq"),             3);
    
    // Add IO regions of memory
    // According to silabs this range is 0x0080_0000 to 0x0080_0FFF
    void'(rvviRefMemorySetVolatile('h00800000, 'h00800FFF)); //TODO: deal with int return value

    `uvm_info(info_tag, "ref_init() complete", UVM_NONE)
  endtask // ref_init

endmodule : uvmt_cv32e40x_imperas_dv_wrap

`else // ! USE_IMPERASDV
    
    module uvmt_cv32e40x_imperas_dv_wrap
      import uvm_pkg::*;
      import uvme_cv32e40x_pkg::*;
      #(
       )

       (
               rvviTrace  rvvi // RVVI SystemVerilog Interface
       );
    
       task ref_init;
       endtask
endmodule : uvmt_cv32e40x_imperas_dv_wrap

`endif  // USE_IMPERASDV

`endif // __UVMT_CV32E40X_IMPERAS_DV_WRAP_SV__

