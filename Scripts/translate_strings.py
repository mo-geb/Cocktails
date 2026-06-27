#!/usr/bin/env python3
"""
translate_strings.py — Scalable .xcstrings translation manager for Cocktails app.

Usage:
  # Add a brand-new language:
  python3 scripts/translate_strings.py --lang de --add

  # Complete/update translations for one language:
  python3 scripts/translate_strings.py --lang de

  # Complete ALL incomplete languages:
  python3 scripts/translate_strings.py --all

  # Dry-run (show what would be translated without writing):
  python3 scripts/translate_strings.py --lang de --dry-run

  # Use a specific backend (default: openai):
  python3 scripts/translate_strings.py --lang de --backend openai
  python3 scripts/translate_strings.py --lang de --backend google

Backends:
  - openai  : Uses GPT-4o. Set OPENAI_API_KEY env var.
              Best quality, understands context and doesn't mangle format strings.
  - google  : Uses deep-translator (free, no key needed).
              Install: pip install deep-translator
              Decent quality, may need review for complex strings.

Strategy:
  - English (source) + German are used as context for translation to avoid
    ambiguity. German context is used when available (after first --add de run).
  - Only strings with state "new" or "needs_review" (or entirely missing for
    the target language) are translated.
  - Existing "translated" strings are NEVER touched unless --force is used.
  - Plural forms are handled per CLDR rules for each language.
  - Format placeholders (%@, %lld, %1$@, etc.) are preserved exactly.
  - The xcstrings "comment" field is passed to the LLM as additional context.
  - Results are written atomically (temp file + rename).
"""

import argparse
import json
import os
import re
import sys
import tempfile
import time
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

PROJECT_DIR = Path(__file__).parent.parent / "Cocktails"


def discover_xcstrings() -> list[Path]:
    """Every String Catalog in the app (Localizable, AppShortcuts, InfoPlist, …)."""
    return sorted(PROJECT_DIR.rglob("*.xcstrings"))

# CLDR plural categories required per language.
PLURAL_CATEGORIES: dict[str, list[str]] = {
    "de": ["one", "other"],
    "en": ["one", "other"],
    "es": ["one", "many", "other"],
    "fr": ["one", "many", "other"],
    "it": ["one", "many", "other"],
    "nl": ["one", "other"],
    "sk": ["one", "few", "many", "other"],
    "sv": ["one", "other"],
    "uk": ["one", "few", "many", "other"],
    "ja": ["other"],
    "zh-Hans": ["other"],
    "zh-Hant": ["other"],
    "pt-BR": ["one", "many", "other"],
    "pl": ["one", "few", "many", "other"],
    "ru": ["one", "few", "many", "other"],
    "tr": ["one", "other"],
    "ko": ["other"],
    "ar": ["zero", "one", "two", "few", "many", "other"],
    "da": ["one", "other"],
    "fi": ["one", "other"],
    "nb": ["one", "other"],
    "cs": ["one", "few", "many", "other"],
    "hu": ["one", "other"],
    "ro": ["one", "few", "other"],
    "el": ["one", "other"],
    "he": ["one", "two", "many", "other"],
    "hi": ["one", "other"],
    "id": ["other"],
    "vi": ["other"],
    "th": ["other"],
    "ms": ["other"],
}

LANG_NAMES: dict[str, str] = {
    "de": "German",
    "en": "English",
    "es": "Spanish",
    "fr": "French",
    "it": "Italian",
    "nl": "Dutch",
    "sk": "Slovak",
    "sv": "Swedish",
    "uk": "Ukrainian",
    "ja": "Japanese",
    "zh-Hans": "Simplified Chinese",
    "zh-Hant": "Traditional Chinese",
    "pt-BR": "Brazilian Portuguese",
    "pl": "Polish",
    "ru": "Russian",
    "tr": "Turkish",
    "ko": "Korean",
    "ar": "Arabic",
    "da": "Danish",
    "fi": "Finnish",
    "nb": "Norwegian Bokmål",
    "cs": "Czech",
    "hu": "Hungarian",
    "ro": "Romanian",
    "el": "Greek",
    "he": "Hebrew",
    "hi": "Hindi",
    "id": "Indonesian",
    "vi": "Vietnamese",
    "th": "Thai",
    "ms": "Malay",
}

