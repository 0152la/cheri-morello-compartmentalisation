.data

comps_cnt:     .dword 0
comps_addr:    .dword 0
switcher_caps: .dword 0

.text
.balign 4

#include "comps_offsets.h"

// Variables
.global comps_cnt
.global comps_addr
.global switcher_caps

// Functions
.global asm_call_wrapper
.global init_compartments
.global add_compartment
.global del_compartment

/**
 * Wrapper to store/restore state when coming from C
 *
 * @param x0 ASM function to call
 * @param x1-x6 parameters to pass to function in c0
 */
.type asm_call_wrapper, "function"
asm_call_wrapper:
    // Save `x0` so we can temporarily use it
    cvtp      c0, x0
    str       c0, [sp]

    // Derive `clr` (in case asm function does something weird with `PCC`)
    cvtp      c0, lr
    swp       c0, c0, [sp]
    sub       sp, sp, #16

    blr       c0
    ldr       clr, [sp, #16]!
    ret       clr

/**
 * Sets up memory for compartments
 *
 * Initializes required memory for compartments. This involves allocating a
 * memory region for use by switcher code, to contain required capabilities,
 * and deriving appropriate PCC/DDC values containing the executable switcher
 * code, and the aforementioned memory region, respectively.
 */
.type init_compartments, "function"
init_compartments:
    // Save `lr`
    mov       x6, lr

    // Compute size of required memory, equivalent to `length` parameter of
    // `mmap`
    mov       x0, #COMP_SIZE
    mov       x1, #MAX_COMP_COUNT
    mov       x2, #32    // size of the 2 switcher capabilities
    madd      x1, x0, x1, x2

    // Allocate memory for switcher
    mov       x0, xzr    // address
                         // length - already stored in `x1`
    mov       w2, #3     // prot == PROT_READ | PROT_WRITE
    mov       w3, #4098  // flags == MAP_PRIVATE | MAP_ANONYMOUS
    mov       w4, #-1    // fd
    mov       w5, wzr    // offset
    bl        mmap

    // Restore `lr`
    mov       lr, x6

    // Save pointer to new allocated memory in `switcher_caps`
    adr       x2, switcher_caps
    str       x0, [x2]

    // Derive DDC for switcher
    cvtp      c2, x0
    scbnds    c2, c2, x1

    // Derive PCC for `switch_compartments` and friends
    adr       x3, switcher_entry
    adr       x4, switch_compartment_end
    sub       x4, x4, x3
    cvtp      c3, x3
    scbndse   c3, c3, x4

    // Store (DDC, PCC) at `switcher_caps`
    ldr       x1, switcher_caps
    stp       c2, c3, [x1], #32

    // Save start address for compartment capabilities in `comps_addr`
    adr       x2, comps_addr
    str       x1, [x2]

    ret

/**
 * Function to add information for a compartment
 *
 * @param c1 Start address
 * @param c2 Size of memory region
 * @param c3 Function address
 */
.type add_compartment, "function"
add_compartment:

  // Derive compartment PCC
  cvtp        c3, x3
  mov         x4, #320 // TODO dynamic value
  scbndse     c3, c3, x4

  // Derive compartment DDC
  cvtp        c1, x1
  scbnds      c2, c1, x2

  // Store new PCC and DDC
  ldr         x0, comps_addr
  ldr         x1, comps_cnt
  mov         x3, #COMP_SIZE
  madd        x0, x1, x2, x0
  stp         c3, c2, [x0]

  // Increment counter
  adr         x3, comps_cnt
  ldr         x4, [x3]
  add         x4, x4, #1
  str         x4, [x3]

  // Update switcher DDC
  adr         x2, switcher_caps
  ldr         c0, [x2]
  gclen       x1, c0
  add         x1, x1, #32
  scbndse     c0, c0, x1
  str         c0, [x2]

  ret

/**
 * Function to delete an existing compartment data
 *
 * @param c0 ID of compartment to be deleted
 */
.type del_compartment, "function"
del_compartment:
