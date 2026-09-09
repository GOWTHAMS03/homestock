# -*- coding: utf-8 -*-
"""
Matrix Catalog Expansion Part 2: Contains 117 culturally authentic,
normalized household products for Indian / Tamil Nadu households.
"""
import json

_DATA = r"""[
  {
    "id": "kanchipuram_idli_mix_spiced",
    "name": "Kanchipuram Idli Mix Spiced",
    "tamilName": "காஞ்சிபுரம் இட்லி மிக்ஸ்",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Breakfast & Mixes",
    "productType": "Instant Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "kanchipuram idli mix",
      "spiced idli mix"
    ],
    "aliases": [
      "kanchipuram idli mix",
      "spiced idli mix"
    ],
    "brands": [
      "MTR",
      "Aachi",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "rava_dosa_instant_mix",
    "name": "Rava Dosa Instant Mix",
    "tamilName": "ரவா தோசை மிக்ஸ்",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Breakfast & Mixes",
    "productType": "Instant Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "rava dosa mix",
      "sooji dosa mix"
    ],
    "aliases": [
      "rava dosa mix",
      "sooji dosa mix"
    ],
    "brands": [
      "MTR",
      "Aachi",
      "Priya"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "oats_dosa_instant_healthy_mix",
    "name": "Oats Dosa Instant Healthy Mix",
    "tamilName": "ஓட்ஸ் தோசை மிக்ஸ்",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Breakfast & Mixes",
    "productType": "Instant Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "oats dosa mix"
    ],
    "aliases": [
      "oats dosa mix"
    ],
    "brands": [
      "MTR",
      "Aashirvaad"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "multi_millet_idli_instant_mix",
    "name": "Multi Millet Idli Instant Mix",
    "tamilName": "சிறுதானிய இட்லி மிக்ஸ்",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Breakfast & Mixes",
    "productType": "Instant Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "millet idli mix"
    ],
    "aliases": [
      "millet idli mix"
    ],
    "brands": [
      "Gramiyum",
      "Millet Magic"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "neer_dosa_instant_rice_mix",
    "name": "Neer Dosa Instant Rice Mix",
    "tamilName": "நீர் தோசை மிக்ஸ்",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Breakfast & Mixes",
    "productType": "Instant Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "neer dosa mix"
    ],
    "aliases": [
      "neer dosa mix"
    ],
    "brands": [
      "MTR",
      "Eastern"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "sweet_spicy_kuzhi_paniyaram_mix",
    "name": "Sweet & Spicy Kuzhi Paniyaram Mix",
    "tamilName": "குழி பணியாரம் மிக்ஸ்",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Breakfast & Mixes",
    "productType": "Instant Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "paniyaram mix",
      "kuzhi paniyaram"
    ],
    "aliases": [
      "paniyaram mix",
      "kuzhi paniyaram"
    ],
    "brands": [
      "Aachi",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "crispy_medu_vada_instant_mix",
    "name": "Crispy Medu Vada Instant Mix",
    "tamilName": "மெது வடை மிக்ஸ்",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Breakfast & Mixes",
    "productType": "Instant Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "medu vada mix",
      "urad vada mix"
    ],
    "aliases": [
      "medu vada mix",
      "urad vada mix"
    ],
    "brands": [
      "MTR",
      "Aachi",
      "Gits"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "masala_vada_instant_dal_mix",
    "name": "Masala Vada Instant Dal Mix",
    "tamilName": "மசால் வடை மிக்ஸ்",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Breakfast & Mixes",
    "productType": "Instant Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "masala vada mix",
      "chana dal vada mix"
    ],
    "aliases": [
      "masala vada mix",
      "chana dal vada mix"
    ],
    "brands": [
      "Aachi",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "rice_sevai_string_hoppers_plain",
    "name": "Rice Sevai String Hoppers Plain",
    "tamilName": "அரிசி சேவை",
    "category": "Food & Grocery",
    "subCategory": "Noodles & Vermicelli",
    "productType": "Sevai",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 400.0,
    "customQuantities": [
      200.0,
      400.0,
      500.0
    ],
    "commonNames": [
      "rice sevai",
      "idiyappam sevai",
      "arisi sevai"
    ],
    "aliases": [
      "rice sevai",
      "idiyappam sevai",
      "arisi sevai"
    ],
    "brands": [
      "Anil Rice Sevai",
      "Concord",
      "Naga"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "ragi_sevai_finger_millet_vermicelli",
    "name": "Ragi Sevai Finger Millet Vermicelli",
    "tamilName": "கேழ்வரகு சேவை",
    "category": "Food & Grocery",
    "subCategory": "Noodles & Vermicelli",
    "productType": "Sevai",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 400.0,
    "customQuantities": [
      200.0,
      400.0
    ],
    "commonNames": [
      "ragi sevai",
      "kezhvaragu sevai"
    ],
    "aliases": [
      "ragi sevai",
      "kezhvaragu sevai"
    ],
    "brands": [
      "Anil Ragi Sevai",
      "Concord"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "wheat_sevai_whole_wheat_vermicelli",
    "name": "Wheat Sevai Whole Wheat Vermicelli",
    "tamilName": "கோதுமை சேவை",
    "category": "Food & Grocery",
    "subCategory": "Noodles & Vermicelli",
    "productType": "Sevai",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 400.0,
    "customQuantities": [
      200.0,
      400.0
    ],
    "commonNames": [
      "wheat sevai",
      "godhumai sevai"
    ],
    "aliases": [
      "wheat sevai",
      "godhumai sevai"
    ],
    "brands": [
      "Anil Wheat Sevai",
      "Naga"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "lemon_rice_sevai_instant_seasoning_mix",
    "name": "Lemon Rice Sevai Instant Seasoning Mix",
    "tamilName": "எலுமிச்சை சேவை மிக்ஸ்",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Breakfast & Mixes",
    "productType": "Instant Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "lemon sevai mix"
    ],
    "aliases": [
      "lemon sevai mix"
    ],
    "brands": [
      "Anil",
      "MTR"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "tomato_sevai_instant_seasoning_mix",
    "name": "Tomato Sevai Instant Seasoning Mix",
    "tamilName": "தக்காளி சேவை மிக்ஸ்",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Breakfast & Mixes",
    "productType": "Instant Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "tomato sevai mix"
    ],
    "aliases": [
      "tomato sevai mix"
    ],
    "brands": [
      "Anil",
      "MTR"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "pepper_jeera_rice_sevai_mix",
    "name": "Pepper Jeera Rice Sevai Mix",
    "tamilName": "மிளகு சீரக சேவை மிக்ஸ்",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Breakfast & Mixes",
    "productType": "Instant Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "pepper sevai mix"
    ],
    "aliases": [
      "pepper sevai mix"
    ],
    "brands": [
      "Anil",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "sweet_achu_murukku_rose_cookies",
    "name": "Sweet Achu Murukku Rose Cookies",
    "tamilName": "அச்சு முறுக்கு (ரோஸ் குக்கீஸ்)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Snacks",
    "productType": "Murukku",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 10.0,
    "customQuantities": [
      10.0,
      20.0
    ],
    "commonNames": [
      "achu murukku",
      "rose cookies sweet"
    ],
    "aliases": [
      "achu murukku",
      "rose cookies sweet"
    ],
    "brands": [
      "Grand Sweets",
      "A2B",
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
    "id": "garlic_kara_sevu_spicy",
    "name": "Garlic Kara Sevu Spicy",
    "tamilName": "பூண்டு காராசேவு",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Snacks",
    "productType": "Namkeen",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "poondu kara sevu",
      "garlic sev"
    ],
    "aliases": [
      "poondu kara sevu",
      "garlic sev"
    ],
    "brands": [
      "Shanmuganadar",
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
    "id": "pepper_kara_sevu_spicy",
    "name": "Pepper Kara Sevu Spicy",
    "tamilName": "மிளகு காராசேவு",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Snacks",
    "productType": "Namkeen",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "milagu sevu",
      "black pepper sev"
    ],
    "aliases": [
      "milagu sevu",
      "black pepper sev"
    ],
    "brands": [
      "Shanmuganadar",
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
    "id": "instant_mysore_bonda_flour_mix",
    "name": "Instant Mysore Bonda Flour Mix",
    "tamilName": "மைசூர் போண்டா மிக்ஸ்",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Breakfast & Mixes",
    "productType": "Instant Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "mysore bonda mix"
    ],
    "aliases": [
      "mysore bonda mix"
    ],
    "brands": [
      "Aachi",
      "MTR"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "kerala_guruvayur_special_pappadam_pack",
    "name": "Kerala Guruvayur Special Pappadam Pack",
    "tamilName": "குருவாயூர் ஸ்பெஷல் பப்படம்",
    "category": "Food & Grocery",
    "subCategory": "Vathal & Papad",
    "productType": "Appalam",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 20.0,
    "customQuantities": [
      10.0,
      20.0
    ],
    "commonNames": [
      "guruvayur pappadam",
      "kerala pappadam"
    ],
    "aliases": [
      "guruvayur pappadam",
      "kerala pappadam"
    ],
    "brands": [
      "Double Horse",
      "Guruvayur Pappadam"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "staple"
  },
  {
    "id": "crispy_rice_appalam_arisi_appalam",
    "name": "Crispy Rice Appalam Arisi Appalam",
    "tamilName": "அரிசி அப்பளம்",
    "category": "Food & Grocery",
    "subCategory": "Vathal & Papad",
    "productType": "Appalam",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 20.0,
    "customQuantities": [
      10.0,
      20.0
    ],
    "commonNames": [
      "arisi appalam",
      "rice papad"
    ],
    "aliases": [
      "arisi appalam",
      "rice papad"
    ],
    "brands": [
      "Ambika Appalam",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "staple"
  },
  {
    "id": "sun_dried_tapioca_maravalli_papad",
    "name": "Sun Dried Tapioca Maravalli Papad",
    "tamilName": "மரவள்ளிக்கிழங்கு அப்பளம்",
    "category": "Food & Grocery",
    "subCategory": "Vathal & Papad",
    "productType": "Appalam",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "maravalli appalam",
      "tapioca papad"
    ],
    "aliases": [
      "maravalli appalam",
      "tapioca papad"
    ],
    "brands": [
      "Salem Artisans",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "staple"
  },
  {
    "id": "spicy_potato_papad_aloo_papad",
    "name": "Spicy Potato Papad Aloo Papad",
    "tamilName": "உருளைக்கிழங்கு அப்பளம்",
    "category": "Food & Grocery",
    "subCategory": "Vathal & Papad",
    "productType": "Appalam",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "aloo papad",
      "potato papad"
    ],
    "aliases": [
      "aloo papad",
      "potato papad"
    ],
    "brands": [
      "Haldiram's",
      "Bikaji",
      "Local"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "staple"
  },
  {
    "id": "moong_dal_papad_bikaneri",
    "name": "Moong Dal Papad Bikaneri",
    "tamilName": "பாசிப்பருப்பு பப்படம் (பிகானேரி)",
    "category": "Food & Grocery",
    "subCategory": "Vathal & Papad",
    "productType": "Appalam",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "moong dal papad",
      "lijjat moong"
    ],
    "aliases": [
      "moong dal papad",
      "lijjat moong"
    ],
    "brands": [
      "Lijjat Moong Papad",
      "Bikaji",
      "Haldiram's"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "staple"
  },
  {
    "id": "lijjat_urad_dal_garlic_papad",
    "name": "Lijjat Urad Dal Garlic Papad",
    "tamilName": "லிஜ்ஜத் பூண்டு அப்பளம்",
    "category": "Food & Grocery",
    "subCategory": "Vathal & Papad",
    "productType": "Appalam",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "lijjat garlic papad",
      "poondu appalam"
    ],
    "aliases": [
      "lijjat garlic papad",
      "poondu appalam"
    ],
    "brands": [
      "Lijjat Garlic Papad"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "staple"
  },
  {
    "id": "lijjat_punjabi_masala_papad_spicy",
    "name": "Lijjat Punjabi Masala Papad Spicy",
    "tamilName": "லிஜ்ஜத் பஞ்சாபி மசாலா அப்பளம்",
    "category": "Food & Grocery",
    "subCategory": "Vathal & Papad",
    "productType": "Appalam",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "lijjat punjabi masala",
      "masala papad"
    ],
    "aliases": [
      "lijjat punjabi masala",
      "masala papad"
    ],
    "brands": [
      "Lijjat Masala Papad"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "staple"
  },
  {
    "id": "andhra_spicy_gongura_nilva_pachadi",
    "name": "Andhra Spicy Gongura Nilva Pachadi",
    "tamilName": "ஆந்திரா கோங்குரா ஊறுகாய்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Pickle",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0,
      500.0
    ],
    "commonNames": [
      "gongura pickle",
      "andhra gongura pachadi"
    ],
    "aliases": [
      "gongura pickle",
      "andhra gongura pachadi"
    ],
    "brands": [
      "Priya Gongura",
      "Mother's Recipe",
      "Ruchi"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "andhra_avakaya_spicy_mango_pickle",
    "name": "Andhra Avakaya Spicy Mango Pickle",
    "tamilName": "ஆந்திரா ஆவக்காய் மாங்காய் ஊறுகாய்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Pickle",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0,
      500.0,
      1000.0
    ],
    "commonNames": [
      "avakaya pickle",
      "andhra avakaya mango"
    ],
    "aliases": [
      "avakaya pickle",
      "andhra avakaya mango"
    ],
    "brands": [
      "Priya Avakaya",
      "Ruchi",
      "Mother's Recipe"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "bellam_avakaya_sweet_jaggery_mango_pickle",
    "name": "Bellam Avakaya Sweet Jaggery Mango Pickle",
    "tamilName": "பெல்லம் ஆவக்காய் (வெல்ல மாங்காய் ஊறுகாய்)",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Pickle",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0
    ],
    "commonNames": [
      "bellam avakaya",
      "sweet avakaya pickle"
    ],
    "aliases": [
      "bellam avakaya",
      "sweet avakaya pickle"
    ],
    "brands": [
      "Priya",
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
    "id": "magaya_sun_dried_mango_pickle",
    "name": "Magaya Sun Dried Mango Pickle",
    "tamilName": "மகா ஆவக்காய் (உலர்ந்த மாங்காய்)",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Pickle",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0
    ],
    "commonNames": [
      "magaya pickle",
      "magai pachadi"
    ],
    "aliases": [
      "magaya pickle",
      "magai pachadi"
    ],
    "brands": [
      "Priya Magaya",
      "Ruchi"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "usirikaya_amla_gooseberry_pickle",
    "name": "Usirikaya Amla Gooseberry Pickle",
    "tamilName": "உசிரிகாயா நெல்லிக்காய் ஊறுகாய்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Pickle",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0,
      500.0
    ],
    "commonNames": [
      "usirikaya pickle",
      "amla pickle andhra"
    ],
    "aliases": [
      "usirikaya pickle",
      "amla pickle andhra"
    ],
    "brands": [
      "Priya Usirikaya",
      "Mother's Recipe"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "pandu_mirapakaya_ripe_red_chilli_pickle",
    "name": "Pandu Mirapakaya Ripe Red Chilli Pickle",
    "tamilName": "பண்டு மிரப்பகாயா சிவப்பு மிளகாய் ஊறுகாய்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Pickle",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0
    ],
    "commonNames": [
      "pandu mirapakaya",
      "red chilli pickle andhra"
    ],
    "aliases": [
      "pandu mirapakaya",
      "red chilli pickle andhra"
    ],
    "brands": [
      "Priya",
      "Ruchi"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "chintakaya_raw_tamarind_pachadi",
    "name": "Chintakaya Raw Tamarind Pachadi",
    "tamilName": "சிந்தகாயா புளி ஊறுகாய்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Pickle",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0
    ],
    "commonNames": [
      "chintakaya pickle",
      "raw tamarind chutney"
    ],
    "aliases": [
      "chintakaya pickle",
      "raw tamarind chutney"
    ],
    "brands": [
      "Priya",
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
    "id": "nimmakaya_traditional_lemon_pickle",
    "name": "Nimmakaya Traditional Lemon Pickle",
    "tamilName": "நிம்மகாயா எலுமிச்சை ஊறுகாய்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Pickle",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0,
      500.0
    ],
    "commonNames": [
      "nimmakaya pickle",
      "lemon pickle spicy"
    ],
    "aliases": [
      "nimmakaya pickle",
      "lemon pickle spicy"
    ],
    "brands": [
      "Priya",
      "Ruchi",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "dabbakaya_citron_whole_fruit_pickle",
    "name": "Dabbakaya Citron Whole Fruit Pickle",
    "tamilName": "டப்பகாயா நார்த்தங்காய் ஊறுகாய்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Pickle",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0
    ],
    "commonNames": [
      "dabbakaya pickle",
      "citron pickle andhra"
    ],
    "aliases": [
      "dabbakaya pickle",
      "citron pickle andhra"
    ],
    "brands": [
      "Priya",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "spicy_tomato_garlic_pickle",
    "name": "Spicy Tomato Garlic Pickle",
    "tamilName": "தக்காளி பூண்டு ஊறுகாய்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Pickle",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0,
      500.0
    ],
    "commonNames": [
      "tomato garlic pickle",
      "thakkali poondu oorugai"
    ],
    "aliases": [
      "tomato garlic pickle",
      "thakkali poondu oorugai"
    ],
    "brands": [
      "Priya",
      "Ruchi",
      "Mother's Recipe"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "garlic_ginger_mixed_spicy_pickle",
    "name": "Garlic Ginger Mixed Spicy Pickle",
    "tamilName": "இஞ்சி பூண்டு ஊறுகாய்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Pickle",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0
    ],
    "commonNames": [
      "ginger garlic pickle",
      "inji poondu oorugai"
    ],
    "aliases": [
      "ginger garlic pickle",
      "inji poondu oorugai"
    ],
    "brands": [
      "Mother's Recipe",
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
    "id": "kakarakaya_bitter_gourd_pickle",
    "name": "Kakarakaya Bitter Gourd Pickle",
    "tamilName": "பாகற்காய் ஊறுகாய்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Pickle",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0
    ],
    "commonNames": [
      "bitter gourd pickle",
      "karela pickle",
      "pavakkai oorugai"
    ],
    "aliases": [
      "bitter gourd pickle",
      "karela pickle",
      "pavakkai oorugai"
    ],
    "brands": [
      "Priya Kakarakaya",
      "Ruchi"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "maavadu_tender_baby_mango_pickle",
    "name": "Maavadu Tender Baby Mango Pickle",
    "tamilName": "மாவடு (சிறிய பிஞ்சு மாங்காய் ஊறுகாய்)",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Pickle",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0,
      500.0
    ],
    "commonNames": [
      "maavadu",
      "vadumangai",
      "baby mango pickle"
    ],
    "aliases": [
      "maavadu",
      "vadumangai",
      "baby mango pickle"
    ],
    "brands": [
      "Grand Sweets",
      "Ruchi",
      "Ambika"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "green_chilli_pachai_milagai_pickle",
    "name": "Green Chilli Pachai Milagai Pickle",
    "tamilName": "பச்சை மிளகாய் ஊறுகாய்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Pickle",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0
    ],
    "commonNames": [
      "green chilli pickle",
      "hari mirch pickle"
    ],
    "aliases": [
      "green chilli pickle",
      "hari mirch pickle"
    ],
    "brands": [
      "Mother's Recipe",
      "Priya",
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
    "id": "mixed_vegetable_traditional_pickle",
    "name": "Mixed Vegetable Traditional Pickle",
    "tamilName": "கலவை காய் ஊறுகாய்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Pickle",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0,
      500.0
    ],
    "commonNames": [
      "mixed veg pickle",
      "pacharanga pickle"
    ],
    "aliases": [
      "mixed veg pickle",
      "pacharanga pickle"
    ],
    "brands": [
      "Mother's Recipe",
      "Priya",
      "Ruchi",
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
    "id": "sweet_gujarati_mango_chunda",
    "name": "Sweet Gujarati Mango Chunda",
    "tamilName": "குஜராத்தி மாங்காய் சுண்டா",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Sweet Pickle",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0
    ],
    "commonNames": [
      "chunda",
      "sweet mango pickle"
    ],
    "aliases": [
      "chunda",
      "sweet mango pickle"
    ],
    "brands": [
      "Mother's Recipe Chunda",
      "Bedekar"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "sweet_lime_chutney_gor_keri",
    "name": "Sweet Lime Chutney Gor Keri",
    "tamilName": "இனிப்பு எலுமிச்சை சட்னி",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Sweet Pickle",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0
    ],
    "commonNames": [
      "sweet lime chutney",
      "gor keri"
    ],
    "aliases": [
      "sweet lime chutney",
      "gor keri"
    ],
    "brands": [
      "Mother's Recipe",
      "Bedekar"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "tamarind_date_sweet_chutney_saunth",
    "name": "Tamarind Date Sweet Chutney Saunth",
    "tamilName": "புளி பேரீச்சம்பழ இனிப்பு சட்னி",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Chutney",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0
    ],
    "commonNames": [
      "tamarind date chutney",
      "saunth sweet chutney"
    ],
    "aliases": [
      "tamarind date chutney",
      "saunth sweet chutney"
    ],
    "brands": [
      "Mother's Recipe",
      "Haldiram's",
      "Veeba"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "mint_coriander_spicy_green_chutney",
    "name": "Mint Coriander Spicy Green Chutney",
    "tamilName": "புதினா கொத்தமல்லி பச்சை சட்னி",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Chutney",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0
    ],
    "commonNames": [
      "green chutney",
      "hari chutney sandwich"
    ],
    "aliases": [
      "green chutney",
      "hari chutney sandwich"
    ],
    "brands": [
      "Mother's Recipe",
      "Veeba",
      "Haldiram's"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "dry_garlic_chutney_lasun_chutney_for_vada_pav",
    "name": "Dry Garlic Chutney Lasun Chutney for Vada Pav",
    "tamilName": "உலர் பூண்டு சட்னி (வடா பாவ்)",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Chutney Powder",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "dry garlic chutney",
      "vada pav chutney"
    ],
    "aliases": [
      "dry garlic chutney",
      "vada pav chutney"
    ],
    "brands": [
      "Suhana",
      "K-Praveen",
      "Mother's Recipe"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "schezwan_spicy_dip_chutney",
    "name": "Schezwan Spicy Dip Chutney",
    "tamilName": "செஷ்வான் சட்னி",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Chutney",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0
    ],
    "commonNames": [
      "schezwan chutney",
      "schezwan sauce"
    ],
    "aliases": [
      "schezwan chutney",
      "schezwan sauce"
    ],
    "brands": [
      "Ching's Secret",
      "Veeba"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "tamarind_concentrated_cooking_paste",
    "name": "Tamarind Concentrated Cooking Paste",
    "tamilName": "புளி பேஸ்ட் (சமையல்)",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Cooking Paste",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      400.0
    ],
    "commonNames": [
      "tamarind paste",
      "imli paste"
    ],
    "aliases": [
      "tamarind paste",
      "imli paste"
    ],
    "brands": [
      "Dabur Hommade",
      "Priya",
      "Eastern"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "ginger_pure_cooking_paste_inji_paste",
    "name": "Ginger Pure Cooking Paste Inji Paste",
    "tamilName": "இஞ்சி பேஸ்ட்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Cooking Paste",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "ginger paste",
      "adrak paste"
    ],
    "aliases": [
      "ginger paste",
      "adrak paste"
    ],
    "brands": [
      "Dabur Hommade",
      "Mother's Recipe",
      "Eastern"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "garlic_pure_cooking_paste_poondu_paste",
    "name": "Garlic Pure Cooking Paste Poondu Paste",
    "tamilName": "பூண்டு பேஸ்ட்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Cooking Paste",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "garlic paste",
      "lahsun paste"
    ],
    "aliases": [
      "garlic paste",
      "lahsun paste"
    ],
    "brands": [
      "Dabur Hommade",
      "Mother's Recipe",
      "Eastern"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "ginger_garlic_combined_cooking_paste",
    "name": "Ginger Garlic Combined Cooking Paste",
    "tamilName": "இஞ்சி பூண்டு பேஸ்ட்",
    "category": "Pickles, Sauces & Condiments",
    "subCategory": "Pickles & Sauces",
    "productType": "Cooking Paste",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0,
      500.0
    ],
    "commonNames": [
      "ginger garlic paste",
      "adrak lahsun paste"
    ],
    "aliases": [
      "ginger garlic paste",
      "adrak lahsun paste"
    ],
    "brands": [
      "Dabur Hommade",
      "Mother's Recipe",
      "Tata Sampann",
      "Eastern"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "condiment"
  },
  {
    "id": "whole_dried_figs_dried_anjeer",
    "name": "Whole Dried Figs Dried Anjeer",
    "tamilName": "உலர் அத்திப்பழம் (அஞ்சீர்)",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Dried Fruit",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      200.0,
      250.0,
      500.0
    ],
    "commonNames": [
      "anjeer",
      "dried figs",
      "athi pazham dry"
    ],
    "aliases": [
      "anjeer",
      "dried figs",
      "athi pazham dry"
    ],
    "brands": [
      "Happilo",
      "Nutraj",
      "Tulsi"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "dried_turkish_apricots_jardalu",
    "name": "Dried Turkish Apricots Jardalu",
    "tamilName": "உலர் பாதாமி (ஆப்ரிகாட்)",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Dried Fruit",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "dried apricots",
      "jardalu",
      "khubani"
    ],
    "aliases": [
      "dried apricots",
      "jardalu",
      "khubani"
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
    "id": "dried_cranberries_sweetened",
    "name": "Dried Cranberries Sweetened",
    "tamilName": "உலர் கிரான்பெர்ரி",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Dried Fruit",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "dried cranberries"
    ],
    "aliases": [
      "dried cranberries"
    ],
    "brands": [
      "Happilo",
      "True Elements"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "dried_blueberries_wild",
    "name": "Dried Blueberries Wild",
    "tamilName": "உலர் புளூபெர்ரி",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Dried Fruit",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 150.0,
    "customQuantities": [
      150.0
    ],
    "commonNames": [
      "dried blueberries"
    ],
    "aliases": [
      "dried blueberries"
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
    "id": "black_raisins_seedless_kismis",
    "name": "Black Raisins Seedless Kismis",
    "tamilName": "கருப்பு உலர் திராட்சை",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Raisins",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      200.0,
      250.0,
      500.0
    ],
    "commonNames": [
      "black raisins",
      "karuppu drakshai dry"
    ],
    "aliases": [
      "black raisins",
      "karuppu drakshai dry"
    ],
    "brands": [
      "Happilo",
      "Nutraj",
      "BB Royal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "golden_long_raisins_kismis",
    "name": "Golden Long Raisins Kismis",
    "tamilName": "தங்க உலர் திராட்சை (கிஸ்மிஸ்)",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Raisins",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      200.0,
      250.0,
      500.0
    ],
    "commonNames": [
      "golden raisins",
      "kismis",
      "drakshai dry"
    ],
    "aliases": [
      "golden raisins",
      "kismis",
      "drakshai dry"
    ],
    "brands": [
      "Happilo",
      "Nutraj",
      "Tata Sampann"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "roasted_salted_pistachios_in_shell_pista",
    "name": "Roasted Salted Pistachios In Shell Pista",
    "tamilName": "வறுத்த உப்பு பிஸ்தா (தோலுடன்)",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Pistachios",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "salted pistachios",
      "roasted pista"
    ],
    "aliases": [
      "salted pistachios",
      "roasted pista"
    ],
    "brands": [
      "Happilo",
      "Nutraj",
      "Tulsi"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "raw_pistachio_kernels_pista_green",
    "name": "Raw Pistachio Kernels Pista Green",
    "tamilName": "பச்சை பிஸ்தா பருப்பு",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Pistachios",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      250.0
    ],
    "commonNames": [
      "pista kernels",
      "green pista raw"
    ],
    "aliases": [
      "pista kernels",
      "green pista raw"
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
    "id": "chilean_whole_walnuts_in_shell_akhrot",
    "name": "Chilean Whole Walnuts In Shell Akhrot",
    "tamilName": "அக்ரூட் பருப்பு (தோலுடன்)",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Walnuts",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "walnuts with shell",
      "akhrot sabut"
    ],
    "aliases": [
      "walnuts with shell",
      "akhrot sabut"
    ],
    "brands": [
      "Nutraj",
      "Happilo"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "walnut_kernels_halves_akhrot_giri",
    "name": "Walnut Kernels Halves Akhrot Giri",
    "tamilName": "அக்ரூட் பருப்பு (உடைத்தது)",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Walnuts",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      200.0,
      250.0,
      500.0
    ],
    "commonNames": [
      "walnut kernels",
      "akhrot giri"
    ],
    "aliases": [
      "walnut kernels",
      "akhrot giri"
    ],
    "brands": [
      "Happilo",
      "Nutraj",
      "Tata Sampann"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "california_whole_almonds_badam_giri",
    "name": "California Whole Almonds Badam Giri",
    "tamilName": "கலிபோர்னியா பாதாம் பருப்பு",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Almonds",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      200.0,
      500.0,
      1000.0
    ],
    "commonNames": [
      "california badam",
      "almond kernels"
    ],
    "aliases": [
      "california badam",
      "almond kernels"
    ],
    "brands": [
      "Happilo",
      "Nutraj",
      "Tata Sampann",
      "Tulsi"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "cashew_nuts_whole_w240_premium_kaju",
    "name": "Cashew Nuts Whole W240 Premium Kaju",
    "tamilName": "முந்திரி பருப்பு W240 (பெரியது)",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Cashews",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "cashew w240",
      "kaju whole big",
      "munthiri"
    ],
    "aliases": [
      "cashew w240",
      "kaju whole big",
      "munthiri"
    ],
    "brands": [
      "Happilo",
      "Nutraj",
      "Tata Sampann"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "cashew_splits_tukda_kaju_for_cooking",
    "name": "Cashew Splits Tukda Kaju for Cooking",
    "tamilName": "முந்திரி துண்டு (சமையல் முந்திரி)",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Cashews",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "tukda kaju",
      "split cashews",
      "munthiri thundu"
    ],
    "aliases": [
      "tukda kaju",
      "split cashews",
      "munthiri thundu"
    ],
    "brands": [
      "BB Royal",
      "Local Mills"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "medjool_soft_black_dates_jumbo",
    "name": "Medjool Soft Black Dates Jumbo",
    "tamilName": "மெட்ஜூல் மென்மையான பேரீச்சம்பழம்",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Dates",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "medjool dates",
      "jumbo dates"
    ],
    "aliases": [
      "medjool dates",
      "jumbo dates"
    ],
    "brands": [
      "Happilo Medjool",
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
    "id": "kimia_soft_black_wet_dates_box",
    "name": "Kimia Soft Black Wet Dates Box",
    "tamilName": "கிமியா ஈர பேரீச்சம்பழம்",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Dates",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "kimia dates",
      "black soft dates"
    ],
    "aliases": [
      "kimia dates",
      "black soft dates"
    ],
    "brands": [
      "Kimia Dates",
      "Happilo",
      "Lion Dates"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "lion_seeded_desert_dates_pouch",
    "name": "Lion Seeded Desert Dates Pouch",
    "tamilName": "லயன் பேரீச்சம்பழம்",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Dates",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "lion dates",
      "desert dates"
    ],
    "aliases": [
      "lion dates",
      "desert dates"
    ],
    "brands": [
      "Lion Dates"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "thoodhuvalai_keerai_purple_pea_leaves",
    "name": "Thoodhuvalai Keerai Purple Pea Leaves",
    "tamilName": "தூதுவளை கீரை",
    "category": "Fresh Vegetables",
    "subCategory": "Greens & Herbs",
    "productType": "Keerai",
    "defaultUnit": "bunch",
    "soldBy": "piece",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "thoodhuvalai",
      "purple fruited pea leaves"
    ],
    "aliases": [
      "thoodhuvalai",
      "purple fruited pea leaves"
    ],
    "brands": [
      "Local Farmers"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "pirandai_veldt_grape_fresh_stem",
    "name": "Pirandai Veldt Grape Fresh Stem",
    "tamilName": "பிரண்டை (பச்சை தண்டு)",
    "category": "Fresh Vegetables",
    "subCategory": "Greens & Herbs",
    "productType": "Country Herb",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "pirandai stem",
      "adamant creeper fresh"
    ],
    "aliases": [
      "pirandai stem",
      "adamant creeper fresh"
    ],
    "brands": [
      "Local Farmers"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "sirukurinjan_keerai_gymnema_leaves",
    "name": "Sirukurinjan Keerai Gymnema Leaves",
    "tamilName": "சிறுகுறிஞ்சான் கீரை",
    "category": "Fresh Vegetables",
    "subCategory": "Greens & Herbs",
    "productType": "Keerai",
    "defaultUnit": "bunch",
    "soldBy": "piece",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "sirukurinjan",
      "gymnema leaves"
    ],
    "aliases": [
      "sirukurinjan",
      "gymnema leaves"
    ],
    "brands": [
      "Local Farmers"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "musumusukkai_keerai_herb_leaves",
    "name": "Musumusukkai Keerai Herb Leaves",
    "tamilName": "முசுமுசுக்கை கீரை",
    "category": "Fresh Vegetables",
    "subCategory": "Greens & Herbs",
    "productType": "Keerai",
    "defaultUnit": "bunch",
    "soldBy": "piece",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "musumusukkai"
    ],
    "aliases": [
      "musumusukkai"
    ],
    "brands": [
      "Local Farmers"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "kuppaimeni_keerai_acalypha_leaves",
    "name": "Kuppaimeni Keerai Acalypha Leaves",
    "tamilName": "குப்பைமேனி கீரை",
    "category": "Fresh Vegetables",
    "subCategory": "Greens & Herbs",
    "productType": "Keerai",
    "defaultUnit": "bunch",
    "soldBy": "piece",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "kuppaimeni",
      "acalypha indica"
    ],
    "aliases": [
      "kuppaimeni",
      "acalypha indica"
    ],
    "brands": [
      "Local Farmers"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "murungai_poo_drumstick_tree_blossom_flowers",
    "name": "Murungai Poo Drumstick Tree Blossom Flowers",
    "tamilName": "முருங்கைப்பூ",
    "category": "Fresh Vegetables",
    "subCategory": "Greens & Herbs",
    "productType": "Country Flower",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "murungai poo",
      "moringa flower"
    ],
    "aliases": [
      "murungai poo",
      "moringa flower"
    ],
    "brands": [
      "Local Farmers"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "spicy_country_ginger_nattu_inji",
    "name": "Spicy Country Ginger Nattu Inji",
    "tamilName": "நாட்டு இஞ்சி",
    "category": "Fresh Vegetables",
    "subCategory": "Daily Vegetables",
    "productType": "Ginger",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 0.25,
    "customQuantities": [
      0.25,
      0.5,
      1.0
    ],
    "commonNames": [
      "nattu inji",
      "country ginger",
      "desi adrak"
    ],
    "aliases": [
      "nattu inji",
      "country ginger",
      "desi adrak"
    ],
    "brands": [
      "Local Farmers"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "dosakaya_andhra_sambar_cucumber_yellow",
    "name": "Dosakaya Andhra Sambar Cucumber Yellow",
    "tamilName": "தோசக்காய் (மஞ்சள் வெள்ளரி)",
    "category": "Fresh Vegetables",
    "subCategory": "Daily Vegetables",
    "productType": "Cucumber",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "dosakaya",
      "yellow cucumber",
      "sambar vellarikkai"
    ],
    "aliases": [
      "dosakaya",
      "yellow cucumber",
      "sambar vellarikkai"
    ],
    "brands": [
      "Local Farmers"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "purple_cabbage_red_cabbage_head",
    "name": "Purple Cabbage Red Cabbage Head",
    "tamilName": "ஊதா முட்டைக்கோஸ்",
    "category": "Fresh Vegetables",
    "subCategory": "Daily Vegetables",
    "productType": "Vegetable",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5
    ],
    "commonNames": [
      "red cabbage",
      "purple cabbage"
    ],
    "aliases": [
      "red cabbage",
      "purple cabbage"
    ],
    "brands": [
      "Local Farmers"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "fresh_oyster_mushrooms_pack",
    "name": "Fresh Oyster Mushrooms Pack",
    "tamilName": "சிப்பி காளான்",
    "category": "Fresh Vegetables",
    "subCategory": "Daily Vegetables",
    "productType": "Mushrooms",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "oyster mushrooms",
      "sippi kaalan"
    ],
    "aliases": [
      "oyster mushrooms",
      "sippi kaalan"
    ],
    "brands": [
      "Local Growers"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "fresh_produce"
  },
  {
    "id": "red_radish_small_round",
    "name": "Red Radish Small Round",
    "tamilName": "சிவப்பு முள்ளங்கி",
    "category": "Fresh Vegetables",
    "subCategory": "Daily Vegetables",
    "productType": "Root Vegetable",
    "defaultUnit": "bunch",
    "soldBy": "piece",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "red radish",
      "lal mooli"
    ],
    "aliases": [
      "red radish",
      "lal mooli"
    ],
    "brands": [
      "Local Farmers"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "kiran_dark_green_sweet_watermelon",
    "name": "Kiran Dark Green Sweet Watermelon",
    "tamilName": "கிரண் தர்பூசணி (அடர் பச்சை)",
    "category": "Fresh Fruits",
    "subCategory": "Fresh Fruits",
    "productType": "Fruit",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "kiran watermelon",
      "dark watermelon"
    ],
    "aliases": [
      "kiran watermelon",
      "dark watermelon"
    ],
    "brands": [
      "Local Orchards"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "sun_melon_yellow_sweet_melon",
    "name": "Sun Melon Yellow Sweet Melon",
    "tamilName": "சன் மெலன் (மஞ்சள் கிர்ணி)",
    "category": "Fresh Fruits",
    "subCategory": "Fresh Fruits",
    "productType": "Fruit",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "sun melon",
      "yellow melon"
    ],
    "aliases": [
      "sun melon",
      "yellow melon"
    ],
    "brands": [
      "Local Orchards"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "robusta_green_cavendish_bananas",
    "name": "Robusta Green Cavendish Bananas",
    "tamilName": "பச்சை ரோபஸ்டா வாழைப்பழம்",
    "category": "Fresh Fruits",
    "subCategory": "Bananas",
    "productType": "Banana",
    "defaultUnit": "dozen",
    "soldBy": "piece",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 1.0,
    "customQuantities": [
      0.5,
      1.0,
      2.0
    ],
    "commonNames": [
      "robusta banana",
      "pachai vazhai"
    ],
    "aliases": [
      "robusta banana",
      "pachai vazhai"
    ],
    "brands": [
      "Local Farmers"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "dasheri_sweet_mango_lucknow",
    "name": "Dasheri Sweet Mango Lucknow",
    "tamilName": "தசாரி மாம்பழம்",
    "category": "Fresh Fruits",
    "subCategory": "Mangoes",
    "productType": "Mango",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "dasheri mango",
      "dussheri"
    ],
    "aliases": [
      "dasheri mango",
      "dussheri"
    ],
    "brands": [
      "Lucknow Orchards"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "langra_fragrant_green_mango_banaras",
    "name": "Langra Fragrant Green Mango Banaras",
    "tamilName": "லங்கரா மாம்பழம்",
    "category": "Fresh Fruits",
    "subCategory": "Mangoes",
    "productType": "Mango",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "langra mango"
    ],
    "aliases": [
      "langra mango"
    ],
    "brands": [
      "Banaras Orchards"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "kesar_saffron_fragrant_mango_gujarat",
    "name": "Kesar Saffron Fragrant Mango Gujarat",
    "tamilName": "கேசர் மாம்பழம்",
    "category": "Fresh Fruits",
    "subCategory": "Mangoes",
    "productType": "Mango",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "kesar mango",
      "gir kesar"
    ],
    "aliases": [
      "kesar mango",
      "gir kesar"
    ],
    "brands": [
      "Gir Orchards"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "bullock_s_heart_sweet_ramphal",
    "name": "Bullock's Heart Sweet Ramphal",
    "tamilName": "ராம்பழம் (ராம்பல்)",
    "category": "Fresh Fruits",
    "subCategory": "Fresh Fruits",
    "productType": "Fruit",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "ramphal",
      "bullocks heart"
    ],
    "aliases": [
      "ramphal",
      "bullocks heart"
    ],
    "brands": [
      "Local Orchards"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "arunellikai_small_star_gooseberry",
    "name": "Arunellikai Small Star Gooseberry",
    "tamilName": "அரை நெல்லிக்காய் (நட்சத்திர நெல்லி)",
    "category": "Fresh Fruits",
    "subCategory": "Fresh Fruits",
    "productType": "Amla",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "arunellikai",
      "star gooseberry"
    ],
    "aliases": [
      "arunellikai",
      "star gooseberry"
    ],
    "brands": [
      "Local Farmers"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "white_flesh_dragon_fruit_pitaya",
    "name": "White Flesh Dragon Fruit Pitaya",
    "tamilName": "டிராகன் பழம் (வெள்ளை)",
    "category": "Fresh Fruits",
    "subCategory": "Exotics",
    "productType": "Fruit",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "white dragon fruit"
    ],
    "aliases": [
      "white dragon fruit"
    ],
    "brands": [
      "Local Exotics"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "kashmiri_red_sweet_delicious_apples",
    "name": "Kashmiri Red Sweet Delicious Apples",
    "tamilName": "காஷ்மீரி ஆப்பிள்",
    "category": "Fresh Fruits",
    "subCategory": "Apples & Pears",
    "productType": "Apples",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 1.0,
    "customQuantities": [
      0.5,
      1.0,
      2.0
    ],
    "commonNames": [
      "kashmiri apple",
      "red apple shimla"
    ],
    "aliases": [
      "kashmiri apple",
      "red apple shimla"
    ],
    "brands": [
      "Kashmir Orchards",
      "Kinnaur"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "royal_gala_imported_sweet_apples",
    "name": "Royal Gala Imported Sweet Apples",
    "tamilName": "ராயல் காலா ஆப்பிள்",
    "category": "Fresh Fruits",
    "subCategory": "Apples & Pears",
    "productType": "Apples",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "royal gala apple"
    ],
    "aliases": [
      "royal gala apple"
    ],
    "brands": [
      "Washington",
      "New Zealand"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "fresh_produce"
  },
  {
    "id": "granny_smith_tangy_green_apples",
    "name": "Granny Smith Tangy Green Apples",
    "tamilName": "பச்சை ஆப்பிள் (கிரானி ஸ்மித்)",
    "category": "Fresh Fruits",
    "subCategory": "Apples & Pears",
    "productType": "Apples",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "green apple",
      "granny smith"
    ],
    "aliases": [
      "green apple",
      "granny smith"
    ],
    "brands": [
      "Imported Orchards"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "fresh_produce"
  },
  {
    "id": "indian_bartlett_babgusha_sweet_pears",
    "name": "Indian Bartlett Babgusha Sweet Pears",
    "tamilName": "பேரிக்காய் (பாபுகோஷா)",
    "category": "Fresh Fruits",
    "subCategory": "Apples & Pears",
    "productType": "Pears",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 1.0,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "babgusha pear",
      "indian pear",
      "perikkai"
    ],
    "aliases": [
      "babgusha pear",
      "indian pear",
      "perikkai"
    ],
    "brands": [
      "Himachal Orchards",
      "Kashmir"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "fresh_black_amber_plums",
    "name": "Fresh Black Amber Plums",
    "tamilName": "கருப்பு பிளம்ஸ் பழம்",
    "category": "Fresh Fruits",
    "subCategory": "Fresh Fruits",
    "productType": "Stone Fruit",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 500.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "black plums",
      "aloo bukhara fresh"
    ],
    "aliases": [
      "black plums",
      "aloo bukhara fresh"
    ],
    "brands": [
      "Himachal Orchards"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "fresh_purple_figs_anjeer",
    "name": "Fresh Purple Figs Anjeer",
    "tamilName": "பச்சை அத்திப்பழம் (அஞ்சீர்)",
    "category": "Fresh Fruits",
    "subCategory": "Fresh Fruits",
    "productType": "Figs",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "fresh anjeer",
      "fresh figs",
      "athi pazham fresh"
    ],
    "aliases": [
      "fresh anjeer",
      "fresh figs",
      "athi pazham fresh"
    ],
    "brands": [
      "Pune Orchards"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": false,
    "iconKey": "fresh_produce"
  },
  {
    "id": "dried_turmeric_whole_fingers_viral_manjal",
    "name": "Dried Turmeric Whole Fingers Viral Manjal",
    "tamilName": "விரலி மஞ்சள் கிழங்கு",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Turmeric",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      100.0,
      250.0,
      500.0
    ],
    "commonNames": [
      "viral manjal",
      "whole turmeric fingers",
      "haldi sabut"
    ],
    "aliases": [
      "viral manjal",
      "whole turmeric fingers",
      "haldi sabut"
    ],
    "brands": [
      "Gopuram",
      "Local Ayurvedic"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "round_turmeric_whole_bulbs_gundu_manjal",
    "name": "Round Turmeric Whole Bulbs Gundu Manjal",
    "tamilName": "குண்டு மஞ்சள் கிழங்கு",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Turmeric",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      100.0,
      250.0
    ],
    "commonNames": [
      "gundu manjal",
      "round turmeric bulb"
    ],
    "aliases": [
      "gundu manjal",
      "round turmeric bulb"
    ],
    "brands": [
      "Gopuram",
      "Local Ayurvedic"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pure_sandalwood_whole_log_chandan_lakdi",
    "name": "Pure Sandalwood Whole Log Chandan Lakdi",
    "tamilName": "சந்தனக் கட்டை",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Sandalwood",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "sandalwood stick",
      "chandan lakdi"
    ],
    "aliases": [
      "sandalwood stick",
      "chandan lakdi"
    ],
    "brands": [
      "Cauvery Handicrafts",
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
    "id": "stone_rubbing_slab_for_sandalwood_sanaikallu",
    "name": "Stone Rubbing Slab for Sandalwood Sanaikallu",
    "tamilName": "சானைக்கல் (சந்தனம் உரைக்க)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Rubbing Stone",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "sanaikallu",
      "chandan rubbing stone"
    ],
    "aliases": [
      "sanaikallu",
      "chandan rubbing stone"
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
    "id": "areca_nut_diamond_betel_chips_seval_paakku",
    "name": "Areca Nut Diamond Betel Chips Seval Paakku",
    "tamilName": "சீவல் பாக்கு",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Nut",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "seval paakku",
      "sliced supari"
    ],
    "aliases": [
      "seval paakku",
      "sliced supari"
    ],
    "brands": [
      "Gopuram",
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
    "id": "sacred_cotton_thread_janeu_poonal_pack_of_3",
    "name": "Sacred Cotton Thread Janeu Poonal Pack of 3",
    "tamilName": "பூணூல் (3 எண்ணிக்கை)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Holy Thread",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 3.0,
    "customQuantities": [
      3.0
    ],
    "commonNames": [
      "poonal",
      "janeu thread",
      "yajnopavita"
    ],
    "aliases": [
      "poonal",
      "janeu thread",
      "yajnopavita"
    ],
    "brands": [
      "Temple Stores",
      "Ganapathy Stores"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "sacred_wrist_protection_thread_mauli_kalava_red",
    "name": "Sacred Wrist Protection Thread Mauli Kalava Red",
    "tamilName": "காப்பு நூல் / மௌலி கயிறு",
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
      "mauli",
      "kalava",
      "kaapu nool"
    ],
    "aliases": [
      "mauli",
      "kalava",
      "kaapu nool"
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
    "id": "yellow_pure_cotton_pooja_cloth_piece_1_meter",
    "name": "Yellow Pure Cotton Pooja Cloth Piece 1 Meter",
    "tamilName": "மஞ்சள் பூஜை துணி (1 மீட்டர்)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Cloth",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "yellow pooja cloth",
      "manjal thuni"
    ],
    "aliases": [
      "yellow pooja cloth",
      "manjal thuni"
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
    "id": "red_pure_cotton_pooja_cloth_piece_1_meter",
    "name": "Red Pure Cotton Pooja Cloth Piece 1 Meter",
    "tamilName": "சிகப்பு பூஜை துணி (1 மீட்டர்)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Cloth",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "red pooja cloth",
      "sigappu thuni"
    ],
    "aliases": [
      "red pooja cloth",
      "sigappu thuni"
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
    "id": "pure_dry_desi_cow_dung_cakes_varatti_pack_5s",
    "name": "Pure Dry Desi Cow Dung Cakes Varatti Pack 5s",
    "tamilName": "நாட்டு மாட்டு வரட்டி (5 எண்ணிக்கை)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Homam Material",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 5.0,
    "customQuantities": [
      5.0,
      10.0
    ],
    "commonNames": [
      "varatti",
      "cow dung cake",
      "upla"
    ],
    "aliases": [
      "varatti",
      "cow dung cake",
      "upla"
    ],
    "brands": [
      "Gau Seva",
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
    "id": "dried_whole_copra_half_shell_sakkarai_thengai",
    "name": "Dried Whole Copra Half Shell Sakkarai Thengai",
    "tamilName": "கொப்பரைத் தேங்காய்",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Dravyam",
    "productType": "Dry Coconut",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "kopra",
      "sakkarai thengai",
      "dry coconut half"
    ],
    "aliases": [
      "kopra",
      "sakkarai thengai",
      "dry coconut half"
    ],
    "brands": [
      "Temple Stores",
      "Local Farmers"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "solid_brass_oil_diya_deepak_small",
    "name": "Solid Brass Oil Diya Deepak Small",
    "tamilName": "பித்தளை அகல் விளக்கு",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Utensils",
    "productType": "Diya",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "brass diya",
      "agal vilakku"
    ],
    "aliases": [
      "brass diya",
      "agal vilakku"
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
    "id": "solid_brass_camphor_aarti_burner_with_wooden_handle",
    "name": "Solid Brass Camphor Aarti Burner with Wooden Handle",
    "tamilName": "பித்தளை கற்பூர ஆரத்தி தட்டு",
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
      "camphor aarti",
      "karpoora aarti thaddu"
    ],
    "aliases": [
      "camphor aarti",
      "karpoora aarti thaddu"
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
    "id": "solid_brass_pooja_hand_bell_ghanti",
    "name": "Solid Brass Pooja Hand Bell Ghanti",
    "tamilName": "பித்தளை மணி (பூஜை)",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Pooja Utensils",
    "productType": "Bell",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "pooja bell",
      "brass ghanti",
      "mani"
    ],
    "aliases": [
      "pooja bell",
      "brass ghanti",
      "mani"
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
    "id": "nag_champa_heritage_agarbatti_sticks",
    "name": "Nag Champa Heritage Agarbatti Sticks",
    "tamilName": "நாக் சம்பா ஊதுபத்தி",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Camphor & Agarbatti",
    "productType": "Agarbatti",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 20.0,
    "customQuantities": [
      20.0,
      50.0
    ],
    "commonNames": [
      "nag champa agarbatti",
      "satya nag champa"
    ],
    "aliases": [
      "nag champa agarbatti",
      "satya nag champa"
    ],
    "brands": [
      "Satya Sai Baba Nag Champa"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pooja"
  },
  {
    "id": "pure_loban_resin_cups_for_pooja",
    "name": "Pure Loban Resin Cups for Pooja",
    "tamilName": "தூய லோபான் சாம்பிராணி கப்",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Camphor & Agarbatti",
    "productType": "Sambrani",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 12.0,
    "customQuantities": [
      12.0
    ],
    "commonNames": [
      "loban cups",
      "dhoop loban"
    ],
    "aliases": [
      "loban cups",
      "dhoop loban"
    ],
    "brands": [
      "Phool",
      "Cycle",
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
    "id": "pure_guggul_resin_cups_for_homam_aarti",
    "name": "Pure Guggul Resin Cups for Homam & Aarti",
    "tamilName": "தூய குக்குல் சாம்பிராணி கப்",
    "category": "Pooja & Spiritual Essentials",
    "subCategory": "Camphor & Agarbatti",
    "productType": "Sambrani",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pooja Shelf",
    "minimumQuantity": 12.0,
    "customQuantities": [
      12.0
    ],
    "commonNames": [
      "guggul cups",
      "guggal dhoop"
    ],
    "aliases": [
      "guggul cups",
      "guggal dhoop"
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
    "id": "natural_camphor_scent_cone_for_home_car",
    "name": "Natural Camphor Scent Cone for Home & Car",
    "tamilName": "கற்பூர வாசனை கோன்",
    "category": "Household & Cleaning",
    "subCategory": "Surface Cleaners & Pest Control",
    "productType": "Fragrance",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Wardrobe",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "camphor cone",
      "campure cone"
    ],
    "aliases": [
      "camphor cone",
      "campure cone"
    ],
    "brands": [
      "Mangalam Camphor Cone",
      "Campure"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "front_load_liquid_detergent_2_litres",
    "name": "Front Load Liquid Detergent 2 Litres",
    "tamilName": "ஃபிரண்ட் லோட் லிக்விட் டிடர்ஜென்ட் (2 லிட்டர்)",
    "category": "Household & Cleaning",
    "subCategory": "Laundry Care",
    "productType": "Liquid Detergent",
    "defaultUnit": "l",
    "soldBy": "volume",
    "storageLocation": "Laundry Cabinet",
    "minimumQuantity": 2.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "front load liquid detergent",
      "surf matic liquid"
    ],
    "aliases": [
      "front load liquid detergent",
      "surf matic liquid"
    ],
    "brands": [
      "Surf Excel Matic Liquid",
      "Ariel Matic Liquid"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "top_load_liquid_detergent_2_litres",
    "name": "Top Load Liquid Detergent 2 Litres",
    "tamilName": "டாப் லோட் லிக்விட் டிடர்ஜென்ட் (2 லிட்டர்)",
    "category": "Household & Cleaning",
    "subCategory": "Laundry Care",
    "productType": "Liquid Detergent",
    "defaultUnit": "l",
    "soldBy": "volume",
    "storageLocation": "Laundry Cabinet",
    "minimumQuantity": 2.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "top load liquid detergent",
      "surf top liquid"
    ],
    "aliases": [
      "top load liquid detergent",
      "surf top liquid"
    ],
    "brands": [
      "Surf Excel Matic Top",
      "Ariel Top Load Liquid"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "gentle_baby_laundry_liquid_detergent_pouch",
    "name": "Gentle Baby Laundry Liquid Detergent Pouch",
    "tamilName": "குழந்தை துணி துவைக்கும் திரவம்",
    "category": "Baby Care",
    "subCategory": "Baby Hygiene & Wellness",
    "productType": "Baby Detergent",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Laundry Cabinet",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0,
      1000.0
    ],
    "commonNames": [
      "baby laundry detergent",
      "baby fabric wash"
    ],
    "aliases": [
      "baby laundry detergent",
      "baby fabric wash"
    ],
    "brands": [
      "Pigeon Baby Detergent",
      "Mee Mee",
      "Himalaya"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "baby_care"
  },
  {
    "id": "biodegradable_small_dustbin_bags_30s",
    "name": "Biodegradable Small Dustbin Bags 30s",
    "tamilName": "குப்பை பை - ஸ்மால் (30 எண்ணிக்கை)",
    "category": "Household & Cleaning",
    "subCategory": "Cleaning Tools",
    "productType": "Garbage Bags",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Utility Shelf",
    "minimumQuantity": 30.0,
    "customQuantities": [
      30.0
    ],
    "commonNames": [
      "small garbage bags",
      "chota dustbin cover"
    ],
    "aliases": [
      "small garbage bags",
      "chota dustbin cover"
    ],
    "brands": [
      "Shalimar",
      "Presto!"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "food_grade_heavy_duty_aluminium_foil_18m",
    "name": "Food Grade Heavy Duty Aluminium Foil 18m",
    "tamilName": "அலுமினியம் ஃபாயில் (18 மீட்டர்)",
    "category": "Household & Cleaning",
    "subCategory": "Kitchen Disposables",
    "productType": "Foil",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Kitchen Cabinet",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "aluminium foil 18m",
      "big foil roll"
    ],
    "aliases": [
      "aluminium foil 18m",
      "big foil roll"
    ],
    "brands": [
      "Freshwrapp 18m",
      "Hindalco"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "zip_lock_bags_medium_size_20s",
    "name": "Zip Lock Bags Medium Size 20s",
    "tamilName": "ஜிப் லாக் பைகள் - மீடியம் (20 எண்ணிக்கை)",
    "category": "Household & Cleaning",
    "subCategory": "Kitchen Disposables",
    "productType": "Bags",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Kitchen Cabinet",
    "minimumQuantity": 20.0,
    "customQuantities": [
      20.0
    ],
    "commonNames": [
      "medium zip lock bags",
      "zipper bags"
    ],
    "aliases": [
      "medium zip lock bags",
      "zipper bags"
    ],
    "brands": [
      "Shalimar",
      "Freshwrapp"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "zip_lock_bags_large_size_15s",
    "name": "Zip Lock Bags Large Size 15s",
    "tamilName": "ஜிப் லாக் பைகள் - லார்ஜ் (15 எண்ணிக்கை)",
    "category": "Household & Cleaning",
    "subCategory": "Kitchen Disposables",
    "productType": "Bags",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Kitchen Cabinet",
    "minimumQuantity": 15.0,
    "customQuantities": [
      15.0
    ],
    "commonNames": [
      "large zip lock bags"
    ],
    "aliases": [
      "large zip lock bags"
    ],
    "brands": [
      "Shalimar",
      "Freshwrapp"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  }
]"""

def get_matrix_catalog_part2():
    return json.loads(_DATA)

if __name__ == "__main__":
    items = get_matrix_catalog_part2()
    print(f"Loaded {len(items)} matrix expansion part 2 items.")
