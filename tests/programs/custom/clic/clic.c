//
// Copyright 2022 Silicon Labs, Inc.
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
///////////////////////////////////////////////////////////////////////////////
//
// CLIC CSR access tests
//
/////////////////////////////////////////////////////////////////////////////////

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>

// MUST be 31 or less
#define NUM_TESTS 9
#define ABORT_ON_ERROR_IMMEDIATE 0
#define SMCLIC_ID_WIDTH 5

// ---------------------------------------------------------------
// Test prototypes - should match uint32_t <name>(uint32_t index)
// ---------------------------------------------------------------
uint32_t mcause_mstatus_mirror_init(uint32_t index);
uint32_t w_mcause_mpp_r_mstatus_mpp(uint32_t index);
uint32_t w_mstatus_mpp_r_mcause_mpp(uint32_t index);
uint32_t w_mcause_mpie_r_mstatus_mpie(uint32_t index);
uint32_t w_mstatus_mpie_r_mcause_mpie(uint32_t index);
uint32_t w_mie_notrap_r_zero(uint32_t index);
uint32_t w_mip_notrap_r_zero(uint32_t index);
uint32_t w_mtvt_rd_alignment(uint32_t index);
uint32_t w_mtvec_rd_alignment(uint32_t index);

// Helper functions
uint32_t set_test_status(uint32_t test_no, uint32_t val_prev);
uint32_t run_test(uint32_t (*ptr)(), uint32_t index);
int get_result(uint32_t res);
uint32_t max(uint32_t a, uint32_t b);

const uint32_t MSTATUS_MPP_OFFSET  = 11;
const uint32_t MSTATUS_MPIE_OFFSET = 7;
const uint32_t MCAUSE_MPP_OFFSET   = 28;
const uint32_t MCAUSE_MPIE_OFFSET  = 27;

const uint32_t MSTATUS_MPP_MASK  = 0x3 << MSTATUS_MPP_OFFSET;
const uint32_t MSTATUS_MPIE_MASK = 0x1 << MSTATUS_MPIE_OFFSET;
const uint32_t MCAUSE_MPP_MASK   = 0x3 << MCAUSE_MPP_OFFSET;
const uint32_t MCAUSE_MPIE_MASK  = 0x1 << MCAUSE_MPIE_OFFSET;

// ---------------------------------------------------------------
// Test entry point
// ---------------------------------------------------------------
int main(int argc, char **argv){

  uint32_t (*tests[NUM_TESTS])();
  uint32_t test_res = 0x1;
  int      retval   = 0;

  // Add function pointers to new tests here
  tests[0] = mcause_mstatus_mirror_init;
  tests[1] = w_mcause_mpp_r_mstatus_mpp;
  tests[2] = w_mstatus_mpp_r_mcause_mpp;
  tests[3] = w_mcause_mpie_r_mstatus_mpie;
  tests[4] = w_mstatus_mpie_r_mcause_mpie;
  tests[5] = w_mie_notrap_r_zero;
  tests[6] = w_mip_notrap_r_zero;
  tests[7] = w_mtvt_rd_alignment;
  tests[8] = w_mtvec_rd_alignment;

  // Run all tests in list above
  printf("\nCLIC Test start\n\n");
  for (int i = 0; i < NUM_TESTS; i++) {
    test_res = set_test_status( run_test( (uint32_t (*)())(*tests[i]), i) , test_res);
  }

  // Report failures
  retval = get_result(test_res);
  return retval; // Nonzero for failing tests
}

uint32_t set_test_status(uint32_t test_no, uint32_t val_prev){
  uint32_t res;
  res = val_prev | (1 << test_no);
  return res;
}

uint32_t run_test(uint32_t (*ptr)(), uint32_t index) {
  return (*ptr)(index);
}

#pragma GCC push_options
#pragma GCC optimize ("O0")

