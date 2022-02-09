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

extern void* __capability * comps_addr;
extern size_t comps_cnt;

extern void* init_compartments();
extern void* add_compartment(size_t, void*);

/*******************************************************************************
 * Main
 ******************************************************************************/

int comp_f_fn();

int
main()
{
    init_compartments();

    size_t comp_size = 2000;
    assert(add_compartment(comp_size, comp_f_fn) != MAP_FAILED);

    assert(comps_cnt == 1);

    void* __capability comp_ddc = comps_addr[0];
    assert(cheri_is_valid(comp_ddc));
    assert(cheri_length_get(comp_ddc) == comp_size);

    void* __capability comp_pcc = comps_addr[1];
    assert(cheri_is_valid(comp_pcc));
    assert(cheri_address_get(comp_pcc) == (unsigned long) comp_f_fn);

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