NEEDS_TRANSLATION = {"new", "needs_review"}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def lang_name(code: str) -> str:
    return LANG_NAMES.get(code, code)


def plural_categories_for(lang: str) -> list[str]:
    return PLURAL_CATEGORIES.get(lang, ["one", "other"])


def get_en_value(entry: dict) -> Optional[str]:
    locs = entry.get("localizations", {})
    en = locs.get("en", {})
    if "stringUnit" in en:
        return en["stringUnit"].get("value")
    return None


def get_en_plural_values(entry: dict) -> dict[str, str]:
    locs = entry.get("localizations", {})
    en = locs.get("en", {})
    result = {}
    if "variations" in en:
        plural = en["variations"].get("plural", {})
        for cat, cat_data in plural.items():
            result[cat] = cat_data.get("stringUnit", {}).get("value", "")
    return result


def get_de_value(entry: dict) -> Optional[str]:
    locs = entry.get("localizations", {})
    de = locs.get("de", {})
    if "stringUnit" in de:
        return de["stringUnit"].get("value")
    return None


def get_de_plural_values(entry: dict) -> dict[str, str]:
    locs = entry.get("localizations", {})
    de = locs.get("de", {})
    result = {}
    if "variations" in de:
        plural = de["variations"].get("plural", {})
        for cat, cat_data in plural.items():
            result[cat] = cat_data.get("stringUnit", {}).get("value", "")
    return result


def is_plural_entry(entry: dict) -> bool:
    locs = entry.get("localizations", {})
    return any("variations" in lv for lv in locs.values())


def is_set_entry(entry: dict) -> bool:
    """App Shortcut phrases are stored as a stringSet (an array of values)."""
    locs = entry.get("localizations", {})
    return any("stringSet" in lv for lv in locs.values())


def entry_kind(entry: dict) -> str:
    if is_plural_entry(entry):
        return "plural"
    if is_set_entry(entry):
        return "set"
    return "unit"


def get_en_set_values(entry: dict) -> list[str]:
    en = entry.get("localizations", {}).get("en", {})
    return list(en.get("stringSet", {}).get("values", []))


def needs_translation_lang(entry: dict, lang: str) -> bool:
    if not entry.get("shouldTranslate", True):
        return False
    locs = entry.get("localizations", {})
    if lang not in locs:
        return True
    lang_data = locs[lang]
    if "stringUnit" in lang_data:
        return lang_data["stringUnit"].get("state") in NEEDS_TRANSLATION
    if "stringSet" in lang_data:
        return lang_data["stringSet"].get("state") in NEEDS_TRANSLATION
    if "variations" in lang_data:
        plural = lang_data["variations"].get("plural", {})
        return any(
            pv.get("stringUnit", {}).get("state") in NEEDS_TRANSLATION
            for pv in plural.values()
        )
    return True


def protect_placeholders(s: str) -> tuple[str, dict[str, str]]:
    # %-style format specifiers AND ${...} tokens (e.g. ${applicationName}
    # in App Shortcut phrases) must survive translation untouched.
    placeholders = re.findall(r"%(?:\d+\$)?[@ldfuLq%]|%%|\$\{[^}]+\}", s)
    mapping = {}
    protected = s
    for i, ph in enumerate(placeholders):
        token = f"__PH{i}__"
        mapping[token] = ph
        protected = protected.replace(ph, token, 1)
    return protected, mapping


def restore_placeholders(s: str, mapping: dict[str, str]) -> str:
    for token, original in mapping.items():
        s = s.replace(token, original)
    return s


# ---------------------------------------------------------------------------
# Translation Backends
# ---------------------------------------------------------------------------

class TranslationBackend:
    def translate_batch(
        self,
        texts: list[str],
        target_lang: str,
        source_lang: str = "en",
        context_hint: str = "",
    ) -> list[str]:
        raise NotImplementedError


