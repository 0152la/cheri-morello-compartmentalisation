#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/mman.h>

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

extern void* init_compartments();
extern int switch_compartment();

extern void* comps_addr;
extern void* switcher_caps;

/*******************************************************************************
 * Main
 ******************************************************************************/

int
main()
{
    void* inner_addr = init_compartments();
    assert(switcher_caps != MAP_FAILED);

    return 0;
}
