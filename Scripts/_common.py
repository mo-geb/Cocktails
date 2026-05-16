"""Shared OpenAI client, prompt fragments, and save helper."""
import base64
import os

from openai import OpenAI

client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

MODEL = "gpt-image-1-mini"

BASE_STYLE = (
    "Rendered in the official Apple iOS emoji style. "
    "Glossy finish, vibrant colors, and soft ambient occlusion shadows. "
    "Centered on a transparent background. Slightly isometric/3D perspective, "
    "realistic textures and studio lighting. No text, no borders, no extra characters."
)

CATEGORY_PROMPTS = {
    "spirit":        "a bottle of {name} spirit",
    "liqueur":       "a bottle of {name} liqueur",
    "fortifiedWine": "a bottle of {name}",
    "juice":         "a glass of {name} with the source fruit beside it",
    "mixer":         "a can or bottle of {name}",
    "syrup":         "a small bottle of {name} syrup",
    "bitters":       "a small dasher bottle of {name} bitters",
    "garnish":       "a {name} as a cocktail garnish",
    "other":         "a {name}",
}


def generate_and_save(prompt: str, save_path: str, image_name: str, label: str) -> None:
    """Call the image API and write the result to <save_path>/<image_name>.png."""
    os.makedirs(save_path, exist_ok=True)
    print(f"Generating: {label}…")
    try:
        result = client.images.generate(model=MODEL, prompt=prompt, n=1, size="auto", quality="auto")
        image_bytes = base64.b64decode(result.data[0].b64_json)
        out_path = os.path.join(save_path, f"{image_name}.png")
        with open(out_path, "wb") as fh:
            fh.write(image_bytes)
        print(f"✅ {out_path}")
    except Exception as exc:
        print(f"❌ {label}: {exc}")