class OpenAIBackend(TranslationBackend):
    def __init__(self):
        try:
            from openai import OpenAI
        except ImportError:
            sys.exit("openai package not found. Run: pip install openai")
        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            sys.exit("OPENAI_API_KEY environment variable not set.")
        self.client = OpenAI(api_key=api_key)

    def translate_batch(self, texts, target_lang, source_lang="en", context_hint=""):
        lang_full = lang_name(target_lang)
        system = (
            f"You are a professional app localisation expert translating an iOS cocktail recipe app "
            f"into {lang_full}. "
            "Rules:\n"
            "1. Preserve ALL format specifiers exactly (%@, %lld, %1$@, %2$lld, __PH0__, etc.).\n"
            "2. Keep translations short — these are UI labels, buttons, alerts, and ingredient names.\n"
            "3. Use the informal/familiar register (e.g. 'du' not 'Sie' in German, "
            "'tu' not 'vous' in French, 'tú' not 'usted' in Spanish). The app should feel personal.\n"
            "4. For ingredient names, use the standard culinary term in the target language. "
            "If the ingredient name is universally known by its English/original name (e.g. 'Campari', "
            "'Aperol', 'Baileys'), keep it as-is.\n"
            "5. Return ONLY a JSON array of translated strings, same length and order as input.\n"
            "6. Do NOT add explanations or markdown — output raw JSON only, starting with [ and ending with ]."
        )
        if context_hint:
            system += f"\nContext for this batch: {context_hint}"

        user = (
            f"Translate the following {len(texts)} strings from {lang_name(source_lang)} to {lang_full}.\n"
            f"Input JSON array:\n{json.dumps(texts, ensure_ascii=False)}"
        )

        for attempt in range(3):
            try:
                resp = self.client.chat.completions.create(
                    model="gpt-4o",
                    messages=[{"role": "system", "content": system},
                               {"role": "user", "content": user}],
                    temperature=0.2,
                )
                raw = resp.choices[0].message.content
                if not raw:
                    raise ValueError("Empty response from OpenAI API.")

                try:
                    parsed = json.loads(raw)
                    if isinstance(parsed, list):
                        return parsed
                    for v in parsed.values():
                        if isinstance(v, list):
                            return v
                except json.JSONDecodeError:
                    pass

                match = re.search(r"\[.*\]", raw, re.DOTALL)
                if match:
                    parsed = json.loads(match.group(0))
                    if isinstance(parsed, list):
                        return parsed

                raise ValueError(f"Could not parse a JSON array from response: {raw[:300]}")
            except Exception as e:
                if attempt == 2:
                    raise
                wait = 2 ** attempt
                print(f"  [warn] OpenAI error ({e}), retrying in {wait}s…")
                time.sleep(wait)


class GoogleBackend(TranslationBackend):
    def __init__(self):
        try:
            from deep_translator import GoogleTranslator
            self._GT = GoogleTranslator
        except ImportError:
            sys.exit("deep-translator not found. Run: pip install deep-translator")

    def translate_batch(self, texts, target_lang, source_lang="en", context_hint=""):
        tgt = target_lang.split("-")[0]
        src = source_lang.split("-")[0]
        results = []
        for text in texts:
            translated = self._GT(source=src, target=tgt).translate(text)
            results.append(translated)
            time.sleep(0.1)
        return results


BACKENDS = {
    "openai": OpenAIBackend,
    "google": GoogleBackend,
}


# ---------------------------------------------------------------------------
# Core translation logic
# ---------------------------------------------------------------------------

def get_source_value(key: str, entry: dict) -> str:
    en_val = get_en_value(entry)
    if en_val:
        return en_val
    return key


def build_context_hint(key: str, entry: dict) -> str:
    """Build context using English value, German value (if available), and the xcstrings comment."""
    parts = []
    en_val = get_source_value(key, entry)
    parts.append(f"English: '{en_val}'")
    de_val = get_de_value(entry)
    if de_val:
        parts.append(f"German: '{de_val}'")
    comment = entry.get("comment")
    if comment:
        parts.append(f"Context: {comment}")
    return " | ".join(parts)


def source_text_for(key: str, entry: dict, kind: str, selector) -> str:
    """The English source for a single work item (unit / plural cat / set index)."""
    if kind == "plural":
        en_plurals = get_en_plural_values(entry)
        return en_plurals.get(selector) or en_plurals.get("other") or key
    if kind == "set":
        values = get_en_set_values(entry)
        return values[selector] if selector < len(values) else key
    return get_source_value(key, entry)


