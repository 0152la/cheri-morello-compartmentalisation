function(new_proj_test test_name)
    add_executable(${test_name}
        ${test_name}.c)
    target_link_libraries(${test_name} morello-compartments)
    add_test(NAME ${test_name}
             COMMAND ${CMAKE_SOURCE_DIR}/tests/run_test.sh $<TARGET_FILE:${test_name}>)
endfunction()

new_proj_test(simple_init)
new_proj_test(simple_add)
