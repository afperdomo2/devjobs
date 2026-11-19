#!/usr/bin/env bash
# Incrementa la versión en pubspec.yaml (version: X.Y.Z+N).
#
#   ./scripts/bump-version.sh            # build number +1 (por defecto)
#   ./scripts/bump-version.sh build      # idem, explícito
#   ./scripts/bump-version.sh patch      # parche Z+1 y build +1
#   ./scripts/bump-version.sh minor      # minor Y+1, Z=0 y build +1
#   ./scripts/bump-version.sh major      # major X+1, zeros y build +1
#
# La versión que muestra la app sale SIEMPRE del pubspec (package_info_plus),
# así que este script es la única forma de cambiarla y nunca se desincroniza.
# Regla del proyecto: al terminar un cambio de código que se vaya a compilar
# o distribuir, ejecutar este script antes de scripts/build.sh.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

LEVEL="${1:-build}"
PUBSPEC="pubspec.yaml"

CURRENT="$(sed -n 's/^version: *//p' "$PUBSPEC" | head -1)"
if [[ -z "$CURRENT" ]]; then
  echo "No se encontró 'version:' en $PUBSPEC" >&2
  exit 1
fi

NAME="${CURRENT%%+*}"
BUILD="${CURRENT##*+}"
if [[ "$NAME" == "$CURRENT" ]]; then
  BUILD=0
fi
if ! [[ "$BUILD" =~ ^[0-9]+$ ]]; then
  echo "Build number inválido en '$CURRENT' ($PUBSPEC)" >&2
  exit 1
fi

IFS=. read -r MAJOR MINOR PATCH <<< "$NAME"
if ! [[ "${MAJOR:-}" =~ ^[0-9]+$ && "${MINOR:-}" =~ ^[0-9]+$ && "${PATCH:-}" =~ ^[0-9]+$ ]]; then
  echo "Versión inválida en '$CURRENT' ($PUBSPEC)" >&2
  exit 1
fi

case "$LEVEL" in
  build)
    BUILD=$((BUILD + 1))
    ;;
  patch)
    PATCH=$((PATCH + 1))
    BUILD=$((BUILD + 1))
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    BUILD=$((BUILD + 1))
    ;;
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    BUILD=$((BUILD + 1))
    ;;
  *)
    echo "Uso: $(basename "$0") [build|patch|minor|major]" >&2
    exit 2
    ;;
esac

NEW="${MAJOR}.${MINOR}.${PATCH}+${BUILD}"

sed -i "s/^version: .*/version: ${NEW}/" "$PUBSPEC"
echo "Versión: ${CURRENT} → ${NEW}"
