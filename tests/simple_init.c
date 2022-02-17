#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/mman.h>

#include "cheriintrin.h"

#include "comps_offsets.h"

/*******************************************************************************
 * Extern functions
 ******************************************************************************/

extern void* init_compartments();
extern void* __capability * switcher_caps;

extern void switcher_start();
extern void switcher_end();

/*******************************************************************************
 * Main
 ******************************************************************************/

int
main()
{
    void* inner_addr = init_compartments();

    assert(inner_addr != MAP_FAILED);
    assert(switcher_caps == inner_addr);

    void* __capability switcher_ddc = switcher_caps[0];
    assert(cheri_is_valid(switcher_ddc));
    assert(cheri_length_get(switcher_ddc) ==
            COMP_SIZE * MAX_COMP_COUNT + SWITCHER_OFFSET_COMPS);

    void* __capability switcher_pcc = switcher_caps[1];
    assert(cheri_is_valid(switcher_pcc));
    assert(cheri_address_get(switcher_pcc) == (unsigned long) switcher_start);
    assert(cheri_address_get(switcher_pcc) + cheri_length_get(switcher_pcc) ==
            (unsigned long) switcher_end);

    return 0;
}
