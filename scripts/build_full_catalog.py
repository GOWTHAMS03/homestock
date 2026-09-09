# -*- coding: utf-8 -*-
"""
Full Catalog Builder for HomeStock:
Consolidates all 12 expansion and normalization modules into a single,
strictly deduplicated master product catalog with >2,000 products.

Outputs:
1. data/products.json
2. frontend/assets/data/products.json
3. frontend/lib/core/constants/master_product_staples.dart
"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import scripts.normalize_existing as m1
import scripts.expand_food_grocery as m2
import scripts.expand_oils_spices_condiments as m3
import scripts.expand_fresh_produce_dairy as m4
import scripts.expand_snacks_beverages as m5
import scripts.expand_non_food as m6
import scripts.expand_mega_catalog as m7
import scripts.expand_full_catalog_2000 as m8
import scripts.expand_extra_catalog as m9
import scripts.expand_matrix_catalog as m10
import scripts.expand_matrix_catalog_part2 as m11
import scripts.expand_matrix_catalog_part3 as m12

ICON_TO_FLUTTER = {
    "rice": "Icons.grain_rounded",
    "grains": "Icons.grain_rounded",
    "dal": "Icons.circle",
    "oil": "Icons.opacity_rounded",
    "masala": "Icons.soup_kitchen_rounded",
    "spice": "Icons.soup_kitchen_rounded",
    "condiment": "Icons.dinner_dining_rounded",
    "fresh_produce": "Icons.eco_rounded",
    "dairy": "Icons.egg_rounded",
    "beverage": "Icons.local_cafe_rounded",
    "snacks": "Icons.bakery_dining_rounded",
    "cleaning": "Icons.cleaning_services_rounded",
    "personal_care": "Icons.spa_rounded",
    "baby_care": "Icons.child_care_rounded",
    "pets": "Icons.pets_rounded",
    "hardware": "Icons.build_rounded",
    "pooja": "Icons.wb_sunny_rounded",
    "staple": "Icons.inventory_2_rounded",
    "packaged_food": "Icons.inventory_2_rounded",
}

ICON_TO_EMOJI = {
    "rice": "🌾",
    "grains": "🌾",
    "dal": "🥣",
    "oil": "🫒",
    "masala": "🌶️",
    "spice": "🌶️",
    "condiment": "🥫",
    "fresh_produce": "🥬",
    "dairy": "🥛",
    "beverage": "☕",
    "snacks": "🍪",
    "cleaning": "🧹",
    "personal_care": "🧴",
    "baby_care": "🍼",
    "pets": "🐾",
    "hardware": "💡",
    "pooja": "🪔",
    "staple": "📦",
    "packaged_food": "🍱",
}

def clean_string_for_dart(s):
    if s is None:
        return ""
    return s.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$")

def main():
    print("Loading catalog sources...")
    c1 = m1.get_normalized_existing()
    c2 = m2.get_food_grocery_expansion()
    c3 = m3.get_oils_spices_condiments_expansion()
    c4 = m4.get_fresh_produce_dairy_expansion()
    c5 = m5.get_snacks_beverages_expansion()
    c6 = m6.get_non_food_expansion()
    c7 = m7.get_mega_catalog_expansion()
    c8 = m8.get_expansion_2000()
    c9 = m9.get_extra_catalog_expansion()
    c10 = m10.get_matrix_catalog()
    c11 = m11.get_matrix_catalog_part2()
    c12 = m12.get_matrix_catalog_part3()

    all_raw = c1 + c2 + c3 + c4 + c5 + c6 + c7 + c8 + c9 + c10 + c11 + c12
    print(f"Total raw items across all 12 modules: {len(all_raw)}")

    # Strict deduplication by ID and lowercase Name
    deduped = []
    seen_ids = set()
    seen_names = set()

    for item in all_raw:
        item_id = item["id"].strip()
        name_key = item["name"].strip().lower()

        if item_id in seen_ids or name_key in seen_names:
            continue

        seen_ids.add(item_id)
        seen_names.add(name_key)

        # Sanitize and ensure proper unit and soldBy
        unit_raw = item.get("defaultUnit", "pack").strip().lower()
        UNIT_MAP = {
            "kg": "kg", "g": "g", "gm": "g", "gms": "g",
            "l": "l", "liter": "l", "litre": "l",
            "ml": "ml",
            "piece": "piece", "pieces": "piece", "pc": "piece", "pcs": "piece", "bar": "piece",
            "bunch": "bunch", "bunches": "bunch",
            "dozen": "dozen",
            "roll": "roll", "meter": "roll", "m": "roll",
            "pack": "pack", "packet": "pack", "packets": "pack", "box": "pack", "can": "pack", "bottle": "pack", "tube": "pack"
        }
        unit = UNIT_MAP.get(unit_raw, "pack")
        if unit in ["kg", "g"]:
            sold_by = "weight"
        elif unit in ["l", "ml"]:
            sold_by = "volume"
        elif unit in ["piece", "bunch", "dozen", "roll"]:
            sold_by = "piece"
        else:
            sold_by = "package"

        # Ensure barcodes is a list
        barcodes = item.get("barcodes", [])
        if not isinstance(barcodes, list):
            barcodes = []

        prod = {
            "id": item_id,
            "name": item["name"].strip(),
            "tamilName": item.get("tamilName", "").strip(),
            "category": item.get("category", "General").strip(),
            "subCategory": item.get("subCategory", "General").strip(),
            "productType": item.get("productType", "General").strip(),
            "defaultUnit": unit,
            "soldBy": sold_by,
            "storageLocation": item.get("storageLocation", "Pantry Shelf").strip(),
            "minimumQuantity": float(item.get("minimumQuantity", 1.0)),
            "customQuantities": [float(q) for q in item.get("customQuantities", [1.0])],
            "commonNames": item.get("commonNames", []),
            "aliases": [a.lower().strip() for a in item.get("aliases", [])],
            "brands": item.get("brands", []),
            "barcodeSupport": bool(item.get("barcodeSupport", True)),
            "barcodeType": item.get("barcodeType", "EAN_13"),
            "barcodes": barcodes,
            "isLoose": bool(item.get("isLoose", False)),
            "isPackaged": bool(item.get("isPackaged", True)),
            "iconKey": item.get("iconKey", "staple")
        }
        deduped.append(prod)

    print(f"Total deduplicated unique products: {len(deduped)}")
    assert len(deduped) >= 2000, f"Expected at least 2000 items, got {len(deduped)}"

    # Save to data/products.json
    os.makedirs("data", exist_ok=True)
    with open("data/products.json", "w", encoding="utf-8") as f:
        json.dump(deduped, f, ensure_ascii=False, indent=2)
    print("Saved data/products.json")

    # Save to frontend/assets/data/products.json
    os.makedirs("frontend/assets/data", exist_ok=True)
    with open("frontend/assets/data/products.json", "w", encoding="utf-8") as f:
        json.dump(deduped, f, ensure_ascii=False, indent=2)
    print("Saved frontend/assets/data/products.json")

    # Generate frontend/lib/core/constants/master_product_staples.dart
    print("Generating Dart master_product_staples.dart file...")
    dart_lines = [
        "// GENERATED MASTER PRODUCT STAPLES CATALOG",
        f"// Contains {len(deduped)} authentic Indian household products with Tamil names, units, and icons.",
        "// Auto-generated by scripts/build_full_catalog.py - DO NOT EDIT DIRECTLY.",
        "import 'package:flutter/material.dart';",
        "import 'household_staples.dart';",
        "",
        "const List<HouseholdStaple> kMasterProductCatalogStaples = [",
    ]

    for p in deduped:
        icon_str = ICON_TO_FLUTTER.get(p["iconKey"], "Icons.inventory_2_rounded")
        emoji_str = ICON_TO_EMOJI.get(p["iconKey"], "📦")
        name_esc = clean_string_for_dart(p["name"])
        tamil_esc = clean_string_for_dart(p["tamilName"])
        cat_esc = clean_string_for_dart(p["category"])
        subcat_esc = clean_string_for_dart(p["subCategory"])
        loc_esc = clean_string_for_dart(p["storageLocation"])
        unit_esc = clean_string_for_dart(p["defaultUnit"])
        sold_esc = clean_string_for_dart(p["soldBy"])
        btype_esc = clean_string_for_dart(p["barcodeType"])

        quantities_str = "[" + ", ".join(f"{q:.1f}" if q.is_integer() else f"{q}" for q in p["customQuantities"]) + "]"
        brands_str = "[" + ", ".join(f"'{clean_string_for_dart(b)}'" for b in p["brands"]) + "]"
        common_names_str = "[" + ", ".join(f"'{clean_string_for_dart(c)}'" for c in p["commonNames"]) + "]"

        dart_lines.append("  HouseholdStaple(")
        dart_lines.append(f"    name: '{name_esc}',")
        if tamil_esc:
            dart_lines.append(f"    tamilName: '{tamil_esc}',")
        dart_lines.append(f"    defaultQty: {p['minimumQuantity']},")
        dart_lines.append(f"    defaultUnit: '{unit_esc}',")
        dart_lines.append(f"    emoji: '{emoji_str}',")
        dart_lines.append(f"    icon: {icon_str},")
        dart_lines.append(f"    category: '{cat_esc}',")
        if subcat_esc:
            dart_lines.append(f"    subCategory: '{subcat_esc}',")
        dart_lines.append(f"    storageLocation: '{loc_esc}',")
        dart_lines.append(f"    minimumQuantity: {p['minimumQuantity']},")
        dart_lines.append(f"    customQuantities: {quantities_str},")
        dart_lines.append(f"    customBrands: {brands_str},")
        dart_lines.append(f"    commonNames: {common_names_str},")
        dart_lines.append(f"    isLoose: {'true' if p['isLoose'] else 'false'},")
        dart_lines.append(f"    isPackaged: {'true' if p['isPackaged'] else 'false'},")
        dart_lines.append(f"    barcodeSupport: {'true' if p['barcodeSupport'] else 'false'},")
        dart_lines.append(f"    barcodeType: '{btype_esc}',")
        dart_lines.append(f"    soldBy: '{sold_esc}',")
        dart_lines.append("  ),")

    dart_lines.append("];")
    dart_lines.append("")

    with open("frontend/lib/core/constants/master_product_staples.dart", "w", encoding="utf-8") as f:
        f.write("\n".join(dart_lines))
    print("Saved frontend/lib/core/constants/master_product_staples.dart")

    # Category summary
    cat_counts = {}
    for p in deduped:
        cat_counts[p["category"]] = cat_counts.get(p["category"], 0) + 1

    print("\n=== CATALOG SUMMARY ===")
    print(f"Total Verified Products: {len(deduped)}")
    for cat, count in sorted(cat_counts.items(), key=lambda x: -x[1]):
        print(f" - {cat}: {count}")

if __name__ == "__main__":
    main()
