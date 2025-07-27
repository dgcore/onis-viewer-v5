#ifndef ONIS_CORE_H
#define ONIS_CORE_H

#ifdef __cplusplus
extern "C" {
#endif

// Fonction simple pour tester l'intégration FFI
const char *onis_get_version();

// Fonction pour additionner deux entiers
int onis_add(int a, int b);

// Fonction pour obtenir le nom du logiciel
const char *onis_get_name();

#ifdef __cplusplus
}
#endif

#endif // ONIS_CORE_H