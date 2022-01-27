set(BUILD_SHARED_LIBS ON)

add_library(morello-compartments SHARED
    ${SRC_DIR}/manager.S
    ${SRC_DIR}/switcher.S
    )
