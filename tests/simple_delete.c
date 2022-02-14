#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/mman.h>

#include "cheriintrin.h"

#include "comps_offsets.h"

/*******************************************************************************
 * Extern functions
 ******************************************************************************/

extern void* __capability * comps_addr;
extern size_t comps_cnt;

extern void* init_compartments();
extern void* add_compartment(size_t, void*);
extern void* del_compartment(void*);

/*******************************************************************************
 * Main
 ******************************************************************************/

int comp_f_fn();
int comp_g_fn();
int comp_h_fn();

/**
 * Checks whether a (DDC, PCC) pair at a given offset into the `comps_addr`
 * pseudo-array are valid, and point to the given function.
 *
 * @param id Offset into `comps_addr` array, where we expect a DDC cap,
 *           followed by a PCC cap
 * @param func Pointer to function expected in the PCC
 */
void
check_valid_compartment_caps(size_t id, void* func)
{
    const size_t comps_fields_count = 3;
    void* __capability comp_ddc = comps_addr[id * comps_fields_count];
    assert(cheri_is_valid(comp_ddc));

    void* __capability comp_pcc = comps_addr[id * comps_fields_count + 1];
    assert(cheri_is_valid(comp_pcc));
    assert(cheri_address_get(comp_pcc) == (unsigned long) func);
}

int
main()
{
    init_compartments();

    size_t comp_size = 2000;
    assert(add_compartment(comp_size, comp_f_fn) != MAP_FAILED);
    assert(add_compartment(comp_size, comp_g_fn) != MAP_FAILED);
    assert(add_compartment(comp_size, comp_h_fn) != MAP_FAILED);

    assert(comps_cnt == 3);
    check_valid_compartment_caps(0, comp_f_fn);
    check_valid_compartment_caps(1, comp_g_fn);
    check_valid_compartment_caps(2, comp_h_fn);

    del_compartment(comp_g_fn);

    check_valid_compartment_caps(0, comp_f_fn);
    check_valid_compartment_caps(1, comp_h_fn);
    assert(!cheri_is_valid(comps_addr[2 * 3 + 0]));
    assert(!cheri_is_valid(comps_addr[2 * 3 + 1]));

    int (*fn)() = (__cheri_fromcap int(*)()) comps_addr[1 * 3 + 1];
    assert(fn() == 420);

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

int
comp_g_fn()
{
    return 24;
}

int
comp_h_fn()
{
    return 420;
}
