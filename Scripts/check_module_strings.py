#!/usr/bin/env python3
"""check_module_strings.py — verify per-module String Catalog coverage.

Each package module owns its strings: user-facing literals are referenced with
`bundle: .module` and translated in that module's `Localizable.xcstrings`
(es, fr-CA, ja). This script reports, per module:

  * literals referenced with `bundle: .module` that are missing from the module catalog
  * catalog entries missing any of the expected languages
  * key-based SwiftUI initializers that forgot the bundle (they'd silently resolve
    against Bundle.main and display the raw key)

Run it after adding user-facing strings to package code:

    python3 Scripts/check_module_strings.py
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCES = ROOT / "Packages" / "Stork" / "Sources"
LANGUAGES = {"es", "fr-CA", "ja"}

LIT = r'"((?:[^"\\]|\\.)+)"'
BUNDLED = [
    re.compile(rf'Text\({LIT}, bundle: \.module\)'),
    re.compile(rf'String\(localized: {LIT}, bundle: \.module\)'),
    re.compile(rf'LocalizedStringResource\({LIT}, bundle:'),
]
# Key-based initializers that resolve in Bundle.main when no bundle is given.
FORGOT_BUNDLE = [
    re.compile(rf'Text\({LIT}\)(?!, bundle)'),
    re.compile(rf'String\(localized: {LIT}\)'),
    re.compile(rf'Label\({LIT}, systemImage:'),
    re.compile(rf'\.navigationTitle\({LIT}\)'),
    re.compile(rf'\.accessibilityLabel\({LIT}\)'),
]
# Swift interpolation, tolerating a few levels of nested parentheses.
_P3 = r"[^()]*"
_P2 = rf"(?:[^()]|\({_P3}\))*"
_P1 = rf"(?:[^()]|\({_P2}\))*"
INTERP = re.compile(rf"\\\({_P1}\)")


def literal_covered(literal: str, keys: set[str]) -> bool:
    if INTERP.search(literal):
        fragments = [f.replace('\\"', '"') for f in INTERP.split(literal) if f.strip()]
        return any(all(fr in key for fr in fragments) for key in keys)
    return literal.replace('\\"', '"') in keys


def main() -> int:
    problems = 0
    for module_dir in sorted(p for p in SOURCES.iterdir() if p.is_dir()):
        catalog_path = module_dir / "Localizable.xcstrings"
        keys: set[str] = set()
        entries: dict = {}
        if catalog_path.exists():
            entries = json.loads(catalog_path.read_text())["strings"]
            keys = set(entries)

        missing, forgot = set(), set()
        for f in module_dir.rglob("*.swift"):
            text = f.read_text()
            for pattern in BUNDLED:
                for m in pattern.finditer(text):
                    if not literal_covered(m.group(1), keys):
                        missing.add(m.group(1))
            for pattern in FORGOT_BUNDLE:
                for m in pattern.finditer(text):
                    forgot.add(f"{f.relative_to(SOURCES)}: {m.group(0)}")

        untranslated = sorted(
            key for key, entry in entries.items()
            if entry.get("shouldTranslate", True)
            and not LANGUAGES <= set(entry.get("localizations", {}))
        )

        if missing or forgot or untranslated:
            print(f"\n== {module_dir.name}")
            for lit in sorted(missing):
                print(f"  MISSING KEY: {lit!r}")
            for site in sorted(forgot):
                print(f"  NO BUNDLE:   {site}")
            for key in untranslated:
                print(f"  UNTRANSLATED: {key!r}")
            problems += len(missing) + len(forgot) + len(untranslated)

    if problems == 0:
        print("all module catalogs cover their strings; translations complete")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
