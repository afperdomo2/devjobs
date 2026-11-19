#!/usr/bin/env bash
# Genera las capturas de la app para el README en screenshots/.
#
# La app se ejecuta en una ventana real y las capturas se toman del árbol de
# render en tamaño de teléfono (420x880 @2x) y tema claro. Requiere:
#   - flutter con soporte de escritorio Linux,
#   - Python 3 con Pillow para crear el WebP.
#
# En esta máquina `flutter` no está en el PATH: se usa la ruta absoluta del SDK
# por defecto y se puede sobreescribir con la variable FLUTTER.
set -euo pipefail

cd "$(dirname "$0")/.."

OUT_DIR="screenshots"

FLUTTER_BIN="${FLUTTER:-/home/felipe/Documentos/flutter/bin/flutter}"
if [ ! -x "$FLUTTER_BIN" ]; then
  FLUTTER_BIN="flutter"
fi

if ! python3 -c 'import PIL' 2>/dev/null; then
  echo "error: se necesita Python 3 con Pillow (sudo apt install python3-pil)" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

"$FLUTTER_BIN" drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshots_test.dart \
  --device-id=linux \
  --dart-define=SCREENSHOT_DIR="$(cd "$OUT_DIR" && pwd)"

# Comprime a WebP para que el README no pese de más.
python3 - "$OUT_DIR" <<'PY'
import pathlib
import sys

from PIL import Image

out_dir = pathlib.Path(sys.argv[1])
for png in sorted(out_dir.glob('*.png')):
    webp = png.with_suffix('.webp')
    with Image.open(png) as image:
        image.save(webp, 'WEBP', quality=82, method=6)
    png.unlink()
    print(f'{png.name} -> {webp.name} ({webp.stat().st_size // 1024} KB)')
PY

echo "Listo: $OUT_DIR/"
