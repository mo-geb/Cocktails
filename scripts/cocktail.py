"""Generate a single cocktail icon.

Usage:
    python cocktail.py "Old Fashioned" --glass rocks --garnish "orange zest" --image old_fashioned
"""
import argparse

from _common import BASE_STYLE, generate_and_save


def generate_sf_style_icon(cocktail_name, cocktail_glass, garnish, image_name, save_path="icons"):
    garnish_phrase = f", garnished with a {garnish}" if garnish and garnish.lower() != "no garnish" else ""
    prompt = (
        f"A high-quality 3D emoji icon of a {cocktail_name} cocktail in a "
        f"{cocktail_glass} glass{garnish_phrase}. {BASE_STYLE}"
    )
    generate_and_save(prompt, save_path, image_name, f"{cocktail_name} cocktail")


def main():
    p = argparse.ArgumentParser(description="Generate a single cocktail icon.")
    p.add_argument("name", help="Cocktail name, e.g. 'Old Fashioned'")
    p.add_argument("--glass", required=True, help="Glass type, e.g. rocks, martini, highball")
    p.add_argument("--garnish", default="", help="Garnish description, e.g. 'orange zest'")
    p.add_argument("--image", required=True, help="Output filename stem (without .png)")
    p.add_argument("--save-path", default="icons")
    args = p.parse_args()
    generate_sf_style_icon(args.name, args.glass, args.garnish, args.image, save_path=args.save_path)


if __name__ == "__main__":
    main()