def translate_entries(
    strings: dict,
    target_lang: str,
    backend: TranslationBackend,
    force: bool = False,
    dry_run: bool = False,
    batch_size: int = 30,
) -> tuple[int, int]:
    # Each work item is (key, entry, kind, selector):
    #   kind="unit"   selector=None      → single stringUnit
    #   kind="plural" selector=category  → one plural variation
    #   kind="set"    selector=index     → one value of a stringSet (App Shortcut phrases)
    work_items: list[tuple[str, dict, str, object]] = []

    for key, entry in strings.items():
        if not entry.get("shouldTranslate", True):
            continue
        if not force and not needs_translation_lang(entry, target_lang):
            continue
        kind = entry_kind(entry)
        if kind == "plural":
            for cat in plural_categories_for(target_lang):
                work_items.append((key, entry, "plural", cat))
        elif kind == "set":
            for idx in range(len(get_en_set_values(entry))):
                work_items.append((key, entry, "set", idx))
        else:
            work_items.append((key, entry, "unit", None))

    if not work_items:
        print(f"  Nothing to translate for '{target_lang}' — all strings are complete.")
        return 0, 0

    print(f"  Found {len(work_items)} string(s) to translate into {lang_name(target_lang)}.")

    if dry_run:
        for key, entry, kind, selector in work_items:
            src = source_text_for(key, entry, kind, selector)
            tag = {"plural": f"plural/{selector}", "set": f"phrase[{selector}]"}.get(kind)
            label = f"{tag}: {src!r}" if tag else repr(src)
            print(f"    [dry-run] {label}")
        return len(work_items), 0

    protected_texts: list[str] = []
    mappings: list[dict[str, str]] = []
    context_hints: list[str] = []

    for key, entry, kind, selector in work_items:
        src = source_text_for(key, entry, kind, selector)
        protected, mapping = protect_placeholders(src)
        protected_texts.append(protected)
        mappings.append(mapping)
        context_hints.append(build_context_hint(key, entry))

    translated_texts: list[str] = []
    for i in range(0, len(protected_texts), batch_size):
        batch = protected_texts[i : i + batch_size]
        hint = context_hints[i] if i < len(context_hints) else ""
        print(f"  Translating batch {i // batch_size + 1} ({len(batch)} strings)…")
        results = backend.translate_batch(batch, target_lang, context_hint=hint)
        if len(results) != len(batch):
            raise ValueError(f"Backend returned {len(results)} results for {len(batch)} inputs.")
        translated_texts.extend(results)

    for i, (key, entry, kind, selector) in enumerate(work_items):
        raw = restore_placeholders(translated_texts[i], mappings[i])
        locs = entry.setdefault("localizations", {})

        if kind == "plural":
            lang_data = locs.setdefault(target_lang, {"variations": {"plural": {}}})
            lang_data.setdefault("variations", {}).setdefault("plural", {})
            lang_data["variations"]["plural"][selector] = {
                "stringUnit": {"state": "translated", "value": raw}
            }
        elif kind == "set":
            lang_data = locs.setdefault(target_lang, {"stringSet": {"state": "translated", "values": []}})
            sset = lang_data.setdefault("stringSet", {"state": "translated", "values": []})
            sset["state"] = "translated"
            values = sset.setdefault("values", [])
            while len(values) <= selector:
                values.append("")
            values[selector] = raw
        else:
            locs[target_lang] = {
                "stringUnit": {"state": "translated", "value": raw}
            }

    return len(work_items), 0


# ---------------------------------------------------------------------------
# File I/O
# ---------------------------------------------------------------------------