uint32_t mcause_mstatus_mirror_init(uint32_t index){
  volatile uint8_t test_fail = 0;
  volatile uint32_t readback_val_mcause = 0x0;
  volatile uint32_t readback_val_mstatus = 0x0;

  printf("\nTesting mirroring of mcause.mpp/mpie and mstatus.mpp/mpie without write\n");
  __asm__ volatile ( R"(
    csrrs %0, mcause, x0
    csrrs %1, mstatus, x0
  )"
      : "=r"(readback_val_mcause), "=r"(readback_val_mstatus)
      :
      :
      );
  test_fail += (((readback_val_mcause & MCAUSE_MPP_MASK) >> MCAUSE_MPP_OFFSET) != ((readback_val_mstatus & MSTATUS_MPP_MASK) >> MSTATUS_MPP_OFFSET));
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);

  test_fail += (((readback_val_mcause & MCAUSE_MPIE_MASK) >> MCAUSE_MPIE_OFFSET) != ((readback_val_mstatus & MSTATUS_MPIE_MASK) >> MSTATUS_MPIE_OFFSET));
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);

  if (test_fail) {
    printf("\nTest: \"%s\" FAIL!\n", __FUNCTION__);
    return index + 1;
  }
  printf("\nTest: \"%s\" OK!\n", __FUNCTION__);
  return 0;
}

uint32_t w_mcause_mpp_r_mstatus_mpp(uint32_t index){

  volatile uint8_t  test_fail = 0;
  volatile uint32_t readback_val = 0x0;
  volatile uint32_t mcause_initial_val = 0x0;

  printf("\nTesting write to mcause.mpp, read from mstatus.mpp\n");
  // Backup mcause
  __asm__ volatile ( R"(
      csrrs %0, mcause, x0
  )"
      : "=r"(mcause_initial_val)
      :
      :
      );
  printf("Initial value mcause.mpp: %0lx\n", ((mcause_initial_val & MCAUSE_MPP_MASK) >> MCAUSE_MPP_OFFSET));

  // Bit set and read back
  __asm__ volatile ( R"(
      csrrs x0, mcause, %0
      csrrs %0, mstatus, x0
  )"
      : "=r"(readback_val)
      : "r"(MCAUSE_MPP_MASK)
      :
      );

  test_fail += (((readback_val & MSTATUS_MPP_MASK) >> MSTATUS_MPP_OFFSET) != 0x3);
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);
  printf("Read back mstatus.mpp after setting bits: %0lx\n", ((readback_val & MSTATUS_MPP_MASK) >> MSTATUS_MPP_OFFSET));

  // Bit clear and read back
  __asm__ volatile ( R"(
      csrrc x0, mcause, %0
      csrrc %0, mstatus, x0
  )"
      : "=r"(readback_val)
      : "r"(MCAUSE_MPP_MASK)
      :
      );

  test_fail += (((readback_val & MSTATUS_MPP_MASK) >> MSTATUS_MPP_OFFSET) != 0x0);
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);
  printf("Read back mstatus.mpp after clearing bits: %0lx\n", ((readback_val & MSTATUS_MPP_MASK) >> MSTATUS_MPP_OFFSET));

  // Restore value and read back
  __asm__ volatile ( R"(
      csrrw x0, mcause, %0
      csrrw %0, mstatus, x0
  )"
      : "=r"(readback_val)
      : "r"(mcause_initial_val)
      :
      );

  test_fail += (((readback_val & MSTATUS_MPP_MASK) >> MSTATUS_MPP_OFFSET) != ((mcause_initial_val & MCAUSE_MPP_MASK) >> MCAUSE_MPP_OFFSET));
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);
  printf("Read back mstatus.mpp after restore: %0lx\n", ((readback_val & MSTATUS_MPP_MASK) >> MSTATUS_MPP_OFFSET));

  if (test_fail) {
    printf("\nTest: \"%s\" FAIL!\n", __FUNCTION__);
    return index + 1;
  }
  printf("\nTest: \"%s\" OK!\n", __FUNCTION__);
  return 0;
}

// -----------------------------------------------------------------------------

