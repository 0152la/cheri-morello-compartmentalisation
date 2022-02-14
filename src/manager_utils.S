#include "comps_offsets.h"

// Functions
.global pcc_from_addr

/**
 * Get PCC cap from given address
 * *
 * @param x0 Address
 * @return Base address of compartment (`x0`), and PCC cap (`c1`)
 */
.type pcc_from_addr, "function"
pcc_from_addr:
    // Find capabilities (DDC/PCC) of given compartment
    ldr       x1, comps_addr
    mov       w2, #0
    ldr       w3, comps_cnt

pcc_check_start:
    ldr       c4, [x1, #COMP_OFFSET_PCC] // get current stored PCC to check
    gcvalue   x5, c4
    cmp       x5, x0 // check value of current PCC against given function
    b.eq      pcc_found
    add       w2, w2, #1
    cmp       w2, w3 // compartment bounds check
    b.eq      pcc_not_found
    add       x1, x1, #COMP_SIZE // go check next PCC
    b         pcc_check_start

pcc_not_found:
    b         abort

pcc_found:
    // We found the address to the start of the compartment info area, at
    // address `$x1`
    mov       x0, x1
    mov       c1, c4
    ret
