.data

comps_cnt:     .dword 0
comps_addr:    .dword
switcher_caps: .dword

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
    ldr       clr, [sp]
    ret       clr

/**
 * Sets up memory for compartments
 *
 * @param c0 Start address of switcher memory region
 * @param c1 Address of `switch_compartment`
 */
.type init_compartments, "function"
init_compartments:

    // Derive DDC
    cvtp      c0, x0
    scbnds    c0, c0, x1

    // Derive PCC
    cvtp      c1, x2
    mov       x2, #320 // TODO dynamic value
    scbndse   c1, c1, x2

    // Store (DDC, PCC) at `[switcher_caps]`
    ldr       x3, switcher_caps
    stp       c0, c1, [x3]

    ret

/**
 * Function to add information for a compartment
 *
 * @param c0 Start address
 * @param c1 Function address
 */
.type add_compartment, "function"
add_compartment:
  // Derive compartment PCC

  // Derive compartment DDC

  // Increment counter
  adr         x2, comps_cnt
  ldr         x3, [x2]
  add         x3, x3, #1
  str         x3, [x2]


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
