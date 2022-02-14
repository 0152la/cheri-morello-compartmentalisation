#include <assert.h>

#include "comps_offsets.h"

static_assert(COMP_SIZE == sizeof(void* __capability) * 3, "Invalid `COMP_SIZE` provided");
static_assert(COMP_OFFSET_DDC == 0, "Invalid `COMP_OFFSET_DDC` provided.");
static_assert(COMP_OFFSET_PCC == sizeof(void* __capability) * 1, "Invalid `COMP_OFFSET_PCC` provided.");
static_assert(COMP_OFFSET_STK_ADDR == sizeof(void* __capability) * 2, "Invalid `COMP_OFFSET_STK_LEN` provided.");
