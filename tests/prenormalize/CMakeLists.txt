set(TESTS
  normalize-01
  roscoe-01
  roscoe-02
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

add_executable(normalization/prenormalize test-prenormalize.cc)
set_target_properties(
  normalization/prenormalize
  PROPERTIES
  OUTPUT_NAME test-prenormalize
)
target_link_libraries(normalization/prenormalize hst)
foreach(_test ${TESTS})
  add_test(
    normalization:prenormalize:${_test}
    bash -c "./test-prenormalize < ${_test}.input | cmp - ${_test}.output"
  )
endforeach(_test)
