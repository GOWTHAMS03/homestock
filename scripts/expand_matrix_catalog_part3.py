# -*- coding: utf-8 -*-
"""
Matrix Catalog Expansion Part 3: Contains 187 culturally authentic,
normalized household products for Indian / Tamil Nadu households.
"""
import json

_DATA = r"""[
  {
    "id": "athimathuram_whole_licorice_roots",
    "name": "Athimathuram Whole Licorice Roots",
    "tamilName": "அதிமதுரம் வேர் (முழுசு)",
    "category": "Spices & Seasonings",
    "subCategory": "Ayurvedic Powders",
    "productType": "Herbal Root",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 100.0,
    "customQuantities": [
      50.0,
      100.0,
      200.0
    ],
    "commonNames": [
      "athimathuram ver",
      "licorice root whole",
      "mulethi root"
    ],
    "aliases": [
      "athimathuram ver",
      "licorice root whole",
      "mulethi root"
    ],
    "brands": [
      "Local Ayurvedic",
      "Ganapathy Stores"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "spice"
  },
  {
    "id": "chitharathai_lesser_galangal_rhizome_whole",
    "name": "Chitharathai Lesser Galangal Rhizome Whole",
    "tamilName": "சித்தரத்தை (முழுசு)",
    "category": "Spices & Seasonings",
    "subCategory": "Ayurvedic Powders",
    "productType": "Herbal Root",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 100.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "chitharathai whole",
      "galangal rhizome"
    ],
    "aliases": [
      "chitharathai whole",
      "galangal rhizome"
    ],
    "brands": [
      "Local Ayurvedic"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "spice"
  },
  {
    "id": "kandanthippili_dried_wild_pepper_roots",
    "name": "Kandanthippili Dried Wild Pepper Roots",
    "tamilName": "கண்டந்திப்பிலி வேர்",
    "category": "Spices & Seasonings",
    "subCategory": "Ayurvedic Powders",
    "productType": "Herbal Root",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 50.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "kandanthippili",
      "long pepper root"
    ],
    "aliases": [
      "kandanthippili",
      "long pepper root"
    ],
    "brands": [
      "Local Ayurvedic",
      "Gopuram"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "spice"
  },
  {
    "id": "arisithippili_long_pepper_spikes_whole",
    "name": "Arisithippili Long Pepper Spikes Whole",
    "tamilName": "அரிசித்திப்பிலி (முழுசு)",
    "category": "Spices & Seasonings",
    "subCategory": "Ayurvedic Powders",
    "productType": "Herbal Spike",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 50.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "arisithippili",
      "pippali whole"
    ],
    "aliases": [
      "arisithippili",
      "pippali whole"
    ],
    "brands": [
      "Local Ayurvedic"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "spice"
  },
  {
    "id": "vettiveru_khus_vetiver_roots_fragrant",
    "name": "Vettiveru Khus Vetiver Roots Fragrant",
    "tamilName": "வெட்டிவேர்",
    "category": "Personal Care & Hygiene",
    "subCategory": "Bath & Body Care",
    "productType": "Fragrant Root",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Bathroom Shelf",
    "minimumQuantity": 50.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "vettiveru",
      "vetiver grass root",
      "khus"
    ],
    "aliases": [
      "vettiveru",
      "vetiver grass root",
      "khus"
    ],
    "brands": [
      "Local Ayurvedic",
      "Gopuram"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "vilamichai_ver_fragrant_mallow_roots",
    "name": "Vilamichai Ver Fragrant Mallow Roots",
    "tamilName": "விளாமிச்சை வேர்",
    "category": "Personal Care & Hygiene",
    "subCategory": "Bath & Body Care",
    "productType": "Fragrant Root",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Bathroom Shelf",
    "minimumQuantity": 50.0,
    "customQuantities": [
      50.0
    ],
    "commonNames": [
      "vilamichai ver",
      "fragrant swamp mallow root"
    ],
    "aliases": [
      "vilamichai ver",
      "fragrant swamp mallow root"
    ],
    "brands": [
      "Local Ayurvedic"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "nannari_ver_sarsaparilla_root_whole",
    "name": "Nannari Ver Sarsaparilla Root Whole",
    "tamilName": "நன்னாரி வேர் (முழுசு)",
    "category": "Beverages",
    "subCategory": "Herbal Drinks",
    "productType": "Herbal Root",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "nannari ver",
      "sarsaparilla root"
    ],
    "aliases": [
      "nannari ver",
      "sarsaparilla root"
    ],
    "brands": [
      "Local Ayurvedic",
      "Gramiyum"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "kadukkai_whole_haritaki_chebulic_myrobalan",
    "name": "Kadukkai Whole Haritaki Chebulic Myrobalan",
    "tamilName": "கடுக்காய் (முழுசு)",
    "category": "Spices & Seasonings",
    "subCategory": "Ayurvedic Powders",
    "productType": "Herbal Fruit",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "kadukkai",
      "haritaki whole",
      "harad"
    ],
    "aliases": [
      "kadukkai",
      "haritaki whole",
      "harad"
    ],
    "brands": [
      "Local Ayurvedic",
      "Baidyanath"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "spice"
  },
  {
    "id": "nellikkai_dried_amla_fruit_pieces",
    "name": "Nellikkai Dried Amla Fruit Pieces",
    "tamilName": "நெல்லிக்காய் வற்றல் (உலர்ந்தது)",
    "category": "Spices & Seasonings",
    "subCategory": "Ayurvedic Powders",
    "productType": "Herbal Fruit",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "dried amla",
      "nellikai vathal"
    ],
    "aliases": [
      "dried amla",
      "nellikai vathal"
    ],
    "brands": [
      "Local Ayurvedic",
      "Baidyanath"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "spice"
  },
  {
    "id": "thandrikkai_whole_bibhitaki",
    "name": "Thandrikkai Whole Bibhitaki",
    "tamilName": "தான்றிக்காய் (முழுசு)",
    "category": "Spices & Seasonings",
    "subCategory": "Ayurvedic Powders",
    "productType": "Herbal Fruit",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "thandrikkai",
      "bibhitaki whole",
      "baheda"
    ],
    "aliases": [
      "thandrikkai",
      "bibhitaki whole",
      "baheda"
    ],
    "brands": [
      "Local Ayurvedic"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "spice"
  },
  {
    "id": "nilavembu_kudineer_churna_decoction_powder",
    "name": "Nilavembu Kudineer Churna Decoction Powder",
    "tamilName": "நிலவேம்பு குடிநீர் சூரணம்",
    "category": "Spices & Seasonings",
    "subCategory": "Ayurvedic Powders",
    "productType": "Herbal Powder",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 100.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "nilavembu kudineer",
      "nilavembu powder"
    ],
    "aliases": [
      "nilavembu kudineer",
      "nilavembu powder"
    ],
    "brands": [
      "SKM Siddha",
      "IMPCOPS",
      "Local Ayurvedic"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "kabasura_kudineer_churna_immunity_powder",
    "name": "Kabasura Kudineer Churna Immunity Powder",
    "tamilName": "கபசுர குடிநீர் சூரணம்",
    "category": "Spices & Seasonings",
    "subCategory": "Ayurvedic Powders",
    "productType": "Herbal Powder",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 100.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "kabasura kudineer",
      "kabasuram powder"
    ],
    "aliases": [
      "kabasura kudineer",
      "kabasuram powder"
    ],
    "brands": [
      "IMPCOPS",
      "SKM Siddha"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "adathodai_malabar_nut_dried_leaves",
    "name": "Adathodai Malabar Nut Dried Leaves",
    "tamilName": "ஆடாதோடை இலை (உலர்ந்தது)",
    "category": "Spices & Seasonings",
    "subCategory": "Ayurvedic Powders",
    "productType": "Dried Leaves",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 50.0,
    "customQuantities": [
      50.0
    ],
    "commonNames": [
      "adathodai",
      "vasaka leaves"
    ],
    "aliases": [
      "adathodai",
      "vasaka leaves"
    ],
    "brands": [
      "Local Ayurvedic"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "spice"
  },
  {
    "id": "karunjeeragam_black_caraway_kalonji_seeds",
    "name": "Karunjeeragam Black Caraway Kalonji Seeds",
    "tamilName": "கருஞ்சீரகம்",
    "category": "Spices & Seasonings",
    "subCategory": "Whole Spices",
    "productType": "Oilseed",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      50.0,
      100.0,
      250.0
    ],
    "commonNames": [
      "karunjeeragam",
      "kalonji",
      "black seed"
    ],
    "aliases": [
      "karunjeeragam",
      "kalonji",
      "black seed"
    ],
    "brands": [
      "Tata Sampann",
      "BB Royal",
      "Local Ayurvedic"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "spice"
  },
  {
    "id": "poolankizhangu_white_turmeric_rhizome",
    "name": "Poolankizhangu White Turmeric Rhizome",
    "tamilName": "பூலாங்கிழங்கு (வெள்ளை மஞ்சள்)",
    "category": "Personal Care & Hygiene",
    "subCategory": "Bath & Body Care",
    "productType": "Herbal Root",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Bathroom Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "poolankizhangu",
      "white turmeric"
    ],
    "aliases": [
      "poolankizhangu",
      "white turmeric"
    ],
    "brands": [
      "Local Ayurvedic",
      "Gopuram"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "vasambu_sweet_flag_root_acorus_calamus",
    "name": "Vasambu Sweet Flag Root Acorus Calamus",
    "tamilName": "வசம்பு (பேராசான்)",
    "category": "Personal Care & Hygiene",
    "subCategory": "Baby Care",
    "productType": "Herbal Root",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 2.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "vasambu",
      "sweet flag root",
      "ghoravach"
    ],
    "aliases": [
      "vasambu",
      "sweet flag root",
      "ghoravach"
    ],
    "brands": [
      "Local Ayurvedic",
      "Temple Stores"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "aavarampoo_dried_tanner_cassia_flowers",
    "name": "Aavarampoo Dried Tanner Cassia Flowers",
    "tamilName": "ஆவாரம்பூ (உலர்ந்த பூக்கள்)",
    "category": "Beverages",
    "subCategory": "Herbal Drinks",
    "productType": "Dried Flowers",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "aavarampoo",
      "tanner cassia flowers"
    ],
    "aliases": [
      "aavarampoo",
      "tanner cassia flowers"
    ],
    "brands": [
      "Local Ayurvedic",
      "Gramiyum"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "sembaruthi_poo_dried_hibiscus_flower_petals",
    "name": "Sembaruthi Poo Dried Hibiscus Flower Petals",
    "tamilName": "செம்பருத்திப் பூ (உலர்ந்த இதழ்கள்)",
    "category": "Beverages",
    "subCategory": "Herbal Drinks",
    "productType": "Dried Flowers",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "sembaruthi poo",
      "hibiscus petals dry"
    ],
    "aliases": [
      "sembaruthi poo",
      "hibiscus petals dry"
    ],
    "brands": [
      "Gramiyum",
      "Local Ayurvedic"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "dried_country_rose_petals_panneer_roja",
    "name": "Dried Country Rose Petals Panneer Roja",
    "tamilName": "பன்னீர் ரோஜா உலர்ந்த இதழ்கள்",
    "category": "Food & Grocery",
    "subCategory": "Baking Ingredients",
    "productType": "Dried Petals",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 50.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "dried rose petals",
      "panneer roja idhazh"
    ],
    "aliases": [
      "dried rose petals",
      "panneer roja idhazh"
    ],
    "brands": [
      "Local Ayurvedic",
      "Urban Platter"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "spice"
  },
  {
    "id": "chyawanprash_ayurvedic_immunity_paste_1kg",
    "name": "Chyawanprash Ayurvedic Immunity Paste 1kg",
    "tamilName": "சியவன்பிராஷ் லேகியம் (1 கிலோ)",
    "category": "Personal Care & Hygiene",
    "subCategory": "Health & Wellness",
    "productType": "Herbal Jam",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "chyawanprash",
      "chyawanprash 1kg"
    ],
    "aliases": [
      "chyawanprash",
      "chyawanprash 1kg"
    ],
    "brands": [
      "Dabur Chyawanprash",
      "Baidyanath",
      "Patanjali"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "plain_unsweetened_greek_yogurt_cup_100g",
    "name": "Plain Unsweetened Greek Yogurt Cup 100g",
    "tamilName": "கிரேக்க யோகர்ட் (இனிப்பில்லாதது)",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Yogurt",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      400.0
    ],
    "commonNames": [
      "greek yogurt plain",
      "unsweetened yogurt"
    ],
    "aliases": [
      "greek yogurt plain",
      "unsweetened yogurt"
    ],
    "brands": [
      "Epigamia Greek Yogurt",
      "Milky Mist"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "strawberry_flavored_greek_yogurt_cup",
    "name": "Strawberry Flavored Greek Yogurt Cup",
    "tamilName": "ஸ்ட்ராபெரி கிரேக்க யோகர்ட்",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Yogurt",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 90.0,
    "customQuantities": [
      90.0
    ],
    "commonNames": [
      "strawberry yogurt",
      "greek yogurt fruit"
    ],
    "aliases": [
      "strawberry yogurt",
      "greek yogurt fruit"
    ],
    "brands": [
      "Epigamia",
      "Milky Mist"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "blueberry_flavored_greek_yogurt_cup",
    "name": "Blueberry Flavored Greek Yogurt Cup",
    "tamilName": "புளூபெரி கிரேக்க யோகர்ட்",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Yogurt",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 90.0,
    "customQuantities": [
      90.0
    ],
    "commonNames": [
      "blueberry greek yogurt"
    ],
    "aliases": [
      "blueberry greek yogurt"
    ],
    "brands": [
      "Epigamia",
      "Milky Mist"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "traditional_terracotta_cup_mishti_doi_sweet_curd",
    "name": "Traditional Terracotta Cup Mishti Doi Sweet Curd",
    "tamilName": "மிஷ்டி தோய் (பெங்காலி இனிப்பு தயிர்)",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Sweet Curd",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "mishti doi",
      "sweet curd"
    ],
    "aliases": [
      "mishti doi",
      "sweet curd"
    ],
    "brands": [
      "Mother Dairy Mishti Doi",
      "Amul",
      "Milky Mist"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "kesar_elaichi_shrikhand_tub_200g",
    "name": "Kesar Elaichi Shrikhand Tub 200g",
    "tamilName": "கேசர் ஏலக்காய் ஸ்ரீகண்ட்",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Shrikhand",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "kesar elaichi shrikhand",
      "shrikhand"
    ],
    "aliases": [
      "kesar elaichi shrikhand",
      "shrikhand"
    ],
    "brands": [
      "Amul Shrikhand",
      "Mother Dairy"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "amrakhand_mango_shrikhand_tub",
    "name": "Amrakhand Mango Shrikhand Tub",
    "tamilName": "ஆம்ரகண்ட் (மாம்பழ ஸ்ரீகண்ட்)",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Shrikhand",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "amrakhand",
      "mango shrikhand"
    ],
    "aliases": [
      "amrakhand",
      "mango shrikhand"
    ],
    "brands": [
      "Amul Amrakhand",
      "Mother Dairy"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "organic_firm_soya_tofu_block_200g",
    "name": "Organic Firm Soya Tofu Block 200g",
    "tamilName": "சோயா டோஃபு (பன்னீர் மாற்று)",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Tofu",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "soya tofu",
      "tofu block",
      "firm tofu"
    ],
    "aliases": [
      "soya tofu",
      "tofu block",
      "firm tofu"
    ],
    "brands": [
      "Health on Plants",
      "Mori-Nu",
      "Urban Platter"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "gouda_cheese_slices_pack_10s",
    "name": "Gouda Cheese Slices Pack 10s",
    "tamilName": "கௌடா சீஸ் ஸ்லைஸ்",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Cheese",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 150.0,
    "customQuantities": [
      150.0
    ],
    "commonNames": [
      "gouda cheese slices"
    ],
    "aliases": [
      "gouda cheese slices"
    ],
    "brands": [
      "Milky Mist Gouda",
      "Amul"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "heavy_whipping_cream_35_milk_fat_250ml",
    "name": "Heavy Whipping Cream 35% Milk Fat 250ml",
    "tamilName": "விப்பிங் கிரீம் (35% கொழுப்பு)",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Cream",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      1000.0
    ],
    "commonNames": [
      "heavy whipping cream",
      "baking cream"
    ],
    "aliases": [
      "heavy whipping cream",
      "baking cream"
    ],
    "brands": [
      "Amul Whipping Cream",
      "Rich's"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "unsweetened_almond_milk_carton_1l",
    "name": "Unsweetened Almond Milk Carton 1L",
    "tamilName": "பாதாம் பால் (சர்க்கரை இல்லாதது, 1 லிட்டர்)",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Alternatives",
    "productType": "Plant Milk",
    "defaultUnit": "l",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "almond milk unsweetened",
      "vegan almond milk"
    ],
    "aliases": [
      "almond milk unsweetened",
      "vegan almond milk"
    ],
    "brands": [
      "Raw Pressery",
      "Epigamia Almond Milk",
      "Urban Platter"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "unsweetened_soya_milk_carton_1l",
    "name": "Unsweetened Soya Milk Carton 1L",
    "tamilName": "சோயா பால் (1 லிட்டர்)",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Alternatives",
    "productType": "Plant Milk",
    "defaultUnit": "l",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "sofit soy milk",
      "soya milk"
    ],
    "aliases": [
      "sofit soy milk",
      "soya milk"
    ],
    "brands": [
      "Sofit Soya Milk",
      "Urban Platter"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "barista_oat_milk_carton_1l",
    "name": "Barista Oat Milk Carton 1L",
    "tamilName": "ஓட்ஸ் பால் (1 லிட்டர்)",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Alternatives",
    "productType": "Plant Milk",
    "defaultUnit": "l",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "oat milk carton",
      "barista oat milk"
    ],
    "aliases": [
      "oat milk carton",
      "barista oat milk"
    ],
    "brands": [
      "Oatly",
      "Alt Co",
      "Urban Platter"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "culinary_coconut_milk_carton_200ml",
    "name": "Culinary Coconut Milk Carton 200ml",
    "tamilName": "தேங்காய் பால் டெட்ரா பேக் (200 மி.லி)",
    "category": "Food & Grocery",
    "subCategory": "Cooking & Baking",
    "productType": "Coconut Milk",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      1000.0
    ],
    "commonNames": [
      "coconut milk tetra pack",
      "thengai paal"
    ],
    "aliases": [
      "coconut milk tetra pack",
      "thengai paal"
    ],
    "brands": [
      "Dabur Hommade Coconut Milk",
      "Chaokoh"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "thick_coconut_cooking_cream_carton_200ml",
    "name": "Thick Coconut Cooking Cream Carton 200ml",
    "tamilName": "கெட்டி தேங்காய் கிரீம் (200 மி.லி)",
    "category": "Food & Grocery",
    "subCategory": "Cooking & Baking",
    "productType": "Coconut Cream",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "coconut cream",
      "thick thengai paal"
    ],
    "aliases": [
      "coconut cream",
      "thick thengai paal"
    ],
    "brands": [
      "Dabur Hommade",
      "Kara"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "plain_puffed_rice_pori_muri",
    "name": "Plain Puffed Rice Pori Muri",
    "tamilName": "வெள்ளை பொரி",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Puffed Rice",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "pori",
      "puffed rice plain",
      "muri",
      "mamra"
    ],
    "aliases": [
      "pori",
      "puffed rice plain",
      "muri",
      "mamra"
    ],
    "brands": [
      "Local Mills",
      "Udhayam"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "aval_pori_beaten_puffed_rice",
    "name": "Aval Pori Beaten Puffed Rice",
    "tamilName": "அவல் பொரி",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Puffed Rice",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "aval pori",
      "puffed aval"
    ],
    "aliases": [
      "aval pori",
      "puffed aval"
    ],
    "brands": [
      "Local Mills",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "spicy_garlic_masala_pori_fry",
    "name": "Spicy Garlic Masala Pori Fry",
    "tamilName": "மசாலா பூண்டு பொரி",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Snacks",
    "productType": "Namkeen",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "masala pori",
      "garlic spiced puffed rice"
    ],
    "aliases": [
      "masala pori",
      "garlic spiced puffed rice"
    ],
    "brands": [
      "Grand Sweets",
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "andhra_crunchy_murukku_jantikalu",
    "name": "Andhra Crunchy Murukku Jantikalu",
    "tamilName": "ஆந்திரா ஜந்திகலு முறுக்கு",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Snacks",
    "productType": "Murukku",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "jantikalu",
      "andhra murukku"
    ],
    "aliases": [
      "jantikalu",
      "andhra murukku"
    ],
    "brands": [
      "Priya Jantikalu",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "chettinad_handmade_kai_murukku_5s",
    "name": "Chettinad Handmade Kai Murukku 5s",
    "tamilName": "செட்டிநாடு கை முறுக்கு (5 எண்ணிக்கை)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Snacks",
    "productType": "Murukku",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 5.0,
    "customQuantities": [
      5.0,
      10.0
    ],
    "commonNames": [
      "chettinad kai murukku"
    ],
    "aliases": [
      "chettinad kai murukku"
    ],
    "brands": [
      "Chettinad Artisans",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "ring_murukku_chegodilu_rings",
    "name": "Ring Murukku Chegodilu Rings",
    "tamilName": "ரிங் முறுக்கு (செகோடிலு)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Snacks",
    "productType": "Murukku",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "ring murukku",
      "chegodilu"
    ],
    "aliases": [
      "ring murukku",
      "chegodilu"
    ],
    "brands": [
      "Priya",
      "Grand Sweets",
      "A2B"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "crunchy_kodubale_ring_snack",
    "name": "Crunchy Kodubale Ring Snack",
    "tamilName": "கொடுபலே",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Snacks",
    "productType": "Namkeen",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "kodubale",
      "karnataka ring snack"
    ],
    "aliases": [
      "kodubale",
      "karnataka ring snack"
    ],
    "brands": [
      "MTR Kodubale",
      "Grand Sweets",
      "A2B"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "chettinad_spicy_thattai",
    "name": "Chettinad Spicy Thattai",
    "tamilName": "செட்டிநாடு கார தட்டை",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Snacks",
    "productType": "Thattai",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      400.0
    ],
    "commonNames": [
      "chettinad thattai",
      "kara thattai"
    ],
    "aliases": [
      "chettinad thattai",
      "kara thattai"
    ],
    "brands": [
      "Chettinad Artisans",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "garlic_poondu_thattai",
    "name": "Garlic Poondu Thattai",
    "tamilName": "பூண்டு தட்டை",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Snacks",
    "productType": "Thattai",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "poondu thattai",
      "garlic thattai"
    ],
    "aliases": [
      "poondu thattai",
      "garlic thattai"
    ],
    "brands": [
      "Grand Sweets",
      "A2B"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "andhra_spicy_chekkalu_rice_crackers",
    "name": "Andhra Spicy Chekkalu Rice Crackers",
    "tamilName": "ஆந்திரா செக்கலு (தட்டை)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Snacks",
    "productType": "Crackers",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0
    ],
    "commonNames": [
      "chekkalu",
      "andhra rice crackers"
    ],
    "aliases": [
      "chekkalu",
      "andhra rice crackers"
    ],
    "brands": [
      "Priya Chekkalu",
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "karnataka_spicy_nippattu",
    "name": "Karnataka Spicy Nippattu",
    "tamilName": "கர்நாடகா நிப்பட்டு",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Snacks",
    "productType": "Crackers",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "nippattu",
      "spicy nippat"
    ],
    "aliases": [
      "nippattu",
      "spicy nippat"
    ],
    "brands": [
      "MTR Nippattu",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "sweet_jaggery_banana_chips_sharkara_upperi",
    "name": "Sweet Jaggery Banana Chips Sharkara Upperi",
    "tamilName": "சர்க்கரை வரட்டி (வெல்ல நேந்திரங்காய் சிப்ஸ்)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Banana Chips",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "sharkara upperi",
      "jaggery banana chips",
      "sarkara varatti"
    ],
    "aliases": [
      "sharkara upperi",
      "jaggery banana chips",
      "sarkara varatti"
    ],
    "brands": [
      "A1 Chips",
      "Double Horse",
      "Kerala Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "crispy_bitter_gourd_chips_pavakkai_chips",
    "name": "Crispy Bitter Gourd Chips Pavakkai Chips",
    "tamilName": "பாகற்காய் சிப்ஸ்",
    "category": "Snacks & Namkeen",
    "subCategory": "Chips & Crisps",
    "productType": "Vegetable Chips",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 150.0,
    "customQuantities": [
      150.0
    ],
    "commonNames": [
      "pavakkai chips",
      "karela chips"
    ],
    "aliases": [
      "pavakkai chips",
      "karela chips"
    ],
    "brands": [
      "Hot Chips",
      "A1 Chips",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "crispy_taro_root_chips_arbi_chips",
    "name": "Crispy Taro Root Chips Arbi Chips",
    "tamilName": "சேப்பங்கிழங்கு சிப்ஸ்",
    "category": "Snacks & Namkeen",
    "subCategory": "Chips & Crisps",
    "productType": "Vegetable Chips",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 150.0,
    "customQuantities": [
      150.0
    ],
    "commonNames": [
      "arbi chips",
      "cheppankizhangu chips"
    ],
    "aliases": [
      "arbi chips",
      "cheppankizhangu chips"
    ],
    "brands": [
      "Hot Chips",
      "A1 Chips"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "crispy_elephant_yam_chips_senai_chips",
    "name": "Crispy Elephant Yam Chips Senai Chips",
    "tamilName": "சேனைக்கிழங்கு சிப்ஸ்",
    "category": "Snacks & Namkeen",
    "subCategory": "Chips & Crisps",
    "productType": "Vegetable Chips",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 150.0,
    "customQuantities": [
      150.0
    ],
    "commonNames": [
      "senai chips",
      "yam chips crispy"
    ],
    "aliases": [
      "senai chips",
      "yam chips crispy"
    ],
    "brands": [
      "Hot Chips",
      "A1 Chips"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "bhuna_chana_roasted_gram_with_skin",
    "name": "Bhuna Chana Roasted Gram with Skin",
    "tamilName": "வறுத்த கருப்பு கொண்டைக்கடலை (தோலுடன்)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Snacks",
    "productType": "Healthy Snack",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "bhuna chana",
      "roasted chana with skin"
    ],
    "aliases": [
      "bhuna chana",
      "roasted chana with skin"
    ],
    "brands": [
      "Tata Sampann",
      "Haldiram's"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "fried_salted_moong_dal_namkeen",
    "name": "Fried Salted Moong Dal Namkeen",
    "tamilName": "வறுத்த உப்பு பாசிப்பருப்பு",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Snacks",
    "productType": "Namkeen",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      400.0
    ],
    "commonNames": [
      "salted moong dal",
      "fried moong dal"
    ],
    "aliases": [
      "salted moong dal",
      "fried moong dal"
    ],
    "brands": [
      "Haldiram's Moong Dal",
      "Bikano"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "crispy_methi_mathri_flaky_crackers",
    "name": "Crispy Methi Mathri Flaky Crackers",
    "tamilName": "வெந்தயக்கீரை மத்ரி (கசூரி மேத்தி)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Snacks",
    "productType": "Namkeen",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      200.0,
      250.0
    ],
    "commonNames": [
      "methi mathri",
      "flaky mathri"
    ],
    "aliases": [
      "methi mathri",
      "flaky mathri"
    ],
    "brands": [
      "Haldiram's Mathri",
      "Bikaji"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "pani_puri_ready_to_fry_pellets_box_50s",
    "name": "Pani Puri Ready-to-Fry Pellets Box 50s",
    "tamilName": "பானி பூரி பொரிக்கும் அப்பளம் (50 எண்ணிக்கை)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Snacks",
    "productType": "Pani Puri",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 50.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "pani puri pellets",
      "fry ready golgappa"
    ],
    "aliases": [
      "pani puri pellets",
      "fry ready golgappa"
    ],
    "brands": [
      "Bikano",
      "Ching's",
      "Urban Platter"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "chaat_papdi_crispy_round_discs_box_200g",
    "name": "Chaat Papdi Crispy Round Discs Box 200g",
    "tamilName": "சாட் பப்டி தட்டுகள்",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Snacks",
    "productType": "Chaat",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "chaat papdi",
      "sev puri papdi"
    ],
    "aliases": [
      "chaat papdi",
      "sev puri papdi"
    ],
    "brands": [
      "Haldiram's Papdi",
      "Bikano"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "durum_wheat_penne_rigate_pasta_500g",
    "name": "Durum Wheat Penne Rigate Pasta 500g",
    "tamilName": "பென்னே பாஸ்தா (500 கிராம்)",
    "category": "Food & Grocery",
    "subCategory": "Pasta & Noodles",
    "productType": "Pasta",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "penne pasta",
      "durum wheat penne"
    ],
    "aliases": [
      "penne pasta",
      "durum wheat penne"
    ],
    "brands": [
      "Barilla",
      "Borges",
      "Disano"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "durum_wheat_fusilli_spiral_pasta_500g",
    "name": "Durum Wheat Fusilli Spiral Pasta 500g",
    "tamilName": "ஃபுசில்லி சுருள் பாஸ்தா (500 கிராம்)",
    "category": "Food & Grocery",
    "subCategory": "Pasta & Noodles",
    "productType": "Pasta",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "fusilli pasta",
      "spiral pasta"
    ],
    "aliases": [
      "fusilli pasta",
      "spiral pasta"
    ],
    "brands": [
      "Barilla",
      "Borges",
      "Disano"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "durum_wheat_elbow_macaroni_pasta_500g",
    "name": "Durum Wheat Elbow Macaroni Pasta 500g",
    "tamilName": "மேக்ரோனி பாஸ்தா (500 கிராம்)",
    "category": "Food & Grocery",
    "subCategory": "Pasta & Noodles",
    "productType": "Pasta",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "macaroni",
      "elbow pasta"
    ],
    "aliases": [
      "macaroni",
      "elbow pasta"
    ],
    "brands": [
      "Bambino Macaroni",
      "Disano",
      "Weikfield"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "spaghetti_long_durum_wheat_pasta_500g",
    "name": "Spaghetti Long Durum Wheat Pasta 500g",
    "tamilName": "ஸ்பாகெட்டி நீள பாஸ்தா (500 கிராம்)",
    "category": "Food & Grocery",
    "subCategory": "Pasta & Noodles",
    "productType": "Pasta",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "spaghetti",
      "long pasta"
    ],
    "aliases": [
      "spaghetti",
      "long pasta"
    ],
    "brands": [
      "Barilla Spaghetti",
      "Borges",
      "Disano"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "hakka_veg_noodles_flat_cake_300g",
    "name": "Hakka Veg Noodles Flat Cake 300g",
    "tamilName": "ஹக்கா நூடுல்ஸ் கேக் (300 கிராம்)",
    "category": "Food & Grocery",
    "subCategory": "Pasta & Noodles",
    "productType": "Noodles",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0
    ],
    "commonNames": [
      "hakka noodles",
      "veg noodles cake"
    ],
    "aliases": [
      "hakka noodles",
      "veg noodles cake"
    ],
    "brands": [
      "Ching's Secret Hakka Noodles",
      "Smith & Jones"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "classic_eggless_mayonnaise_squeeze_bottle_250g",
    "name": "Classic Eggless Mayonnaise Squeeze Bottle 250g",
    "tamilName": "முட்டையில்லா மயோனைஸ்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Mayonnaise",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      800.0
    ],
    "commonNames": [
      "eggless mayonnaise",
      "veeba mayo"
    ],
    "aliases": [
      "eggless mayonnaise",
      "veeba mayo"
    ],
    "brands": [
      "Veeba Eggless Mayo",
      "FunFoods Dr. Oetker"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "mint_herb_eggless_mayonnaise_250g",
    "name": "Mint Herb Eggless Mayonnaise 250g",
    "tamilName": "புதினா மயோனைஸ்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Mayonnaise",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0
    ],
    "commonNames": [
      "mint mayo",
      "hari chutney mayonnaise"
    ],
    "aliases": [
      "mint mayo",
      "hari chutney mayonnaise"
    ],
    "brands": [
      "Veeba Mint Mayo",
      "FunFoods"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "tandoori_spicy_eggless_mayonnaise_250g",
    "name": "Tandoori Spicy Eggless Mayonnaise 250g",
    "tamilName": "தந்தூரி மயோனைஸ்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Mayonnaise",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0
    ],
    "commonNames": [
      "tandoori mayo"
    ],
    "aliases": [
      "tandoori mayo"
    ],
    "brands": [
      "Veeba Tandoori Mayo",
      "FunFoods"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "pizza_pasta_herb_tomato_sauce_jar_350g",
    "name": "Pizza & Pasta Herb Tomato Sauce Jar 350g",
    "tamilName": "பிட்சா & பாஸ்தா சாஸ் ஜாடி",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Cooking Sauce",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 350.0,
    "customQuantities": [
      350.0
    ],
    "commonNames": [
      "pizza pasta sauce",
      "red pasta sauce"
    ],
    "aliases": [
      "pizza pasta sauce",
      "red pasta sauce"
    ],
    "brands": [
      "Veeba Pizza Pasta Sauce",
      "Dr. Oetker",
      "Barilla"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "traditional_bengali_kasundi_mustard_sauce_300g",
    "name": "Traditional Bengali Kasundi Mustard Sauce 300g",
    "tamilName": "காசுந்தி கடுகு சாஸ்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Mustard Sauce",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0
    ],
    "commonNames": [
      "kasundi mustard",
      "bengali mustard sauce"
    ],
    "aliases": [
      "kasundi mustard",
      "bengali mustard sauce"
    ],
    "brands": [
      "Mukharochak Kasundi",
      "Druk",
      "Urban Platter"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "synthetic_white_vinegar_for_cooking_500ml",
    "name": "Synthetic White Vinegar for Cooking 500ml",
    "tamilName": "வெள்ளை சமையல் வினிகர்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Vinegar",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "white vinegar",
      "synthetic vinegar"
    ],
    "aliases": [
      "white vinegar",
      "synthetic vinegar"
    ],
    "brands": [
      "Ching's Secret Vinegar",
      "Tops",
      "Disano"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "raw_organic_apple_cider_vinegar_with_mother_500ml",
    "name": "Raw Organic Apple Cider Vinegar with Mother 500ml",
    "tamilName": "ஆப்பிள் சைடர் வினிகர்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Vinegar",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "apple cider vinegar with mother",
      "acv"
    ],
    "aliases": [
      "apple cider vinegar with mother",
      "acv"
    ],
    "brands": [
      "Bragg Apple Cider",
      "Wow",
      "Kapiva"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "dindigul_thalappakatti_biryani_masala",
    "name": "Dindigul Thalappakatti Biryani Masala",
    "tamilName": "திண்டுக்கல் தலப்பாகட்டி பிரியாணி மசாலா",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Biryani Masala",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "dindigul biryani masala",
      "seeraga samba biryani masala"
    ],
    "aliases": [
      "dindigul biryani masala",
      "seeraga samba biryani masala"
    ],
    "brands": [
      "Thalappakatti",
      "Aachi"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "ambur_star_biryani_masala_powder",
    "name": "Ambur Star Biryani Masala Powder",
    "tamilName": "ஆம்பூர் ஸ்டார் பிரியாணி மசாலா",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Biryani Masala",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "ambur biryani masala"
    ],
    "aliases": [
      "ambur biryani masala"
    ],
    "brands": [
      "Ambur Star",
      "Aachi"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "hyderabadi_dum_biryani_pot_masala",
    "name": "Hyderabadi Dum Biryani Pot Masala",
    "tamilName": "ஹைதராபாதி தம் பிரியாணி மசாலா",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Biryani Masala",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "hyderabadi biryani masala",
      "dum biryani masala"
    ],
    "aliases": [
      "hyderabadi biryani masala",
      "dum biryani masala"
    ],
    "brands": [
      "Shan Hyderabadi Biryani",
      "Everest",
      "MDH"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "kerala_malabar_garam_masala_whole_ground",
    "name": "Kerala Malabar Garam Masala Whole Ground",
    "tamilName": "கேரளா மலபார் கரம் மசாலா",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "malabar garam masala",
      "kerala garam masala"
    ],
    "aliases": [
      "malabar garam masala",
      "kerala garam masala"
    ],
    "brands": [
      "Eastern Malabar Masala",
      "Kitchen Treasures"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "madurai_mutton_chukka_fry_masala",
    "name": "Madurai Mutton Chukka Fry Masala",
    "tamilName": "மதுரை மட்டன் சுக்கா மசாலா",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Meat Masala",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "mutton chukka masala",
      "madurai chukka masala"
    ],
    "aliases": [
      "mutton chukka masala",
      "madurai chukka masala"
    ],
    "brands": [
      "Aachi",
      "Sakthi"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "kongunadu_kari_masala_coimbatore_style",
    "name": "Kongunadu Kari Masala Coimbatore Style",
    "tamilName": "கொங்குநாடு கறி மசாலா",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "kongunadu masala",
      "coimbatore kari masala"
    ],
    "aliases": [
      "kongunadu masala",
      "coimbatore kari masala"
    ],
    "brands": [
      "Aachi",
      "Local Spices"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "mangalorean_ghee_roast_masala_paste",
    "name": "Mangalorean Ghee Roast Masala Paste",
    "tamilName": "மங்களூர் நெய் ரோஸ்ட் மசாலா",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Cooking Paste",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "ghee roast masala",
      "kori ghee roast"
    ],
    "aliases": [
      "ghee roast masala",
      "kori ghee roast"
    ],
    "brands": [
      "Chef Pillai",
      "Eastern"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "chettinad_fish_fry_masala_podi",
    "name": "Chettinad Fish Fry Masala Podi",
    "tamilName": "செட்டிநாடு மீன் வறுவல் மசாலா",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Fish Masala",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "fish fry masala",
      "meen varuval podi"
    ],
    "aliases": [
      "fish fry masala",
      "meen varuval podi"
    ],
    "brands": [
      "Aachi Fish Fry",
      "Sakthi",
      "Eastern"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "prawns_pepper_fry_masala_podi",
    "name": "Prawns Pepper Fry Masala Podi",
    "tamilName": "இறால் மிளகு வறுவல் மசாலா",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Seafood Masala",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "prawns masala",
      "eraal milagu masala"
    ],
    "aliases": [
      "prawns masala",
      "eraal milagu masala"
    ],
    "brands": [
      "Aachi",
      "Eastern"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "tangy_jaljeera_cumin_drink_mix_powder",
    "name": "Tangy Jaljeera Cumin Drink Mix Powder",
    "tamilName": "ஜல்ஜீரா பவுடர்",
    "category": "Beverages",
    "subCategory": "Instant Drinks",
    "productType": "Drink Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "jaljeera powder",
      "cumin drink mix"
    ],
    "aliases": [
      "jaljeera powder",
      "cumin drink mix"
    ],
    "brands": [
      "Catch Jaljeera",
      "MDH",
      "Everest"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "spicy_chaas_buttermilk_seasoning_sprinkler",
    "name": "Spicy Chaas Buttermilk Seasoning Sprinkler",
    "tamilName": "மோர் மசாலா தூவல்",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Seasoning",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "chaas masala",
      "neer mor podi"
    ],
    "aliases": [
      "chaas masala",
      "neer mor podi"
    ],
    "brands": [
      "Catch Chaas Masala",
      "MDH"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "peri_peri_chilli_garlic_sprinkler_100g",
    "name": "Peri Peri Chilli Garlic Sprinkler 100g",
    "tamilName": "பெரி பெரி மசாலா ஸ்பிரிங்க்ளர்",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Seasoning",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "peri peri sprinkler",
      "peri peri spice mix"
    ],
    "aliases": [
      "peri peri sprinkler",
      "peri peri spice mix"
    ],
    "brands": [
      "Keya Peri Peri",
      "Snapin",
      "Urban Platter"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "brasso_metal_polish_liquid_for_brass_100ml",
    "name": "Brasso Metal Polish Liquid for Brass 100ml",
    "tamilName": "பிராஸோ பித்தளை பாலிஷ் திரவம்",
    "category": "Household & Cleaning",
    "subCategory": "Home Utilities",
    "productType": "Metal Polish",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Utility Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "brasso",
      "brass polish liquid"
    ],
    "aliases": [
      "brasso",
      "brass polish liquid"
    ],
    "brands": [
      "Brasso Reckitt"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "hardware"
  },
  {
    "id": "silvo_silver_polish_liquid_100ml",
    "name": "Silvo Silver Polish Liquid 100ml",
    "tamilName": "சில்வோ வெள்ளி பாலிஷ் திரவம்",
    "category": "Household & Cleaning",
    "subCategory": "Home Utilities",
    "productType": "Metal Polish",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Utility Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "silvo",
      "silver polish liquid"
    ],
    "aliases": [
      "silvo",
      "silver polish liquid"
    ],
    "brands": [
      "Silvo Reckitt"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "hardware"
  },
  {
    "id": "pure_copper_water_bottle_hammered_1l",
    "name": "Pure Copper Water Bottle Hammered 1L",
    "tamilName": "தூய செம்பு தண்ணீர் பாட்டில் (1 லிட்டர்)",
    "category": "Home Utility & Hardware",
    "subCategory": "Kitchenware",
    "productType": "Copperware",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "copper water bottle",
      "sembu bottle"
    ],
    "aliases": [
      "copper water bottle",
      "sembu bottle"
    ],
    "brands": [
      "Prestige Copper",
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "hardware"
  },
  {
    "id": "natural_clay_water_pot_matka_with_tap",
    "name": "Natural Clay Water Pot Matka with Tap",
    "tamilName": "மண் பானை (குழாயுடன்)",
    "category": "Home Utility & Hardware",
    "subCategory": "Kitchenware",
    "productType": "Earthenware",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "clay water pot",
      "matka with tap",
      "manpaanai"
    ],
    "aliases": [
      "clay water pot",
      "matka with tap",
      "manpaanai"
    ],
    "brands": [
      "Local Potters"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "hardware"
  },
  {
    "id": "electrical_ceramic_camphor_diffuser_kapurdan",
    "name": "Electrical Ceramic Camphor Diffuser Kapurdan",
    "tamilName": "எலக்ட்ரிக் கற்பூர டிஃப்பியூசர்",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Camphor & Agarbatti",
    "productType": "Diffuser",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "electric camphor diffuser",
      "kapurdan"
    ],
    "aliases": [
      "electric camphor diffuser",
      "kapurdan"
    ],
    "brands": [
      "Pure Kapoor",
      "Local Electricals"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "rechargeable_electric_mosquito_swatter_racket",
    "name": "Rechargeable Electric Mosquito Swatter Racket",
    "tamilName": "ரீசார்ஜபிள் கொசு பேட்",
    "category": "Household & Cleaning",
    "subCategory": "Surface Cleaners & Pest Control",
    "productType": "Electrical Pest Control",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Living Room",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "mosquito racket",
      "electric mosquito bat"
    ],
    "aliases": [
      "mosquito racket",
      "electric mosquito bat"
    ],
    "brands": [
      "Hit Mosquito Racket",
      "Hunter"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "hardware"
  },
  {
    "id": "anti_tick_flea_herbal_neem_dog_shampoo_200ml",
    "name": "Anti-Tick & Flea Herbal Neem Dog Shampoo 200ml",
    "tamilName": "நாய் பேன் ஒண்ணி ஷாம்பு",
    "category": "Pet Care",
    "subCategory": "Pet Hygiene",
    "productType": "Pet Shampoo",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Pet Care Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "dog tick shampoo",
      "erina ep"
    ],
    "aliases": [
      "dog tick shampoo",
      "erina ep"
    ],
    "brands": [
      "Himalaya Erina-EP",
      "Bolfo",
      "Captain Zack"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pets"
  },
  {
    "id": "pet_grooming_slicker_brush_for_dogs_cats",
    "name": "Pet Grooming Slicker Brush for Dogs & Cats",
    "tamilName": "செல்லப்பிராணி முடி சீவும் பிரஷ்",
    "category": "Pet Care",
    "subCategory": "Pet Grooming",
    "productType": "Pet Brush",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pet Care Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "slicker brush",
      "dog grooming brush"
    ],
    "aliases": [
      "slicker brush",
      "dog grooming brush"
    ],
    "brands": [
      "Meat Up",
      "Drools"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pets"
  },
  {
    "id": "strong_nylon_dog_walking_leash_1_5m",
    "name": "Strong Nylon Dog Walking Leash 1.5m",
    "tamilName": "நாய் வாக்கிங் லீஷ் கயிறு",
    "category": "Pet Care",
    "subCategory": "Pet Accessories",
    "productType": "Pet Leash",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pet Care Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "dog leash",
      "walking rope dog"
    ],
    "aliases": [
      "dog leash",
      "walking rope dog"
    ],
    "brands": [
      "Pets Empire",
      "Trixie"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pets"
  },
  {
    "id": "crushed_peanut_chikki_jaggery_bar",
    "name": "Crushed Peanut Chikki Jaggery Bar",
    "tamilName": "கடலை மிட்டாய் பார் (வெல்லம்)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Chikki",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0,
      400.0
    ],
    "commonNames": [
      "peanut chikki bar",
      "crushed kadalai mittai"
    ],
    "aliases": [
      "peanut chikki bar",
      "crushed kadalai mittai"
    ],
    "brands": [
      "Kovilpatti Artisans",
      "Grand Sweets",
      "Haldiram's"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "dry_fruit_mixed_chikki_honey_jaggery",
    "name": "Dry Fruit Mixed Chikki Honey Jaggery",
    "tamilName": "ட்ரை ஃப்ரூட் மிக்ஸ்ட் சிக்கி",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Chikki",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "dry fruit chikki",
      "mixed nuts chikki"
    ],
    "aliases": [
      "dry fruit chikki",
      "mixed nuts chikki"
    ],
    "brands": [
      "Haldiram's",
      "Bikano"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "sesame_til_laddu_white_seeds",
    "name": "Sesame Til Laddu White Seeds",
    "tamilName": "வெள்ளை எள் லட்டு",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Laddu",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "til laddu white",
      "vellai ellu urundai"
    ],
    "aliases": [
      "til laddu white",
      "vellai ellu urundai"
    ],
    "brands": [
      "Grand Sweets",
      "Haldiram's"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "black_sesame_ellu_mittai_crunchy",
    "name": "Black Sesame Ellu Mittai Crunchy",
    "tamilName": "கருப்பு எள் மிட்டாய்",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Candy",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "ellu mittai",
      "black til chikki"
    ],
    "aliases": [
      "ellu mittai",
      "black til chikki"
    ],
    "brands": [
      "Grand Sweets",
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "kamarkat_hard_coconut_jaggery_candy",
    "name": "Kamarkat Hard Coconut Jaggery Candy",
    "tamilName": "கமர்கட் தேங்காய் வெல்ல மிட்டாய்",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Candy",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 150.0,
    "customQuantities": [
      150.0
    ],
    "commonNames": [
      "kamarkat candy",
      "hard coconut candy"
    ],
    "aliases": [
      "kamarkat candy",
      "hard coconut candy"
    ],
    "brands": [
      "Grand Sweets",
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "kadalai_urundai_jaggery_peanut_ball",
    "name": "Kadalai Urundai Jaggery Peanut Ball",
    "tamilName": "கடலை உருண்டை (நாட்டு வெல்லம்)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Sweet",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 6.0,
    "customQuantities": [
      6.0,
      12.0
    ],
    "commonNames": [
      "kadalai urundai",
      "peanut jaggery ball"
    ],
    "aliases": [
      "kadalai urundai",
      "peanut jaggery ball"
    ],
    "brands": [
      "Grand Sweets",
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "pori_urundai_jaggery_puffed_rice_ball",
    "name": "Pori Urundai Jaggery Puffed Rice Ball",
    "tamilName": "பொரி உருண்டை (வெல்லம்)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Sweet",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 6.0,
    "customQuantities": [
      6.0,
      12.0
    ],
    "commonNames": [
      "pori urundai",
      "puffed rice ball"
    ],
    "aliases": [
      "pori urundai",
      "puffed rice ball"
    ],
    "brands": [
      "Grand Sweets",
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "roasted_salted_almonds_california_200g",
    "name": "Roasted Salted Almonds California 200g",
    "tamilName": "வறுத்த உப்பு பாதாம் பருப்பு",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Almonds",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "roasted salted almonds",
      "salted badam"
    ],
    "aliases": [
      "roasted salted almonds",
      "salted badam"
    ],
    "brands": [
      "Happilo",
      "Nutraj"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "roasted_salted_cashews_kaju_200g",
    "name": "Roasted Salted Cashews Kaju 200g",
    "tamilName": "வறுத்த உப்பு முந்திரி பருப்பு",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Cashews",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "roasted salted cashews",
      "salted kaju"
    ],
    "aliases": [
      "roasted salted cashews",
      "salted kaju"
    ],
    "brands": [
      "Happilo",
      "Nutraj"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "black_pepper_roasted_cashews_200g",
    "name": "Black Pepper Roasted Cashews 200g",
    "tamilName": "மிளகு வறுத்த முந்திரி பருப்பு",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Cashews",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "pepper cashews",
      "milagu kaju"
    ],
    "aliases": [
      "pepper cashews",
      "milagu kaju"
    ],
    "brands": [
      "Happilo",
      "Nutraj"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "roasted_salted_sunflower_seeds_200g",
    "name": "Roasted Salted Sunflower Seeds 200g",
    "tamilName": "வறுத்த உப்பு சூரியகாந்தி விதைகள்",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Seeds",
    "productType": "Seeds",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "roasted sunflower seeds"
    ],
    "aliases": [
      "roasted sunflower seeds"
    ],
    "brands": [
      "True Elements",
      "Neuherbs"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "roasted_salted_pumpkin_seeds_200g",
    "name": "Roasted Salted Pumpkin Seeds 200g",
    "tamilName": "வறுத்த உப்பு பூசணி விதைகள்",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Seeds",
    "productType": "Seeds",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "roasted pumpkin seeds"
    ],
    "aliases": [
      "roasted pumpkin seeds"
    ],
    "brands": [
      "True Elements",
      "Neuherbs"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "spiced_roasted_flax_seeds_200g",
    "name": "Spiced Roasted Flax Seeds 200g",
    "tamilName": "வறுத்த மசாலா ஆளி விதைகள்",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Seeds",
    "productType": "Seeds",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "roasted flax seeds",
      "mukhwas alsi"
    ],
    "aliases": [
      "roasted flax seeds",
      "mukhwas alsi"
    ],
    "brands": [
      "True Elements",
      "Organic Tattva"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "organic_white_chia_seeds_200g",
    "name": "Organic White Chia Seeds 200g",
    "tamilName": "வெள்ளை சியா விதைகள்",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Seeds",
    "productType": "Seeds",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "white chia seeds"
    ],
    "aliases": [
      "white chia seeds"
    ],
    "brands": [
      "True Elements",
      "Neuherbs"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "whole_dried_coconut_copra_gola",
    "name": "Whole Dried Coconut Copra Gola",
    "tamilName": "முழு கொப்பரை தேங்காய் (கோலா)",
    "category": "Food & Grocery",
    "subCategory": "Cooking & Baking",
    "productType": "Dry Coconut",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "dry copra",
      "sukha nariyal",
      "gola"
    ],
    "aliases": [
      "dry copra",
      "sukha nariyal",
      "gola"
    ],
    "brands": [
      "Local Mills",
      "Udhayam"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "desiccated_coconut_powder_fine",
    "name": "Desiccated Coconut Powder Fine",
    "tamilName": "உலர்ந்த தேங்காய் துருவல் பொடி",
    "category": "Food & Grocery",
    "subCategory": "Cooking & Baking",
    "productType": "Coconut Powder",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "desiccated coconut",
      "dry coconut powder"
    ],
    "aliases": [
      "desiccated coconut",
      "dry coconut powder"
    ],
    "brands": [
      "Urban Platter",
      "BB Royal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "pure_cane_sugar_sulphur_free",
    "name": "Pure Cane Sugar Sulphur Free",
    "tamilName": "கரும்பு சர்க்கரை (சல்பர் இல்லாதது)",
    "category": "Salt, Sugar & Sweeteners",
    "subCategory": "Sugar & Sweeteners",
    "productType": "Sugar",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0
    ],
    "commonNames": [
      "cane sugar",
      "refined sugar sulphur free",
      "cheeni"
    ],
    "aliases": [
      "cane sugar",
      "refined sugar sulphur free",
      "cheeni"
    ],
    "brands": [
      "Dhampure",
      "Trust",
      "Mawana"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "staple"
  },
  {
    "id": "natural_brown_demerara_sugar",
    "name": "Natural Brown Demerara Sugar",
    "tamilName": "பிரவுன் சுகர் டெமராரா",
    "category": "Salt, Sugar & Sweeteners",
    "subCategory": "Sugar & Sweeteners",
    "productType": "Sugar",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "brown sugar",
      "demerara sugar"
    ],
    "aliases": [
      "brown sugar",
      "demerara sugar"
    ],
    "brands": [
      "Dhampure",
      "Trust"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "staple"
  },
  {
    "id": "organic_coconut_palm_jaggery_karupatti",
    "name": "Organic Coconut Palm Jaggery Karupatti",
    "tamilName": "பனை கருப்பட்டி (சுத்தமானது)",
    "category": "Salt, Sugar & Sweeteners",
    "subCategory": "Sugar & Sweeteners",
    "productType": "Jaggery",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "karupatti",
      "palm jaggery",
      "pana karupatti"
    ],
    "aliases": [
      "karupatti",
      "palm jaggery",
      "pana karupatti"
    ],
    "brands": [
      "Gramiyum",
      "B&B Organics",
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "staple"
  },
  {
    "id": "panakarkandu_palm_sugar_candy_crystals",
    "name": "Panakarkandu Palm Sugar Candy Crystals",
    "tamilName": "பனங்கற்கண்டு",
    "category": "Salt, Sugar & Sweeteners",
    "subCategory": "Sugar & Sweeteners",
    "productType": "Sugar Candy",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "panakarkandu",
      "palm sugar candy",
      "tal mishri"
    ],
    "aliases": [
      "panakarkandu",
      "palm sugar candy",
      "tal mishri"
    ],
    "brands": [
      "Local Artisans",
      "Gramiyum",
      "Gopuram"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "staple"
  },
  {
    "id": "round_jaggery_balls_mandi_vellam",
    "name": "Round Jaggery Balls Mandi Vellam",
    "tamilName": "மண்டி உருண்டை வெல்லம்",
    "category": "Salt, Sugar & Sweeteners",
    "subCategory": "Sugar & Sweeteners",
    "productType": "Jaggery",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "round jaggery",
      "urundai vellam",
      "gur"
    ],
    "aliases": [
      "round jaggery",
      "urundai vellam",
      "gur"
    ],
    "brands": [
      "Udhayam",
      "Local Mills"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "staple"
  },
  {
    "id": "nattu_sakkarai_country_sugar_jaggery_powder",
    "name": "Nattu Sakkarai Country Sugar Jaggery Powder",
    "tamilName": "நாட்டுச் சர்க்கரை",
    "category": "Salt, Sugar & Sweeteners",
    "subCategory": "Sugar & Sweeteners",
    "productType": "Jaggery Powder",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "nattu sakkarai",
      "country sugar",
      "brown jaggery powder"
    ],
    "aliases": [
      "nattu sakkarai",
      "country sugar",
      "brown jaggery powder"
    ],
    "brands": [
      "Gramiyum",
      "Udhayam",
      "24 Mantra"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "staple"
  },
  {
    "id": "raw_multi_flora_forest_honey_squeeze_bottle",
    "name": "Raw Multi-Flora Forest Honey Squeeze Bottle",
    "tamilName": "சுத்தமான காட்டுத் தேன்",
    "category": "Salt, Sugar & Sweeteners",
    "subCategory": "Sugar & Sweeteners",
    "productType": "Honey",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      250.0,
      500.0,
      1000.0
    ],
    "commonNames": [
      "honey",
      "raw forest honey",
      "then"
    ],
    "aliases": [
      "honey",
      "raw forest honey",
      "then"
    ],
    "brands": [
      "Dabur Honey",
      "Patanjali Honey",
      "Saffola Honey",
      "Lion Honey"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "staple"
  },
  {
    "id": "pure_himalayan_shilajit_resin_20g",
    "name": "Pure Himalayan Shilajit Resin 20g",
    "tamilName": "இமயமலை சிலாஜித் பிசின்",
    "category": "Personal Care & Hygiene",
    "subCategory": "Health & Wellness",
    "productType": "Ayurvedic Resin",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 20.0,
    "customQuantities": [
      20.0
    ],
    "commonNames": [
      "shilajit resin",
      "pure shilajit"
    ],
    "aliases": [
      "shilajit resin",
      "pure shilajit"
    ],
    "brands": [
      "Kapiva Shilajit",
      "Upakarma"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "grade_1_pure_kashmiri_saffron_kesar_1g",
    "name": "Grade 1 Pure Kashmiri Saffron Kesar 1g",
    "tamilName": "தூய காஷ்மீரி குங்குமப்பூ (1 கிராம்)",
    "category": "Spices & Seasonings",
    "subCategory": "Whole Spices",
    "productType": "Saffron",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "saffron",
      "kesar",
      "kungumapoo"
    ],
    "aliases": [
      "saffron",
      "kesar",
      "kungumapoo"
    ],
    "brands": [
      "Baby Saffron",
      "Lion Saffron",
      "Tata Sampann"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "spice"
  },
  {
    "id": "bhimseni_pure_kapoor_crystal_flakes_100g",
    "name": "Bhimseni Pure Kapoor Crystal Flakes 100g",
    "tamilName": "பீம்சேனி தூய கற்பூர படிகங்கள்",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Camphor & Agarbatti",
    "productType": "Camphor",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "bhimseni kapoor",
      "edible camphor flakes"
    ],
    "aliases": [
      "bhimseni kapoor",
      "edible camphor flakes"
    ],
    "brands": [
      "Mangalam Bhimseni",
      "Cycle"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "aroma_sambrani_dhoop_cups_benzoin_24s",
    "name": "Aroma Sambrani Dhoop Cups Benzoin 24s",
    "tamilName": "நறுமண சாம்பிராணி கப் (24 எண்ணிக்கை)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Camphor & Agarbatti",
    "productType": "Sambrani",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 24.0,
    "customQuantities": [
      24.0
    ],
    "commonNames": [
      "sambrani dhoop cups 24",
      "fragrant cup dhoop"
    ],
    "aliases": [
      "sambrani dhoop cups 24",
      "fragrant cup dhoop"
    ],
    "brands": [
      "Phool",
      "Cycle"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "traditional_scented_sandalwood_pooja_fragrance_oil",
    "name": "Traditional Scented Sandalwood Pooja Fragrance Oil",
    "tamilName": "பூஜை சந்தன வாசனை எண்ணெய்",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Oils & Wicks",
    "productType": "Pooja Oil",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 10.0,
    "customQuantities": [
      10.0
    ],
    "commonNames": [
      "sandalwood pooja oil",
      "chandan sugandh"
    ],
    "aliases": [
      "sandalwood pooja oil",
      "chandan sugandh"
    ],
    "brands": [
      "Cycle Sugandh",
      "Gopuram"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "ready_ghee_lamp_dipped_clay_diyas_12s",
    "name": "Ready Ghee Lamp Dipped Clay Diyas 12s",
    "tamilName": "நெய் நிரப்பிய மண் விளக்குகள் (12 எண்ணிக்கை)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Oils & Wicks",
    "productType": "Diya",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 12.0,
    "customQuantities": [
      12.0
    ],
    "commonNames": [
      "clay ghee diyas",
      "ready diya pack"
    ],
    "aliases": [
      "clay ghee diyas",
      "ready diya pack"
    ],
    "brands": [
      "Cycle Ghee Diyas",
      "Pure Desi"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "terracotta_clay_diyas_natural_pack_of_12",
    "name": "Terracotta Clay Diyas Natural Pack of 12",
    "tamilName": "மண் அகல் விளக்குகள் (12 எண்ணிக்கை)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Utensils",
    "productType": "Diya",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 12.0,
    "customQuantities": [
      12.0
    ],
    "commonNames": [
      "clay diyas",
      "man vilakku"
    ],
    "aliases": [
      "clay diyas",
      "man vilakku"
    ],
    "brands": [
      "Local Potters"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "cotton_pooja_wicks_long_twisted_100s",
    "name": "Cotton Pooja Wicks Long Twisted 100s",
    "tamilName": "நீட்டு திரி பஞ்சு (100 எண்ணிக்கை)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Oils & Wicks",
    "productType": "Wicks",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "long pooja wicks",
      "neettu thiri 100"
    ],
    "aliases": [
      "long pooja wicks",
      "neettu thiri 100"
    ],
    "brands": [
      "Cycle",
      "Gopuram"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "solid_brass_panchapatra_udharani_set",
    "name": "Solid Brass Panchapatra & Udharani Set",
    "tamilName": "பித்தளை பஞ்சபாத்திரம் & உத்தரணி",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Utensils",
    "productType": "Utensil Set",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "panchapatra udharani",
      "brass theertha pathiram"
    ],
    "aliases": [
      "panchapatra udharani",
      "brass theertha pathiram"
    ],
    "brands": [
      "Local Brass Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pure_copper_panchapatra_spoon_set",
    "name": "Pure Copper Panchapatra & Spoon Set",
    "tamilName": "செம்பு பஞ்சபாத்திரம் & ஸ்பூன்",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Utensils",
    "productType": "Utensil Set",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "copper panchapatra"
    ],
    "aliases": [
      "copper panchapatra"
    ],
    "brands": [
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "solid_brass_agarbatti_stand_with_ash_catcher",
    "name": "Solid Brass Agarbatti Stand with Ash Catcher",
    "tamilName": "பித்தளை ஊதுபத்தி ஸ்டாண்ட்",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Utensils",
    "productType": "Incense Stand",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "agarbatti stand brass",
      "incense holder"
    ],
    "aliases": [
      "agarbatti stand brass",
      "incense holder"
    ],
    "brands": [
      "Local Brass Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "solid_brass_kalash_lota_for_pooja",
    "name": "Solid Brass Kalash Lota for Pooja",
    "tamilName": "பித்தளை பூர்வ கும்ப கலசம்",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Utensils",
    "productType": "Kalash",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "brass kalash",
      "pooja lota"
    ],
    "aliases": [
      "brass kalash",
      "pooja lota"
    ],
    "brands": [
      "Local Brass Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pure_copper_kalash_lota_for_holy_water",
    "name": "Pure Copper Kalash Lota for Holy Water",
    "tamilName": "செம்பு கலச செம்பு",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Utensils",
    "productType": "Kalash",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "copper kalash",
      "sembu kalasam"
    ],
    "aliases": [
      "copper kalash",
      "sembu kalasam"
    ],
    "brands": [
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "solid_brass_aarti_thali_plate_10_inch",
    "name": "Solid Brass Aarti Thali Plate 10 Inch",
    "tamilName": "பித்தளை ஆரத்தி தட்டு (10 இன்ச்)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Utensils",
    "productType": "Plate",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "brass aarti thali",
      "pooja plate 10 inch"
    ],
    "aliases": [
      "brass aarti thali",
      "pooja plate 10 inch"
    ],
    "brands": [
      "Local Brass Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "solid_brass_kuthuvilakku_pair_12_inch",
    "name": "Solid Brass Kuthuvilakku Pair 12 Inch",
    "tamilName": "பித்தளை குத்துவிளக்கு ஜோடி (12 இன்ச்)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Utensils",
    "productType": "Diya Stand",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 2.0,
    "customQuantities": [
      2.0
    ],
    "commonNames": [
      "kuthuvilakku pair",
      "brass diya stand pair"
    ],
    "aliases": [
      "kuthuvilakku pair",
      "brass diya stand pair"
    ],
    "brands": [
      "Nachiar Koil Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "vessel_scrubbing_sponge_heavy_duty_3_pack",
    "name": "Vessel Scrubbing Sponge Heavy Duty 3 Pack",
    "tamilName": "பாத்திரம் கழுவும் ஸ்பாஞ்ச் (3 எண்ணிக்கை)",
    "category": "Household & Cleaning",
    "subCategory": "Cleaning Tools",
    "productType": "Sponge",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Utility Shelf",
    "minimumQuantity": 3.0,
    "customQuantities": [
      3.0
    ],
    "commonNames": [
      "heavy duty scrubber sponge",
      "bartan sponge"
    ],
    "aliases": [
      "heavy duty scrubber sponge",
      "bartan sponge"
    ],
    "brands": [
      "Scotch-Brite Heavy Duty",
      "Gala"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "steel_wool_wire_scrubber_heavy_duty_pack_4",
    "name": "Steel Wool Wire Scrubber Heavy Duty Pack 4",
    "tamilName": "ஸ்டீல் கம்பி நார் (4 எண்ணிக்கை)",
    "category": "Household & Cleaning",
    "subCategory": "Cleaning Tools",
    "productType": "Wire Scrubber",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Utility Shelf",
    "minimumQuantity": 4.0,
    "customQuantities": [
      4.0
    ],
    "commonNames": [
      "steel wool pack",
      "wire juna 4s"
    ],
    "aliases": [
      "steel wool pack",
      "wire juna 4s"
    ],
    "brands": [
      "Scotch-Brite Steel Scrubber",
      "Gala"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "stainless_steel_kitchen_sink_drain_strainer_mesh",
    "name": "Stainless Steel Kitchen Sink Drain Strainer Mesh",
    "tamilName": "ஸ்டெயின்லெஸ் ஸ்டீல் சின்க் வடிகட்டி",
    "category": "Home Utility & Hardware",
    "subCategory": "Kitchenware",
    "productType": "Sink Strainer",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Kitchen Cabinet",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "sink strainer mesh",
      "kitchen drain filter"
    ],
    "aliases": [
      "sink strainer mesh",
      "kitchen drain filter"
    ],
    "brands": [
      "Presto!",
      "Local"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "hardware"
  },
  {
    "id": "silicone_kitchen_spatula_heat_resistant",
    "name": "Silicone Kitchen Spatula Heat Resistant",
    "tamilName": "சிலிகான் கிச்சன் ஸ்பேட்டுலா",
    "category": "Home Utility & Hardware",
    "subCategory": "Kitchenware",
    "productType": "Kitchen Tool",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Kitchen Cabinet",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "silicone spatula",
      "rubber spatula"
    ],
    "aliases": [
      "silicone spatula",
      "rubber spatula"
    ],
    "brands": [
      "Wonderchef",
      "Prestige"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "hardware"
  },
  {
    "id": "natural_neem_wood_cooking_ladle_spatula_set",
    "name": "Natural Neem Wood Cooking Ladle Spatula Set",
    "tamilName": "வேப்பமர சமையல் கரண்டி செட்",
    "category": "Home Utility & Hardware",
    "subCategory": "Kitchenware",
    "productType": "Wooden Ladle",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Kitchen Cabinet",
    "minimumQuantity": 3.0,
    "customQuantities": [
      3.0
    ],
    "commonNames": [
      "wooden ladle neem",
      "marakkai karandi"
    ],
    "aliases": [
      "wooden ladle neem",
      "marakkai karandi"
    ],
    "brands": [
      "Local Wood Artisans",
      "Urban Platter"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "hardware"
  },
  {
    "id": "plastic_clothes_drying_pegs_with_basket_24s",
    "name": "Plastic Clothes Drying Pegs with Basket 24s",
    "tamilName": "துணி கிளிப்புகள் கூடடை செட் (24 எண்ணிக்கை)",
    "category": "Home Utility & Hardware",
    "subCategory": "Electrical & Utility",
    "productType": "Clips",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Balcony Shelf",
    "minimumQuantity": 24.0,
    "customQuantities": [
      24.0
    ],
    "commonNames": [
      "clothes pegs with basket",
      "drying clips 24s"
    ],
    "aliases": [
      "clothes pegs with basket",
      "drying clips 24s"
    ],
    "brands": [
      "Gala",
      "Presto!"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "hardware"
  },
  {
    "id": "stainless_steel_wire_clothes_drying_pegs_12s",
    "name": "Stainless Steel Wire Clothes Drying Pegs 12s",
    "tamilName": "ஸ்டீல் துணி கிளிப்புகள் (12 எண்ணிக்கை)",
    "category": "Home Utility & Hardware",
    "subCategory": "Electrical & Utility",
    "productType": "Clips",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Balcony Shelf",
    "minimumQuantity": 12.0,
    "customQuantities": [
      12.0
    ],
    "commonNames": [
      "steel clothes pegs",
      "wire clips"
    ],
    "aliases": [
      "steel clothes pegs",
      "wire clips"
    ],
    "brands": [
      "Gala",
      "Local"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "hardware"
  },
  {
    "id": "strong_braided_nylon_clothesline_rope_15m",
    "name": "Strong Braided Nylon Clothesline Rope 15m",
    "tamilName": "நைலான் துணி காயவைக்கும் கயிறு (15 மீட்டர்)",
    "category": "Home Utility & Hardware",
    "subCategory": "Electrical & Utility",
    "productType": "Rope",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Balcony Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "clothesline rope",
      "drying rope 15m"
    ],
    "aliases": [
      "clothesline rope",
      "drying rope 15m"
    ],
    "brands": [
      "Local",
      "Presto!"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "hardware"
  },
  {
    "id": "plastic_bathroom_bucket_heavy_duty_18l",
    "name": "Plastic Bathroom Bucket Heavy Duty 18L",
    "tamilName": "பிளாஸ்டிக் குளியலறை வாளி (18 லிட்டர்)",
    "category": "Home Utility & Hardware",
    "subCategory": "Bathroom Utilities",
    "productType": "Bucket",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Bathroom Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "bathroom bucket 18L",
      "plastic vaali"
    ],
    "aliases": [
      "bathroom bucket 18l",
      "plastic vaali"
    ],
    "brands": [
      "Cello",
      "Nayasa",
      "Milton"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "hardware"
  },
  {
    "id": "plastic_bathroom_water_mug_1l",
    "name": "Plastic Bathroom Water Mug 1L",
    "tamilName": "பிளாஸ்டிக் தண்ணீர் குவளை (1 லிட்டர்)",
    "category": "Home Utility & Hardware",
    "subCategory": "Bathroom Utilities",
    "productType": "Mug",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Bathroom Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "bathroom mug 1L",
      "thanni mug"
    ],
    "aliases": [
      "bathroom mug 1l",
      "thanni mug"
    ],
    "brands": [
      "Cello",
      "Milton",
      "Nayasa"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "hardware"
  },
  {
    "id": "heavy_duty_dustpan_with_rubber_lip",
    "name": "Heavy Duty Dustpan with Rubber Lip",
    "tamilName": "குப்பை முறம் (ரப்பர் விளிம்புடன்)",
    "category": "Household & Cleaning",
    "subCategory": "Cleaning Tools",
    "productType": "Dustpan",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Utility Room",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "dustpan with rubber lip",
      "kuppai muram"
    ],
    "aliases": [
      "dustpan with rubber lip",
      "kuppai muram"
    ],
    "brands": [
      "Gala Dustpan",
      "Scotch-Brite"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "herbal_vetiver_bath_loofah_natural",
    "name": "Herbal Vetiver Bath Loofah Natural",
    "tamilName": "வெட்டிவேர் குளியல் நார்",
    "category": "Personal Care & Hygiene",
    "subCategory": "Bath & Body Care",
    "productType": "Bath Loofah",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Bathroom Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "vetiver loofah",
      "vettiveru bath scrub"
    ],
    "aliases": [
      "vetiver loofah",
      "vettiveru bath scrub"
    ],
    "brands": [
      "Gramiyum",
      "Local Ayurvedic"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "natural_coir_body_scrubber_loofah",
    "name": "Natural Coir Body Scrubber Loofah",
    "tamilName": "தேங்காய் நார் குளியல் ஸ்க்ரப்பர்",
    "category": "Personal Care & Hygiene",
    "subCategory": "Bath & Body Care",
    "productType": "Bath Loofah",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Bathroom Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "coir bath scrubber",
      "thengai naar kuliyal scrub"
    ],
    "aliases": [
      "coir bath scrubber",
      "thengai naar kuliyal scrub"
    ],
    "brands": [
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "pure_neem_wood_wide_tooth_hair_comb",
    "name": "Pure Neem Wood Wide Tooth Hair Comb",
    "tamilName": "வேப்பமர அகல பல் சீப்பு",
    "category": "Personal Care & Hygiene",
    "subCategory": "Hair Care",
    "productType": "Comb",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Dressing Table",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "neem wood comb",
      "veppamara seeppu"
    ],
    "aliases": [
      "neem wood comb",
      "veppamara seeppu"
    ],
    "brands": [
      "The Body Shop",
      "Local Neem Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "pure_tea_tree_essential_oil_antibacterial_15ml",
    "name": "Pure Tea Tree Essential Oil Antibacterial 15ml",
    "tamilName": "டீ ட்ரீ எசென்ஷியல் ஆயில் (15 மி.லி)",
    "category": "Personal Care & Hygiene",
    "subCategory": "Skin Care",
    "productType": "Essential Oil",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Dressing Table",
    "minimumQuantity": 15.0,
    "customQuantities": [
      15.0
    ],
    "commonNames": [
      "tea tree oil",
      "pure tea tree"
    ],
    "aliases": [
      "tea tree oil",
      "pure tea tree"
    ],
    "brands": [
      "Soulflower",
      "Organic Harvest"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "pure_rosemary_essential_oil_for_hair_growth_30ml",
    "name": "Pure Rosemary Essential Oil for Hair Growth 30ml",
    "tamilName": "ரோஸ்மேரி தலை கூந்தல் எண்ணெய் (30 மி.லி)",
    "category": "Personal Care & Hygiene",
    "subCategory": "Hair Care",
    "productType": "Essential Oil",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Dressing Table",
    "minimumQuantity": 30.0,
    "customQuantities": [
      30.0
    ],
    "commonNames": [
      "rosemary essential oil",
      "rosemary hair oil"
    ],
    "aliases": [
      "rosemary essential oil",
      "rosemary hair oil"
    ],
    "brands": [
      "Soulflower Rosemary",
      "Biotique"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "frozen_green_peas_tender_sweet_500g",
    "name": "Frozen Green Peas Tender Sweet 500g",
    "tamilName": "உறைந்த பச்சை பட்டாணி (500 கிராம்)",
    "category": "Dairy & Refrigerated",
    "subCategory": "Frozen Foods",
    "productType": "Frozen Vegetables",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Freezer",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0,
      1000.0
    ],
    "commonNames": [
      "frozen green peas",
      "frozen matar"
    ],
    "aliases": [
      "frozen green peas",
      "frozen matar"
    ],
    "brands": [
      "Safal Green Peas",
      "ITC Master Chef",
      "Godrej Yummiez"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "fresh_produce"
  },
  {
    "id": "frozen_sweet_corn_kernels_500g",
    "name": "Frozen Sweet Corn Kernels 500g",
    "tamilName": "உறைந்த இனிப்பு மக்காச்சோளம் (500 கிராம்)",
    "category": "Dairy & Refrigerated",
    "subCategory": "Frozen Foods",
    "productType": "Frozen Vegetables",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Freezer",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "frozen sweet corn",
      "frozen makka"
    ],
    "aliases": [
      "frozen sweet corn",
      "frozen makka"
    ],
    "brands": [
      "Safal Sweet Corn",
      "ITC Master Chef"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "fresh_produce"
  },
  {
    "id": "frozen_mixed_vegetables_pack_500g",
    "name": "Frozen Mixed Vegetables Pack 500g",
    "tamilName": "உறைந்த கலவை காய்கறிகள் (500 கிராம்)",
    "category": "Dairy & Refrigerated",
    "subCategory": "Frozen Foods",
    "productType": "Frozen Vegetables",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Freezer",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "frozen mixed vegetables"
    ],
    "aliases": [
      "frozen mixed vegetables"
    ],
    "brands": [
      "Safal Mix Veg",
      "ITC Master Chef"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "fresh_produce"
  },
  {
    "id": "frozen_french_fries_crispy_400g",
    "name": "Frozen French Fries Crispy 400g",
    "tamilName": "உறைந்த பிரெஞ்சு பிரைஸ் (400 கிராம்)",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Frozen Foods",
    "productType": "Frozen Snack",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Freezer",
    "minimumQuantity": 400.0,
    "customQuantities": [
      400.0,
      1000.0
    ],
    "commonNames": [
      "french fries frozen",
      "mccain fries"
    ],
    "aliases": [
      "french fries frozen",
      "mccain fries"
    ],
    "brands": [
      "McCain French Fries",
      "ITC Master Chef"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "frozen_veg_burger_patties_4_pack",
    "name": "Frozen Veg Burger Patties 4 Pack",
    "tamilName": "உறைந்த வெஜ் பர்கர் பேட்டி (4 எண்ணிக்கை)",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Frozen Foods",
    "productType": "Frozen Snack",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Freezer",
    "minimumQuantity": 4.0,
    "customQuantities": [
      4.0
    ],
    "commonNames": [
      "burger patty frozen"
    ],
    "aliases": [
      "burger patty frozen"
    ],
    "brands": [
      "McCain Veggie Burger Patty",
      "Godrej Yummiez"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "frozen_spiced_aloo_tikki_400g",
    "name": "Frozen Spiced Aloo Tikki 400g",
    "tamilName": "உறைந்த ஆலு டிக்கி (400 கிராம்)",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Frozen Foods",
    "productType": "Frozen Snack",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Freezer",
    "minimumQuantity": 400.0,
    "customQuantities": [
      400.0
    ],
    "commonNames": [
      "aloo tikki frozen"
    ],
    "aliases": [
      "aloo tikki frozen"
    ],
    "brands": [
      "McCain Aloo Tikki",
      "Haldiram's"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "frozen_flaky_malabar_parotta_5s",
    "name": "Frozen Flaky Malabar Parotta 5s",
    "tamilName": "உறைந்த மலபார் பரோட்டா (5 எண்ணிக்கை)",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Frozen Foods",
    "productType": "Frozen Bread",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Freezer",
    "minimumQuantity": 5.0,
    "customQuantities": [
      5.0
    ],
    "commonNames": [
      "frozen malabar parotta",
      "id parota"
    ],
    "aliases": [
      "frozen malabar parotta",
      "id parota"
    ],
    "brands": [
      "iD Malabar Parota",
      "Asal Parotta",
      "Summosa"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "frozen_whole_wheat_phulka_roti_10s",
    "name": "Frozen Whole Wheat Phulka Roti 10s",
    "tamilName": "உறைந்த முழு கோதுமை புல்கா (10 எண்ணிக்கை)",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Frozen Foods",
    "productType": "Frozen Bread",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Freezer",
    "minimumQuantity": 10.0,
    "customQuantities": [
      10.0
    ],
    "commonNames": [
      "frozen chapati",
      "frozen roti phulka"
    ],
    "aliases": [
      "frozen chapati",
      "frozen roti phulka"
    ],
    "brands": [
      "iD Whole Wheat Roti",
      "Asal Chapati"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "extra_virgin_olive_oil_cold_pressed_500ml",
    "name": "Extra Virgin Olive Oil Cold Pressed 500ml",
    "tamilName": "எக்ஸ்ட்ரா வெர்ஜின் ஆலிவ் எண்ணெய் (500 மி.லி)",
    "category": "Oils & Fats",
    "subCategory": "Cooking Oils",
    "productType": "Olive Oil",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      250.0,
      500.0,
      1000.0
    ],
    "commonNames": [
      "extra virgin olive oil",
      "evoo olive oil"
    ],
    "aliases": [
      "extra virgin olive oil",
      "evoo olive oil"
    ],
    "brands": [
      "Borges Extra Virgin",
      "Figaro",
      "Disano"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "oil"
  },
  {
    "id": "pure_olive_pomace_oil_for_indian_cooking_1l",
    "name": "Pure Olive Pomace Oil for Indian Cooking 1L",
    "tamilName": "ஆலிவ் பொமாஸ் சமையல் எண்ணெய் (1 லிட்டர்)",
    "category": "Oils & Fats",
    "subCategory": "Cooking Oils",
    "productType": "Olive Oil",
    "defaultUnit": "l",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0
    ],
    "commonNames": [
      "olive pomace oil",
      "cooking olive oil"
    ],
    "aliases": [
      "olive pomace oil",
      "cooking olive oil"
    ],
    "brands": [
      "Borges Pomace",
      "Figaro",
      "Disano"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "oil"
  },
  {
    "id": "physically_refined_rice_bran_oil_1l",
    "name": "Physically Refined Rice Bran Oil 1L",
    "tamilName": "ரைஸ் பிரான் தவிட்டு எண்ணெய் (1 லிட்டர்)",
    "category": "Oils & Fats",
    "subCategory": "Cooking Oils",
    "productType": "Rice Bran Oil",
    "defaultUnit": "l",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0
    ],
    "commonNames": [
      "rice bran oil",
      "thavittu ennai"
    ],
    "aliases": [
      "rice bran oil",
      "thavittu ennai"
    ],
    "brands": [
      "Fortune Rice Bran",
      "Saffola Gold",
      "Dhara"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "oil"
  },
  {
    "id": "heart_care_blended_cooking_oil_1l",
    "name": "Heart Care Blended Cooking Oil 1L",
    "tamilName": "ஹார்ட்கேர் பிளெண்டட் சமையல் எண்ணெய் (1 லிட்டர்)",
    "category": "Oils & Fats",
    "subCategory": "Cooking Oils",
    "productType": "Blended Oil",
    "defaultUnit": "l",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0
    ],
    "commonNames": [
      "saffola gold oil",
      "blended cooking oil"
    ],
    "aliases": [
      "saffola gold oil",
      "blended cooking oil"
    ],
    "brands": [
      "Saffola Gold",
      "Saffola Total",
      "Fortune Vivo"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "oil"
  },
  {
    "id": "pure_canola_cooking_oil_1l",
    "name": "Pure Canola Cooking Oil 1L",
    "tamilName": "கனோலா சமையல் எண்ணெய் (1 லிட்டர்)",
    "category": "Oils & Fats",
    "subCategory": "Cooking Oils",
    "productType": "Canola Oil",
    "defaultUnit": "l",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "canola oil"
    ],
    "aliases": [
      "canola oil"
    ],
    "brands": [
      "Hudson Canola",
      "Disano Canola",
      "Jivo"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "oil"
  },
  {
    "id": "refined_corn_oil_for_cooking_1l",
    "name": "Refined Corn Oil for Cooking 1L",
    "tamilName": "சோள சமையல் எண்ணெய் (1 லிட்டர்)",
    "category": "Oils & Fats",
    "subCategory": "Cooking Oils",
    "productType": "Corn Oil",
    "defaultUnit": "l",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0
    ],
    "commonNames": [
      "corn oil cooking",
      "makka ennai"
    ],
    "aliases": [
      "corn oil cooking",
      "makka ennai"
    ],
    "brands": [
      "Fortune Corn Oil",
      "Dhara Corn"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "oil"
  },
  {
    "id": "refined_soyabean_cooking_oil_1l",
    "name": "Refined Soyabean Cooking Oil 1L",
    "tamilName": "சோயாபீன் சமையல் எண்ணெய் (1 லிட்டர்)",
    "category": "Oils & Fats",
    "subCategory": "Cooking Oils",
    "productType": "Soyabean Oil",
    "defaultUnit": "l",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0
    ],
    "commonNames": [
      "soyabean oil",
      "refined soya oil"
    ],
    "aliases": [
      "soyabean oil",
      "refined soya oil"
    ],
    "brands": [
      "Fortune Soya Oil",
      "Dhara",
      "Mahakosh"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "oil"
  },
  {
    "id": "traditional_curry_leaf_thuvaiyal_karuveppilai",
    "name": "Traditional Curry Leaf Thuvaiyal Karuveppilai",
    "tamilName": "கருவேப்பிலை துவையல் பேஸ்ட்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Thuvaiyal",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "karuveppilai thuvaiyal",
      "curry leaf paste"
    ],
    "aliases": [
      "karuveppilai thuvaiyal",
      "curry leaf paste"
    ],
    "brands": [
      "Grand Sweets",
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "traditional_pirandai_thuvaiyal_paste",
    "name": "Traditional Pirandai Thuvaiyal Paste",
    "tamilName": "பிரண்டை துவையல் பேஸ்ட்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Thuvaiyal",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "pirandai thuvaiyal",
      "adamant creeper chutney"
    ],
    "aliases": [
      "pirandai thuvaiyal",
      "adamant creeper chutney"
    ],
    "brands": [
      "Grand Sweets",
      "B&B Organics"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "traditional_poondu_garlic_thuvaiyal_paste",
    "name": "Traditional Poondu Garlic Thuvaiyal Paste",
    "tamilName": "பூண்டு துவையல் பேஸ்ட்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Thuvaiyal",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "poondu thuvaiyal",
      "garlic thuvaiyal"
    ],
    "aliases": [
      "poondu thuvaiyal",
      "garlic thuvaiyal"
    ],
    "brands": [
      "Grand Sweets",
      "Priya"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "traditional_inji_ginger_thuvaiyal_paste",
    "name": "Traditional Inji Ginger Thuvaiyal Paste",
    "tamilName": "இஞ்சி துவையல் பேஸ்ட்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Thuvaiyal",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "inji thuvaiyal",
      "ginger thuvaiyal"
    ],
    "aliases": [
      "inji thuvaiyal",
      "ginger thuvaiyal"
    ],
    "brands": [
      "Grand Sweets",
      "Priya"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "traditional_kollu_horsegram_thuvaiyal_paste",
    "name": "Traditional Kollu Horsegram Thuvaiyal Paste",
    "tamilName": "கொள்ளு துவையல் பேஸ்ட்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Thuvaiyal",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "kollu thuvaiyal",
      "horsegram chutney paste"
    ],
    "aliases": [
      "kollu thuvaiyal",
      "horsegram chutney paste"
    ],
    "brands": [
      "Grand Sweets",
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "traditional_mint_pudina_thuvaiyal_paste",
    "name": "Traditional Mint Pudina Thuvaiyal Paste",
    "tamilName": "புதினா துவையல் பேஸ்ட்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Thuvaiyal",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "pudina thuvaiyal",
      "mint thuvaiyal"
    ],
    "aliases": [
      "pudina thuvaiyal",
      "mint thuvaiyal"
    ],
    "brands": [
      "Grand Sweets",
      "Aachi"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "traditional_thakkali_tomato_thuvaiyal_paste",
    "name": "Traditional Thakkali Tomato Thuvaiyal Paste",
    "tamilName": "தக்காளி துவையல் பேஸ்ட்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Thuvaiyal",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "thakkali thuvaiyal",
      "tomato thuvaiyal"
    ],
    "aliases": [
      "thakkali thuvaiyal",
      "tomato thuvaiyal"
    ],
    "brands": [
      "Grand Sweets",
      "Priya"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "traditional_nellikkai_gooseberry_thuvaiyal_paste",
    "name": "Traditional Nellikkai Gooseberry Thuvaiyal Paste",
    "tamilName": "நெல்லிக்காய் துவையல் பேஸ்ட்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Thuvaiyal",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "nellikai thuvaiyal",
      "amla thuvaiyal"
    ],
    "aliases": [
      "nellikai thuvaiyal",
      "amla thuvaiyal"
    ],
    "brands": [
      "Grand Sweets",
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "instant_gulab_jamun_ready_mix_powder_200g",
    "name": "Instant Gulab Jamun Ready Mix Powder 200g",
    "tamilName": "குலாப் ஜாமுன் ரெடி மிக்ஸ் (200 கிராம்)",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Dessert Mixes",
    "productType": "Dessert Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "gulab jamun mix",
      "jamun mix"
    ],
    "aliases": [
      "gulab jamun mix",
      "jamun mix"
    ],
    "brands": [
      "MTR Gulab Jamun Mix",
      "Gits",
      "Aachi"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "instant_kulfi_falooda_dessert_mix_200g",
    "name": "Instant Kulfi Falooda Dessert Mix 200g",
    "tamilName": "குல்ஃபி ஃபாலூடா மிக்ஸ் (200 கிராம்)",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Dessert Mixes",
    "productType": "Dessert Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "kulfi mix",
      "falooda mix"
    ],
    "aliases": [
      "kulfi mix",
      "falooda mix"
    ],
    "brands": [
      "Weikfield Falooda",
      "Gits Kulfi"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "canned_sweet_pineapple_slices_in_syrup_800g",
    "name": "Canned Sweet Pineapple Slices in Syrup 800g",
    "tamilName": "அன்னாசிப்பழ துண்டுகள் டின் (800 கிராம்)",
    "category": "Food & Grocery",
    "subCategory": "Canned & Preserved",
    "productType": "Canned Fruit",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 800.0,
    "customQuantities": [
      800.0
    ],
    "commonNames": [
      "canned pineapple",
      "pineapple slices tin"
    ],
    "aliases": [
      "canned pineapple",
      "pineapple slices tin"
    ],
    "brands": [
      "Del Monte Pineapple",
      "Golden Crown"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "canned_sliced_button_mushrooms_400g",
    "name": "Canned Sliced Button Mushrooms 400g",
    "tamilName": "நறுக்கிய காளான் டின் (400 கிராம்)",
    "category": "Food & Grocery",
    "subCategory": "Canned & Preserved",
    "productType": "Canned Vegetable",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 400.0,
    "customQuantities": [
      400.0
    ],
    "commonNames": [
      "canned mushrooms",
      "sliced mushrooms tin"
    ],
    "aliases": [
      "canned mushrooms",
      "sliced mushrooms tin"
    ],
    "brands": [
      "Urban Platter",
      "Golden Crown",
      "Del Monte"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "canned_baked_beans_in_rich_tomato_sauce_400g",
    "name": "Canned Baked Beans in Rich Tomato Sauce 400g",
    "tamilName": "பேக்டு பீன்ஸ் டின் (400 கிராம்)",
    "category": "Food & Grocery",
    "subCategory": "Canned & Preserved",
    "productType": "Canned Beans",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 400.0,
    "customQuantities": [
      400.0
    ],
    "commonNames": [
      "baked beans can",
      "heinz beans"
    ],
    "aliases": [
      "baked beans can",
      "heinz beans"
    ],
    "brands": [
      "Heinz Baked Beans",
      "Del Monte"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "pooja_red_sandalwood_rakta_chandanam_powder_50g",
    "name": "Pooja Red Sandalwood Rakta Chandanam Powder 50g",
    "tamilName": "இரத்த சந்தனப் பொடி (50 கிராம்)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Chandanam",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 50.0,
    "customQuantities": [
      50.0
    ],
    "commonNames": [
      "rakta chandanam",
      "red sandalwood powder"
    ],
    "aliases": [
      "rakta chandanam",
      "red sandalwood powder"
    ],
    "brands": [
      "Local Ayurvedic",
      "Gopuram"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pooja_holy_basil_tulsi_wood_japa_mala_108_beads",
    "name": "Pooja Holy Basil Tulsi Wood Japa Mala 108 Beads",
    "tamilName": "துளசி மணி மாலை (108 மணிகள்)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Japa Mala",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "tulsi mala 108",
      "tulsi japa mala"
    ],
    "aliases": [
      "tulsi mala 108",
      "tulsi japa mala"
    ],
    "brands": [
      "Temple Stores",
      "Vrindavan Seva"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pooja_sandalwood_japa_mala_108_beads",
    "name": "Pooja Sandalwood Japa Mala 108 Beads",
    "tamilName": "சந்தன மணி மாலை (108 மணிகள்)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Japa Mala",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "sandalwood mala",
      "chandan japa mala"
    ],
    "aliases": [
      "sandalwood mala",
      "chandan japa mala"
    ],
    "brands": [
      "Cauvery",
      "Mysore Sandal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pooja_lotus_seed_kamal_gatta_mala_108_beads",
    "name": "Pooja Lotus Seed Kamal Gatta Mala 108 Beads",
    "tamilName": "தாமரை மணி மாலை (கமல்கட்டா, 108 மணிகள்)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Japa Mala",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "kamal gatta mala",
      "lotus seed mala"
    ],
    "aliases": [
      "kamal gatta mala",
      "lotus seed mala"
    ],
    "brands": [
      "Temple Stores"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pooja_rudraksha_sacred_japa_mala_108_beads",
    "name": "Pooja Rudraksha Sacred Japa Mala 108 Beads",
    "tamilName": "ருத்ராட்ச மாலை (108 மணிகள்)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Japa Mala",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "rudraksha mala",
      "rudraksha 108 beads"
    ],
    "aliases": [
      "rudraksha mala",
      "rudraksha 108 beads"
    ],
    "brands": [
      "Isha Life",
      "Temple Stores"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pooja_spatika_crystal_quartz_sphatik_mala_108_beads",
    "name": "Pooja Spatika Crystal Quartz Sphatik Mala 108 Beads",
    "tamilName": "ஸ்படிக மாலை (108 மணிகள்)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Japa Mala",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "spatika mala",
      "sphatik crystal mala"
    ],
    "aliases": [
      "spatika mala",
      "sphatik crystal mala"
    ],
    "brands": [
      "Temple Stores",
      "Isha Life"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pooja_pure_ghee_wicks_pack_of_50_wicks",
    "name": "Pooja Pure Ghee Wicks Pack of 50 Wicks",
    "tamilName": "நெய் திரி விளக்கு (50 எண்ணிக்கை)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Oils & Wicks",
    "productType": "Wicks",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 50.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "ghee wicks 50s",
      "ready ghee batti"
    ],
    "aliases": [
      "ghee wicks 50s",
      "ready ghee batti"
    ],
    "brands": [
      "Cycle Ghee Wicks",
      "Pure Desi"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pooja_loban_agarbatti_long_burning_50_sticks",
    "name": "Pooja Loban Agarbatti Long Burning 50 Sticks",
    "tamilName": "லோபான் ஊதுபத்தி (50 எண்ணிக்கை)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Camphor & Agarbatti",
    "productType": "Agarbatti",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 50.0,
    "customQuantities": [
      50.0
    ],
    "commonNames": [
      "loban agarbatti",
      "loban incense sticks"
    ],
    "aliases": [
      "loban agarbatti",
      "loban incense sticks"
    ],
    "brands": [
      "Cycle Pure",
      "Mangaldeep"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pooja_pure_kumkum_roli_vermillion_jar_100g",
    "name": "Pooja Pure Kumkum Roli Vermillion Jar 100g",
    "tamilName": "பூஜை ரோலி குங்குமம் (100 கிராம்)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Kumkum",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "roli kumkum jar",
      "pooja roli vermillion"
    ],
    "aliases": [
      "roli kumkum jar",
      "pooja roli vermillion"
    ],
    "brands": [
      "Cycle Roli",
      "Gopuram"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pooja_scented_chandan_tika_paste_tube_50g",
    "name": "Pooja Scented Chandan Tika Paste Tube 50g",
    "tamilName": "சந்தன திலகம் பேஸ்ட் (50 கிராம்)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Chandanam",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 50.0,
    "customQuantities": [
      50.0
    ],
    "commonNames": [
      "chandan tika tube",
      "sandalwood paste tube"
    ],
    "aliases": [
      "chandan tika tube",
      "sandalwood paste tube"
    ],
    "brands": [
      "Kasturi Chandan",
      "Cycle"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pooja_sacred_holy_thread_yellow_mauli_roll",
    "name": "Pooja Sacred Holy Thread Yellow Mauli Roll",
    "tamilName": "மஞ்சள் காப்பு கயிறு ரோல்",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Holy Thread",
    "defaultUnit": "roll",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "yellow mauli roll",
      "manjal kaapu kayiru"
    ],
    "aliases": [
      "yellow mauli roll",
      "manjal kaapu kayiru"
    ],
    "brands": [
      "Temple Stores"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pooja_brass_single_diya_stand_6_inch",
    "name": "Pooja Brass Single Diya Stand 6 Inch",
    "tamilName": "பித்தளை ஒற்றை விளக்கு (6 இன்ச்)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Utensils",
    "productType": "Diya Stand",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "brass diya 6 inch",
      "kuthuvilakku single 6 inch"
    ],
    "aliases": [
      "brass diya 6 inch",
      "kuthuvilakku single 6 inch"
    ],
    "brands": [
      "Local Brass Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pooja_brass_single_diya_stand_8_inch",
    "name": "Pooja Brass Single Diya Stand 8 Inch",
    "tamilName": "பித்தளை ஒற்றை விளக்கு (8 இன்ச்)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Utensils",
    "productType": "Diya Stand",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "brass diya 8 inch",
      "kuthuvilakku single 8 inch"
    ],
    "aliases": [
      "brass diya 8 inch",
      "kuthuvilakku single 8 inch"
    ],
    "brands": [
      "Local Brass Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pooja_brass_panchamrit_offering_cup_set_5_cups",
    "name": "Pooja Brass Panchamrit Offering Cup Set 5 Cups",
    "tamilName": "பித்தளை பஞ்சாமிர்த கிண்ணங்கள் (5 எண்ணிக்கை)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Utensils",
    "productType": "Utensil Set",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 5.0,
    "customQuantities": [
      5.0
    ],
    "commonNames": [
      "panchamrit cups brass",
      "pooja offering bowls"
    ],
    "aliases": [
      "panchamrit cups brass",
      "pooja offering bowls"
    ],
    "brands": [
      "Local Brass Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pooja_brass_handheld_camphor_aarti_deepam",
    "name": "Pooja Brass Handheld Camphor Aarti Deepam",
    "tamilName": "பித்தளை ஒற்றை கற்பூர தீபாராதனை தட்டு",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Utensils",
    "productType": "Aarti",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "brass single aarti deepam",
      "ek aarti brass"
    ],
    "aliases": [
      "brass single aarti deepam",
      "ek aarti brass"
    ],
    "brands": [
      "Local Brass Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pooja_brass_ashtalakshmi_diya_oil_lamp",
    "name": "Pooja Brass Ashtalakshmi Diya Oil Lamp",
    "tamilName": "அஷ்டலட்சுமி விளக்கு (பித்தளை)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Utensils",
    "productType": "Diya",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "ashtalakshmi vilakku",
      "ashtalakshmi diya brass"
    ],
    "aliases": [
      "ashtalakshmi vilakku",
      "ashtalakshmi diya brass"
    ],
    "brands": [
      "Local Brass Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pooja_brass_peacock_diya_single_wick_mayil_vilakku",
    "name": "Pooja Brass Peacock Diya Single Wick Mayil Vilakku",
    "tamilName": "பித்தளை மயில் விளக்கு",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Utensils",
    "productType": "Diya",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "mayil vilakku",
      "peacock brass diya"
    ],
    "aliases": [
      "mayil vilakku",
      "peacock brass diya"
    ],
    "brands": [
      "Local Brass Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pooja_brass_elephant_deepam_yanai_vilakku",
    "name": "Pooja Brass Elephant Deepam Yanai Vilakku",
    "tamilName": "பித்தளை யானை விளக்கு",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Utensils",
    "productType": "Diya",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "yanai vilakku",
      "elephant brass diya"
    ],
    "aliases": [
      "yanai vilakku",
      "elephant brass diya"
    ],
    "brands": [
      "Local Brass Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  }
]"""

def get_matrix_catalog_part3():
    return json.loads(_DATA)

if __name__ == "__main__":
    items = get_matrix_catalog_part3()
    print(f"Loaded {len(items)} matrix expansion part 3 items.")
