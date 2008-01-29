# - Look for GNU Bison, the parser generator
# Based off a news post from Andy Cedilnik at Kitware
# Defines the following:
#  BISON_EXECUTABLE - path to the bison executable
#  BISON_FILE - parse a file with bison
#  BISON_PREFIX_OUTPUTS - Set to true to make BISON_FILE produce prefixed
#                         symbols in the generated output based on filename.
#                         So for ${filename}.y, you'll get ${filename}parse(), etc.
#                         instead of yyparse().
#  BISON_GENERATE_DEFINES - Set to true to make BISON_FILE output the matching
#                           .h file for a .c file. You want this if you're using
#                           flex.

IF(NOT DEFINED BISON_PREFIX_OUTPUTS)
  SET(BISON_PREFIX_OUTPUTS FALSE)
ENDIF(NOT DEFINED BISON_PREFIX_OUTPUTS)

IF(NOT DEFINED BISON_GENERATE_DEFINES)
  SET(BISON_GENERATE_DEFINES FALSE)
ENDIF(NOT DEFINED BISON_GENERATE_DEFINES)

IF(NOT BISON_EXECUTABLE)
  MESSAGE(STATUS "Looking for bison")
  FIND_PROGRAM(BISON_EXECUTABLE bison)
  IF(BISON_EXECUTABLE)
    MESSAGE(STATUS "Looking for bison -- ${BISON_EXECUTABLE}")
  ENDIF(BISON_EXECUTABLE)
ENDIF(NOT BISON_EXECUTABLE)

IF(BISON_EXECUTABLE)
  MACRO(BISON_FILE FILENAME)
    GET_FILENAME_COMPONENT(PATH "${FILENAME}" PATH)
    GET_FILENAME_COMPONENT(HEAD "${FILENAME}" NAME_WE)

    IF(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/${PATH}")
      FILE(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${PATH}")
    ENDIF(NOT EXISTS "${CMAKE_CURRENT_BINARY_DIR}/${PATH}")

    IF(BISON_PREFIX_OUTPUTS)
      SET(PREFIX "${HEAD}")
    ELSE(BISON_PREFIX_OUTPUTS)
      SET(PREFIX "yy")
    ENDIF(BISON_PREFIX_OUTPUTS)

    GET_FILENAME_COMPONENT(EXT "${FILENAME}" EXT)
    IF(EXT STREQUAL ".yy")
      SET(C_EXT ".cc")
      SET(H_EXT ".hh")
    ELSEIF(EXT STREQUAL ".ypp")
      SET(C_EXT ".cpp")
      SET(H_EXT ".hpp")
    ELSEIF(EXT STREQUAL ".y++")
      SET(C_EXT ".c++")
      SET(H_EXT ".h++")
    ELSE(EXT STREQUAL ".yy")
      SET(C_EXT ".c")
      SET(H_EXT ".h")
    ENDIF(EXT STREQUAL ".yy")

    SET(OUTFILE "${CMAKE_CURRENT_BINARY_DIR}/${PATH}/${HEAD}.tab${C_EXT}")

    IF(BISON_GENERATE_DEFINES)
      SET(HEADER "${CMAKE_CURRENT_BINARY_DIR}/${PATH}/${HEAD}.tab${H_EXT}")

      ADD_CUSTOM_COMMAND(
        OUTPUT "${OUTFILE}" "${HEADER}"
        COMMAND "${BISON_EXECUTABLE}"
        ARGS "--name-prefix=${PREFIX}"
        "--defines"
        "--output-file=${OUTFILE}"
        "${CMAKE_CURRENT_SOURCE_DIR}/${FILENAME}"
        DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/${FILENAME}"
        COMMENT "Generating bison grammar ${FILENAME}"
      )
      SET_SOURCE_FILES_PROPERTIES("${OUTFILE}" "${HEADER}" PROPERTIES GENERATED TRUE)
      SET_SOURCE_FILES_PROPERTIES("${HEADER}" PROPERTIES HEADER_FILE_ONLY TRUE)
    ELSE(BISON_GENERATE_DEFINES)
      ADD_CUSTOM_COMMAND(
        OUTPUT "${OUTFILE}"
        COMMAND "${BISON_EXECUTABLE}"
        ARGS "--name-prefix=${PREFIX}"
        "--output-file=${OUTFILE}"
        "${CMAKE_CURRENT_SOURCE_DIR}/${FILENAME}"
        DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/${FILENAME}")
      SET_SOURCE_FILES_PROPERTIES("${OUTFILE}" PROPERTIES GENERATED TRUE)
    ENDIF(BISON_GENERATE_DEFINES)
  ENDMACRO(BISON_FILE)
ELSE (BISON_EXECUTABLE)
  IF (Bison_FIND_REQUIRED)
    MESSAGE(FATAL_ERROR "Could NOT find bison")
  ENDIF (Bison_FIND_REQUIRED)
ENDIF(BISON_EXECUTABLE)
