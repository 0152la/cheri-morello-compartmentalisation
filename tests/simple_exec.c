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
extern void* call_compartment(void*, ...);

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

    call_compartment(comp_f_fn);
    void* __capability g_ddc =
        (void* __capability) comps_addr[COMP_FIELDS * 1 + COMP_IDX_DDC];
    void* g_ddc_base = (void*) cheri_address_get(g_ddc);
    assert(((int*) g_ddc_base)[160] == 43);

    return 0;
}

/*******************************************************************************
 * Compartments
 ******************************************************************************/

int
comp_f_fn()
{
    void* __capability * this_ddc = (__cheri_fromcap void* __capability *) cheri_ddc_get();
    void* __capability this_call_comp_func = (void* __capability) *this_ddc;
    assert(cheri_is_valid(this_call_comp_func));
    unsigned int val = 42;
    int (*fn)(unsigned int) = comp_g_fn;

    // Emulate a capability function call, setting parameters
    // TODO have a good way of calling a capability function
    asm("stp %0, %1, [sp, #-32]!\n\t"
        "str %w2, [sp, #16]\n\t"
        "ldr c2, [sp, #16]\n\t"
        "ldp x1, x0, [sp], #32\n\t"
        "str clr, [sp, #16]!\n\t"
        "ldpblr c29, [c2]\n\t"
        "ldr clr, [sp], 16"
        : "+r"(val)
        : "r"(comp_g_fn), "r"(this_call_comp_func));

    //TODO have a good way of performing in-built compiler cleanup, such as
    //resetting `sp`
    asm("add sp, sp, #0x20\n\t"
        "ret clr");
    return val;
}

int
comp_g_fn(unsigned int val)
{
    val += 1;
    void* __capability this_ddc = cheri_ddc_get();
    int * addr = (__cheri_fromcap int*) this_ddc;
    addr[160] = val;

    asm("add sp, sp, #0x30\n\t"
        "ret clr");
    return val;
}