uint32_t w_mstatus_mpp_r_mcause_mpp(uint32_t index){

  volatile uint8_t  test_fail = 0;
  volatile uint32_t readback_val = 0x0;
  volatile uint32_t mstatus_initial_val = 0x0;

  printf("\nTesting write to mstatus.mpp, read from mcause.mpp\n");

  // Backup mstatus
  __asm__ volatile ( R"(
      csrrs %0, mstatus, x0
  )"
      : "=r"(mstatus_initial_val)
      :
      :
      );

  printf("Initial value mstatus.mpp: %0lx\n", ((mstatus_initial_val & MSTATUS_MPP_MASK) >> MSTATUS_MPP_OFFSET));

  // Bit set and read back
  __asm__ volatile ( R"(
      csrrs x0, mstatus, %0
      csrrs %0, mcause, x0
  )"
      : "=r"(readback_val)
      : "r"(MSTATUS_MPP_MASK)
      :
      );

  test_fail += (((readback_val & MCAUSE_MPP_MASK) >> MCAUSE_MPP_OFFSET) != 0x3);
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);
  printf("Read back mcause.mpp after setting bits: %0lx\n", ((readback_val & MCAUSE_MPP_MASK) >> MCAUSE_MPP_OFFSET));

  // Bit clear and read back
  __asm__ volatile ( R"(
      csrrc x0, mstatus, %0
      csrrc %0, mcause, x0
  )"
      : "=r"(readback_val)
      : "r"(MSTATUS_MPP_MASK)
      :
      );

  test_fail += (((readback_val & MCAUSE_MPP_MASK) >> MCAUSE_MPP_OFFSET) != 0x0);
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);
  printf("Read back mcause.mpp after clearing bits: %0lx\n", ((readback_val & MCAUSE_MPP_MASK) >> MCAUSE_MPP_OFFSET));

  // Restore value and read back
  __asm__ volatile ( R"(
      csrrw x0, mstatus, %0
      csrrw %0, mcause, x0
  )"
      : "=r"(readback_val)
      : "r"(mstatus_initial_val)
      :
      );

  test_fail += (((readback_val & MCAUSE_MPP_MASK) >> MCAUSE_MPP_OFFSET) != ((mstatus_initial_val & MSTATUS_MPP_MASK) >> MSTATUS_MPP_OFFSET));
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);
  printf("Read back mcause.mpp after restore: %0lx\n", ((readback_val & MCAUSE_MPP_MASK) >> MCAUSE_MPP_OFFSET));

  if (test_fail) {
    printf("\nTest: \"%s\" FAIL!\n", __FUNCTION__);
    return index + 1;
  }
  printf("\nTest: \"%s\" OK!\n", __FUNCTION__);
  return 0;
}


uint32_t w_mcause_mpie_r_mstatus_mpie(uint32_t index){

  volatile uint8_t  test_fail = 0;
  volatile uint32_t readback_val = 0x0;
  volatile uint32_t mcause_initial_val = 0x0;

  printf("\nTesting write to mcause.mpie, read from mstatus.mpie\n");
  // Backup mcause
  __asm__ volatile ( R"(
      csrrs %0, mcause, x0
  )"
      : "=r"(mcause_initial_val)
      :
      :
      );

  printf("Initial value mcause.mpie: %0lx\n", ((mcause_initial_val & MCAUSE_MPIE_MASK) >> MCAUSE_MPIE_OFFSET));

  // Bit set and read back
  __asm__ volatile ( R"(
      csrrs x0, mcause, %0
      csrrs %0, mstatus, x0
  )"
      : "=r"(readback_val)
      : "r"(MCAUSE_MPIE_MASK)
      :
      );

  test_fail += (((readback_val & MSTATUS_MPIE_MASK) >> MSTATUS_MPIE_OFFSET) != 0x1);
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);
  printf("Read back mstatus.mpie after setting bits: %0lx\n", ((readback_val & MSTATUS_MPIE_MASK) >> MSTATUS_MPIE_OFFSET));

  // Bit clear and read back
  __asm__ volatile ( R"(
      csrrc x0, mcause, %0
      csrrc %0, mstatus, x0
  )"
      : "=r"(readback_val)
      : "r"(MCAUSE_MPIE_MASK)
      :
      );

  test_fail += (((readback_val & MSTATUS_MPIE_MASK) >> MSTATUS_MPIE_OFFSET) != 0x0);
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);
  printf("Read back mstatus.mpie after clearing bits: %0lx\n", ((readback_val & MSTATUS_MPIE_MASK) >> MSTATUS_MPIE_OFFSET));
  // Restore value and read back
  __asm__ volatile ( R"(
      csrrw x0, mcause, %0
      csrrw %0, mstatus, x0
  )"
      : "=r"(readback_val)
      : "r"(mcause_initial_val)
      :
      );

  test_fail += (((readback_val & MSTATUS_MPIE_MASK) >> MSTATUS_MPIE_OFFSET) != ((mcause_initial_val & MCAUSE_MPIE_MASK) >> MCAUSE_MPIE_OFFSET));
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);
  printf("Read back mcause.mpie after restore: %0lx\n", ((readback_val & MSTATUS_MPIE_MASK) >> MSTATUS_MPIE_OFFSET));

  if (test_fail) {
    printf("\nTest: \"%s\" FAIL!\n", __FUNCTION__);
    return index + 1;
  }
  printf("\nTest: \"%s\" OK!\n", __FUNCTION__);
  return 0;
}

