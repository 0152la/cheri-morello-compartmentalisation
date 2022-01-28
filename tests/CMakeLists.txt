add_executable(simple
    simple.c)

target_link_libraries(simple morello-compartments)

add_test(NAME simple COMMAND simple )
