cmake_minimum_required(VERSION 3.14)
project(ws10_diagnostic_bridge CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# WS10 Core ISO-TP static library
add_library(ws10_isotp_core STATIC
    src/isotp_channel.cpp
)

target_include_directories(ws10_isotp_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

if(MSVC)
    target_compile_options(ws10_isotp_core PRIVATE /W4 /WX)
else()
    target_compile_options(ws10_isotp_core PRIVATE -Wall -Wextra -Wpedantic)
endif()

# Unit tests and CTest setup
include(CTest)

if(BUILD_TESTING)
    add_executable(ws10_isotp_unit_tests
        test/isotp_unit_tests.cpp
    )

    target_link_libraries(ws10_isotp_unit_tests PRIVATE
        ws10_isotp_core
    )

    target_include_directories(ws10_isotp_unit_tests PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    )

    if(NOT MSVC)
        target_compile_options(ws10_isotp_unit_tests PRIVATE -Wall -Wextra -Wpedantic)
    endif()

    # Primary U01~U14 unit test suite
    add_test(NAME ws10_isotp_unit_tests COMMAND ws10_isotp_unit_tests)
    set_tests_properties(ws10_isotp_unit_tests PROPERTIES LABELS "ws10-s2-step1")

    # Specific case execution
    add_test(NAME ws10_case_u01 COMMAND ws10_isotp_unit_tests --case U01)
    set_tests_properties(ws10_case_u01 PROPERTIES LABELS "ws10-s2-step1")

    add_test(NAME ws10_case_u14 COMMAND ws10_isotp_unit_tests --case U14)
    set_tests_properties(ws10_case_u14 PROPERTIES LABELS "ws10-s2-step1")

    # Negative Controls (Expected to fail / return non-zero exit codes)
    add_test(NAME ws10_neg_assertion_fail COMMAND ws10_isotp_unit_tests --neg-assertion-fail)
    set_tests_properties(ws10_neg_assertion_fail PROPERTIES WILL_FAIL TRUE LABELS "ws10-s2-negative-control")

    add_test(NAME ws10_neg_unknown_case COMMAND ws10_isotp_unit_tests --neg-unknown-case)
    set_tests_properties(ws10_neg_unknown_case PROPERTIES WILL_FAIL TRUE LABELS "ws10-s2-negative-control")

    add_test(NAME ws10_neg_zero_match COMMAND ws10_isotp_unit_tests --neg-zero-match)
    set_tests_properties(ws10_neg_zero_match PROPERTIES WILL_FAIL TRUE LABELS "ws10-s2-negative-control")

    add_test(NAME ws10_neg_cli_unknown_case COMMAND ws10_isotp_unit_tests --case U99_NON_EXISTENT)
    set_tests_properties(ws10_neg_cli_unknown_case PROPERTIES WILL_FAIL TRUE LABELS "ws10-s2-negative-control")

    add_test(NAME ws10_neg_cli_unknown_flag COMMAND ws10_isotp_unit_tests --unrecognized-option-flag)
    set_tests_properties(ws10_neg_cli_unknown_flag PROPERTIES WILL_FAIL TRUE LABELS "ws10-s2-negative-control")
endif()
