// stdafx.h : include file for standard system include files,
// or project specific include files that are used frequently, but
// are changed infrequently
//

#pragma once

#ifdef WIN32
#include "targetver.h"

#define WIN32_LEAN_AND_MEAN  // Exclude rarely-used stuff from Windows headers
#define _ATL_CSTRING_EXPLICIT_CONSTRUCTORS  // some CString constructors will be
                                            // explicit
// #define _AFX_NO_MFC_CONTROLS_IN_DIALOGS         // remove support for MFC
// controls in dialogs

#ifndef VC_EXTRALEAN
#define VC_EXTRALEAN  // Exclude rarely-used stuff from Windows headers
#endif

#include <afx.h>
#include <afxwin.h>  // MFC core and standard components

#endif

// TODO: reference additional headers your program requires here
#include <list>
#include <memory>  // for std::shared_ptr, std::weak_ptr, std::make_shared
