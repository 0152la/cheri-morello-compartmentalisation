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
 * Extern functions
 ******************************************************************************/

extern void* init_compartments();
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
