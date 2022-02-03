#include "assert.h"
#include "stdint.h"
#include "stdlib.h"

#include "cheriintrin.h"

#include "comps_offsets.h"

static_assert(COMP_SIZE == sizeof(void* __capability) * 3, "Invalid `COMP_SIZE` provided");
static_assert(COMP_OFFSET_DDC == sizeof(void* __capability) * 1, "Invalid `COMP_OFFSET_DDC` provided.");
static_assert(COMP_OFFSET_STK_ADDR == sizeof(void* __capability) * 2, "Invalid `COMP_OFFSET_STK_LEN` provided.");

/*******************************************************************************
 * Globals and constants
 ******************************************************************************/

const size_t max_comp_cnt = 2;
const size_t switcher_mem_max_size = max_comp_cnt * COMP_SIZE;

/*******************************************************************************
 * Extern functions
 ******************************************************************************/

extern void asm_call_wrapper(void*, ...);
extern void init_compartments(uint8_t*, size_t, uintptr_t);
extern int switch_compartment();

extern void* comps_addr;
extern void* switcher_caps;

/*******************************************************************************
 * Main
 ******************************************************************************/

int
main()
{
    switcher_caps = malloc(sizeof(void* __capability) * 2);
    comps_addr = malloc(COMP_SIZE * max_comp_cnt);

    uint8_t* switcher_start = malloc(switcher_mem_max_size);
    uintptr_t switch_comp_addr = (uintptr_t) switch_compartment;

    asm_call_wrapper(init_compartments,
                     switcher_start, switcher_mem_max_size, switch_comp_addr);
    return 0;
}
