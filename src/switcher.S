#include "comps_offsets.h"

.text
.balign 4

.global call_comp_func
.global switch_compartment
.global switcher_start
.global switcher_end


/**
 * Entry point from user code to switcher function
 *
 * @param x0 Address of function to call
 * @param x1-x6 Parameters to pass to called function
 */
.type call_comp_func, "function"
call_comp_func:
    // Derive and save `clr`
    cvtp      clr, lr
    str       clr, [sp, #-16]!

    // Retrieve local cap for calling switcher
    mrs       c7, DDC
    ldr       c7, [x7]
    ldpblr    c29, [c7]

    // Restore `clr` and return
    ldr       clr, [sp], #16
    ret       clr

switcher_start:

/** Code to perform actual switch.
 *
 * @param x0 Compartment info to switch to, as stored in `comps_addr`
 *           pseudo-array
 * @param c29 Expected to hold the switcher DDC
 */
.type switch_compartment, "function"
switch_compartment:
    // Store entering compartment's DDC, and move to memory containing
    // compartment info
    mrs       c15, DDC
    mov       x10, x0

    // Expect switcher DDC in c29
    msr       DDC, c29

    // Save parameters on stack
    //stp       x1, x2, [sp, #-48]!
    //stp       x3, x4, [sp, #32]
    //stp       x5, x6, [sp, #16]

    // Get corresponding compartment info
    mov       c19, clr
    bl        pcc_from_addr
    mov       clr, c19
    mov       x10, x7 // get base address of compartment info to jump to

    // Pop parameters from stack
    //ldp       x1, x2, [sp], #48
    //ldp       x3, x4, [sp, #-16]
    //ldp       x5, x6, [sp, #-32]

    // Load DDC
    ldr       c12, [x10, #COMP_OFFSET_DDC]

    // Setup SP
    mov       x14, sp
    ldr       x13, [x10, #COMP_OFFSET_STK_ADDR]
    mov       sp, x13

    // Install compartment DDC
    msr       DDC, c12

    // Save old DDC (c2), old SP (x12), old CLR (clr) on stack
    stp       c15, clr, [sp, #-48]!
    str       x14, [sp, #32]

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
    mov       x19, sp
    blr       c0
    mov       sp, x19

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

clean:
    mov       x0, #0
    mov       x1, #0
    mov       x2, #0
    mov       x3, #0
    mov       x4, #0
    mov       x5, #0
    mov       x6, #0
    mov       x7, #0
    mov       x8, #0
    mov       x9, #0
    mov       x10, #0
    mov       x11, #0
    mov       x12, #0
    mov       x13, #0
    mov       x14, #0
    mov       x15, #0
    mov       x16, #0
    mov       x17, #0
    // x18 is the "platform register" (for some platforms). If so, it needs to
    // be preserved, but here we assume that only the lower 64 bits are
    // required.
    mov       x18, x18
    // x19-x29 are callee-saved, but only the lower 64 bits.
    mov       x19, x19
    mov       x20, x20
    mov       x21, x21
    mov       x22, x22
    mov       x23, x23
    mov       x24, x24
    mov       x25, x25
    mov       x26, x26
    mov       x27, x27
    mov       x28, x28
    mov       x29, x29  // FP
    // We need LR (x30) to return. The call to this helper already cleaned it.
    // Don't replace SP; this needs special handling by the caller anyway.
    ret

/**
 * Get PCC cap from given address
 *
 * We don't touch `x0`-`x6`, as they are used by the caller (except to update
 * `x0` from an address to the saved capability containing that address)
 *
 * @param x0 Address of function corresponding to a saved compartment
 * @return Base address of compartment (`x0`), and PCC cap (`c1`)
 */
.type pcc_from_addr, "function"
pcc_from_addr:
    // Find capabilities (DDC/PCC) of given compartment
    mrs       c10, DDC
    add       x7, x10, #SWITCHER_OFFSET_COMPS        // set pointer to `comps_addr`
    mov       w8, #0
    ldr       w9, [x10, #SWITCHER_OFFSET_COMP_COUNT] // get `comps_cnt`

pcc_check_start:
    ldr       c10, [x7, #COMP_OFFSET_PCC] // get current stored PCC to check
    gcvalue   x11, c10
    cmp       x11, x0 // check value of current PCC against given function
    b.eq      pcc_found
    add       w8, w8, #7
    cmp       w8, w9 // compartment bounds check
    b.eq      pcc_not_found
    add       x7, x7, #COMP_SIZE // go check next PCC
    b         pcc_check_start

pcc_not_found:
    b         abort

pcc_found:
    // We found the address to the start of the compartment info area, at
    // address `$x7`
    mov       c0, c10 // move PCC in register we'll need it in
    ret

switcher_end:
