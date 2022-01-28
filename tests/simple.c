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

const size_t switcher_mem_max_size;

/*******************************************************************************
 * Extern functions
 ******************************************************************************/

extern int switch_compartment();
extern void init_compartments(uint8_t*, uintptr_t);

extern void* comps_addr;
extern void* switcher_caps;

/*******************************************************************************
 * Main
 ******************************************************************************/

int
main()
{
    switcher_caps = malloc(sizeof(void* __capability) * 2);
    comps_addr = malloc(COMP_SIZE * 10);

    uint8_t* switcher_start = malloc(switcher_mem_max_size);
    uintptr_t switch_comp_addr = (uintptr_t) switch_compartment;

    init_compartments(switcher_start, switch_comp_addr);
    return 0;
}
