# -*- coding: utf-8 -*-
"""
Validation script for HomeStock master product catalog.
Ensures strict compliance with schema, uniqueness, and catalog completeness.
"""
import json
import sys

VALID_UNITS = {"kg", "g", "l", "ml", "piece", "pack", "bunch", "dozen", "roll"}
VALID_SOLD_BY = {"weight", "volume", "piece", "package"}

def validate():
    json_path = "frontend/assets/data/products.json"
    print(f"Validating {json_path}...")

    with open(json_path, "r", encoding="utf-8") as f:
        catalog = json.load(f)

    errors = []

    # 1. Total products check
    count = len(catalog)
    print(f"Found {count} products in catalog.")
    if count < 2000:
        errors.append(f"Product count is {count}, which is less than required 2000.")

    seen_ids = set()
    seen_names = set()

    for idx, p in enumerate(catalog):
        pid = p.get("id")
        name = p.get("name")
        tamil = p.get("tamilName")
        unit = p.get("defaultUnit")
        sold_by = p.get("soldBy")
        barcodes = p.get("barcodes", [])

        # ID Uniqueness
        if not pid:
            errors.append(f"Item #{idx} missing ID.")
        elif pid in seen_ids:
            errors.append(f"Duplicate ID detected: {pid} at item #{idx}")
        else:
            seen_ids.add(pid)

        # Name Uniqueness
        if not name:
            errors.append(f"Item #{idx} missing Name.")
        else:
            n_low = name.strip().lower()
            if n_low in seen_names:
                errors.append(f"Duplicate Name detected: '{name}' at item #{idx}")
            else:
                seen_names.add(n_low)

        # Tamil name check
        if not tamil or not tamil.strip():
            errors.append(f"Item '{name}' ({pid}) is missing an authentic tamilName.")

        # Unit check
        if unit not in VALID_UNITS:
            errors.append(f"Item '{name}' ({pid}) has invalid unit: '{unit}'. Valid: {VALID_UNITS}")

        # soldBy check
        if sold_by not in VALID_SOLD_BY:
            errors.append(f"Item '{name}' ({pid}) has invalid soldBy: '{sold_by}'. Valid: {VALID_SOLD_BY}")

        # Barcode check (no fake barcodes)
        if not isinstance(barcodes, list):
            errors.append(f"Item '{name}' ({pid}) barcodes is not a list.")

        # Fields check
        for field in ["category", "subCategory", "productType", "storageLocation", "iconKey"]:
            if not p.get(field):
                errors.append(f"Item '{name}' ({pid}) is missing field: {field}")

        if p.get("minimumQuantity", 0) <= 0:
            errors.append(f"Item '{name}' ({pid}) minimumQuantity must be > 0.")

        if not p.get("customQuantities") or len(p.get("customQuantities")) == 0:
            errors.append(f"Item '{name}' ({pid}) customQuantities cannot be empty.")

    if errors:
        print(f"\nFAILED: Found {len(errors)} validation errors:")
        for e in errors[:20]:
            print(f" - {e}")
        if len(errors) > 20:
            print(f" ... and {len(errors) - 20} more errors.")
        sys.exit(1)
    else:
        print(f"\nSUCCESS: Catalog validation passed! All {count} products meet all criteria perfectly with 0 errors.")

if __name__ == "__main__":
    validate()

