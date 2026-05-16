"""
Generate images for cocktails / ingredients that are referenced by the
Cocktails app's JSON files but don't yet have a matching .imageset asset.

Usage:
    python generate_missing.py --report                # just print the plan
    python generate_missing.py --cocktails             # generate missing cocktail images
    python generate_missing.py --ingredients           # generate missing ingredient images
    python generate_missing.py --cocktails --ingredients  # both

Outputs:
    icons/       cocktail PNGs (one per missing imageName)
    ingredients/ ingredient PNGs (one per missing ingredient id)
"""
import argparse
import json
import os
import sys

# cocktail / ingredient generators are imported lazily inside main(),
# so --report works without the openai dependency installed.

REPO = "/Users/mo/Developer/Kleingewerbe/Cocktails/Cocktails"
RECIPES = f"{REPO}/Resources/Recipes"
ASSETS = f"{REPO}/Resources/Assets.xcassets"

COCKTAIL_FILES = [
    "ebsInter2023_cocktails.json",
    "clutterfree_cocktails.json",
    "ibaUnforgettables_cocktails.json",
]


def load_json(path):
    with open(path) as f:
        return json.load(f)


def existing_imagesets(subdir):
    base = f"{ASSETS}/{subdir}"
    return {d[:-len(".imageset")] for d in os.listdir(base) if d.endswith(".imageset")}


def collect_missing_cocktails():
    existing = existing_imagesets("Cocktail")
    missing = []
    seen = set()
    for fname in COCKTAIL_FILES:
        for c in load_json(f"{RECIPES}/{fname}"):
            img = c.get("imageName")
            if not img or img in existing or img in seen:
                continue
            seen.add(img)
            garnish = ""
            if c.get("garnishes"):
                garnish = c["garnishes"][0]["ingredientId"].replace("_", " ")
            missing.append({
                "name": c["name"],
                "image": img,
                "glass": c["glass"],
                "garnish": garnish or "no garnish",
            })
    return missing


def collect_missing_ingredients():
    existing = existing_imagesets("Ingredient")
    missing = []
    for ing in load_json(f"{RECIPES}/ingredients.json"):
        if ing["id"] in existing:
            continue
        missing.append(ing)
    return missing


def collect_orphan_ingredient_assets():
    existing = existing_imagesets("Ingredient")
    catalog = {i["id"] for i in load_json(f"{RECIPES}/ingredients.json")}
    # 'Legacy' is a folder for retired assets, 'fluid' is the type-fallback used by IngredientType.imageName
    return sorted(existing - catalog - {"Legacy", "fluid"})


def print_report():
    cocktails = collect_missing_cocktails()
    ingredients = collect_missing_ingredients()
    orphans = collect_orphan_ingredient_assets()

    print(f"\n=== Missing cocktail images ({len(cocktails)}) ===")
    for c in cocktails:
        print(f"  {c['image']:25} {c['name']:25} glass={c['glass']:8} garnish={c['garnish']}")

    print(f"\n=== Missing ingredient images ({len(ingredients)}) ===")
    for i in ingredients:
        print(f"  {i['id']:25} {i['name']:30} type={i['type']}")

    print(f"\n=== Orphaned ingredient assets ({len(orphans)}) ===")
    print("    (folders in Assets.xcassets/Ingredient with no matching ID in ingredients.json)")
    for o in orphans:
        print(f"  {o}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--report", action="store_true", help="Print the plan and exit")
    p.add_argument("--cocktails", action="store_true", help="Generate missing cocktail images")
    p.add_argument("--ingredients", action="store_true", help="Generate missing ingredient images")
    p.add_argument("--cocktail-out", default="icons")
    p.add_argument("--ingredient-out", default="ingredients")
    p.add_argument("--limit", type=int, default=None, help="Cap how many to generate (for testing)")
    args = p.parse_args()

    if args.report or not (args.cocktails or args.ingredients):
        print_report()
        if not (args.cocktails or args.ingredients):
            sys.exit(0)

    if args.cocktails or args.ingredients:
        from cocktail import generate_sf_style_icon as generate_cocktail
        from ingredient import generate_sf_style_icon as generate_ingredient

    if args.cocktails:
        items = collect_missing_cocktails()
        if args.limit:
            items = items[: args.limit]
        print(f"\nGenerating {len(items)} cocktail image(s)…")
        for c in items:
            generate_cocktail(c["name"], c["glass"], c["garnish"], c["image"], save_path=args.cocktail_out)

    if args.ingredients:
        items = collect_missing_ingredients()
        if args.limit:
            items = items[: args.limit]
        print(f"\nGenerating {len(items)} ingredient image(s)…")
        for i in items:
            generate_ingredient(i["name"], i["type"], i["id"], save_path=args.ingredient_out)


if __name__ == "__main__":
    main()