def load_xcstrings(path: Path) -> dict:
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def save_xcstrings(data: dict, path: Path) -> None:
    tmp = path.with_suffix(".xcstrings.tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    tmp.replace(path)
    print(f"  ✅ Saved to {path}")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    group = p.add_mutually_exclusive_group(required=True)
    group.add_argument("--lang", metavar="LANG_CODE",
                       help="Target language code (e.g. de, fr, es).")
    group.add_argument("--all", action="store_true",
                       help="Complete the union of all languages across every catalog, "
                            "seeding any catalog that is missing a language (keeps them in sync).")
    p.add_argument("--add", action="store_true",
                   help="Allow adding a brand-new language (--lang only).")
    p.add_argument("--backend", choices=list(BACKENDS), default="openai",
                   help="Translation backend (default: openai).")
    p.add_argument("--force", action="store_true",
                   help="Re-translate strings already marked 'translated'.")
    p.add_argument("--dry-run", action="store_true",
                   help="Show what would be translated without writing.")
    p.add_argument("--batch-size", type=int, default=30,
                   help="Strings per API call (default: 30).")
    p.add_argument("--file", type=Path, default=None,
                   help="Path to a single .xcstrings file. "
                        "If omitted, every catalog in the app is processed.")
    return p


def file_languages(path: Path) -> set[str]:
    """Non-source language codes already present in a catalog."""
    if not path.exists():
        return set()
    data = load_xcstrings(path)
    langs: set[str] = set()
    for entry in data.get("strings", {}).values():
        langs.update(entry.get("localizations", {}).keys())
    langs.discard(data.get("sourceLanguage", "en"))
    return langs


def collect_languages(files: list[Path]) -> list[str]:
    """Union of every non-source language across all catalogs (keeps files in sync)."""
    langs: set[str] = set()
    for path in files:
        langs |= file_languages(path)
    return sorted(langs)


def process_file(
    path: Path,
    args: argparse.Namespace,
    backend: Optional[TranslationBackend],
    target_langs: list[str],
    seed_missing: bool,
) -> int:
    """Translate one catalog; returns the number of strings translated."""
    if not path.exists():
        print(f"  [skip] File not found: {path}")
        return 0

    print(f"\n📂 Loading {os.path.relpath(path)} …")
    data = load_xcstrings(path)
    strings = data.get("strings", {})
    existing = file_languages(path)

    file_total = 0
    for lang in target_langs:
        if lang not in existing and not seed_missing:
            print(f"  [skip] {path.name}: '{lang}' not present (use --add to seed it).")
            continue
        seeding = " (seeding new)" if lang not in existing else ""
        print(f"\n🌍 {path.name} → {lang_name(lang)} ({lang}){seeding}")
        count, _ = translate_entries(
            strings=strings,
            target_lang=lang,
            backend=backend,
            force=args.force,
            dry_run=args.dry_run,
            batch_size=args.batch_size,
        )
        file_total += count

    if not args.dry_run and file_total > 0:
        save_xcstrings(data, path)
    return file_total


def run(args: argparse.Namespace) -> None:
    if args.file is not None:
        files = [args.file]
    else:
        files = discover_xcstrings()
    if not files:
        sys.exit(f"No .xcstrings files found under {PROJECT_DIR}.")

    if args.lang and args.lang not in PLURAL_CATEGORIES and args.add:
        print(
            f"  [warn] No CLDR plural categories defined for '{args.lang}'. "
            "Defaulting to ['one', 'other']. Update PLURAL_CATEGORIES in the script."
        )

    backend = None
    if not args.dry_run:
        print(f"🔧 Using backend: {args.backend}")
        backend = BACKENDS[args.backend]()
    else:
        print(f"🔧 Backend: {args.backend} (dry-run — not initialized)")

    print(f"🗂  Catalogs: {', '.join(f.name for f in files)}")

    if args.all:
        target_langs = collect_languages(files)
        if not target_langs:
            sys.exit("--all: no non-source languages found in any catalog.")
        seed_missing = True
        print(f"🌐 Languages ({len(target_langs)}): {', '.join(target_langs)}")
    else:
        target_langs = [args.lang]
        seed_missing = args.add

    total_translated = 0
    for path in files:
        total_translated += process_file(path, args, backend, target_langs, seed_missing)

    if not args.dry_run and total_translated > 0:
        print(f"\n✅ Done — {total_translated} string(s) translated and marked 'translated'.")
    elif args.dry_run:
        print(f"\n[dry-run] Would have translated {total_translated} string(s).")
    else:
        print("\nNo changes made.")


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    run(args)


if __name__ == "__main__":
    main()
