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
.global init_compartments
.global add_compartment
.global del_compartment

/**
 * Sets up memory for compartments
 *
 * Initializes required memory for compartments. This involves allocating a
 * memory region for use by switcher code, to contain required capabilities,
 * and deriving appropriate PCC/DDC values containing the executable switcher
 * code, and the aforementioned memory region, respectively.
 *
 * @return Pointer to newly allocated memory region
 */
.type init_compartments, "function"
init_compartments:
    // Compute size of required memory, equivalent to `length` parameter of
    // `mmap`
    mov       x1, #(32 + (COMP_SIZE * MAX_COMP_COUNT))

    // Store length and `lr` on stack, as we'll need them later
    stp       x1, lr, [sp, #-16]!

    // Allocate memory for switcher
    mov       x0, xzr    // address
                         // length - already stored in `x1`
    mov       w2, #3     // prot == PROT_READ | PROT_WRITE
    mov       w3, #4098  // flags == MAP_PRIVATE | MAP_ANONYMOUS
    mov       w4, #-1    // fd
    mov       w5, wzr    // offset
    bl        mmap

    // Restore length and `lr`
    ldp       x1, lr, [sp], #16

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

    // Store (DDC, PCC) at `switcher_caps` (saved in `x0`)
    mov       x1, x0
    stp       c2, c3, [x1], #32

    // Save start address for compartment capabilities in `comps_addr`
    adr       x2, comps_addr
    str       x1, [x2]

    ret

/**
 * Function to add information for a compartment
 *
 * @param x0 Compartment memory size
 * @param x1 Compartment executable function
 *
 * @return Pointer to newly allocated memory region
 */
.type add_compartment, "function"
add_compartment:
    // Store inputs and `lr` so we can call `mmap`
    stp       x0, x1, [sp, #-32]!
    str       lr, [sp, #16]
    mov       x1, x0

    // Allocate memory for new compartment
    mov       x0, xzr    // address
                         // length - already stored in `x1`
    mov       w2, #3     // prot == PROT_READ | PROT_WRITE
    mov       w3, #4098  // flags == MAP_PRIVATE | MAP_ANONYMOUS
    mov       w4, #-1    // fd
    mov       w5, wzr    // offset
    bl        mmap

    // Restore memory size and function address
    ldp       x1, x2, [sp], #32
    ldr       lr, [sp, #-16]

    // Derive compartment DDC
    cvtp      c0, x0
    scbnds    c0, c0, x1

    // Derive compartment PCC
    cvtp      c1, x2
    mov       x2, #320 // TODO dynamic value
    scbndse   c1, c1, x2

    // Store new PCC and DDC
    ldr       x2, comps_addr
    ldr       x3, comps_cnt
    mov       x4, #COMP_SIZE
    madd      x2, x3, x4, x2
    stp       c0, c1, [x2]

    // Increment counter
    adr       x4, comps_cnt
    add       x3, x3, #1
    str       x3, [x4]

    // Check we have not exceeded max number of compartments
    cmp       x3, #MAX_COMP_COUNT
    b.gt      abort

    ret

/**
 * Function to delete an existing compartment data
 *
 * @param x0 Function of compartment to be deleted
 */
.type del_compartment, "function"
del_compartment:
    // Find capabilities (DDC/PCC) of given compartment
    ldr       x1, comps_addr
    mov       w2, #0
    ldr       w3, comps_cnt

pcc_check_start:
    ldr       c4, [x1, #COMP_OFFSET_PCC] // get current stored PCC to check
    gcvalue   x4, c4
    cmp       x4, x0 // check value of current PCC against given function
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
    stp       x1, lr, [sp, #-16]! // store `x1` and `lr`
    ldr       c2, [x1, #COMP_OFFSET_DDC]

    // Unmap memory region allocated
    gcvalue   x0, c2
    gclen     x1, c2
    bl        munmap
    cmp       x0, #-1
    b.eq      abort // munmap failed
    ldp       x0, lr, [sp], #16

    // Shift subsequent capabilities forward (if we delete the last
    // compartment, we put gibberish instead)
    ldr       w5, comps_cnt
    mov       x6, #COMP_SIZE
    ldr       x7, comps_addr
    madd      x5, x5, x6, x7 // Get last allocated compartment address
shift_next_comp:
    add       x1, x0, #COMP_SIZE
    ldp       c2, c3, [x1] // load next (DDC, PCC)
    stp       c2, c3, [x0]     // store them
    add       x1, x1, #COMP_OFFSET_STK_ADDR
    ldr       x2, [x1]                        // load next (STK_ADDR)
    str       x2, [x0, #COMP_OFFSET_STK_ADDR] // store it
    add       x0, x0, #COMP_SIZE
    cmp       x0, x5
    b.lt      shift_next_comp

    ret
