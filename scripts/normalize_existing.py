import json
import re

def slugify(text):
    text = text.lower().strip()
    text = re.sub(r'\(.*?\)', '', text).strip()
    text = re.sub(r'[^a-z0-9]+', '_', text).strip('_')
    return text

def clean_name(name):
    cleaned = re.sub(r'\s*\([^)]*\)', '', name).strip()
    return cleaned

def parse_pack_sizes(pack_sizes_str_list):
    res = []
    for s in pack_sizes_str_list:
        m = re.search(r'([0-9.]+)', s)
        if m:
            try:
                res.append(float(m.group(1)))
            except ValueError:
                pass
    return sorted(list(set(res))) if res else [1.0]

def extract_brands_from_name(name):
    brands = []
    if '(' in name and ')' in name:
        inside = name[name.find('(')+1:name.find(')')]
        parts = [p.strip() for p in inside.split('/')]
        for p in parts:
            if any(b in p.lower() for b in [
                'amul', 'britannia', 'lay', 'bingo', 'kissan', 'maggi', 'heinz', 'tata', 'nestle',
                'bournvita', 'horlicks', 'boost', 'complan', 'everyday', 'amulya', 'veeba', 'funfoods',
                'pintola', 'myfitness', 'surf', 'ariel', 'rin', 'vim', 'pril', 'lizol', 'harpic',
                'colin', 'colgate', 'close-up', 'sensodyne', 'dettol', 'pears', 'lifebuoy', 'dove',
                'pedigree', 'whiskas', 'nan pro', 'lactogen', 'similac', 'act ii', 'pampers', 'mamy poko',
                'huggies', 'johnson', 'himalaya', 'fortune', 'saffola', 'gemini', 'dhara', 'parle',
                'cadbury', 'haldiram', 'bikano', 'aashirvaad', 'pillsbury', 'everest', 'mdh', 'catch'
            ]):
                brands.append(p)
    return brands

CATEGORY_NORMALIZATION = {
    'Rice & Rice Products': ('Food & Grocery', 'Rice & Grains', 'staple'),
    'Dals, Pulses & Legumes': ('Food & Grocery', 'Dals & Pulses', 'staple'),
    'Flours & Grains': ('Food & Grocery', 'Flours & Grains', 'staple'),
    'Cooking Oils & Fats': ('Oils & Fats', 'Cooking Oils', 'staple'),
    'Spices & Masalas': ('Spices & Seasonings', 'Spices & Masalas', 'spice'),
    'Salt, Sugar & Sweeteners': ('Salt, Sugar & Sweeteners', 'Salt & Sweeteners', 'staple'),
    'Breakfast & Ready-to-Eat': ('Instant & Ready-to-Cook', 'Breakfast & Mixes', 'packaged_food'),
    'Snacks': ('Snacks & Namkeen', 'Traditional Snacks', 'snack'),
    'Tea, Coffee & Beverages': ('Beverages', 'Tea & Coffee', 'beverage'),
    'Dairy & Refrigerated Products': ('Dairy & Refrigerated', 'Dairy Products', 'dairy'),
    'Pickles, Sauces & Condiments': ('Pickles, Sauces & Condiments', 'Pickles & Sauces', 'condiment'),
    'Cooking & Baking Ingredients': ('Food & Grocery', 'Baking Ingredients', 'staple'),
    'Dry Fruits, Nuts & Seeds': ('Dry Fruits, Nuts & Seeds', 'Dry Fruits & Nuts', 'snack'),
    'Fresh Vegetables': ('Fresh Vegetables', 'Daily Vegetables', 'fresh_food'),
    'Fruits': ('Fresh Fruits', 'Fresh Fruits', 'fresh_food'),
    'Eggs, Meat & Seafood': ('Fresh Meat, Poultry & Seafood', 'Eggs & Poultry', 'fresh_food'),
    'Household Cleaning Products': ('Cleaning & Household', 'Home Cleaners', 'cleaning'),
    'Laundry Products': ('Cleaning & Household', 'Laundry Care', 'laundry'),
    'Personal Care': ('Personal Care & Hygiene', 'Bath & Body', 'personal_care'),
    'Paper & Disposable Products': ('Kitchen Utility & Disposables', 'Paper & Disposables', 'kitchen_utility'),
    'Kitchen Utility Products': ('Kitchen Utility & Disposables', 'Kitchen Utilities', 'kitchen_utility'),
    'Baby Products': ('Baby Care', 'Baby Essentials', 'baby_care'),
    'Pet Products': ('Pet Care', 'Pet Food & Care', 'pet_care'),
    'Household Essentials': ('Home Utility & Pooja', 'Household Utilities', 'household_utility'),
}

ICON_KEY_MAP = {
    'Rice & Rice Products': 'rice',
    'Dals, Pulses & Legumes': 'dal',
    'Flours & Grains': 'grains',
    'Cooking Oils & Fats': 'oil',
    'Spices & Masalas': 'spices',
    'Salt, Sugar & Sweeteners': 'salt',
    'Breakfast & Ready-to-Eat': 'breakfast',
    'Snacks': 'snacks',
    'Tea, Coffee & Beverages': 'beverages',
    'Dairy & Refrigerated Products': 'dairy',
    'Pickles, Sauces & Condiments': 'condiments',
    'Cooking & Baking Ingredients': 'baking',
    'Dry Fruits, Nuts & Seeds': 'dry_fruits',
    'Fresh Vegetables': 'vegetables',
    'Fruits': 'fruits',
    'Eggs, Meat & Seafood': 'meat',
    'Household Cleaning Products': 'cleaning',
    'Laundry Products': 'laundry',
    'Personal Care': 'personal_care',
    'Paper & Disposable Products': 'paper',
    'Kitchen Utility Products': 'kitchen',
    'Baby Products': 'baby',
    'Pet Products': 'pet',
    'Household Essentials': 'utility',
}

