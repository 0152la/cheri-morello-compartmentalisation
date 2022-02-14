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
extern void* call_comp_func(void*, ...);

/*******************************************************************************
 * Main
 ******************************************************************************/

int comp_f_fn();
int comp_g_fn();

int
main()
{
    init_compartments();

    size_t comp_size = 2000;
    assert(add_compartment(comp_size, comp_f_fn) != MAP_FAILED);
    assert(add_compartment(comp_size, comp_g_fn) != MAP_FAILED);

    call_comp_func(comp_f_fn);
    void* __capability g_ddc =
        (void* __capability) comps_addr[COMP_FIELDS * 1 + COMP_IDX_DDC];
    void* g_ddc_base = (void*) cheri_address_get(g_ddc);
    assert( (*(int*)(g_ddc_base + 160)) == 42);

    return 0;
}

/*******************************************************************************
 * Compartments
 ******************************************************************************/

int
comp_f_fn()
{
    call_comp_func(comp_g_fn, 42);
    return 42;
}

int
comp_g_fn(unsigned int val)
{
    void* __capability this_ddc = cheri_ddc_get();
    *(__cheri_fromcap int*)(this_ddc + 160) = val;
    return val;
}
