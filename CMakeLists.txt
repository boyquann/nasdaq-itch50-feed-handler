cmake_minimum_required(VERSION 3.21)
project(itch LANGUAGES C)

enable_testing()

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

add_compile_options(
	-Wall -Wextra -Wpedantic
	-Wconversion -Wsign-conversion
	-Wshadow -Wcast-align
	-Werror
)

add_compile_definitions(
	_DEFAULT_SOURCE
)

add_library(
	itch
	STATIC
	src/book.c src/framer.c src/hist.c src/pool.c 
	src/rtx.c src/sub.c src/decode.c src/hash.c
	src/mold.c src/pub.c src/source.c
)

add_test(NAME itch_cut_synthetic
	COMMAND ${CMAKE_SOURCE_DIR}/tests/itch_cut/run_tests.sh $<TARGET_FILE:itch_cut>
)
target_include_directories(
	itch
	PUBLIC
	include
)

add_executable(
	itch_stats
	apps/itch_stats.c
)

target_link_libraries(
	itch_stats
	PRIVATE
	itch
)

add_executable(
	itch_book
	apps/itch_book.c
)

target_link_libraries(
	itch_book
	PRIVATE
	itch
)

add_executable(
	itch_cut
	apps/itch_cut.c
)

target_link_libraries(
	itch_cut
	PRIVATE
	itch
)

add_executable(
	itch_pipe
	apps/itch_pipe.c
)

target_link_libraries(
	itch_pipe
	PRIVATE
	itch
)

add_executable(
	itch_pub
	apps/itch_pub.c
)

target_link_libraries(
	itch_pub
	PRIVATE
	itch
)

add_executable(
	itch_sub
	apps/itch_sub.c
)

target_link_libraries(
	itch_sub
	PRIVATE
	itch
)
