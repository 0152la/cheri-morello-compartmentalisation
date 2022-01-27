.global switcher_entry
.global switch_compartment

/**
 * Entry point from user code to switcher function
 *
 * @param c0 DDC of switcher, containing compartment information
 */
.type switcher_entry, "function"
switcher_entry:
    mov      c29, c0
    mov      x0, #0
    cvtp     clr, lr
    b        switch_compartment
    ret      clr

/** Code to perform actual switch
 *
 * @param x0 ID (in `comps` array) of compartment to switch to
 */
.type switch_compartment, "function"
switch_compartment:
    // Store entering compartment's DDC, and move to memory containing
    // compartment info
    mrs       c2, DDC
    mov       x10, x0

    // Expect switcher DDC in c29
    msr       DDC, c29

    // Get compartment to switch to data
    mov       x11, #COMP_SIZE
    mul       x10, x10, x11

    // Load PCC, including function we are jumping to within compartment
    add       x11, x10, #COMP_OFFSET_PCC
    ldr       c0, [x29, x11]

    // Load DDC
    add       x11, x10, #COMP_OFFSET_DDC
    ldr       c1, [x29, x11]

    // Setup SP
    mov       x12, sp
    add       x11, x10, #COMP_OFFSET_STK_ADDR
    ldr       x11, [x29, x11]
    mov       sp, x11

    // Install compartment DDC
    msr       DDC, c1

    // Save old DDC (c2), old SP (x12), old CLR (clr) on stack
    stp       c2, clr, [sp, #-48]!
    str       x12, [sp, #32]

    // Stack layout at this point:
    //
    //     `stack + size` -> ________________________
    //            sp + 40 -> [  <alignment pad>  ]   ^
    //            sp + 32 -> [      old SP       ]   |
    //            sp + 24 -> [ old CLR (hi64)    ]   |
    //            sp + 16 -> [ old CLR (lo64)    ]   |
    //            sp +  8 -> [ old DDC (high 64) ]   | DDC bounds
    //            sp +  0 -> [ old DDC (low 64)  ]   |
    //                                 :             :
    //            `stack` -> ________________________v

    // Clean all registers, except register used to call function within
    // compartment we are transitioning to
    bl        clean+4

    // Jump to the function within the compartment we are switching to (this
    // also sets PCC)
    blr       c0

    // Clean capabilities left in the return value.
    mov       w0, w0
    bl        clean

    // Restore the caller's context and compartment.
    ldp       c10, clr, [sp]
    ldr       x12, [sp, #32]
    msr       DDC, c10
    mov       x10, #0
    mov       sp, x12

    ret       clr

