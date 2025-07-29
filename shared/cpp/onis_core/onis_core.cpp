#include "onis_core.h"
#include <string>

// Variables statiques pour les chaînes de caractères
static const char *VERSION = "5.0.0";
static const char *NAME = "ONIS Viewer";

const char *onis_get_version() { return VERSION; }

int onis_add(int a, int b) { return a + b; }

const char *onis_get_name() { return NAME; }

int test_connection() { return 0; } // 0 = success