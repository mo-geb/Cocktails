"""Generate a single ingredient icon.

Usage:
    python ingredient.py "Calvados" --type spirit --image calvados
"""
import argparse

from _common import BASE_STYLE, CATEGORY_PROMPTS, generate_and_save


def generate_sf_style_icon(ingredient_name, ingredient_type, image_name, save_path="ingredients"):
    subject = CATEGORY_PROMPTS.get(ingredient_type, CATEGORY_PROMPTS["other"]).format(name=ingredient_name)
    prompt = f"A high-quality 3D emoji icon of {subject}. {BASE_STYLE}"
    generate_and_save(prompt, save_path, image_name, f"{ingredient_name} ({ingredient_type})")


def main():
    p = argparse.ArgumentParser(description="Generate a single ingredient icon.")
    p.add_argument("name", help="Ingredient name, e.g. 'Calvados'")
    p.add_argument("--type", required=True, choices=list(CATEGORY_PROMPTS), help="Ingredient category")
    p.add_argument("--image", required=True, help="Output filename stem (without .png)")
    p.add_argument("--save-path", default="ingredients")
    args = p.parse_args()
    generate_sf_style_icon(args.name, args.type, args.image, save_path=args.save_path)


if __name__ == "__main__":
    main()
