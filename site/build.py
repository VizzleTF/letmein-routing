#!/usr/bin/env python3
"""Собирает статическую страницу для GitHub Pages.

Берёт site/index.template.html, подставляет актуальные диплинки и рисует к каждому
QR прямо в разметку (inline SVG — без внешних сервисов и без JS). Результат в _site/.

Запускается из корня репозитория:  python3 site/build.py
Нужен qrencode в PATH (или путь в переменной окружения QRENCODE).
"""

import os
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "_site"
QRENCODE = os.environ.get("QRENCODE", "qrencode")

# маркер -> файл с диплинком
LINKS = {
    "HAPP_DEFAULT": "HAPP/DEFAULT.DEEPLINK",
    "HAPP_GEOBLOCK": "HAPP/GEOBLOCK.DEEPLINK",
    "HAPP_JSONSUB": "HAPP/JSONSUB.DEEPLINK",
    "INCY_DEFAULT": "INCY/DEFAULT.DEEPLINK",
    "INCY_GEOBLOCK": "INCY/GEOBLOCK.DEEPLINK",
    "INCY_JSONSUB": "INCY/JSONSUB.DEEPLINK",
}

# Больше 2953 байт в QR (уровень L, бинарный режим) не влезает физически.
QR_LIMIT = 2953


def qr_png(payload: str, name: str) -> str:
    """Рисует QR в PNG и возвращает <img> на него.

    Не inline-SVG: диплинк на ~2 КБ даёт QR 40-й версии, в SVG это десятки тысяч
    прямоугольников — страница распухала до мегабайтов. PNG весит единицы килобайт.
    """
    qrdir = OUT / "qr"
    qrdir.mkdir(exist_ok=True)
    rel = f"qr/{name.lower().replace('_', '-')}.png"
    subprocess.run(
        [QRENCODE, "-t", "PNG", "-s", "4", "-m", "1", "-l", "M", "-o", str(OUT / rel), payload],
        check=True, capture_output=True,
    )
    return f'<img src="{rel}" alt="QR" width="232" height="232" loading="lazy">' 


def main() -> int:
    OUT.mkdir(exist_ok=True)
    for d in ("HAPP", "INCY", "MIHOMO"):
        shutil.copytree(ROOT / d, OUT / d, dirs_exist_ok=True)
    shutil.copy(ROOT / "README.md", OUT / "README.md")

    page = (ROOT / "site" / "index.template.html").read_text(encoding="utf-8")

    for marker, rel in LINKS.items():
        link = (ROOT / rel).read_text(encoding="utf-8").strip()
        if len(link.encode()) > QR_LIMIT:
            print(f"::error::{rel} = {len(link.encode())} байт, QR не соберётся "
                  f"(лимит {QR_LIMIT}). Сократи списки в JSON.", file=sys.stderr)
            return 1
        page = page.replace(f"@@{marker}@@", link)
        page = page.replace(f"@@QR_{marker}@@", qr_png(link, marker))

    page = page.replace("@@BUILD_DATE@@", datetime.now(timezone.utc).strftime("%d.%m.%Y"))

    left = sorted(set(re.findall(r"@@[A-Z_]+@@", page)))
    if left:
        print(f"::error::в index.html остались неподставленные маркеры: {left}", file=sys.stderr)
        return 1

    (OUT / "index.html").write_text(page, encoding="utf-8")
    print(f"собрано: {OUT/'index.html'} ({len(page)} символов)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
