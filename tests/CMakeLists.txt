add_executable(simple
    simple.c)

target_link_libraries(simple morello-compartments)

add_test(NAME simple
         COMMAND ${CMAKE_SOURCE_DIR}/tests/run_test.sh $<TARGET_FILE:simple>)
