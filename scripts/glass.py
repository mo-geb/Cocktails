"""Generate glass icons (empty / filled / general variants).

Usage:
    python glass.py highball                          # both empty + filled
    python glass.py "copper mug" --variant general
    python glass.py wine --variant empty filled general
"""
import argparse

from _common import BASE_STYLE, generate_and_save

VARIANT_PROMPTS = {
    "empty":   "an empty {name} glass",
    "filled":  "a {name} glass filled with colorful liquid",
    "general": "a {name}",
}


def generate_glass_icon(name, variants, save_path="icons"):
    safe_name = name.replace(" ", "_")
    for variant in variants:
        subject = VARIANT_PROMPTS[variant].format(name=name)
        prompt = f"A high-quality 3D emoji icon of {subject}. {BASE_STYLE}"
        generate_and_save(prompt, save_path, f"{safe_name}_{variant}", f"{name} ({variant})")


def main():
    p = argparse.ArgumentParser(description="Generate glass icons.")
    p.add_argument("name", help="Glass name, e.g. 'highball' or 'copper mug'")
    p.add_argument(
        "--variant",
        choices=list(VARIANT_PROMPTS),
        nargs="+",
        default=["empty", "filled"],
        help="Variant(s) to generate. Defaults to empty + filled.",
    )
    p.add_argument("--save-path", default="icons")
    args = p.parse_args()
    generate_glass_icon(args.name, args.variant, save_path=args.save_path)


if __name__ == "__main__":
    main()