def get_normalized_existing():
    with open(r'd:\New folder (3)\home\data\master_product_catalog.json', 'r', encoding='utf-8') as f:
        master_raw = json.load(f)

    normalized = []
    seen_ids = set()

    for item in master_raw:
        orig_name = item['productName']
        cleaned = clean_name(orig_name)
        if not cleaned:
            cleaned = orig_name

        cat_orig = item.get('category', 'Food & Grocery')
        cat_norm, subcat_norm, ptype_norm = CATEGORY_NORMALIZATION.get(
            cat_orig, ('Food & Grocery', cat_orig, 'staple')
        )

        prefix_map = {
            'Rice & Rice Products': 'rice',
            'Dals, Pulses & Legumes': 'dal',
            'Flours & Grains': 'flour',
            'Cooking Oils & Fats': 'oil',
            'Spices & Masalas': 'spice',
            'Salt, Sugar & Sweeteners': 'sweet',
            'Breakfast & Ready-to-Eat': 'bfirst',
            'Snacks': 'snack',
            'Tea, Coffee & Beverages': 'bev',
            'Dairy & Refrigerated Products': 'dairy',
            'Pickles, Sauces & Condiments': 'pickle',
            'Cooking & Baking Ingredients': 'bake',
            'Dry Fruits, Nuts & Seeds': 'nut',
            'Fresh Vegetables': 'veg',
            'Fruits': 'fruit',
            'Eggs, Meat & Seafood': 'meat',
            'Household Cleaning Products': 'clean',
            'Laundry Products': 'laundry',
            'Personal Care': 'personal',
            'Paper & Disposable Products': 'paper',
            'Kitchen Utility Products': 'kitchen',
            'Baby Products': 'baby',
            'Pet Products': 'pet',
            'Household Essentials': 'util',
        }
        prefix = prefix_map.get(cat_orig, 'item')
        base_slug = slugify(cleaned)
        item_id = f"{prefix}_{base_slug}"
        if item_id in seen_ids:
            item_id = f"{item_id}_2"
        seen_ids.add(item_id)

        tamil_name = item.get('regionalNames', {}).get('tamil', '')
        common_names = list(item.get('commonNames', []))
        aliases = [orig_name] if orig_name != cleaned else []
        for cn in common_names:
            if cn not in aliases and cn != cleaned:
                aliases.append(cn)
        for r_lang, r_val in item.get('regionalNames', {}).items():
            if r_lang != 'tamil' and r_val and r_val not in aliases:
                aliases.append(r_val)

        extracted_brands = extract_brands_from_name(orig_name)

        unit = item.get('typicalUnit', 'kg')
        if unit == 'pcs':
            unit = 'piece'

        sale_mode = item.get('saleMode', {})
        if sale_mode.get('weightBased'):
            sold_by = 'weight'
        elif unit in ['L', 'ml']:
            sold_by = 'volume'
        elif unit in ['piece', 'bunch', 'pair']:
            sold_by = 'piece'
        else:
            sold_by = 'package'

        pack_sizes = parse_pack_sizes(item.get('packSizes', []))

        storage_type = item.get('storageType', 'pantry').lower()
        if 'fridge' in storage_type or 'refrigerat' in storage_type:
            storage_location = 'Refrigerator'
        elif 'bathroom' in storage_type:
            storage_location = 'Bathroom'
        elif 'cleaning' in storage_type or 'utility' in storage_type:
            storage_location = 'Utility Room'
        elif 'counter' in storage_type:
            storage_location = 'Kitchen Counter'
        else:
            storage_location = 'Pantry Shelf'

        prod = {
            "id": item_id,
            "name": cleaned,
            "tamilName": tamil_name,
            "category": cat_norm,
            "subCategory": subcat_norm,
            "productType": ptype_norm,
            "defaultUnit": unit,
            "soldBy": sold_by,
            "storageLocation": storage_location,
            "minimumQuantity": pack_sizes[0] if pack_sizes else 1.0,
            "commonNames": common_names,
            "aliases": aliases,
            "brands": extracted_brands,
            "barcodeSupport": item.get('barcode', {}).get('possible', True),
            "barcodeType": item.get('barcode', {}).get('type', 'EAN_13'),
            "barcodes": [],
            "isLoose": sale_mode.get('loose', False),
            "isPackaged": sale_mode.get('packaged', True),
            "iconKey": ICON_KEY_MAP.get(cat_orig, 'grains'),
            "customQuantities": pack_sizes
        }
        normalized.append(prod)

    print(f"Normalized {len(normalized)} existing master items.")
    return normalized

if __name__ == "__main__":
    items = get_normalized_existing()
    print(f"Sample item: {json.dumps(items[0], indent=2, ensure_ascii=False)}")

