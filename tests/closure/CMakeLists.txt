set(TESTS
  test01
)

# Copy the test data from the source directory to the build directory.

foreach(_test ${TESTS})
  foreach(_ext input output)
    configure_file(
      ${CMAKE_CURRENT_SOURCE_DIR}/${_test}.${_ext}
      ${CMAKE_CURRENT_BINARY_DIR}/${_test}.${_ext}
      COPYONLY
    )
  endforeach(_ext)
endforeach(_test)

# Finally, add compilation targets for all of the test executables.

add_executable(normalization/closure test-closure.cc)
set_target_properties(
  normalization/closure
  PROPERTIES
  OUTPUT_NAME test-closure
)
target_link_libraries(normalization/closure hst)
foreach(_test ${TESTS})
  add_test(
    normalization:closure:${_test}
    bash -c "./test-closure < ${_test}.input | cmp - ${_test}.output"
  )
endforeach(_test)
