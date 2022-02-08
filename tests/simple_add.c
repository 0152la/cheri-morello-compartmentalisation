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
extern void init_compartments(void*, size_t, void*);
extern void add_compartment(void*, size_t, void*);
extern int switch_compartment();

extern void* comps_addr;
extern void* switcher_caps;

/*******************************************************************************
 * Main
 ******************************************************************************/

int comp_f_fn();

int
main()
{
    switcher_caps = malloc(sizeof(void* __capability) * 2);
    comps_addr = malloc(COMP_SIZE * max_comp_cnt);

    void* switcher_start = malloc(switcher_mem_max_size);
    void* switch_comp_addr = switch_compartment;

    asm_call_wrapper(init_compartments,
                     switcher_start, switcher_mem_max_size, switch_comp_addr);

    const size_t comp_f_size = 1000;
    uintptr_t comp_f_start = (uintptr_t) malloc(comp_f_size);
    asm_call_wrapper(add_compartment,
                     comp_f_start, comp_f_size, comp_f_fn);

    return 0;
}

/*******************************************************************************
 * Compartments
 ******************************************************************************/

int
comp_f_fn()
{
    return 42;
}
