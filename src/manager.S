// Variables
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
    // Derive DDC
    cvtp      c0, x0
    scbnds   c0, c0, #32

    // Store DDC
    str       c0, =comps_addr

    // Derive PCC
    cvtp      c1, x1
    mov       x2, #320 // TODO dynamic value
    scbndse   c1, c1, x2

    // Store PCC
    str       c1, =comps_addr+16

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

  // Update DDC
  ldr         c0, =comps_addr
  gclen       x1, c0
  add         x1, x1, #32
  scbndse     c0, c0, x1
  str         c0, =comps_addr

  ret

/**
 * Function to delete an existing compartment data
 *
 * @param c0 ID of compartment to be deleted
 */
.type del_compartment, "function"
del_compartment:
