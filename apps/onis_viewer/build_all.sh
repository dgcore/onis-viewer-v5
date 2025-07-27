#!/bin/bash

# Script de build complet pour ONIS Viewer

set -e

echo "🚀 Démarrage du build ONIS Viewer..."

# Détecter la plateforme
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    PLATFORM="windows"
else
    echo "❌ Plateforme non supportée: $OSTYPE"
    exit 1
fi

echo "📱 Plateforme détectée: $PLATFORM"

# Compiler le code C++ natif
echo "🔨 Compilation du code C++ natif..."
if [ "$PLATFORM" = "macos" ]; then
    cd macos
    ./build_native.sh
    cd ..
elif [ "$PLATFORM" = "linux" ]; then
    # TODO: Ajouter la compilation Linux
    echo "⚠️  Compilation Linux à implémenter"
elif [ "$PLATFORM" = "windows" ]; then
    # TODO: Ajouter la compilation Windows
    echo "⚠️  Compilation Windows à implémenter"
fi

# Compiler l'application Flutter
echo "📱 Compilation de l'application Flutter..."
flutter build $PLATFORM

echo "✅ Build terminé avec succès!"
echo "🎯 Application disponible dans: build/$PLATFORM/" 