uint32_t w_mstatus_mpie_r_mcause_mpie(uint32_t index){

  volatile uint8_t  test_fail = 0;
  volatile uint32_t readback_val = 0x0;
  volatile uint32_t mstatus_initial_val = 0x0;

  printf("\nTesting write to mstatus.mpie, read from mcause.mpie\n");

  // Backup mstatus
  __asm__ volatile ( R"(
      csrrs %0, mstatus, x0
  )"
      : "=r"(mstatus_initial_val)
      :
      :
      );

  printf("Initial value mstatus.mpie: %0lx\n", ((mstatus_initial_val & MSTATUS_MPIE_MASK) >> MSTATUS_MPIE_OFFSET));

  // Bit set and read back
  __asm__ volatile ( R"(
      csrrs x0, mstatus, %0
      csrrs %0, mcause, x0
  )"
      : "=r"(readback_val)
      : "r"(MSTATUS_MPIE_MASK)
      :
      );

  test_fail += (((readback_val & MCAUSE_MPIE_MASK) >> MCAUSE_MPIE_OFFSET) != 0x1);
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);
  printf("Read back mcause.mpie after setting bits: %0lx\n", ((readback_val & MCAUSE_MPIE_MASK) >> MCAUSE_MPIE_OFFSET));

  // Bit clear and read back
  __asm__ volatile ( R"(
      csrrc x0, mstatus, %0
      csrrc %0, mcause, x0
  )"
      : "=r"(readback_val)
      : "r"(MSTATUS_MPIE_MASK)
      :
      );

  test_fail += (((readback_val & MCAUSE_MPIE_MASK) >> MCAUSE_MPIE_OFFSET) != 0x0);
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);
  printf("Read back mcause.mpie after clearing bits: %0lx\n", ((readback_val & MCAUSE_MPIE_MASK) >> MCAUSE_MPIE_OFFSET));

  // Restore value and read back
  __asm__ volatile ( R"(
      csrrw x0, mstatus, %0
      csrrw %1, mcause, x0
  )"
      : "=r"(readback_val)
      : "r"(mstatus_initial_val)
      :
      );

  test_fail += (((readback_val & MCAUSE_MPIE_MASK) >> MCAUSE_MPIE_OFFSET) != ((mstatus_initial_val & MSTATUS_MPIE_MASK) >> MSTATUS_MPIE_OFFSET));
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);
  printf("Read back mcause.mpie after restore: %0lx\n", ((readback_val & MCAUSE_MPIE_MASK) >> MCAUSE_MPIE_OFFSET));

  if (test_fail) {
    printf("\nTest: \"%s\" FAIL!\n", __FUNCTION__);
    return index + 1;
  }
  printf("\nTest: \"%s\" OK!\n", __FUNCTION__);
  return 0;
}

#pragma GCC pop_options

uint32_t w_mie_notrap_r_zero(uint32_t index){
  uint8_t test_fail = 0;
  volatile uint32_t readback_val_mepc = 0x0;
  volatile uint32_t readback_val_mie = 0x0;
  printf("\nTesting write to mie, should not trap and readback 0\n");
  __asm__ volatile ( R"(
      addi t0, x0, -1
      csrrw x0, mepc, t0
      csrrw x0, mie, t0
      csrrw %1, mie, x0
      csrrw %0, mepc, x0
  )"
      : "=r"(readback_val_mepc), "=r"(readback_val_mie)
      :
      : "t0"
      );

  test_fail = (readback_val_mepc != 0xfffffffe) || (readback_val_mie != 0);
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);

  if (test_fail) {
    printf("\nTest: \"%s\" FAIL!\n", __FUNCTION__);
    printf("\nMIE: 0x%08lx, MEPC: 0x%08lx\n", readback_val_mie, readback_val_mepc);
    return index + 1;
  }
  printf("\nTest: \"%s\" OK!\n", __FUNCTION__);
  return 0;
}


