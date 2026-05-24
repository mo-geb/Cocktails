#!/usr/bin/env python3
"""
sync_ingredient_strings.py — Keep ingredient localization keys in sync with
ingredients.json.

For every ingredient `id` in ingredients.json there should be a corresponding
`ingredient.<id>` key in Localizable.xcstrings. This script reports:
  • MISSING — IDs in JSON without a matching xcstrings key (app falls back
              to the raw JSON `name` for these).
  • STALE   — `ingredient.*` keys in xcstrings whose `id` no longer exists
              in ingredients.json.

Usage:
  # Report both missing and stale keys:
  python3 Scripts/sync_ingredient_strings.py

  # Insert stub English entries for missing keys:
  python3 Scripts/sync_ingredient_strings.py --add

  # Remove stale ingredient.* keys:
  python3 Scripts/sync_ingredient_strings.py --prune

  # Do both:
  python3 Scripts/sync_ingredient_strings.py --add --prune

  # Preview without writing:
  python3 Scripts/sync_ingredient_strings.py --add --prune --dry-run
"""

import argparse
import json
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
INGREDIENTS_JSON = REPO / "Cocktails" / "Resources" / "Recipes" / "ingredients.json"
XCSTRINGS = REPO / "Cocktails" / "Resources" / "Localizable.xcstrings"

KEY_PREFIX = "ingredient."


def load_json(path: Path):
    with path.open() as f:
        return json.load(f)


def write_json_atomic(path: Path, data) -> None:
    tmp = tempfile.NamedTemporaryFile(
        mode="w", delete=False, dir=str(path.parent), suffix=".tmp", encoding="utf-8"
    )
    try:
        # Don't sort_keys — Xcode preserves insertion order and the existing
        # file is not alphabetized. Keeping order keeps diffs minimal.
        json.dump(data, tmp, indent=2, ensure_ascii=False)
        tmp.write("\n")
        tmp.flush()
        tmp.close()
        Path(tmp.name).replace(path)
    except Exception:
        Path(tmp.name).unlink(missing_ok=True)
        raise


def stub_entry(english_value: str) -> dict:
    """Build a fresh xcstrings entry with only an English source string set."""
    return {
        "comment": "Ingredient name",
        "extractionState": "manual",
        "localizations": {
            "en": {
                "stringUnit": {
                    "state": "translated",
                    "value": english_value,
                }
            }
        },
    }


def english_value(entry: dict) -> str:
    """Best-effort extraction of the English source string for display."""
    try:
        return entry["localizations"]["en"]["stringUnit"]["value"]
    except (KeyError, TypeError):
        return ""


def main() -> int:
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    p.add_argument("--add", action="store_true", help="Insert stub entries for missing keys.")
    p.add_argument("--prune", action="store_true", help="Remove stale ingredient.* keys.")
    p.add_argument("--dry-run", action="store_true", help="Preview actions; do not write.")
    args = p.parse_args()

    ingredients = load_json(INGREDIENTS_JSON)
    xc = load_json(XCSTRINGS)
    strings = xc.setdefault("strings", {})

    json_ids = {ing["id"] for ing in ingredients}
    json_name_by_id = {ing["id"]: ing.get("name", "") for ing in ingredients}

    xc_ingredient_keys = {k for k in strings if k.startswith(KEY_PREFIX)}
    xc_ids = {k[len(KEY_PREFIX):] for k in xc_ingredient_keys}

    missing_ids = sorted(json_ids - xc_ids)
    stale_ids = sorted(xc_ids - json_ids)

    if missing_ids:
        print(f"MISSING ({len(missing_ids)}) — in ingredients.json, not in xcstrings:")
        for ing_id in missing_ids:
            print(f"  • {KEY_PREFIX}{ing_id:38s}  →  {json_name_by_id[ing_id]!r}")
    if stale_ids:
        if missing_ids:
            print()
        print(f"STALE ({len(stale_ids)}) — in xcstrings, not in ingredients.json:")
        for ing_id in stale_ids:
            key = f"{KEY_PREFIX}{ing_id}"
            print(f"  • {key:40s}  (en: {english_value(strings[key])!r})")
    if not missing_ids and not stale_ids:
        print("✓ ingredients.json and Localizable.xcstrings are in sync.")
        return 0

    did_anything = False

    if args.add and missing_ids:
        if args.dry_run:
            print(f"\n[dry-run] Would add {len(missing_ids)} stub(s).")
        else:
            for ing_id in missing_ids:
                strings[f"{KEY_PREFIX}{ing_id}"] = stub_entry(json_name_by_id[ing_id])
            did_anything = True
            print(f"\nAdded {len(missing_ids)} stub(s).")

    if args.prune and stale_ids:
        if args.dry_run:
            print(f"\n[dry-run] Would remove {len(stale_ids)} stale key(s).")
        else:
            for ing_id in stale_ids:
                del strings[f"{KEY_PREFIX}{ing_id}"]
            did_anything = True
            print(f"\nRemoved {len(stale_ids)} stale key(s).")

    if did_anything:
        write_json_atomic(XCSTRINGS, xc)
        print(f"Wrote {XCSTRINGS.relative_to(REPO)}.")
        if args.add and missing_ids:
            print("Next: run `python3 Scripts/translate_strings.py --all` to fill other languages.")
        return 0

    if not (args.add or args.prune):
        hints = []
        if missing_ids:
            hints.append("--add to insert stubs")
        if stale_ids:
            hints.append("--prune to remove stale keys")
        print(f"\nRun with {' and/or '.join(hints)}.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
