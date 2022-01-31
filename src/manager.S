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
.global init_compartments
.global add_compartment
.global del_compartment

/**
 * Sets up memory for compartments
 *
 * @param c0 Start address of switcher memory region
 * @param c1 Address of `switch_compartment`
 */
.type init_compartments, "function"
init_compartments:
    // Get address to store at
    adr       x3, switcher_caps

    // Derive DDC
    cvtp      c0, x0
    scbnds    c0, c0, #32

    // Store DDC
    str       c0, [x3]
    add       x3, x3, #16

    // Derive PCC
    cvtp      c1, x1
    mov       x2, #320 // TODO dynamic value
    scbndse   c1, c1, x2

    // Store PCC
    str       c1, [x3]

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