uint32_t w_mip_notrap_r_zero(uint32_t index){
  uint8_t test_fail = 0;
  volatile uint32_t readback_val_mepc = 0x0;
  volatile uint32_t readback_val_mip = 0x0;
  printf("\nTesting write to mip, should not trap and readback 0\n");
  __asm__ volatile ( R"(
      addi t0, x0, -1
      csrrw x0, mepc, t0
      csrrw x0, mip, t0
      csrrw %1, mip, x0
      csrrw %0, mepc, x0
  )"
      : "=r"(readback_val_mepc), "=r"(readback_val_mip)
      :
      : "t0"
      );

  test_fail = (readback_val_mepc != 0xfffffffe) || ( readback_val_mip != 0);
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);

  if (test_fail) {
    printf("\nTest: \"%s\" FAIL!\n", __FUNCTION__);
    printf("\nMIP: 0x%08lx, MEPC: 0x%08lx\n", readback_val_mip, readback_val_mepc);
    return index + 1;
  }
  printf("\nTest: \"%s\" OK!\n", __FUNCTION__);
  return 0;
}

uint32_t w_mtvt_rd_alignment(uint32_t index){
  uint8_t test_fail = 0;
  volatile uint32_t mtvt_initial_val = 0x0;
  volatile uint32_t readback_val_mtvt = 0x0;

  // Clear mtvt
  __asm__ volatile ( R"(
      csrrw %0, 0x307, x0
      csrrw %1, 0x307, %1
  )"
      : "=r"(mtvt_initial_val), "=r"(readback_val_mtvt)
      : "r"(mtvt_initial_val)
      :
      );

  // All bits should be zeroed
  test_fail += readback_val_mtvt;
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);

  __asm__ volatile ( R"(
      addi t0, x0, -1
      csrrw %0, 0x307, t0
      csrrw %1, 0x307, %1
  )"
      : "=r"(mtvt_initial_val), "=r"(readback_val_mtvt)
      : "r"(mtvt_initial_val)
      :
      );

  // Check for correct alignment
  test_fail += ~(readback_val_mtvt >> max(SMCLIC_ID_WIDTH+2, 6));
  if (ABORT_ON_ERROR_IMMEDIATE) assert (test_fail == 0);
  printf("\nmtvt readback after 0xffff_ffff write: 0x%08lx\n", readback_val_mtvt);

  if (test_fail) {
    printf("\nTest: \"%s\" FAIL!\n", __FUNCTION__);
    return index + 1;
  }
  printf("\nTest: \"%s\" OK!\n", __FUNCTION__);
  return 0;
}

uint32_t w_mtvec_rd_alignment(uint32_t index){
  uint8_t test_fail = 0;
  volatile uint32_t mtvec_initial_val = 0x0;
  volatile uint32_t readback_val_mtvec = 0x0;

  // Clear mtvec
  __asm__ volatile ( R"(
      csrrw %0, mtvec, x0
      csrrw %1, mtvec, %1
  )"
      : "=r"(mtvec_initial_val), "=r"(readback_val_mtvec)
      : "r"(mtvec_initial_val)
      :
      );

  // All bits above 2 should be zeroed
  test_fail += (readback_val_mtvec >> 2);
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);

  __asm__ volatile ( R"(
      addi t0, x0, -1
      csrrw %0, mtvec, t0
      csrrw %1, mtvec, %1
  )"
      : "=r"(mtvec_initial_val), "=r"(readback_val_mtvec)
      : "r"(mtvec_initial_val)
      :
      );

  // upper bits all writeable
  test_fail += ~(readback_val_mtvec >> 7);
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);
  // lower [6:2] bits not updated
  test_fail += ((readback_val_mtvec << 25) >> 2);
  if (ABORT_ON_ERROR_IMMEDIATE) assert(test_fail == 0);

  printf("\nmtvec readback after 0xffff_ffff write: 0x%08lx\n", readback_val_mtvec);

  if (test_fail) {
    printf("\nTest: \"%s\" FAIL!\n", __FUNCTION__);
    return index + 1;
  }
  printf("\nTest: \"%s\" OK!\n", __FUNCTION__);
  return 0;
}

int get_result(uint32_t res){
  if (res == 1) {
    printf("ALL PASS\n\n");
    return 0;
  }
  printf("\nResult: 0x%0lx\n", res);
  for (int i = 1; i <= NUM_TESTS; i++){
    if ((res >> i) & 0x1) {
      printf ("Test %0d failed\n", i-1);
    }
  }
  return res;
}

uint32_t max(uint32_t a, uint32_t b) {
  return a > b ? a : b;
}
