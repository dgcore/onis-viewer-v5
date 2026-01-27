#pragma once

#define S32_MAX 2147483647
#define S32_MIN INT_MIN
#define F32_MAX 3.402823466e+38F
#define F32_MIN 1.175494351e-38F
#define F64_MAX 1.7976931348623158e+308
#define F64_MIN 2.2250738585072014e-308
#define U64_MAX 0xFFFFFFFFFFFFFFFF

#define OS_RED 0
#define OS_GREEN 1
#define OS_BLUE 2
#define OS_ALPHA 3

// Result status constants
#define OSRSP_SUCCESS 0
#define OSRSP_FAILURE 1

namespace onis {
typedef unsigned char u8;
typedef signed char s8;
typedef char c8;
typedef float f32;
typedef double f64;
}  // namespace onis
