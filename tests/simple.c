#include "stdint.h"
#include "stdlib.h"

#include "cheriintrin.h"

/*******************************************************************************
 * Globals and constants
 ******************************************************************************/

const size_t switcher_mem_max_size;

/*******************************************************************************
 * Extern functions
 ******************************************************************************/

extern int switch_compartment();
extern void init_compartments(uint8_t*, uintptr_t);

/*******************************************************************************
 * Main
 ******************************************************************************/

int
main()
{
    uint8_t* switcher_start = malloc(switcher_mem_max_size);
    uintptr_t switch_comp_addr = (uintptr_t) switch_compartment;

    init_compartments(switcher_start, switch_comp_addr);
    return 0;
}
