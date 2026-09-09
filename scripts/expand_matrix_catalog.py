# -*- coding: utf-8 -*-
"""
Matrix Catalog Expansion: Contains 279 culturally authentic,
normalized household products for Indian / Tamil Nadu households.
"""
import json

_DATA = r"""[
  {
    "id": "kichili_samba_rice",
    "name": "Kichili Samba Rice",
    "tamilName": "கிச்சிலி சம்பா அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0,
      25.0
    ],
    "commonNames": [
      "kichili samba",
      "kichili samba rice"
    ],
    "aliases": [
      "kichili samba",
      "kichili samba rice"
    ],
    "brands": [
      "Organic Farmers",
      "Gramiyum",
      "Bio Basics"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "thanga_samba_rice",
    "name": "Thanga Samba Rice",
    "tamilName": "தங்க சம்பா அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0
    ],
    "commonNames": [
      "thanga samba",
      "gold rice"
    ],
    "aliases": [
      "thanga samba",
      "gold rice"
    ],
    "brands": [
      "Bio Basics",
      "Organic Farmers"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "garudan_samba_rice",
    "name": "Garudan Samba Rice",
    "tamilName": "கருடன் சம்பா அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0
    ],
    "commonNames": [
      "garudan samba",
      "karudan samba"
    ],
    "aliases": [
      "garudan samba",
      "karudan samba"
    ],
    "brands": [
      "B&B Organics",
      "Bio Basics"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "kullakar_rice",
    "name": "Kullakar Rice",
    "tamilName": "குள்ளக்கார் அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0
    ],
    "commonNames": [
      "kullakar",
      "red kullakar"
    ],
    "aliases": [
      "kullakar",
      "red kullakar"
    ],
    "brands": [
      "B&B Organics",
      "Natureland"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "poongar_rice",
    "name": "Poongar Rice",
    "tamilName": "பூங்கார் அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0
    ],
    "commonNames": [
      "poongar",
      "women rice"
    ],
    "aliases": [
      "poongar",
      "women rice"
    ],
    "brands": [
      "B&B Organics",
      "24 Mantra"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "karungkuruvai_rice",
    "name": "Karungkuruvai Rice",
    "tamilName": "கருங்குறுவை அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0
    ],
    "commonNames": [
      "karungkuruvai",
      "black kuruvai"
    ],
    "aliases": [
      "karungkuruvai",
      "black kuruvai"
    ],
    "brands": [
      "Bio Basics",
      "Gramiyum"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "neelam_samba_rice",
    "name": "Neelam Samba Rice",
    "tamilName": "நீலம் சம்பா அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0
    ],
    "commonNames": [
      "neelam samba"
    ],
    "aliases": [
      "neelam samba"
    ],
    "brands": [
      "Organic Farmers"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "kuzhivedichan_rice",
    "name": "Kuzhivedichan Rice",
    "tamilName": "குழிவெடிச்சான் அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0
    ],
    "commonNames": [
      "kuzhivedichan"
    ],
    "aliases": [
      "kuzhivedichan"
    ],
    "brands": [
      "Bio Basics"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "sornamasuri_handpound_rice",
    "name": "Sornamasuri Handpound Rice",
    "tamilName": "கைக்குத்தல் சோனா மசூரி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0,
      25.0
    ],
    "commonNames": [
      "handpound sona masoori",
      "kaikuthal arisi"
    ],
    "aliases": [
      "handpound sona masoori",
      "kaikuthal arisi"
    ],
    "brands": [
      "Organic Tattva",
      "24 Mantra"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "vaigunda_samba_rice",
    "name": "Vaigunda Samba Rice",
    "tamilName": "வைகுண்ட சம்பா அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0
    ],
    "commonNames": [
      "vaigunda samba"
    ],
    "aliases": [
      "vaigunda samba"
    ],
    "brands": [
      "Bio Basics"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "illuppai_poo_samba_rice",
    "name": "Illuppai Poo Samba Rice",
    "tamilName": "இலுப்பைப்பூ சம்பா அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0
    ],
    "commonNames": [
      "illuppai poo samba"
    ],
    "aliases": [
      "illuppai poo samba"
    ],
    "brands": [
      "Gramiyum",
      "Bio Basics"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "salem_sanna_rice",
    "name": "Salem Sanna Rice",
    "tamilName": "சேலம் சன்னா அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0
    ],
    "commonNames": [
      "salem sanna"
    ],
    "aliases": [
      "salem sanna"
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
    "iconKey": "rice"
  },
  {
    "id": "athur_kichili_samba_rice",
    "name": "Athur Kichili Samba Rice",
    "tamilName": "ஆத்தூர் கிச்சிலி சம்பா",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0
    ],
    "commonNames": [
      "athur kichili"
    ],
    "aliases": [
      "athur kichili"
    ],
    "brands": [
      "Bio Basics"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "sigappu_kavuni_rice",
    "name": "Sigappu Kavuni Rice",
    "tamilName": "சிவப்பு கவுனி அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0
    ],
    "commonNames": [
      "sigappu kavuni",
      "red kavuni"
    ],
    "aliases": [
      "sigappu kavuni",
      "red kavuni"
    ],
    "brands": [
      "B&B Organics"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "navara_ayurvedic_rice",
    "name": "Navara Ayurvedic Rice",
    "tamilName": "ஞவரா அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0,
      5.0
    ],
    "commonNames": [
      "navara rice",
      "njavara arisi"
    ],
    "aliases": [
      "navara rice",
      "njavara arisi"
    ],
    "brands": [
      "Arya Vaidya Sala",
      "Kerala Ayurveda"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "basmati_broken_mogra_rice",
    "name": "Basmati Broken Mogra Rice",
    "tamilName": "பாஸ்மதி மோக்ரா அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0
    ],
    "commonNames": [
      "mogra rice",
      "broken basmati"
    ],
    "aliases": [
      "mogra rice",
      "broken basmati"
    ],
    "brands": [
      "India Gate",
      "Daawat",
      "Fortune"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "basmati_tibar_rice",
    "name": "Basmati Tibar Rice",
    "tamilName": "பாஸ்மதி திபார் அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0
    ],
    "commonNames": [
      "tibar basmati"
    ],
    "aliases": [
      "tibar basmati"
    ],
    "brands": [
      "Daawat",
      "India Gate"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "basmati_dubar_rice",
    "name": "Basmati Dubar Rice",
    "tamilName": "பாஸ்மதி துபார் அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0
    ],
    "commonNames": [
      "dubar basmati"
    ],
    "aliases": [
      "dubar basmati"
    ],
    "brands": [
      "India Gate",
      "Daawat"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "super_basmati_extra_long_rice",
    "name": "Super Basmati Extra Long Rice",
    "tamilName": "சூப்பர் பாஸ்மதி நீள அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0
    ],
    "commonNames": [
      "super basmati",
      "extra long rice"
    ],
    "aliases": [
      "super basmati",
      "extra long rice"
    ],
    "brands": [
      "Daawat",
      "India Gate",
      "Lal Qilla"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "brown_basmati_rice",
    "name": "Brown Basmati Rice",
    "tamilName": "பழுப்பு பாஸ்மதி அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0
    ],
    "commonNames": [
      "brown basmati"
    ],
    "aliases": [
      "brown basmati"
    ],
    "brands": [
      "India Gate",
      "Daawat",
      "24 Mantra"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "jeerakasala_kaima_rice",
    "name": "Jeerakasala Kaima Rice",
    "tamilName": "சீரகசாலா கைமா அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0
    ],
    "commonNames": [
      "jeerakasala",
      "kaima rice",
      "thalassery biryani rice"
    ],
    "aliases": [
      "jeerakasala",
      "kaima rice",
      "thalassery biryani rice"
    ],
    "brands": [
      "Double Horse",
      "Nirapara"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "gobindobhog_rice",
    "name": "Gobindobhog Rice",
    "tamilName": "கோபிந்தோபோக் அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0,
      5.0
    ],
    "commonNames": [
      "gobindobhog",
      "payesh rice"
    ],
    "aliases": [
      "gobindobhog",
      "payesh rice"
    ],
    "brands": [
      "Fortune",
      "Organic Tattva"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "wada_kolam_rice",
    "name": "Wada Kolam Rice",
    "tamilName": "வாடா கோலம் அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0,
      25.0
    ],
    "commonNames": [
      "wada kolam",
      "kolam rice"
    ],
    "aliases": [
      "wada kolam",
      "kolam rice"
    ],
    "brands": [
      "Fortune",
      "Royal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "ambemohar_rice",
    "name": "Ambemohar Rice",
    "tamilName": "ஆம்பேமோஹர் அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0
    ],
    "commonNames": [
      "ambemohar"
    ],
    "aliases": [
      "ambemohar"
    ],
    "brands": [
      "Organic Tattva"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "red_raw_rice",
    "name": "Red Raw Rice",
    "tamilName": "சிவப்பு பச்சரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0
    ],
    "commonNames": [
      "red raw rice",
      "kerala pachari"
    ],
    "aliases": [
      "red raw rice",
      "kerala pachari"
    ],
    "brands": [
      "24 Mantra",
      "Double Horse"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "red_boiled_rice",
    "name": "Red Boiled Rice",
    "tamilName": "சிவப்பு புழுங்கல் அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0,
      10.0,
      25.0
    ],
    "commonNames": [
      "red boiled rice",
      "palakkad matta"
    ],
    "aliases": [
      "red boiled rice",
      "palakkad matta"
    ],
    "brands": [
      "Double Horse",
      "Pavizham",
      "Nirapara"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "kerala_matta_broken_rice",
    "name": "Kerala Matta Broken Rice",
    "tamilName": "மட்டா நொய் அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0
    ],
    "commonNames": [
      "matta broken",
      "matta kurunai"
    ],
    "aliases": [
      "matta broken",
      "matta kurunai"
    ],
    "brands": [
      "Double Horse",
      "Brahmins"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "raw_rice_kurunai_broken",
    "name": "Raw Rice Kurunai Broken",
    "tamilName": "பச்சரிசி குறுணை",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0
    ],
    "commonNames": [
      "pachari kurunai",
      "arisi noiyyi"
    ],
    "aliases": [
      "pachari kurunai",
      "arisi noiyyi"
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
    "iconKey": "rice"
  },
  {
    "id": "boiled_rice_kurunai_broken",
    "name": "Boiled Rice Kurunai Broken",
    "tamilName": "புழுங்கல் அரிசி குறுணை",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0
    ],
    "commonNames": [
      "puzhungal kurunai"
    ],
    "aliases": [
      "puzhungal kurunai"
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
    "iconKey": "rice"
  },
  {
    "id": "bamboo_rice_moongil_arisi",
    "name": "Bamboo Rice / Moongil Arisi",
    "tamilName": "மூங்கில் அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Rice",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "bamboo rice",
      "moongil arisi"
    ],
    "aliases": [
      "bamboo rice",
      "moongil arisi"
    ],
    "brands": [
      "B&B Organics",
      "Natureland"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "rice"
  },
  {
    "id": "kambu_aval_bajra_flakes",
    "name": "Kambu Aval Bajra Flakes",
    "tamilName": "கம்பு அவல்",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Millet Flakes",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "kambu aval",
      "pearl millet flakes"
    ],
    "aliases": [
      "kambu aval",
      "pearl millet flakes"
    ],
    "brands": [
      "Gramiyum",
      "B&B Organics"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "cholam_aval_jowar_flakes",
    "name": "Cholam Aval Jowar Flakes",
    "tamilName": "சோளம் அவல்",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Millet Flakes",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "cholam aval",
      "jowar flakes"
    ],
    "aliases": [
      "cholam aval",
      "jowar flakes"
    ],
    "brands": [
      "Gramiyum",
      "24 Mantra"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "kuthiraivali_aval_barnyard_flakes",
    "name": "Kuthiraivali Aval Barnyard Flakes",
    "tamilName": "குதிரைவாலி அவல்",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Millet Flakes",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "kuthiraivali aval"
    ],
    "aliases": [
      "kuthiraivali aval"
    ],
    "brands": [
      "B&B Organics",
      "Gramiyum"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "thinai_aval_foxtail_flakes",
    "name": "Thinai Aval Foxtail Flakes",
    "tamilName": "தினை அவல்",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Millet Flakes",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "thinai aval",
      "foxtail flakes"
    ],
    "aliases": [
      "thinai aval",
      "foxtail flakes"
    ],
    "brands": [
      "B&B Organics",
      "Natureland"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "varagu_aval_kodo_flakes",
    "name": "Varagu Aval Kodo Flakes",
    "tamilName": "வரகு அவல்",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Millet Flakes",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "varagu aval"
    ],
    "aliases": [
      "varagu aval"
    ],
    "brands": [
      "B&B Organics",
      "Gramiyum"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "samai_aval_little_millet_flakes",
    "name": "Samai Aval Little Millet Flakes",
    "tamilName": "சாமை அவல்",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Millet Flakes",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "samai aval"
    ],
    "aliases": [
      "samai aval"
    ],
    "brands": [
      "B&B Organics",
      "Gramiyum"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "ragi_pori_puffed_finger_millet",
    "name": "Ragi Pori Puffed Finger Millet",
    "tamilName": "கேழ்வரகு பொரி",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Puffed Grains",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "ragi pori",
      "kezhvaragu pori"
    ],
    "aliases": [
      "ragi pori",
      "kezhvaragu pori"
    ],
    "brands": [
      "Gramiyum",
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "cholam_pori_puffed_jowar",
    "name": "Cholam Pori Puffed Jowar",
    "tamilName": "சோளப் பொரி",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Puffed Grains",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "cholam pori",
      "jowar dhani"
    ],
    "aliases": [
      "cholam pori",
      "jowar dhani"
    ],
    "brands": [
      "Gramiyum",
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "kambu_pori_puffed_bajra",
    "name": "Kambu Pori Puffed Bajra",
    "tamilName": "கம்புப் பொரி",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Puffed Grains",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "kambu pori"
    ],
    "aliases": [
      "kambu pori"
    ],
    "brands": [
      "Gramiyum",
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "nel_pori_arisi_malar_puffed_paddy",
    "name": "Nel Pori Arisi Malar Puffed Paddy",
    "tamilName": "நெல் பொரி / நெல் மலர்",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Puffed Grains",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "nel pori",
      "arisi malar",
      "karthigai pori"
    ],
    "aliases": [
      "nel pori",
      "arisi malar",
      "karthigai pori"
    ],
    "brands": [
      "Local Mills",
      "Pooja Stores"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "dried_green_peas_sukha_vatana",
    "name": "Dried Green Peas Sukha Vatana",
    "tamilName": "பச்சை பட்டாணி (உலர்ந்தது)",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Legumes",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0,
      2.0
    ],
    "commonNames": [
      "dried green peas",
      "pachai pattani dry"
    ],
    "aliases": [
      "dried green peas",
      "pachai pattani dry"
    ],
    "brands": [
      "Tata Sampann",
      "BB Royal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "dried_white_peas_safed_vatana",
    "name": "Dried White Peas Safed Vatana",
    "tamilName": "வெள்ளை பட்டாணி (உலர்ந்தது)",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Legumes",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0,
      2.0
    ],
    "commonNames": [
      "white peas",
      "safed vatana",
      "vellai pattani"
    ],
    "aliases": [
      "white peas",
      "safed vatana",
      "vellai pattani"
    ],
    "brands": [
      "Tata Sampann",
      "BB Royal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "nattu_kala_chana_brown_chickpeas",
    "name": "Nattu Kala Chana Brown Chickpeas",
    "tamilName": "நாட்டு கருப்பு கொண்டைக்கடலை",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Chickpeas",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0,
      2.0
    ],
    "commonNames": [
      "nattu konda kadalai",
      "desi chana",
      "kala chana"
    ],
    "aliases": [
      "nattu konda kadalai",
      "desi chana",
      "kala chana"
    ],
    "brands": [
      "Tata Sampann",
      "Fortune",
      "Udhayam"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "green_chickpeas_hara_chana_dry",
    "name": "Green Chickpeas Hara Chana Dry",
    "tamilName": "பச்சை கொண்டைக்கடலை",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Chickpeas",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "green chickpeas",
      "hara chana"
    ],
    "aliases": [
      "green chickpeas",
      "hara chana"
    ],
    "brands": [
      "Tata Sampann",
      "BB Royal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "fresh_mochai_field_beans",
    "name": "Fresh Mochai Field Beans",
    "tamilName": "பச்சை மொச்சை",
    "category": "Fresh Vegetables",
    "subCategory": "Beans & Pods",
    "productType": "Fresh Legume",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "pachai mochai",
      "fresh avarekalu"
    ],
    "aliases": [
      "pachai mochai",
      "fresh avarekalu"
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
    "id": "dried_white_mochai_field_beans",
    "name": "Dried White Mochai Field Beans",
    "tamilName": "வெள்ளை மொச்சை (உலர்ந்தது)",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Legumes",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "vellai mochai",
      "dry mochai"
    ],
    "aliases": [
      "vellai mochai",
      "dry mochai"
    ],
    "brands": [
      "BB Royal",
      "Udhayam"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "dried_black_mochai_beans",
    "name": "Dried Black Mochai Beans",
    "tamilName": "கருப்பு மொச்சை",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Legumes",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "karuppu mochai",
      "black field beans"
    ],
    "aliases": [
      "karuppu mochai",
      "black field beans"
    ],
    "brands": [
      "Local Farmers",
      "BB Royal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "split_mochai_dal_val_dal",
    "name": "Split Mochai Dal Val Dal",
    "tamilName": "மொச்சைப் பருப்பு",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Dals",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "mochai paruppu",
      "val dal"
    ],
    "aliases": [
      "mochai paruppu",
      "val dal"
    ],
    "brands": [
      "Udhayam",
      "BB Royal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "whole_horsegram_kollu_kulthi",
    "name": "Whole Horsegram Kollu Kulthi",
    "tamilName": "கொள்ளு",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Pulses",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0,
      2.0
    ],
    "commonNames": [
      "kollu",
      "horsegram",
      "kulthi dal"
    ],
    "aliases": [
      "kollu",
      "horsegram",
      "kulthi dal"
    ],
    "brands": [
      "Udhayam",
      "Tata Sampann",
      "24 Mantra"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "roasted_horsegram_dal",
    "name": "Roasted Horsegram Dal",
    "tamilName": "வறுத்த கொள்ளுப் பருப்பு",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Pulses",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "roasted kollu",
      "varutha kollu"
    ],
    "aliases": [
      "roasted kollu",
      "varutha kollu"
    ],
    "brands": [
      "Gramiyum",
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "red_cowpeas_sigappu_karamani",
    "name": "Red Cowpeas Sigappu Karamani",
    "tamilName": "சிவப்பு காராமணி",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Pulses",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "sigappu karamani",
      "red lobia"
    ],
    "aliases": [
      "sigappu karamani",
      "red lobia"
    ],
    "brands": [
      "Tata Sampann",
      "Udhayam"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "white_cowpeas_vellai_karamani",
    "name": "White Cowpeas Vellai Karamani",
    "tamilName": "வெள்ளை காராமணி",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Pulses",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "vellai karamani",
      "white lobia"
    ],
    "aliases": [
      "vellai karamani",
      "white lobia"
    ],
    "brands": [
      "Tata Sampann",
      "Udhayam"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "black_eye_cowpeas_karamani",
    "name": "Black Eye Cowpeas Karamani",
    "tamilName": "கருப்புக்கண் காராமணி",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Pulses",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0,
      2.0
    ],
    "commonNames": [
      "black eyed peas",
      "lobia",
      "karamani payaru"
    ],
    "aliases": [
      "black eyed peas",
      "lobia",
      "karamani payaru"
    ],
    "brands": [
      "Tata Sampann",
      "Fortune"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "whole_green_moong_sabut",
    "name": "Whole Green Moong Sabut",
    "tamilName": "முழு பச்சை பயறு",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Dals",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0,
      2.0
    ],
    "commonNames": [
      "sabut moong",
      "pachai payaru"
    ],
    "aliases": [
      "sabut moong",
      "pachai payaru"
    ],
    "brands": [
      "Tata Sampann",
      "Fortune",
      "Udhayam"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "sprouted_green_gram_pachai_payaru",
    "name": "Sprouted Green Gram Pachai Payaru",
    "tamilName": "முளைகட்டிய பச்சை பயறு",
    "category": "Fresh Vegetables",
    "subCategory": "Sprouts",
    "productType": "Sprouts",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      400.0
    ],
    "commonNames": [
      "moong sprouts",
      "mulaikattiya payaru"
    ],
    "aliases": [
      "moong sprouts",
      "mulaikattiya payaru"
    ],
    "brands": [
      "Local Fresh",
      "Organic"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "fresh_produce"
  },
  {
    "id": "sprouted_horsegram_kollu",
    "name": "Sprouted Horsegram Kollu",
    "tamilName": "முளைகட்டிய கொள்ளு",
    "category": "Fresh Vegetables",
    "subCategory": "Sprouts",
    "productType": "Sprouts",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      400.0
    ],
    "commonNames": [
      "kollu sprouts"
    ],
    "aliases": [
      "kollu sprouts"
    ],
    "brands": [
      "Local Fresh"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "fresh_produce"
  },
  {
    "id": "sprouted_kala_chana_desi",
    "name": "Sprouted Kala Chana Desi",
    "tamilName": "முளைகட்டிய கொண்டைக்கடலை",
    "category": "Fresh Vegetables",
    "subCategory": "Sprouts",
    "productType": "Sprouts",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      400.0
    ],
    "commonNames": [
      "chana sprouts",
      "sprouted kala chana"
    ],
    "aliases": [
      "chana sprouts",
      "sprouted kala chana"
    ],
    "brands": [
      "Local Fresh"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "fresh_produce"
  },
  {
    "id": "split_green_moong_chilka",
    "name": "Split Green Moong Chilka",
    "tamilName": "உடைத்த பச்சை பயறு (தோலுடன்)",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Dals",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "chilka moong",
      "split green gram with skin"
    ],
    "aliases": [
      "chilka moong",
      "split green gram with skin"
    ],
    "brands": [
      "Tata Sampann",
      "Fortune"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "split_black_urad_chilka",
    "name": "Split Black Urad Chilka",
    "tamilName": "உடைத்த கருப்பு உளுந்து (தோலுடன்)",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Dals",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "chilka urad",
      "split black gram with skin"
    ],
    "aliases": [
      "chilka urad",
      "split black gram with skin"
    ],
    "brands": [
      "Tata Sampann",
      "Udhayam"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "whole_black_urad_sabut",
    "name": "Whole Black Urad Sabut",
    "tamilName": "முழு கருப்பு உளுந்து",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Dals",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0,
      2.0
    ],
    "commonNames": [
      "sabut urad",
      "karuppu ulundhu muzhu"
    ],
    "aliases": [
      "sabut urad",
      "karuppu ulundhu muzhu"
    ],
    "brands": [
      "Tata Sampann",
      "Udhayam"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "moth_beans_matki_nari_payaru",
    "name": "Moth Beans Matki Nari Payaru",
    "tamilName": "நரிப்பயறு / மட்கி",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Pulses",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "moth beans",
      "matki",
      "nari payaru"
    ],
    "aliases": [
      "moth beans",
      "matki",
      "nari payaru"
    ],
    "brands": [
      "Tata Sampann",
      "BB Royal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "whole_soyabeans",
    "name": "Whole Soyabeans",
    "tamilName": "முழு சோயாபீன்ஸ்",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Pulses",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "soyabeans",
      "soya beans whole"
    ],
    "aliases": [
      "soyabeans",
      "soya beans whole"
    ],
    "brands": [
      "Tata Sampann",
      "Nutrela"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "rajma_chitra_speckled_kidney_beans",
    "name": "Rajma Chitra Speckled Kidney Beans",
    "tamilName": "சித்ரா ராஜ்மா",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Beans",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "rajma chitra",
      "spotted rajma"
    ],
    "aliases": [
      "rajma chitra",
      "spotted rajma"
    ],
    "brands": [
      "Tata Sampann",
      "Fortune"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "rajma_kashmiri_red_kidney_beans",
    "name": "Rajma Kashmiri Red Kidney Beans",
    "tamilName": "காஷ்மீரி சிவப்பு ராஜ்மா",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Beans",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "kashmiri rajma",
      "red kidney beans"
    ],
    "aliases": [
      "kashmiri rajma",
      "red kidney beans"
    ],
    "brands": [
      "Tata Sampann",
      "Fortune"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "rajma_black_kidney_beans",
    "name": "Rajma Black Kidney Beans",
    "tamilName": "கருப்பு ராஜ்மா",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Beans",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "black rajma",
      "black kidney beans"
    ],
    "aliases": [
      "black rajma",
      "black kidney beans"
    ],
    "brands": [
      "BB Royal",
      "Organic Tattva"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "masoor_malka_split_red_lentils",
    "name": "Masoor Malka Split Red Lentils",
    "tamilName": "மைசூர் பருப்பு",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Dals",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0,
      2.0
    ],
    "commonNames": [
      "masoor malka",
      "red lentils",
      "mysore paruppu"
    ],
    "aliases": [
      "masoor malka",
      "red lentils",
      "mysore paruppu"
    ],
    "brands": [
      "Tata Sampann",
      "Fortune",
      "Udhayam"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "whole_masoor_brown_lentils_sabut",
    "name": "Whole Masoor Brown Lentils Sabut",
    "tamilName": "முழு மைசூர் பருப்பு",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Dals",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "sabut masoor",
      "whole brown masoor"
    ],
    "aliases": [
      "sabut masoor",
      "whole brown masoor"
    ],
    "brands": [
      "Tata Sampann",
      "Fortune"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "roasted_fried_gram_pottukadalai",
    "name": "Roasted Fried Gram Pottukadalai",
    "tamilName": "பொட்டுக்கடலை",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Dals",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.25,
      0.5,
      1.0
    ],
    "commonNames": [
      "pottukadalai",
      "chutney dal",
      "roasted gram"
    ],
    "aliases": [
      "pottukadalai",
      "chutney dal",
      "roasted gram"
    ],
    "brands": [
      "Udhayam",
      "BB Royal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "raw_groundnuts_peanuts_shelled",
    "name": "Raw Groundnuts Peanuts Shelled",
    "tamilName": "பச்சை வேர்க்கடலை (உடைத்தது)",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Nuts",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0,
      2.0
    ],
    "commonNames": [
      "raw groundnuts",
      "pachai verkadalai",
      "singdana"
    ],
    "aliases": [
      "raw groundnuts",
      "pachai verkadalai",
      "singdana"
    ],
    "brands": [
      "Tata Sampann",
      "Udhayam",
      "Fortune"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "groundnuts_in_shell_pods",
    "name": "Groundnuts In Shell Pods",
    "tamilName": "வேர்க்கடலை (தோலுடன்)",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Nuts",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "groundnuts with shell",
      "shell verkadalai"
    ],
    "aliases": [
      "groundnuts with shell",
      "shell verkadalai"
    ],
    "brands": [
      "Local Farmers"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "double_beans_lima_beans_dried",
    "name": "Double Beans Lima Beans Dried",
    "tamilName": "டபுள் பீன்ஸ்",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Beans",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "double beans",
      "lima beans"
    ],
    "aliases": [
      "double beans",
      "lima beans"
    ],
    "brands": [
      "BB Royal",
      "Tata Sampann"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "dal"
  },
  {
    "id": "soya_chunks_regular_size",
    "name": "Soya Chunks Regular Size",
    "tamilName": "சோயா மீல் மேக்கர்",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Soya",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      1000.0
    ],
    "commonNames": [
      "soya chunks",
      "meal maker",
      "bari"
    ],
    "aliases": [
      "soya chunks",
      "meal maker",
      "bari"
    ],
    "brands": [
      "Nutrela",
      "Fortune"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "mini_soya_chunks",
    "name": "Mini Soya Chunks",
    "tamilName": "மினி சோயா துண்டுகள்",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Soya",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "mini soya chunks",
      "chota meal maker"
    ],
    "aliases": [
      "mini soya chunks",
      "chota meal maker"
    ],
    "brands": [
      "Nutrela",
      "Fortune"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "soya_granules_keema",
    "name": "Soya Granules Keema",
    "tamilName": "சோயா கீமா கிரானியூல்ஸ்",
    "category": "Food & Grocery",
    "subCategory": "Dals & Pulses",
    "productType": "Soya",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "soya granules",
      "soya keema"
    ],
    "aliases": [
      "soya granules",
      "soya keema"
    ],
    "brands": [
      "Nutrela"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "barley_grains_varchu_arisi",
    "name": "Barley Grains Varchu Arisi",
    "tamilName": "பார்லி அரிசி",
    "category": "Food & Grocery",
    "subCategory": "Rice & Grains",
    "productType": "Grains",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "barley grains",
      "varchu arisi"
    ],
    "aliases": [
      "barley grains",
      "varchu arisi"
    ],
    "brands": [
      "24 Mantra",
      "BB Royal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "rolled_oats_whole_grain",
    "name": "Rolled Oats Whole Grain",
    "tamilName": "ரோல்டு ஓட்ஸ்",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Oats",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "rolled oats",
      "whole grain oats"
    ],
    "aliases": [
      "rolled oats",
      "whole grain oats"
    ],
    "brands": [
      "Quaker",
      "Kellogg's",
      "Saffola"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "instant_oats_quick_cooking",
    "name": "Instant Oats Quick Cooking",
    "tamilName": "இன்ஸ்டன்ட் ஓட்ஸ்",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Oats",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      0.5,
      1.0,
      2.0
    ],
    "commonNames": [
      "instant oats",
      "quick oats"
    ],
    "aliases": [
      "instant oats",
      "quick oats"
    ],
    "brands": [
      "Quaker",
      "Saffola",
      "Kellogg's"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "steel_cut_oats",
    "name": "Steel Cut Oats",
    "tamilName": "ஸ்டீல் கட் ஓட்ஸ்",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Oats",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "steel cut oats"
    ],
    "aliases": [
      "steel cut oats"
    ],
    "brands": [
      "True Elements",
      "Urban Platter"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "raw_chia_seeds_black",
    "name": "Raw Chia Seeds Black",
    "tamilName": "சியா விதைகள்",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Seeds",
    "productType": "Seeds",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      100.0,
      250.0
    ],
    "commonNames": [
      "chia seeds",
      "black chia"
    ],
    "aliases": [
      "chia seeds",
      "black chia"
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
    "id": "raw_flax_seeds_alividhai",
    "name": "Raw Flax Seeds Alividhai",
    "tamilName": "ஆளி விதைகள்",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Seeds",
    "productType": "Seeds",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "flax seeds",
      "ali vidhai",
      "alsi"
    ],
    "aliases": [
      "flax seeds",
      "ali vidhai",
      "alsi"
    ],
    "brands": [
      "True Elements",
      "24 Mantra"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "raw_pumpkin_seeds_kaddu_beej",
    "name": "Raw Pumpkin Seeds Kaddu Beej",
    "tamilName": "பூசணி விதைகள்",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Seeds",
    "productType": "Seeds",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      100.0,
      250.0
    ],
    "commonNames": [
      "pumpkin seeds",
      "poosani vidhai"
    ],
    "aliases": [
      "pumpkin seeds",
      "poosani vidhai"
    ],
    "brands": [
      "True Elements",
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
    "id": "raw_sunflower_seeds",
    "name": "Raw Sunflower Seeds",
    "tamilName": "சூரியகாந்தி விதைகள்",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Seeds",
    "productType": "Seeds",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      100.0,
      250.0
    ],
    "commonNames": [
      "sunflower seeds"
    ],
    "aliases": [
      "sunflower seeds"
    ],
    "brands": [
      "True Elements",
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
    "id": "watermelon_seeds_magaz",
    "name": "Watermelon Seeds Magaz",
    "tamilName": "தர்பூசணி பருப்பு (மகாஸ்)",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Seeds",
    "productType": "Seeds",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      250.0
    ],
    "commonNames": [
      "magaz",
      "watermelon kernels"
    ],
    "aliases": [
      "magaz",
      "watermelon kernels"
    ],
    "brands": [
      "Catch",
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
    "id": "sabja_basil_seeds_tukmaria",
    "name": "Sabja Basil Seeds Tukmaria",
    "tamilName": "சப்ஜா விதைகள்",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Seeds",
    "productType": "Seeds",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "sabja seeds",
      "basil seeds",
      "tukmaria"
    ],
    "aliases": [
      "sabja seeds",
      "basil seeds",
      "tukmaria"
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
    "id": "phool_makhana_fox_nuts",
    "name": "Phool Makhana Fox Nuts",
    "tamilName": "தாமரை விதை / மகானா",
    "category": "Dry Fruits, Nuts & Seeds",
    "subCategory": "Dry Fruits & Nuts",
    "productType": "Makhana",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      250.0,
      500.0
    ],
    "commonNames": [
      "phool makhana",
      "fox nuts",
      "lotus seeds"
    ],
    "aliases": [
      "phool makhana",
      "fox nuts",
      "lotus seeds"
    ],
    "brands": [
      "BB Royal",
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
    "id": "nylon_javvarisi_small_sago",
    "name": "Nylon Javvarisi Small Sago",
    "tamilName": "நைலான் ஜவ்வரிசி (சிறியது)",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Sago",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "nylon javvarisi",
      "small sago pearls",
      "chota sabudana"
    ],
    "aliases": [
      "nylon javvarisi",
      "small sago pearls",
      "chota sabudana"
    ],
    "brands": [
      "Salem Sago",
      "BB Royal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "maavu_javvarisi_big_sabudana",
    "name": "Maavu Javvarisi Big Sabudana",
    "tamilName": "மாவு ஜவ்வரிசி (பெரியது)",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Sago",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "maavu javvarisi",
      "bada sabudana",
      "tapioca pearls"
    ],
    "aliases": [
      "maavu javvarisi",
      "bada sabudana",
      "tapioca pearls"
    ],
    "brands": [
      "Salem Sago",
      "BB Royal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "samba_broken_wheat_rava_dalia",
    "name": "Samba Broken Wheat Rava Dalia",
    "tamilName": "சம்பா கோதுமை ரவை",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Rava",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0,
      2.0
    ],
    "commonNames": [
      "samba godhumai ravai",
      "broken wheat",
      "dalia"
    ],
    "aliases": [
      "samba godhumai ravai",
      "broken wheat",
      "dalia"
    ],
    "brands": [
      "Naga",
      "Anil",
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
    "id": "fine_bansi_sooji_rava",
    "name": "Fine Bansi Sooji Rava",
    "tamilName": "ஃபைன் பன்சி ரவை",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Rava",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "bansi rava",
      "fine sooji"
    ],
    "aliases": [
      "bansi rava",
      "fine sooji"
    ],
    "brands": [
      "Naga",
      "Anil"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "coarse_bombay_rava_sooji",
    "name": "Coarse Bombay Rava Sooji",
    "tamilName": "பம்பாய் ரவை",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Rava",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0,
      2.0
    ],
    "commonNames": [
      "bombay rava",
      "coarse rava",
      "upma rava"
    ],
    "aliases": [
      "bombay rava",
      "coarse rava",
      "upma rava"
    ],
    "brands": [
      "Naga",
      "Aashirvaad",
      "Fortune"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "chiroti_rava_fine_semolina",
    "name": "Chiroti Rava Fine Semolina",
    "tamilName": "சிரோட்டி ரவை",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Rava",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "chiroti rava",
      "fine semolina"
    ],
    "aliases": [
      "chiroti rava",
      "fine semolina"
    ],
    "brands": [
      "Naga",
      "Anil"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "roasted_semolina_rava_bhuna_sooji",
    "name": "Roasted Semolina Rava Bhuna Sooji",
    "tamilName": "வறுத்த ரவை",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Rava",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "roasted rava",
      "roasted sooji",
      "varutha ravai"
    ],
    "aliases": [
      "roasted rava",
      "roasted sooji",
      "varutha ravai"
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
    "iconKey": "grains"
  },
  {
    "id": "rice_rava_idli_rava",
    "name": "Rice Rava Idli Rava",
    "tamilName": "இட்லி ரவை / அரிசி ரவை",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Rava",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0,
      5.0
    ],
    "commonNames": [
      "idli rava",
      "rice rava",
      "arisi ravai"
    ],
    "aliases": [
      "idli rava",
      "rice rava",
      "arisi ravai"
    ],
    "brands": [
      "Naga",
      "Udhayam",
      "Priya"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "ragi_flour_kezhvaragu_maavu",
    "name": "Ragi Flour Kezhvaragu Maavu",
    "tamilName": "கேழ்வரகு மாவு",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Atta & Flour",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0,
      2.0
    ],
    "commonNames": [
      "ragi flour",
      "finger millet flour",
      "kezhvaragu maavu"
    ],
    "aliases": [
      "ragi flour",
      "finger millet flour",
      "kezhvaragu maavu"
    ],
    "brands": [
      "Naga",
      "Anil",
      "Aashirvaad"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "kambu_flour_bajra_atta",
    "name": "Kambu Flour Bajra Atta",
    "tamilName": "கம்பு மாவு",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Atta & Flour",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "kambu maavu",
      "bajra flour"
    ],
    "aliases": [
      "kambu maavu",
      "bajra flour"
    ],
    "brands": [
      "Naga",
      "Gramiyum",
      "Organic Tattva"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "jowar_flour_cholam_maavu",
    "name": "Jowar Flour Cholam Maavu",
    "tamilName": "சோள மாவு",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Atta & Flour",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "cholam maavu",
      "jowar flour"
    ],
    "aliases": [
      "cholam maavu",
      "jowar flour"
    ],
    "brands": [
      "Gramiyum",
      "Organic Tattva"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "thinai_flour_foxtail_millet_flour",
    "name": "Thinai Flour Foxtail Millet Flour",
    "tamilName": "தினை மாவு",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Atta & Flour",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "thinai maavu",
      "foxtail flour"
    ],
    "aliases": [
      "thinai maavu",
      "foxtail flour"
    ],
    "brands": [
      "B&B Organics",
      "Gramiyum"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "varagu_flour_kodo_millet_flour",
    "name": "Varagu Flour Kodo Millet Flour",
    "tamilName": "வரகு மாவு",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Atta & Flour",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "varagu maavu",
      "kodo flour"
    ],
    "aliases": [
      "varagu maavu",
      "kodo flour"
    ],
    "brands": [
      "B&B Organics",
      "Gramiyum"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "samai_flour_little_millet_flour",
    "name": "Samai Flour Little Millet Flour",
    "tamilName": "சாமை மாவு",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Atta & Flour",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "samai maavu",
      "little millet flour"
    ],
    "aliases": [
      "samai maavu",
      "little millet flour"
    ],
    "brands": [
      "B&B Organics",
      "Gramiyum"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "kuthiraivali_flour_barnyard_flour",
    "name": "Kuthiraivali Flour Barnyard Flour",
    "tamilName": "குதிரைவாலி மாவு",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Atta & Flour",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "kuthiraivali maavu",
      "barnyard flour"
    ],
    "aliases": [
      "kuthiraivali maavu",
      "barnyard flour"
    ],
    "brands": [
      "B&B Organics",
      "Gramiyum"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "roasted_idiyappam_flour_rice",
    "name": "Roasted Idiyappam Flour Rice",
    "tamilName": "இடியாப்ப மாவு",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Atta & Flour",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "idiyappam flour",
      "sevai maavu"
    ],
    "aliases": [
      "idiyappam flour",
      "sevai maavu"
    ],
    "brands": [
      "Anil",
      "Double Horse",
      "Nirapara"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "pathiri_podi_white_rice_flour",
    "name": "Pathiri Podi White Rice Flour",
    "tamilName": "பத்திரி பொடி",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Atta & Flour",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "pathiri podi",
      "kerala pathiri flour"
    ],
    "aliases": [
      "pathiri podi",
      "kerala pathiri flour"
    ],
    "brands": [
      "Double Horse",
      "Eastern",
      "Nirapara"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "puttu_podi_steamed_rice_powder",
    "name": "Puttu Podi Steamed Rice Powder",
    "tamilName": "புட்டு மாவு",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Atta & Flour",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "puttu podi",
      "arisi puttu maavu"
    ],
    "aliases": [
      "puttu podi",
      "arisi puttu maavu"
    ],
    "brands": [
      "Anil",
      "Double Horse",
      "Eastern"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "ragi_puttu_podi",
    "name": "Ragi Puttu Podi",
    "tamilName": "கேழ்வரகு புட்டு மாவு",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Atta & Flour",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "ragi puttu podi",
      "kezhvaragu puttu maavu"
    ],
    "aliases": [
      "ragi puttu podi",
      "kezhvaragu puttu maavu"
    ],
    "brands": [
      "Anil",
      "Double Horse",
      "Brahmins"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "wheat_puttu_podi",
    "name": "Wheat Puttu Podi",
    "tamilName": "கோதுமை புட்டு மாவு",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Atta & Flour",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "wheat puttu podi",
      "godhumai puttu"
    ],
    "aliases": [
      "wheat puttu podi",
      "godhumai puttu"
    ],
    "brands": [
      "Double Horse",
      "Eastern"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "kozhukattai_maavu_modak_flour",
    "name": "Kozhukattai Maavu Modak Flour",
    "tamilName": "கொழுக்கட்டை மாவு",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Atta & Flour",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "kozhukattai maavu",
      "modak flour"
    ],
    "aliases": [
      "kozhukattai maavu",
      "modak flour"
    ],
    "brands": [
      "Anil",
      "Udhayam"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "adai_flour_mix_multi_lentil",
    "name": "Adai Flour Mix Multi Lentil",
    "tamilName": "அடை மாவு மிக்ஸ்",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Breakfast & Mixes",
    "productType": "Instant Mix",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "adai mix",
      "adai maavu"
    ],
    "aliases": [
      "adai mix",
      "adai maavu"
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
    "id": "pesarattu_green_moong_dosa_mix",
    "name": "Pesarattu Green Moong Dosa Mix",
    "tamilName": "பெசரட்டு மிக்ஸ்",
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
      "pesarattu mix",
      "moong dal dosa mix"
    ],
    "aliases": [
      "pesarattu mix",
      "moong dal dosa mix"
    ],
    "brands": [
      "MTR",
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
    "id": "bajji_bonda_flour_mix",
    "name": "Bajji Bonda Flour Mix",
    "tamilName": "பஜ்ஜி போண்டா மிக்ஸ்",
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
      "bajji bonda mix",
      "pakoda mix"
    ],
    "aliases": [
      "bajji bonda mix",
      "pakoda mix"
    ],
    "brands": [
      "Aachi",
      "Sakthi",
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
    "id": "murukku_flour_mix",
    "name": "Murukku Flour Mix",
    "tamilName": "முறுக்கு மாவு மிக்ஸ்",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Breakfast & Mixes",
    "productType": "Instant Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0,
      1000.0
    ],
    "commonNames": [
      "murukku mix",
      "murukku flour"
    ],
    "aliases": [
      "murukku mix",
      "murukku flour"
    ],
    "brands": [
      "Anil",
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
    "id": "seedai_flour_mix",
    "name": "Seedai Flour Mix",
    "tamilName": "சீடை மாவு மிக்ஸ்",
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
      "seedai mix",
      "seedai maavu"
    ],
    "aliases": [
      "seedai mix",
      "seedai maavu"
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
    "id": "thattai_flour_mix",
    "name": "Thattai Flour Mix",
    "tamilName": "தட்டை மாவு மிக்ஸ்",
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
      "thattai mix",
      "thattai flour"
    ],
    "aliases": [
      "thattai mix",
      "thattai flour"
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
    "id": "appam_batter_mix_vellayappam",
    "name": "Appam Batter Mix Vellayappam",
    "tamilName": "ஆப்ப மாவு மிக்ஸ்",
    "category": "Instant & Ready-to-Cook",
    "subCategory": "Breakfast & Mixes",
    "productType": "Instant Mix",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "appam mix",
      "vellayappam podi"
    ],
    "aliases": [
      "appam mix",
      "vellayappam podi"
    ],
    "brands": [
      "Double Horse",
      "Eastern",
      "Nirapara"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "fresh_idli_dosa_batter_pouch",
    "name": "Fresh Idli Dosa Batter Pouch",
    "tamilName": "இட்லி தோசை மாவு",
    "category": "Dairy & Refrigerated",
    "subCategory": "Batters & Fresh",
    "productType": "Fresh Batter",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "idli dosa batter",
      "ready batter",
      "id batter"
    ],
    "aliases": [
      "idli dosa batter",
      "ready batter",
      "id batter"
    ],
    "brands": [
      "iD Fresh",
      "MTR",
      "Asal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "ragi_idli_dosa_batter_pouch",
    "name": "Ragi Idli Dosa Batter Pouch",
    "tamilName": "கேழ்வரகு இட்லி தோசை மாவு",
    "category": "Dairy & Refrigerated",
    "subCategory": "Batters & Fresh",
    "productType": "Fresh Batter",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "ragi batter",
      "ragi idli batter"
    ],
    "aliases": [
      "ragi batter",
      "ragi idli batter"
    ],
    "brands": [
      "iD Fresh",
      "Asal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "multi_millet_dosa_batter_pouch",
    "name": "Multi Millet Dosa Batter Pouch",
    "tamilName": "சிறுதானிய தோசை மாவு",
    "category": "Dairy & Refrigerated",
    "subCategory": "Batters & Fresh",
    "productType": "Fresh Batter",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "millet batter",
      "sirudhaniyam batter"
    ],
    "aliases": [
      "millet batter",
      "sirudhaniyam batter"
    ],
    "brands": [
      "iD Fresh",
      "Millet Magic"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "corn_starch_cornflour_white",
    "name": "Corn Starch Cornflour White",
    "tamilName": "சோள மாவு கார்ன்பிளவர்",
    "category": "Food & Grocery",
    "subCategory": "Flours & Grains",
    "productType": "Starch",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0,
      500.0
    ],
    "commonNames": [
      "corn flour",
      "cornstarch"
    ],
    "aliases": [
      "corn flour",
      "cornstarch"
    ],
    "brands": [
      "Weikfield",
      "Brown & Polson"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "grains"
  },
  {
    "id": "custard_powder_vanilla_flavor",
    "name": "Custard Powder Vanilla Flavor",
    "tamilName": "கஸ்டர்ட் பவுடர் (வெனிலா)",
    "category": "Food & Grocery",
    "subCategory": "Baking Ingredients",
    "productType": "Dessert Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      500.0
    ],
    "commonNames": [
      "custard powder",
      "vanilla custard"
    ],
    "aliases": [
      "custard powder",
      "vanilla custard"
    ],
    "brands": [
      "Weikfield",
      "Brown & Polson"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "baking_powder_double_action",
    "name": "Baking Powder Double Action",
    "tamilName": "பேக்கிங் பவுடர்",
    "category": "Food & Grocery",
    "subCategory": "Baking Ingredients",
    "productType": "Baking Agent",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "baking powder"
    ],
    "aliases": [
      "baking powder"
    ],
    "brands": [
      "Weikfield",
      "Puratos"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "baking_soda_sodium_bicarbonate",
    "name": "Baking Soda Sodium Bicarbonate",
    "tamilName": "சமையல் சோடா",
    "category": "Food & Grocery",
    "subCategory": "Baking Ingredients",
    "productType": "Baking Agent",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "baking soda",
      "meetha soda",
      "samayal soda"
    ],
    "aliases": [
      "baking soda",
      "meetha soda",
      "samayal soda"
    ],
    "brands": [
      "Tata Salt",
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
    "id": "active_dry_yeast_granules",
    "name": "Active Dry Yeast Granules",
    "tamilName": "உலர் ஈஸ்ட்",
    "category": "Food & Grocery",
    "subCategory": "Baking Ingredients",
    "productType": "Baking Agent",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 50.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "dry yeast",
      "active yeast"
    ],
    "aliases": [
      "dry yeast",
      "active yeast"
    ],
    "brands": [
      "Urban Platter",
      "Puratos"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "idli_milagai_podi_gunpowder",
    "name": "Idli Milagai Podi Gunpowder",
    "tamilName": "இட்லி மிளகாய் பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0,
      500.0
    ],
    "commonNames": [
      "idli podi",
      "gunpowder"
    ],
    "aliases": [
      "idli podi",
      "gunpowder"
    ],
    "brands": [
      "MTR",
      "Aachi",
      "Grand Sweets",
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
    "id": "kollu_idli_podi_horsegram",
    "name": "Kollu Idli Podi Horsegram",
    "tamilName": "கொள்ளு இட்லி பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "kollu idli podi",
      "horsegram podi"
    ],
    "aliases": [
      "kollu idli podi",
      "horsegram podi"
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
    "iconKey": "masala"
  },
  {
    "id": "curry_leaves_idli_podi_karuveppilai",
    "name": "Curry Leaves Idli Podi Karuveppilai",
    "tamilName": "கருவேப்பிலை இட்லி பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "karuveppilai podi",
      "curry leaf podi"
    ],
    "aliases": [
      "karuveppilai podi",
      "curry leaf podi"
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
    "iconKey": "masala"
  },
  {
    "id": "garlic_idli_podi_poondu",
    "name": "Garlic Idli Podi Poondu",
    "tamilName": "பூண்டு இட்லி பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "poondu idli podi",
      "garlic podi"
    ],
    "aliases": [
      "poondu idli podi",
      "garlic podi"
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
    "iconKey": "masala"
  },
  {
    "id": "flaxseed_idli_podi_alividhai",
    "name": "Flaxseed Idli Podi Alividhai",
    "tamilName": "ஆளி விதை இட்லி பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "flaxseed podi",
      "ali vidhai idli podi"
    ],
    "aliases": [
      "flaxseed podi",
      "ali vidhai idli podi"
    ],
    "brands": [
      "Organic Farmers",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "murungai_keerai_podi_drumstick_leaf",
    "name": "Murungai Keerai Podi Drumstick Leaf",
    "tamilName": "முருங்கைக்கீரை சாதப் பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "moringa podi",
      "murungai keerai podi"
    ],
    "aliases": [
      "moringa podi",
      "murungai keerai podi"
    ],
    "brands": [
      "B&B Organics",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "pirandai_rice_podi_cissus",
    "name": "Pirandai Rice Podi Cissus",
    "tamilName": "பிரண்டை சாதப் பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "pirandai podi"
    ],
    "aliases": [
      "pirandai podi"
    ],
    "brands": [
      "B&B Organics",
      "Bio Basics"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "angaya_podi_digestive_health",
    "name": "Angaya Podi Digestive Health",
    "tamilName": "அங்காயப் பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Digestive Spice",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "angaya podi",
      "postpartum powder"
    ],
    "aliases": [
      "angaya podi",
      "postpartum powder"
    ],
    "brands": [
      "Grand Sweets",
      "Ambika Appalam"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "paruppu_podi_roasted_dal_rice_powder",
    "name": "Paruppu Podi Roasted Dal Rice Powder",
    "tamilName": "பருப்பு பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0,
      500.0
    ],
    "commonNames": [
      "paruppu podi",
      "kandi podi",
      "dal podi"
    ],
    "aliases": [
      "paruppu podi",
      "kandi podi",
      "dal podi"
    ],
    "brands": [
      "Grand Sweets",
      "MTR",
      "Aachi",
      "Ambika"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "kothamalli_rice_podi_coriander",
    "name": "Kothamalli Rice Podi Coriander",
    "tamilName": "கொத்தமல்லி சாதப் பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "kothamalli podi",
      "coriander rice powder"
    ],
    "aliases": [
      "kothamalli podi",
      "coriander rice powder"
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
    "iconKey": "masala"
  },
  {
    "id": "pudina_rice_podi_mint",
    "name": "Pudina Rice Podi Mint",
    "tamilName": "புதினா சாதப் பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "pudina podi",
      "mint rice podi"
    ],
    "aliases": [
      "pudina podi",
      "mint rice podi"
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
    "iconKey": "masala"
  },
  {
    "id": "ellu_sadham_podi_sesame_rice_powder",
    "name": "Ellu Sadham Podi Sesame Rice Powder",
    "tamilName": "எள்ளு சாதப் பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "ellu podi",
      "sesame rice powder"
    ],
    "aliases": [
      "ellu podi",
      "sesame rice powder"
    ],
    "brands": [
      "Grand Sweets",
      "Ambika"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "bisibelebath_powder_spice_blend",
    "name": "Bisibelebath Powder Spice Blend",
    "tamilName": "பிசிபேளேபாத் பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "bisibelebath powder"
    ],
    "aliases": [
      "bisibelebath powder"
    ],
    "brands": [
      "MTR",
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
    "id": "vangi_bath_powder_brinjal_rice_spice",
    "name": "Vangi Bath Powder Brinjal Rice Spice",
    "tamilName": "வாங்கி பாத் பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "vangi bath powder"
    ],
    "aliases": [
      "vangi bath powder"
    ],
    "brands": [
      "MTR",
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
    "id": "traditional_rasam_powder",
    "name": "Traditional Rasam Powder",
    "tamilName": "பாரம்பரிய ரசப் பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0,
      500.0
    ],
    "commonNames": [
      "rasam powder",
      "rasapodi"
    ],
    "aliases": [
      "rasam powder",
      "rasapodi"
    ],
    "brands": [
      "MTR",
      "Aachi",
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
    "id": "mysore_rasam_powder_spice_blend",
    "name": "Mysore Rasam Powder Spice Blend",
    "tamilName": "மைசூர் ரசப் பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "mysore rasam powder"
    ],
    "aliases": [
      "mysore rasam powder"
    ],
    "brands": [
      "MTR",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "madras_sambar_powder",
    "name": "Madras Sambar Powder",
    "tamilName": "மெட்ராஸ் சாம்பார் பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0,
      500.0
    ],
    "commonNames": [
      "madras sambar powder",
      "sambar podi"
    ],
    "aliases": [
      "madras sambar powder",
      "sambar podi"
    ],
    "brands": [
      "Aachi",
      "Sakthi",
      "MTR",
      "Tata Sampann"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "arachuvitta_sambar_powder",
    "name": "Arachuvitta Sambar Powder",
    "tamilName": "அரைத்துவிட்ட சாம்பார் பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "arachuvitta sambar powder"
    ],
    "aliases": [
      "arachuvitta sambar powder"
    ],
    "brands": [
      "Grand Sweets",
      "MTR"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "fish_curry_masala_meen_kuzhambu_podi",
    "name": "Fish Curry Masala Meen Kuzhambu Podi",
    "tamilName": "மீன் குழம்பு மசாலா",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "fish curry masala",
      "meen kuzhambu podi"
    ],
    "aliases": [
      "fish curry masala",
      "meen kuzhambu podi"
    ],
    "brands": [
      "Aachi",
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
    "id": "mutton_curry_masala_powder",
    "name": "Mutton Curry Masala Powder",
    "tamilName": "மட்டன் கறி மசாலா",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "mutton masala",
      "mutton curry powder"
    ],
    "aliases": [
      "mutton masala",
      "mutton curry powder"
    ],
    "brands": [
      "Aachi",
      "Sakthi",
      "Everest",
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
    "id": "chicken_chettinad_masala_powder",
    "name": "Chicken Chettinad Masala Powder",
    "tamilName": "செட்டிநாடு சிக்கன் மசாலா",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "chettinad chicken masala"
    ],
    "aliases": [
      "chettinad chicken masala"
    ],
    "brands": [
      "Aachi",
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
    "id": "egg_curry_masala_powder",
    "name": "Egg Curry Masala Powder",
    "tamilName": "முட்டை கறி மசாலா",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "egg curry masala"
    ],
    "aliases": [
      "egg curry masala"
    ],
    "brands": [
      "Eastern",
      "Aachi",
      "Everest"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "royal_biryani_masala_powder",
    "name": "Royal Biryani Masala Powder",
    "tamilName": "ராயல் பிரியாணி மசாலா",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      50.0,
      100.0,
      200.0
    ],
    "commonNames": [
      "biryani masala",
      "briyani podi"
    ],
    "aliases": [
      "biryani masala",
      "briyani podi"
    ],
    "brands": [
      "Aachi",
      "Sakthi",
      "Everest",
      "Shan"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "chana_masala_powder",
    "name": "Chana Masala Powder",
    "tamilName": "சன்னா மசாலா தூள்",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "chana masala",
      "chole masala"
    ],
    "aliases": [
      "chana masala",
      "chole masala"
    ],
    "brands": [
      "Everest",
      "MDH",
      "Catch"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "pav_bhaji_masala_powder",
    "name": "Pav Bhaji Masala Powder",
    "tamilName": "பாவ் பாஜி மசாலா தூள்",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "pav bhaji masala"
    ],
    "aliases": [
      "pav bhaji masala"
    ],
    "brands": [
      "Everest",
      "MDH",
      "Catch",
      "Badshah"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "kitchen_king_all_purpose_masala",
    "name": "Kitchen King All Purpose Masala",
    "tamilName": "கிச்சன் கிங் மசாலா",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "kitchen king masala"
    ],
    "aliases": [
      "kitchen king masala"
    ],
    "brands": [
      "MDH",
      "Everest",
      "Catch"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "chaat_masala_tangy_seasoning",
    "name": "Chaat Masala Tangy Seasoning",
    "tamilName": "சாட் மசாலா",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "chaat masala"
    ],
    "aliases": [
      "chaat masala"
    ],
    "brands": [
      "Catch",
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
    "id": "dry_mango_powder_amchur",
    "name": "Dry Mango Powder Amchur",
    "tamilName": "மாங்காய்த் தூள் (ஆம்சூர்)",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Powder",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "amchur powder",
      "dry mango powder"
    ],
    "aliases": [
      "amchur powder",
      "dry mango powder"
    ],
    "brands": [
      "Catch",
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
    "id": "kasuri_methi_dried_fenugreek",
    "name": "Kasuri Methi Dried Fenugreek",
    "tamilName": "கசூரி மேத்தி",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Dried Herb",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 50.0,
    "customQuantities": [
      25.0,
      50.0,
      100.0
    ],
    "commonNames": [
      "kasuri methi",
      "dried fenugreek leaves"
    ],
    "aliases": [
      "kasuri methi",
      "dried fenugreek leaves"
    ],
    "brands": [
      "Kasuri Methi MDH",
      "Everest",
      "Catch"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "black_salt_kala_namak_powder",
    "name": "Black Salt Kala Namak Powder",
    "tamilName": "கருப்பு உப்பு (காலா நமக்)",
    "category": "Salt, Sugar & Sweeteners",
    "subCategory": "Salt & Sweeteners",
    "productType": "Salt",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "kala namak",
      "black salt powder"
    ],
    "aliases": [
      "kala namak",
      "black salt powder"
    ],
    "brands": [
      "Catch",
      "Tata Salt",
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
    "id": "himalayan_pink_rock_salt_fine",
    "name": "Himalayan Pink Rock Salt Fine",
    "tamilName": "இந்துப்பு பொடி (ஹிமாலயன்)",
    "category": "Salt, Sugar & Sweeteners",
    "subCategory": "Salt & Sweeteners",
    "productType": "Salt",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      0.5,
      1.0
    ],
    "commonNames": [
      "pink salt",
      "sendha namak",
      "indhuppu"
    ],
    "aliases": [
      "pink salt",
      "sendha namak",
      "indhuppu"
    ],
    "brands": [
      "Tata Salt",
      "24 Mantra",
      "Natureland"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "crystal_sea_salt_kalluppu",
    "name": "Crystal Sea Salt Kalluppu",
    "tamilName": "கல் உப்பு",
    "category": "Salt, Sugar & Sweeteners",
    "subCategory": "Salt & Sweeteners",
    "productType": "Salt",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "kallu uppu",
      "crystal salt"
    ],
    "aliases": [
      "kallu uppu",
      "crystal salt"
    ],
    "brands": [
      "Tata Salt",
      "Aashirvaad"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": true,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "iodized_table_salt_thool_uppu",
    "name": "Iodized Table Salt Thool Uppu",
    "tamilName": "தூள் உப்பு (அயோடின்)",
    "category": "Salt, Sugar & Sweeteners",
    "subCategory": "Salt & Sweeteners",
    "productType": "Salt",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "thool uppu",
      "table salt"
    ],
    "aliases": [
      "thool uppu",
      "table salt"
    ],
    "brands": [
      "Tata Salt",
      "Aashirvaad",
      "Annapurna"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "low_sodium_lite_salt",
    "name": "Low Sodium Lite Salt",
    "tamilName": "குறைந்த சோடியம் உப்பு (லைட்)",
    "category": "Salt, Sugar & Sweeteners",
    "subCategory": "Salt & Sweeteners",
    "productType": "Salt",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "low sodium salt",
      "lite salt"
    ],
    "aliases": [
      "low sodium salt",
      "lite salt"
    ],
    "brands": [
      "Tata Salt Lite",
      "Saffola Salt"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "kootu_podi_tamil_brahmin_style",
    "name": "Kootu Podi Tamil Brahmin Style",
    "tamilName": "கூட்டுப் பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "kootu podi"
    ],
    "aliases": [
      "kootu podi"
    ],
    "brands": [
      "Grand Sweets",
      "Ambika Appalam"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "poriyal_curry_powder",
    "name": "Poriyal Curry Powder",
    "tamilName": "பொரியல் மசாலா தூள்",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "poriyal podi",
      "curry powder"
    ],
    "aliases": [
      "poriyal podi",
      "curry powder"
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
    "iconKey": "masala"
  },
  {
    "id": "milagu_rasam_podi_black_pepper_rasam",
    "name": "Milagu Rasam Podi Black Pepper Rasam",
    "tamilName": "மிளகு ரசப் பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "milagu rasam podi",
      "pepper rasam powder"
    ],
    "aliases": [
      "milagu rasam podi",
      "pepper rasam powder"
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
    "iconKey": "masala"
  },
  {
    "id": "poondu_rasam_podi_garlic_rasam",
    "name": "Poondu Rasam Podi Garlic Rasam",
    "tamilName": "பூண்டு ரசப் பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "poondu rasam podi",
      "garlic rasam powder"
    ],
    "aliases": [
      "poondu rasam podi",
      "garlic rasam powder"
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
    "iconKey": "masala"
  },
  {
    "id": "goda_masala_maharashtrian_spice",
    "name": "Goda Masala Maharashtrian Spice",
    "tamilName": "கோடா மசாலா",
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
      "goda masala",
      "kala masala"
    ],
    "aliases": [
      "goda masala",
      "kala masala"
    ],
    "brands": [
      "Suhana",
      "K-Praveen"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "kolhapuri_kanda_lasun_masala",
    "name": "Kolhapuri Kanda Lasun Masala",
    "tamilName": "கோல்ஹாபூரி மசாலா",
    "category": "Spices & Seasonings",
    "subCategory": "Spices & Masalas",
    "productType": "Spice Blend",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "kanda lasun masala",
      "kolhapuri masala"
    ],
    "aliases": [
      "kanda lasun masala",
      "kolhapuri masala"
    ],
    "brands": [
      "Suhana",
      "Badshah"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "shenga_chutney_pudi_peanut_chutney_powder",
    "name": "Shenga Chutney Pudi Peanut Chutney Powder",
    "tamilName": "வேர்க்கடலை சட்னி பொடி",
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
      "shenga chutney pudi",
      "peanut chutney powder",
      "verkadalai podi"
    ],
    "aliases": [
      "shenga chutney pudi",
      "peanut chutney powder",
      "verkadalai podi"
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
    "iconKey": "masala"
  },
  {
    "id": "gurellu_niger_seed_chutney_powder",
    "name": "Gurellu Niger Seed Chutney Powder",
    "tamilName": "குரேள்ளு சட்னி பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Traditional Podis",
    "productType": "Chutney Powder",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "gurellu pudi",
      "niger seed powder"
    ],
    "aliases": [
      "gurellu pudi",
      "niger seed powder"
    ],
    "brands": [
      "MTR",
      "Uchellu"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "dry_coconut_kobbari_chutney_pudi",
    "name": "Dry Coconut Kobbari Chutney Pudi",
    "tamilName": "தேங்காய் சட்னி பொடி",
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
      "kobbari chutney pudi",
      "copra chutney powder"
    ],
    "aliases": [
      "kobbari chutney pudi",
      "copra chutney powder"
    ],
    "brands": [
      "MTR",
      "Grand Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "pure_ashwagandha_powder_withania",
    "name": "Pure Ashwagandha Powder Withania",
    "tamilName": "அஸ்வகந்தா பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Ayurvedic Powders",
    "productType": "Herbal Powder",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "ashwagandha powder",
      "amukkara kizhangu"
    ],
    "aliases": [
      "ashwagandha powder",
      "amukkara kizhangu"
    ],
    "brands": [
      "Patanjali",
      "Baidyanath",
      "Kerala Ayurveda"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "triphala_churna_digestive_powder",
    "name": "Triphala Churna Digestive Powder",
    "tamilName": "திரிபலா சூரணம்",
    "category": "Spices & Seasonings",
    "subCategory": "Ayurvedic Powders",
    "productType": "Herbal Powder",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "triphala churna",
      "triphala powder"
    ],
    "aliases": [
      "triphala churna",
      "triphala powder"
    ],
    "brands": [
      "Dabur",
      "Baidyanath",
      "Patanjali"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "masala"
  },
  {
    "id": "athimathuram_licorice_root_powder",
    "name": "Athimathuram Licorice Root Powder",
    "tamilName": "அதிமதுரம் பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Ayurvedic Powders",
    "productType": "Herbal Powder",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "athimathuram",
      "licorice powder",
      "mulethi"
    ],
    "aliases": [
      "athimathuram",
      "licorice powder",
      "mulethi"
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
    "iconKey": "masala"
  },
  {
    "id": "thippili_long_pepper_powder",
    "name": "Thippili Long Pepper Powder",
    "tamilName": "திப்பிலி பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Ayurvedic Powders",
    "productType": "Herbal Powder",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 50.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "thippili",
      "long pepper powder",
      "pippali"
    ],
    "aliases": [
      "thippili",
      "long pepper powder",
      "pippali"
    ],
    "brands": [
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
    "id": "chitharathai_galangal_powder",
    "name": "Chitharathai Galangal Powder",
    "tamilName": "சித்தரத்தை பொடி",
    "category": "Spices & Seasonings",
    "subCategory": "Ayurvedic Powders",
    "productType": "Herbal Powder",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 50.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "chitharathai",
      "lesser galangal powder"
    ],
    "aliases": [
      "chitharathai",
      "lesser galangal powder"
    ],
    "brands": [
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
    "id": "sukku_malli_coffee_powder",
    "name": "Sukku Malli Coffee Powder",
    "tamilName": "சுக்கு மல்லி காபி தூள்",
    "category": "Beverages",
    "subCategory": "Herbal Drinks",
    "productType": "Herbal Drink Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "sukku malli coffee",
      "dry ginger coriander coffee"
    ],
    "aliases": [
      "sukku malli coffee",
      "dry ginger coriander coffee"
    ],
    "brands": [
      "Grand Sweets",
      "Aachi",
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "buffalo_fresh_milk_pouch",
    "name": "Buffalo Fresh Milk Pouch",
    "tamilName": "எருமைப் பால்",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Milk",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0,
      1000.0
    ],
    "commonNames": [
      "buffalo milk",
      "eruma paal"
    ],
    "aliases": [
      "buffalo milk",
      "eruma paal"
    ],
    "brands": [
      "Aavin",
      "Amul",
      "Nandini"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "standardized_cow_milk_pouch_4_5_fat",
    "name": "Standardized Cow Milk Pouch 4.5% Fat",
    "tamilName": "பசும்பால் (ஆவின் பச்சை)",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Milk",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0,
      1000.0
    ],
    "commonNames": [
      "standard milk",
      "green aavin",
      "pasum paal"
    ],
    "aliases": [
      "standard milk",
      "green aavin",
      "pasum paal"
    ],
    "brands": [
      "Aavin Green",
      "Amul Taaza",
      "Nandini"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "full_cream_rich_milk_pouch_6_fat",
    "name": "Full Cream Rich Milk Pouch 6% Fat",
    "tamilName": "முழு கொழுப்பு பால் (ஆவின் ஆரஞ்சு)",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Milk",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0,
      1000.0
    ],
    "commonNames": [
      "full cream milk",
      "gold milk",
      "orange aavin"
    ],
    "aliases": [
      "full cream milk",
      "gold milk",
      "orange aavin"
    ],
    "brands": [
      "Aavin Orange",
      "Amul Gold",
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
    "id": "toned_cow_milk_pouch_3_fat",
    "name": "Toned Cow Milk Pouch 3% Fat",
    "tamilName": "டோன்டு பால் (ஆவின் நீலம்)",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Milk",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0,
      1000.0
    ],
    "commonNames": [
      "toned milk",
      "blue aavin"
    ],
    "aliases": [
      "toned milk",
      "blue aavin"
    ],
    "brands": [
      "Aavin Blue",
      "Amul Taaza",
      "Nandini"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "skimmed_diet_milk_pouch_0_5_fat",
    "name": "Skimmed Diet Milk Pouch 0.5% Fat",
    "tamilName": "கொழுப்பு நீக்கிய பால் (ஆவின் சிகப்பு)",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Milk",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "skimmed milk",
      "diet milk"
    ],
    "aliases": [
      "skimmed milk",
      "diet milk"
    ],
    "brands": [
      "Aavin Diet",
      "Amul Slim 'n' Trim"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "fresh_set_curd_tub_dahi",
    "name": "Fresh Set Curd Tub Dahi",
    "tamilName": "செட் தயிர்",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Curd",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 400.0,
    "customQuantities": [
      200.0,
      400.0,
      1000.0
    ],
    "commonNames": [
      "set curd",
      "curd tub",
      "dahi"
    ],
    "aliases": [
      "set curd",
      "curd tub",
      "dahi"
    ],
    "brands": [
      "Milky Mist",
      "Amul Masti",
      "Aavin"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "probiotic_cup_curd",
    "name": "Probiotic Cup Curd",
    "tamilName": "புரோபயாடிக் தயிர்",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Curd",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      400.0
    ],
    "commonNames": [
      "probiotic curd",
      "probiotic dahi"
    ],
    "aliases": [
      "probiotic curd",
      "probiotic dahi"
    ],
    "brands": [
      "Amul Probiotic",
      "Epigamia"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "spiced_buttermilk_neer_mor_pouch",
    "name": "Spiced Buttermilk Neer Mor Pouch",
    "tamilName": "மசாலா மோர் / நீர்மோர்",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Buttermilk",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "neer mor",
      "spiced buttermilk",
      "chaas"
    ],
    "aliases": [
      "neer mor",
      "spiced buttermilk",
      "chaas"
    ],
    "brands": [
      "Aavin",
      "Amul Masti Spiced",
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
    "id": "sweet_mango_lassi_bottle",
    "name": "Sweet Mango Lassi Bottle",
    "tamilName": "மாம்பழ லஸ்ஸி",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Lassi",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "mango lassi",
      "sweet lassi"
    ],
    "aliases": [
      "mango lassi",
      "sweet lassi"
    ],
    "brands": [
      "Amul",
      "Mother Dairy",
      "Aavin"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "fresh_malai_paneer_block",
    "name": "Fresh Malai Paneer Block",
    "tamilName": "மசாலா மலாய் பன்னீர்",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Paneer",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0,
      1000.0
    ],
    "commonNames": [
      "paneer block",
      "malai paneer"
    ],
    "aliases": [
      "paneer block",
      "malai paneer"
    ],
    "brands": [
      "Amul Malai Paneer",
      "Milky Mist",
      "Aavin"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "low_fat_paneer_block",
    "name": "Low Fat Paneer Block",
    "tamilName": "குறைந்த கொழுப்பு பன்னீர்",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Paneer",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "low fat paneer",
      "slim paneer"
    ],
    "aliases": [
      "low fat paneer",
      "slim paneer"
    ],
    "brands": [
      "Milky Mist Slim",
      "Amul Light Paneer"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "unsweetened_khoya_mawa_fresh",
    "name": "Unsweetened Khoya Mawa Fresh",
    "tamilName": "கோவா / மாவா (இனிப்பில்லாதது)",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Khoya",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "khoya",
      "mawa unsweetened",
      "palkova raw"
    ],
    "aliases": [
      "khoya",
      "mawa unsweetened",
      "palkova raw"
    ],
    "brands": [
      "Amul Khoya",
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
    "id": "sweetened_condensed_milk_tin",
    "name": "Sweetened Condensed Milk Tin",
    "tamilName": "இனிப்பூட்டப்பட்ட கண்டென்ஸ்டு மில்க்",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Condensed Milk",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 400.0,
    "customQuantities": [
      200.0,
      400.0
    ],
    "commonNames": [
      "milkmaid",
      "condensed milk",
      "mithai mate"
    ],
    "aliases": [
      "milkmaid",
      "condensed milk",
      "mithai mate"
    ],
    "brands": [
      "Nestle Milkmaid",
      "Amul Mithai Mate"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "fresh_dairy_cooking_cream_25_fat",
    "name": "Fresh Dairy Cooking Cream 25% Fat",
    "tamilName": "சமையல் பிரெஷ் கிரீம்",
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
      "fresh cream",
      "cooking cream",
      "amul cream"
    ],
    "aliases": [
      "fresh cream",
      "cooking cream",
      "amul cream"
    ],
    "brands": [
      "Amul Fresh Cream"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "processed_cheese_slices_pack_10s",
    "name": "Processed Cheese Slices Pack 10s",
    "tamilName": "சீஸ் ஸ்லைஸ் (10 எண்ணிக்கை)",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Cheese",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0,
      480.0
    ],
    "commonNames": [
      "cheese slices",
      "amul cheese slice"
    ],
    "aliases": [
      "cheese slices",
      "amul cheese slice"
    ],
    "brands": [
      "Amul",
      "Britannia",
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
    "id": "mozzarella_diced_pizza_cheese",
    "name": "Mozzarella Diced Pizza Cheese",
    "tamilName": "மொசரெல்லா பிட்சா சீஸ்",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Cheese",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "mozzarella cheese",
      "pizza cheese diced"
    ],
    "aliases": [
      "mozzarella cheese",
      "pizza cheese diced"
    ],
    "brands": [
      "Milky Mist Mozzarella",
      "Amul Pizza Cheese",
      "Go Cheese"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "cheddar_cheese_block",
    "name": "Cheddar Cheese Block",
    "tamilName": "செடார் சீஸ் பிளாக்",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Cheese",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "cheddar cheese"
    ],
    "aliases": [
      "cheddar cheese"
    ],
    "brands": [
      "Milky Mist Cheddar",
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
    "id": "cheese_spread_plain_classic",
    "name": "Cheese Spread Plain Classic",
    "tamilName": "சீஸ் ஸ்ப்ரெட்",
    "category": "Dairy & Refrigerated",
    "subCategory": "Dairy Products",
    "productType": "Cheese",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "cheese spread",
      "amul spread"
    ],
    "aliases": [
      "cheese spread",
      "amul spread"
    ],
    "brands": [
      "Amul Cheese Spread",
      "Britannia"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "dairy"
  },
  {
    "id": "whole_wheat_brown_bread_loaf",
    "name": "Whole Wheat Brown Bread Loaf",
    "tamilName": "முழு கோதுமை பிரெட்",
    "category": "Bakery & Breads",
    "subCategory": "Breads & Buns",
    "productType": "Bread",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 400.0,
    "customQuantities": [
      400.0
    ],
    "commonNames": [
      "brown bread",
      "whole wheat bread loaf"
    ],
    "aliases": [
      "brown bread",
      "whole wheat bread loaf"
    ],
    "brands": [
      "Britannia 100% Whole Wheat",
      "Modern",
      "English Oven"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "classic_white_sandwich_bread_loaf",
    "name": "Classic White Sandwich Bread Loaf",
    "tamilName": "வெள்ளை சாண்ட்விச் பிரெட்",
    "category": "Bakery & Breads",
    "subCategory": "Breads & Buns",
    "productType": "Bread",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 400.0,
    "customQuantities": [
      400.0
    ],
    "commonNames": [
      "white bread",
      "sandwich bread"
    ],
    "aliases": [
      "white bread",
      "sandwich bread"
    ],
    "brands": [
      "Britannia Daily Fresh",
      "Modern",
      "Bonn"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "multigrain_fiber_bread_loaf",
    "name": "Multigrain Fiber Bread Loaf",
    "tamilName": "மல்டிகிரைன் பிரெட்",
    "category": "Bakery & Breads",
    "subCategory": "Breads & Buns",
    "productType": "Bread",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 400.0,
    "customQuantities": [
      400.0
    ],
    "commonNames": [
      "multigrain bread"
    ],
    "aliases": [
      "multigrain bread"
    ],
    "brands": [
      "Britannia Multigrain",
      "English Oven",
      "Modern"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "fresh_pav_buns_pack_of_6",
    "name": "Fresh Pav Buns Pack of 6",
    "tamilName": "பாவ் பன் (6 எண்ணிக்கை)",
    "category": "Bakery & Breads",
    "subCategory": "Breads & Buns",
    "productType": "Buns",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 6.0,
    "customQuantities": [
      6.0
    ],
    "commonNames": [
      "pav buns",
      "ladi pav"
    ],
    "aliases": [
      "pav buns",
      "ladi pav"
    ],
    "brands": [
      "Modern",
      "Britannia",
      "Local Bakery"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "burger_buns_pack_of_4",
    "name": "Burger Buns Pack of 4",
    "tamilName": "பர்கர் பன் (4 எண்ணிக்கை)",
    "category": "Bakery & Breads",
    "subCategory": "Breads & Buns",
    "productType": "Buns",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 4.0,
    "customQuantities": [
      4.0
    ],
    "commonNames": [
      "burger buns"
    ],
    "aliases": [
      "burger buns"
    ],
    "brands": [
      "Modern",
      "Britannia",
      "English Oven"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "readymade_pizza_base_pack_of_2",
    "name": "Readymade Pizza Base Pack of 2",
    "tamilName": "பிட்சா பேஸ் (2 எண்ணிக்கை)",
    "category": "Bakery & Breads",
    "subCategory": "Breads & Buns",
    "productType": "Buns",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 2.0,
    "customQuantities": [
      2.0
    ],
    "commonNames": [
      "pizza base pack"
    ],
    "aliases": [
      "pizza base pack"
    ],
    "brands": [
      "Modern",
      "English Oven"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "sweet_coconut_bun_bakery_special",
    "name": "Sweet Coconut Bun Bakery Special",
    "tamilName": "தேங்காய் பன்",
    "category": "Bakery & Breads",
    "subCategory": "Breads & Buns",
    "productType": "Sweet Bun",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Kitchen Counter",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "coconut bun",
      "dilkush bun"
    ],
    "aliases": [
      "coconut bun",
      "dilkush bun"
    ],
    "brands": [
      "Local Bakery",
      "Iyengar Bakery"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "milk_rusk_toast_crunchy_200g",
    "name": "Milk Rusk Toast Crunchy 200g",
    "tamilName": "மில்க் ரஸ்க் டோஸ்ட்",
    "category": "Bakery & Breads",
    "subCategory": "Rusks & Toasts",
    "productType": "Rusk",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      400.0
    ],
    "commonNames": [
      "milk rusk",
      "crisp toast",
      "toastea"
    ],
    "aliases": [
      "milk rusk",
      "crisp toast",
      "toastea"
    ],
    "brands": [
      "Britannia Toastea",
      "Parle Rusk",
      "Sunfeast"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "cake_rusk_double_baked",
    "name": "Cake Rusk Double Baked",
    "tamilName": "கேக் ரஸ்க்",
    "category": "Bakery & Breads",
    "subCategory": "Rusks & Toasts",
    "productType": "Rusk",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      300.0
    ],
    "commonNames": [
      "cake rusk",
      "sweet rusk"
    ],
    "aliases": [
      "cake rusk",
      "sweet rusk"
    ],
    "brands": [
      "Bikaji",
      "Haldiram's",
      "Local Bakery"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "packaged_food"
  },
  {
    "id": "glucose_energy_biscuits",
    "name": "Glucose Energy Biscuits",
    "tamilName": "குளுக்கோஸ் பிஸ்கட்",
    "category": "Snacks & Namkeen",
    "subCategory": "Biscuits & Cookies",
    "productType": "Biscuits",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      100.0,
      250.0,
      800.0
    ],
    "commonNames": [
      "parle g",
      "glucose biscuits"
    ],
    "aliases": [
      "parle g",
      "glucose biscuits"
    ],
    "brands": [
      "Parle-G",
      "Sunfeast Glucose",
      "Tiger"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "marie_gold_tea_biscuits",
    "name": "Marie Gold Tea Biscuits",
    "tamilName": "மேரி கோல்ட் பிஸ்கட்",
    "category": "Snacks & Namkeen",
    "subCategory": "Biscuits & Cookies",
    "productType": "Biscuits",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 300.0,
    "customQuantities": [
      120.0,
      300.0,
      1000.0
    ],
    "commonNames": [
      "marie gold",
      "tea biscuits marie"
    ],
    "aliases": [
      "marie gold",
      "tea biscuits marie"
    ],
    "brands": [
      "Britannia Marie Gold",
      "Sunfeast Marie Light",
      "Parle Marie"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "bourbon_chocolate_cream_biscuits",
    "name": "Bourbon Chocolate Cream Biscuits",
    "tamilName": "போர்பன் சாக்லேட் பிஸ்கட்",
    "category": "Snacks & Namkeen",
    "subCategory": "Biscuits & Cookies",
    "productType": "Biscuits",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 150.0,
    "customQuantities": [
      150.0
    ],
    "commonNames": [
      "bourbon biscuits",
      "chocolate biscuits"
    ],
    "aliases": [
      "bourbon biscuits",
      "chocolate biscuits"
    ],
    "brands": [
      "Britannia Bourbon",
      "Sunfeast Dark Fantasy Bourbon",
      "Parle"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "dark_fantasy_choco_fills_cookies",
    "name": "Dark Fantasy Choco Fills Cookies",
    "tamilName": "டார்க் ஃபேண்டசி சோகோ ஃபில்ஸ்",
    "category": "Snacks & Namkeen",
    "subCategory": "Biscuits & Cookies",
    "productType": "Cookies",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 75.0,
    "customQuantities": [
      75.0,
      300.0
    ],
    "commonNames": [
      "dark fantasy",
      "choco fills cookies"
    ],
    "aliases": [
      "dark fantasy",
      "choco fills cookies"
    ],
    "brands": [
      "Sunfeast Dark Fantasy"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "maska_chaska_butter_herb_crackers_50_50",
    "name": "Maska Chaska Butter Herb Crackers 50-50",
    "tamilName": "மஸ்கா சஸ்கா 50-50 பிஸ்கட்",
    "category": "Snacks & Namkeen",
    "subCategory": "Biscuits & Cookies",
    "productType": "Crackers",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 120.0,
    "customQuantities": [
      120.0
    ],
    "commonNames": [
      "maska chaska",
      "50 50 biscuit"
    ],
    "aliases": [
      "maska chaska",
      "50 50 biscuit"
    ],
    "brands": [
      "Britannia 50-50"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "monaco_classic_salted_crackers",
    "name": "Monaco Classic Salted Crackers",
    "tamilName": "மொனாகோ உப்பு பிஸ்கட்",
    "category": "Snacks & Namkeen",
    "subCategory": "Biscuits & Cookies",
    "productType": "Crackers",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      75.0,
      200.0
    ],
    "commonNames": [
      "monaco biscuits",
      "salted crackers"
    ],
    "aliases": [
      "monaco biscuits",
      "salted crackers"
    ],
    "brands": [
      "Parle Monaco"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "krackjack_sweet_salty_crackers",
    "name": "Krackjack Sweet & Salty Crackers",
    "tamilName": "கிராக்ஜாக் பிஸ்கட்",
    "category": "Snacks & Namkeen",
    "subCategory": "Biscuits & Cookies",
    "productType": "Crackers",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      75.0,
      200.0
    ],
    "commonNames": [
      "krackjack",
      "sweet and salty biscuits"
    ],
    "aliases": [
      "krackjack",
      "sweet and salty biscuits"
    ],
    "brands": [
      "Parle Krackjack"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "good_day_cashew_butter_cookies",
    "name": "Good Day Cashew Butter Cookies",
    "tamilName": "குட் டே முந்திரி பிஸ்கட்",
    "category": "Snacks & Namkeen",
    "subCategory": "Biscuits & Cookies",
    "productType": "Cookies",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0,
      600.0
    ],
    "commonNames": [
      "good day cashew",
      "kaju biscuit"
    ],
    "aliases": [
      "good day cashew",
      "kaju biscuit"
    ],
    "brands": [
      "Britannia Good Day Cashew"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "good_day_butter_cookies_classic",
    "name": "Good Day Butter Cookies Classic",
    "tamilName": "குட் டே வெண்ணெய் பிஸ்கட்",
    "category": "Snacks & Namkeen",
    "subCategory": "Biscuits & Cookies",
    "productType": "Cookies",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "good day butter",
      "butter cookie"
    ],
    "aliases": [
      "good day butter",
      "butter cookie"
    ],
    "brands": [
      "Britannia Good Day Butter"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "good_day_pista_badam_cookies",
    "name": "Good Day Pista Badam Cookies",
    "tamilName": "குட் டே பிஸ்தா பாதாம் பிஸ்கட்",
    "category": "Snacks & Namkeen",
    "subCategory": "Biscuits & Cookies",
    "productType": "Cookies",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "good day pista badam"
    ],
    "aliases": [
      "good day pista badam"
    ],
    "brands": [
      "Britannia Good Day Harmony"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "nice_sugar_sprinkled_coconut_biscuits",
    "name": "Nice Sugar Sprinkled Coconut Biscuits",
    "tamilName": "நைஸ் தேங்காய் பிஸ்கட்",
    "category": "Snacks & Namkeen",
    "subCategory": "Biscuits & Cookies",
    "productType": "Biscuits",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 150.0,
    "customQuantities": [
      150.0
    ],
    "commonNames": [
      "nice biscuits",
      "coconut nice time"
    ],
    "aliases": [
      "nice biscuits",
      "coconut nice time"
    ],
    "brands": [
      "Britannia Nice Time",
      "Parle Nice"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "hide_seek_chocolate_chip_cookies",
    "name": "Hide & Seek Chocolate Chip Cookies",
    "tamilName": "ஹைட் அண்ட் சீக் சாக்லேட் சிப்",
    "category": "Snacks & Namkeen",
    "subCategory": "Biscuits & Cookies",
    "productType": "Cookies",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 120.0,
    "customQuantities": [
      120.0,
      350.0
    ],
    "commonNames": [
      "hide and seek",
      "choco chip cookies"
    ],
    "aliases": [
      "hide and seek",
      "choco chip cookies"
    ],
    "brands": [
      "Parle Hide & Seek"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "little_hearts_sugar_glazed_biscuits",
    "name": "Little Hearts Sugar Glazed Biscuits",
    "tamilName": "லிட்டில் ஹார்ட்ஸ் பிஸ்கட்",
    "category": "Snacks & Namkeen",
    "subCategory": "Biscuits & Cookies",
    "productType": "Biscuits",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 75.0,
    "customQuantities": [
      75.0
    ],
    "commonNames": [
      "little hearts",
      "sugar hearts biscuits"
    ],
    "aliases": [
      "little hearts",
      "sugar hearts biscuits"
    ],
    "brands": [
      "Britannia Little Hearts"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "high_fibre_digestive_wheat_biscuits",
    "name": "High Fibre Digestive Wheat Biscuits",
    "tamilName": "டைஜெஸ்டிவ் பிஸ்கட்",
    "category": "Snacks & Namkeen",
    "subCategory": "Biscuits & Cookies",
    "productType": "Biscuits",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      100.0,
      250.0
    ],
    "commonNames": [
      "digestive biscuits",
      "nutrichoice"
    ],
    "aliases": [
      "digestive biscuits",
      "nutrichoice"
    ],
    "brands": [
      "Britannia NutriChoice Digestive",
      "McVitie's"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "kumbakonam_degree_filter_coffee_powder_80_20",
    "name": "Kumbakonam Degree Filter Coffee Powder 80:20",
    "tamilName": "கும்பகோணம் டிகிரி ஃபில்டர் காபி தூள் (80:20)",
    "category": "Beverages",
    "subCategory": "Coffee",
    "productType": "Filter Coffee",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "kumbakonam degree coffee",
      "filter coffee 80 20"
    ],
    "aliases": [
      "kumbakonam degree coffee",
      "filter coffee 80 20"
    ],
    "brands": [
      "Narasu's",
      "Leo Coffee",
      "Cothas",
      "Bayar's"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "traditional_filter_coffee_powder_70_30_chicory_blend",
    "name": "Traditional Filter Coffee Powder 70:30 Chicory Blend",
    "tamilName": "ஃபில்டர் காபி தூள் (70:30 சிகோரி)",
    "category": "Beverages",
    "subCategory": "Coffee",
    "productType": "Filter Coffee",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "filter coffee 70 30",
      "chicory coffee"
    ],
    "aliases": [
      "filter coffee 70 30",
      "chicory coffee"
    ],
    "brands": [
      "Narasu's Udhayam",
      "Leo Coffee",
      "Cothas Coffee"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "pure_arabica_100_filter_coffee_powder",
    "name": "Pure Arabica 100% Filter Coffee Powder",
    "tamilName": "அராபிகா ஃபில்டர் காபி தூள் (100% பியூர்)",
    "category": "Beverages",
    "subCategory": "Coffee",
    "productType": "Filter Coffee",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "pure arabica coffee",
      "arabica plantation filter"
    ],
    "aliases": [
      "pure arabica coffee",
      "arabica plantation filter"
    ],
    "brands": [
      "Blue Tokai",
      "Leo Coffee",
      "Third Wave"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "instant_agglomerated_pure_coffee_glass_jar",
    "name": "Instant Agglomerated Pure Coffee Glass Jar",
    "tamilName": "இன்ஸ்டன்ட் காபி தூள் (பியூர்)",
    "category": "Beverages",
    "subCategory": "Coffee",
    "productType": "Instant Coffee",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      50.0,
      100.0,
      200.0
    ],
    "commonNames": [
      "nescafe classic",
      "instant coffee pure"
    ],
    "aliases": [
      "nescafe classic",
      "instant coffee pure"
    ],
    "brands": [
      "Nescafe Classic",
      "Bru Pure",
      "Tata Coffee Grand"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "instant_coffee_chicory_blend_jar",
    "name": "Instant Coffee Chicory Blend Jar",
    "tamilName": "இன்ஸ்டன்ட் காபி சிகோரி மிக்ஸ்",
    "category": "Beverages",
    "subCategory": "Coffee",
    "productType": "Instant Coffee",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      50.0,
      100.0,
      200.0
    ],
    "commonNames": [
      "bru instant",
      "sunrise coffee"
    ],
    "aliases": [
      "bru instant",
      "sunrise coffee"
    ],
    "brands": [
      "Bru Instant",
      "Sunrise Instant",
      "Tata Coffee Gold"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "strong_ctc_dust_tea_powder_tamil_nadu_blend",
    "name": "Strong CTC Dust Tea Powder Tamil Nadu Blend",
    "tamilName": "சி.டி.சி டஸ்ட் தேயிலைத் தூள்",
    "category": "Beverages",
    "subCategory": "Tea",
    "productType": "Tea Powder",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 0.5,
    "customQuantities": [
      0.25,
      0.5,
      1.0
    ],
    "commonNames": [
      "dust tea",
      "3 roses dust",
      "strong tea powder"
    ],
    "aliases": [
      "dust tea",
      "3 roses dust",
      "strong tea powder"
    ],
    "brands": [
      "3 Roses Dust",
      "Chakra Gold",
      "Kannan Devan",
      "AVT Premium"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "premium_ctc_leaf_tea",
    "name": "Premium CTC Leaf Tea",
    "tamilName": "சி.டி.சி லீஃப் டீ",
    "category": "Beverages",
    "subCategory": "Tea",
    "productType": "Leaf Tea",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "leaf tea",
      "tata tea gold",
      "red label tea"
    ],
    "aliases": [
      "leaf tea",
      "tata tea gold",
      "red label tea"
    ],
    "brands": [
      "Tata Tea Gold",
      "Red Label Natural Care",
      "Wagh Bakri"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "darjeeling_long_leaf_black_tea_tin",
    "name": "Darjeeling Long Leaf Black Tea Tin",
    "tamilName": "டார்ஜிலிங் லாங் லீஃப் டீ",
    "category": "Beverages",
    "subCategory": "Tea",
    "productType": "Leaf Tea",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      100.0,
      250.0
    ],
    "commonNames": [
      "darjeeling tea",
      "orthodox black tea"
    ],
    "aliases": [
      "darjeeling tea",
      "orthodox black tea"
    ],
    "brands": [
      "Twinings Darjeeling",
      "Tata Tea Gold Care",
      "Teabox"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "cardamom_elaichi_tea_bags_box_25s",
    "name": "Cardamom Elaichi Tea Bags Box 25s",
    "tamilName": "ஏலக்காய் டீ பேக்குகள் (25 எண்ணிக்கை)",
    "category": "Beverages",
    "subCategory": "Tea",
    "productType": "Tea Bags",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 25.0,
    "customQuantities": [
      25.0,
      50.0
    ],
    "commonNames": [
      "elaichi tea bags",
      "cardamom tea"
    ],
    "aliases": [
      "elaichi tea bags",
      "cardamom tea"
    ],
    "brands": [
      "Taj Mahal Elaichi",
      "Tetley",
      "Wagh Bakri"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "green_tea_lemon_honey_bags_box_25s",
    "name": "Green Tea Lemon & Honey Bags Box 25s",
    "tamilName": "கிரீன் டீ (எலுமிச்சை & தேன், 25 எண்ணிக்கை)",
    "category": "Beverages",
    "subCategory": "Tea",
    "productType": "Green Tea",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 25.0,
    "customQuantities": [
      25.0,
      100.0
    ],
    "commonNames": [
      "green tea bags",
      "lemon honey green tea"
    ],
    "aliases": [
      "green tea bags",
      "lemon honey green tea"
    ],
    "brands": [
      "Lipton Green Tea",
      "Tetley",
      "Organic India"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "tulsi_green_tea_detox_bags_box_25s",
    "name": "Tulsi Green Tea Detox Bags Box 25s",
    "tamilName": "துளசி கிரீன் டீ (25 எண்ணிக்கை)",
    "category": "Beverages",
    "subCategory": "Tea",
    "productType": "Green Tea",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 25.0,
    "customQuantities": [
      25.0
    ],
    "commonNames": [
      "tulsi green tea",
      "detox tea"
    ],
    "aliases": [
      "tulsi green tea",
      "detox tea"
    ],
    "brands": [
      "Organic India Tulsi Green",
      "Typhoo"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "authentic_nannari_sarbath_root_syrup",
    "name": "Authentic Nannari Sarbath Root Syrup",
    "tamilName": "நன்னாரி சர்பத் சிரப்",
    "category": "Beverages",
    "subCategory": "Syrups & Squashes",
    "productType": "Syrup",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 750.0,
    "customQuantities": [
      500.0,
      750.0
    ],
    "commonNames": [
      "nannari sarbath",
      "sarasaparilla syrup"
    ],
    "aliases": [
      "nannari sarbath",
      "sarasaparilla syrup"
    ],
    "brands": [
      "Mylapore Ganapathy",
      "Karthik Nannari",
      "Local Artisans"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "traditional_rose_milk_flavored_syrup",
    "name": "Traditional Rose Milk Flavored Syrup",
    "tamilName": "ரோஸ் மில்க் சிரப்",
    "category": "Beverages",
    "subCategory": "Syrups & Squashes",
    "productType": "Syrup",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 750.0,
    "customQuantities": [
      500.0,
      750.0
    ],
    "commonNames": [
      "rose syrup",
      "rose milk essence"
    ],
    "aliases": [
      "rose syrup",
      "rose milk essence"
    ],
    "brands": [
      "Mapro Rose",
      "Kalvert",
      "Mala's"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "kokum_sharbat_natural_digestive_squash",
    "name": "Kokum Sharbat Natural Digestive Squash",
    "tamilName": "கோகம் சர்பத் சிரப்",
    "category": "Beverages",
    "subCategory": "Syrups & Squashes",
    "productType": "Syrup",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "kokum syrup",
      "kokum sharbat"
    ],
    "aliases": [
      "kokum syrup",
      "kokum sharbat"
    ],
    "brands": [
      "Mapro",
      "Kokum Natural"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "royal_badam_drink_mix_powder_jar",
    "name": "Royal Badam Drink Mix Powder Jar",
    "tamilName": "பாதாம் பால் மிக்ஸ் பவுடர்",
    "category": "Beverages",
    "subCategory": "Health Drinks",
    "productType": "Drink Mix",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "badam drink mix",
      "badam milk powder"
    ],
    "aliases": [
      "badam drink mix",
      "badam milk powder"
    ],
    "brands": [
      "MTR Badam Drink Mix",
      "Aachi Badam",
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
    "id": "tender_coconut_water_tetra_pack_200ml",
    "name": "Tender Coconut Water Tetra Pack 200ml",
    "tamilName": "இளநீர் டெட்ரா பேக் (200 மி.லி)",
    "category": "Beverages",
    "subCategory": "Juices & Drinks",
    "productType": "Coconut Water",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "tender coconut water pack",
      "packaged elaneer"
    ],
    "aliases": [
      "tender coconut water pack",
      "packaged elaneer"
    ],
    "brands": [
      "Raw Pressery",
      "Paper Boat",
      "Coco Jal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "pure_aloe_vera_juice_sugar_free_1l",
    "name": "Pure Aloe Vera Juice Sugar Free 1L",
    "tamilName": "சோற்றுக்கற்றாழை சாறு",
    "category": "Beverages",
    "subCategory": "Health Drinks",
    "productType": "Ayurvedic Juice",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1000.0,
    "customQuantities": [
      1000.0
    ],
    "commonNames": [
      "aloe vera juice",
      "katrazhai juice"
    ],
    "aliases": [
      "aloe vera juice",
      "katrazhai juice"
    ],
    "brands": [
      "Kapiva",
      "Baidyanath",
      "Patanjali"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "pure_amla_gooseberry_juice_1l",
    "name": "Pure Amla Gooseberry Juice 1L",
    "tamilName": "நெல்லிக்காய் சாறு (1 லிட்டர்)",
    "category": "Beverages",
    "subCategory": "Health Drinks",
    "productType": "Ayurvedic Juice",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1000.0,
    "customQuantities": [
      1000.0
    ],
    "commonNames": [
      "amla juice pure",
      "nellikai saaru"
    ],
    "aliases": [
      "amla juice pure",
      "nellikai saaru"
    ],
    "brands": [
      "Kapiva Amla Juice",
      "Baidyanath",
      "Patanjali"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "beverage"
  },
  {
    "id": "motichoor_laddu_desi_ghee",
    "name": "Motichoor Laddu Desi Ghee",
    "tamilName": "மோதிசூர் லட்டு (நெய்)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Laddu",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "motichoor laddu",
      "motichur ladoo"
    ],
    "aliases": [
      "motichoor laddu",
      "motichur ladoo"
    ],
    "brands": [
      "A2B",
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
    "id": "besan_laddu_roasted_gram_sweet",
    "name": "Besan Laddu Roasted Gram Sweet",
    "tamilName": "கடலை மாவு லட்டு (பேசன்)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Laddu",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "besan laddu",
      "besan ladoo"
    ],
    "aliases": [
      "besan laddu",
      "besan ladoo"
    ],
    "brands": [
      "Haldiram's",
      "A2B",
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
    "id": "rava_laddu_with_cashews_raisins",
    "name": "Rava Laddu With Cashews & Raisins",
    "tamilName": "ரவா லட்டு",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Laddu",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "rava laddu",
      "sooji ladoo"
    ],
    "aliases": [
      "rava laddu",
      "sooji ladoo"
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
    "id": "maa_laddu_roasted_gram_flour_sweet",
    "name": "Maa Laddu Roasted Gram Flour Sweet",
    "tamilName": "மாலாடு / பொட்டுக்கடலை லட்டு",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Laddu",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0
    ],
    "commonNames": [
      "maladu",
      "maa laddu",
      "pottukadalai laddu"
    ],
    "aliases": [
      "maladu",
      "maa laddu",
      "pottukadalai laddu"
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
    "id": "kaju_katli_diamond_silver_foil",
    "name": "Kaju Katli Diamond Silver Foil",
    "tamilName": "காஜு கட்லி முந்திரி கேக்",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Kaju Sweet",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "kaju katli",
      "cashew barfi"
    ],
    "aliases": [
      "kaju katli",
      "cashew barfi"
    ],
    "brands": [
      "Haldiram's",
      "A2B",
      "Bikano",
      "Sri Krishna Sweets"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "doodh_peda_traditional_milk_sweet",
    "name": "Doodh Peda Traditional Milk Sweet",
    "tamilName": "தூத் பேடா",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Milk Sweet",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "doodh peda",
      "milk peda",
      "nandini peda"
    ],
    "aliases": [
      "doodh peda",
      "milk peda",
      "nandini peda"
    ],
    "brands": [
      "Nandini Peda",
      "A2B",
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
    "id": "rasgulla_canned_tin_1kg",
    "name": "Rasgulla Canned Tin 1kg",
    "tamilName": "ரசகுல்லா டின் (1 கிலோ)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Canned Sweet",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "rasgulla tin",
      "sponge rasgulla"
    ],
    "aliases": [
      "rasgulla tin",
      "sponge rasgulla"
    ],
    "brands": [
      "Haldiram's Rasgulla",
      "Bikano",
      "KC Das"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "gulab_jamun_canned_tin_1kg",
    "name": "Gulab Jamun Canned Tin 1kg",
    "tamilName": "குலாப் ஜாமுன் டின் (1 கிலோ)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Canned Sweet",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "gulab jamun tin",
      "kala jamun canned"
    ],
    "aliases": [
      "gulab jamun tin",
      "kala jamun canned"
    ],
    "brands": [
      "Haldiram's Gulab Jamun",
      "Bikano",
      "MTR"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "soan_papdi_desi_ghee_flaky_sweet",
    "name": "Soan Papdi Desi Ghee Flaky Sweet",
    "tamilName": "சோன் பப்டி (நெய்)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Flaky Sweet",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pantry Shelf",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "soan papdi",
      "patisa"
    ],
    "aliases": [
      "soan papdi",
      "patisa"
    ],
    "brands": [
      "Haldiram's Soan Papdi",
      "Bikaji",
      "Patanjali"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "kasi_halwa_white_pumpkin_sweet",
    "name": "Kasi Halwa White Pumpkin Sweet",
    "tamilName": "காசி அல்வா (பூசணிக்காய்)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Halwa",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0
    ],
    "commonNames": [
      "kasi halwa",
      "ash gourd halwa"
    ],
    "aliases": [
      "kasi halwa",
      "ash gourd halwa"
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
    "id": "fresh_carrot_halwa_gajar_ka_halwa",
    "name": "Fresh Carrot Halwa Gajar Ka Halwa",
    "tamilName": "கேரட் அல்வா (காஜர் கா அல்வா)",
    "category": "Snacks & Namkeen",
    "subCategory": "Traditional Sweets",
    "productType": "Halwa",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Refrigerator",
    "minimumQuantity": 250.0,
    "customQuantities": [
      250.0,
      500.0
    ],
    "commonNames": [
      "gajar halwa",
      "carrot halwa"
    ],
    "aliases": [
      "gajar halwa",
      "carrot halwa"
    ],
    "brands": [
      "Haldiram's",
      "A2B",
      "Bikanervala"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "snacks"
  },
  {
    "id": "bleaching_powder_disinfectant_calcium_hypochlorite",
    "name": "Bleaching Powder Disinfectant Calcium Hypochlorite",
    "tamilName": "ப்ளீச்சிங் பவுடர்",
    "category": "Household & Cleaning",
    "subCategory": "Surface Cleaners & Pest Control",
    "productType": "Disinfectant",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Utility Room",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0,
      1000.0
    ],
    "commonNames": [
      "bleaching powder",
      "chuna bleach"
    ],
    "aliases": [
      "bleaching powder",
      "chuna bleach"
    ],
    "brands": [
      "Bengal Chemicals",
      "Local"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "instant_drain_declogger_drain_cleaner_powder",
    "name": "Instant Drain Declogger Drain Cleaner Powder",
    "tamilName": "ட்ரைன் கிளீனர் பவுடர் (அடைப்பு நீக்கி)",
    "category": "Household & Cleaning",
    "subCategory": "Surface Cleaners & Pest Control",
    "productType": "Drain Cleaner",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Utility Room",
    "minimumQuantity": 50.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "drain cleaner",
      "dranex crystals"
    ],
    "aliases": [
      "drain cleaner",
      "dranex crystals"
    ],
    "brands": [
      "Kiwi Dranex",
      "Mr Muscle Drain"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "concentrated_heavy_duty_floor_phenyl_white",
    "name": "Concentrated Heavy Duty Floor Phenyl White",
    "tamilName": "வெள்ளை பினாயில் (தரை கழுவ)",
    "category": "Household & Cleaning",
    "subCategory": "Surface Cleaners & Pest Control",
    "productType": "Floor Cleaner",
    "defaultUnit": "l",
    "soldBy": "volume",
    "storageLocation": "Utility Room",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      5.0
    ],
    "commonNames": [
      "white phenyl",
      "floor phenyl"
    ],
    "aliases": [
      "white phenyl",
      "floor phenyl"
    ],
    "brands": [
      "Doctor Brand",
      "Bengal Chemicals",
      "Gainda"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "fragrant_green_pine_herbal_floor_cleaner",
    "name": "Fragrant Green Pine Herbal Floor Cleaner",
    "tamilName": "பச்சை பைன் பினாயில்",
    "category": "Household & Cleaning",
    "subCategory": "Surface Cleaners & Pest Control",
    "productType": "Floor Cleaner",
    "defaultUnit": "l",
    "soldBy": "volume",
    "storageLocation": "Utility Room",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "green phenyl",
      "pine oil floor cleaner"
    ],
    "aliases": [
      "green phenyl",
      "pine oil floor cleaner"
    ],
    "brands": [
      "Gainda",
      "Doctor Brand"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "brass_copper_vessels_cleaning_powder_pitambari",
    "name": "Brass & Copper Vessels Cleaning Powder Pitambari",
    "tamilName": "பீதாம்பரி பவுடர் (பித்தளை பாத்திரம் கழுவ)",
    "category": "Household & Cleaning",
    "subCategory": "Dishwashing",
    "productType": "Metal Cleaner",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Utility Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "pitambari powder",
      "brass cleaner powder"
    ],
    "aliases": [
      "pitambari powder",
      "brass cleaner powder"
    ],
    "brands": [
      "Pitambari Shining Powder"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "silver_shine_liquid_dip_cleaner",
    "name": "Silver Shine Liquid Dip Cleaner",
    "tamilName": "சில்வர் கிளீனர் திரவம் (வெள்ளி பாத்திரம்)",
    "category": "Household & Cleaning",
    "subCategory": "Dishwashing",
    "productType": "Metal Cleaner",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Utility Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "silver dip cleaner",
      "velli cleaner"
    ],
    "aliases": [
      "silver dip cleaner",
      "velli cleaner"
    ],
    "brands": [
      "Roopam Silver Shine",
      "Pitambari"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "kitchen_chimney_degreaser_spray_500ml",
    "name": "Kitchen Chimney Degreaser Spray 500ml",
    "tamilName": "சிம்னி கிளீனர் ஸ்ப்ரே",
    "category": "Household & Cleaning",
    "subCategory": "Surface Cleaners & Pest Control",
    "productType": "Degreaser",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Kitchen Cabinet",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "chimney cleaner",
      "kitchen degreaser spray"
    ],
    "aliases": [
      "chimney cleaner",
      "kitchen degreaser spray"
    ],
    "brands": [
      "Cif Power Pro",
      "Mr Muscle Kitchen"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "tap_shower_limescale_remover_spray_500ml",
    "name": "Tap & Shower Limescale Remover Spray 500ml",
    "tamilName": "குழாய் உப்புக்கறை நீக்கி ஸ்ப்ரே",
    "category": "Household & Cleaning",
    "subCategory": "Surface Cleaners & Pest Control",
    "productType": "Limescale Remover",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Bathroom Shelf",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "tap cleaner spray",
      "limescale remover"
    ],
    "aliases": [
      "tap cleaner spray",
      "limescale remover"
    ],
    "brands": [
      "Cif Limescale",
      "Harpic Red Bathroom"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "washing_machine_drum_descaler_tablets_6_pack",
    "name": "Washing Machine Drum Descaler Tablets 6 Pack",
    "tamilName": "வாஷிங் மெஷின் டிரம் கிளீனர் மாத்திரைகள்",
    "category": "Household & Cleaning",
    "subCategory": "Laundry Care",
    "productType": "Descaler",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Utility Shelf",
    "minimumQuantity": 6.0,
    "customQuantities": [
      6.0
    ],
    "commonNames": [
      "washing machine tablets",
      "drum descaler"
    ],
    "aliases": [
      "washing machine tablets",
      "drum descaler"
    ],
    "brands": [
      "Bosch Descaler",
      "IFB Scalego",
      "Fortune"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "spin_mop_bucket_replacement_microfiber_head",
    "name": "Spin Mop Bucket Replacement Microfiber Head",
    "tamilName": "ஸ்பின் மாப் ரீஃபில் தலை",
    "category": "Household & Cleaning",
    "subCategory": "Cleaning Tools",
    "productType": "Mop Refill",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Utility Room",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "spin mop refill head",
      "mop replacement pad"
    ],
    "aliases": [
      "spin mop refill head",
      "mop replacement pad"
    ],
    "brands": [
      "Gala Spin Mop Refill",
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
    "id": "long_handle_bottle_cleaning_brush",
    "name": "Long Handle Bottle Cleaning Brush",
    "tamilName": "பாட்டில் கிளீனிங் பிரஷ்",
    "category": "Household & Cleaning",
    "subCategory": "Cleaning Tools",
    "productType": "Brush",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Kitchen Cabinet",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "bottle brush",
      "flask cleaning brush"
    ],
    "aliases": [
      "bottle brush",
      "flask cleaning brush"
    ],
    "brands": [
      "Gala",
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
    "id": "shoe_polish_black_wax_paste_tin_40g",
    "name": "Shoe Polish Black Wax Paste Tin 40g",
    "tamilName": "கருப்பு ஷூ பாலிஷ் டின்",
    "category": "Household & Cleaning",
    "subCategory": "Home Utilities",
    "productType": "Shoe Care",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Shoe Rack",
    "minimumQuantity": 40.0,
    "customQuantities": [
      40.0
    ],
    "commonNames": [
      "black shoe polish",
      "cherry blossom wax"
    ],
    "aliases": [
      "black shoe polish",
      "cherry blossom wax"
    ],
    "brands": [
      "Cherry Blossom Black",
      "Kiwi"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "hardware"
  },
  {
    "id": "shoe_shine_instant_sponge_neutral",
    "name": "Shoe Shine Instant Sponge Neutral",
    "tamilName": "ஷூ ஷைன் ஸ்பாஞ்ச்",
    "category": "Household & Cleaning",
    "subCategory": "Home Utilities",
    "productType": "Shoe Care",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Shoe Rack",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "shoe shine sponge",
      "instant shoe polish"
    ],
    "aliases": [
      "shoe shine sponge",
      "instant shoe polish"
    ],
    "brands": [
      "Cherry Blossom Express Shine",
      "Kiwi"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "hardware"
  },
  {
    "id": "termite_control_insecticide_spray_200ml",
    "name": "Termite Control Insecticide Spray 200ml",
    "tamilName": "கரையான் மருந்து ஸ்ப்ரே",
    "category": "Household & Cleaning",
    "subCategory": "Surface Cleaners & Pest Control",
    "productType": "Pest Control",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Utility Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0
    ],
    "commonNames": [
      "termite spray",
      "karayan marundhu"
    ],
    "aliases": [
      "termite spray",
      "karayan marundhu"
    ],
    "brands": [
      "Hit Termite",
      "Pest Seal"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "rat_glue_trap_sticky_board_heavy_duty",
    "name": "Rat Glue Trap Sticky Board Heavy Duty",
    "tamilName": "எலி பசை அட்டை (ட்ராப்)",
    "category": "Household & Cleaning",
    "subCategory": "Surface Cleaners & Pest Control",
    "productType": "Pest Control",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Utility Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0,
      2.0
    ],
    "commonNames": [
      "rat glue pad",
      "sticky mouse trap"
    ],
    "aliases": [
      "rat glue pad",
      "sticky mouse trap"
    ],
    "brands": [
      "Trubble Gum Glue Trap",
      "Hit"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "cleaning"
  },
  {
    "id": "nalangu_maavu_herbal_bath_powder",
    "name": "Nalangu Maavu Herbal Bath Powder",
    "tamilName": "நலங்கு மாவு மூலிகை குளியல் பொடி",
    "category": "Personal Care & Hygiene",
    "subCategory": "Bath & Body Care",
    "productType": "Herbal Bath Powder",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Bathroom Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0,
      500.0
    ],
    "commonNames": [
      "nalangu maavu",
      "ubtan powder",
      "herbal bath powder"
    ],
    "aliases": [
      "nalangu maavu",
      "ubtan powder",
      "herbal bath powder"
    ],
    "brands": [
      "Local Ayurvedic",
      "Gramiyum",
      "Kama Ayurveda"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "pure_multani_mitti_fuller_s_earth_powder",
    "name": "Pure Multani Mitti Fuller's Earth Powder",
    "tamilName": "முல்தானி மிட்டி பவுடர்",
    "category": "Personal Care & Hygiene",
    "subCategory": "Skin Care",
    "productType": "Clay Powder",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Bathroom Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "multani mitti",
      "fullers earth"
    ],
    "aliases": [
      "multani mitti",
      "fullers earth"
    ],
    "brands": [
      "Banjara's",
      "Nature's Tattva",
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
    "id": "pure_rose_water_face_toner_spray_bottle",
    "name": "Pure Rose Water Face Toner Spray Bottle",
    "tamilName": "ரோஸ் வாட்டர் டோனர் ஸ்ப்ரே",
    "category": "Personal Care & Hygiene",
    "subCategory": "Skin Care",
    "productType": "Toner",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Dressing Table",
    "minimumQuantity": 200.0,
    "customQuantities": [
      100.0,
      200.0
    ],
    "commonNames": [
      "gulabari rose water",
      "face rose toner"
    ],
    "aliases": [
      "gulabari rose water",
      "face rose toner"
    ],
    "brands": [
      "Dabur Gulabari",
      "Kama Ayurveda"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "pure_glycerin_liquid_usp_grade_100g",
    "name": "Pure Glycerin Liquid USP Grade 100g",
    "tamilName": "கிளிசரின் திரவம்",
    "category": "Personal Care & Hygiene",
    "subCategory": "Skin Care",
    "productType": "Moisturizer",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Bathroom Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "pure glycerin",
      "glycerol"
    ],
    "aliases": [
      "pure glycerin",
      "glycerol"
    ],
    "brands": [
      "Dabur Glycerin",
      "Local Pharma"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "pure_petroleum_jelly_tin_50g",
    "name": "Pure Petroleum Jelly Tin 50g",
    "tamilName": "பெட்ரோலியம் ஜெல்லி டின்",
    "category": "Personal Care & Hygiene",
    "subCategory": "Skin Care",
    "productType": "Skin Protectant",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Dressing Table",
    "minimumQuantity": 50.0,
    "customQuantities": [
      50.0,
      100.0
    ],
    "commonNames": [
      "vaseline jelly",
      "petroleum jelly"
    ],
    "aliases": [
      "vaseline jelly",
      "petroleum jelly"
    ],
    "brands": [
      "Vaseline Pure Jelly"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "pure_aloe_vera_soothing_gel_99",
    "name": "Pure Aloe Vera Soothing Gel 99%",
    "tamilName": "கற்றாழை ஜெல் (99%)",
    "category": "Personal Care & Hygiene",
    "subCategory": "Skin Care",
    "productType": "Gel",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Dressing Table",
    "minimumQuantity": 150.0,
    "customQuantities": [
      100.0,
      150.0
    ],
    "commonNames": [
      "aloe vera gel",
      "katrazhai gel"
    ],
    "aliases": [
      "aloe vera gel",
      "katrazhai gel"
    ],
    "brands": [
      "Patanjali Kanti Aloe",
      "Wow Skin",
      "Mamaearth"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "purifying_neem_face_wash_pump_tube",
    "name": "Purifying Neem Face Wash Pump Tube",
    "tamilName": "வேப்பிலை ஃபேஸ் வாஷ்",
    "category": "Personal Care & Hygiene",
    "subCategory": "Skin Care",
    "productType": "Face Wash",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Bathroom Shelf",
    "minimumQuantity": 150.0,
    "customQuantities": [
      100.0,
      150.0
    ],
    "commonNames": [
      "himalaya neem face wash",
      "neem cleanser"
    ],
    "aliases": [
      "himalaya neem face wash",
      "neem cleanser"
    ],
    "brands": [
      "Himalaya Neem Face Wash",
      "Clean & Clear"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "herbal_anti_dandruff_shampoo",
    "name": "Herbal Anti Dandruff Shampoo",
    "tamilName": "மூலிகை பொடுகு நீக்கும் ஷாம்பு",
    "category": "Personal Care & Hygiene",
    "subCategory": "Hair Care",
    "productType": "Shampoo",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Bathroom Shelf",
    "minimumQuantity": 180.0,
    "customQuantities": [
      180.0,
      360.0
    ],
    "commonNames": [
      "anti dandruff shampoo",
      "podugu shampoo"
    ],
    "aliases": [
      "anti dandruff shampoo",
      "podugu shampoo"
    ],
    "brands": [
      "Head & Shoulders",
      "Himalaya Anti Dandruff"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "nourishing_coconut_milk_conditioner",
    "name": "Nourishing Coconut Milk Conditioner",
    "tamilName": "தேங்காய் பால் ஹேர் கண்டிஷனர்",
    "category": "Personal Care & Hygiene",
    "subCategory": "Hair Care",
    "productType": "Conditioner",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Bathroom Shelf",
    "minimumQuantity": 180.0,
    "customQuantities": [
      180.0
    ],
    "commonNames": [
      "hair conditioner",
      "coconut milk conditioner"
    ],
    "aliases": [
      "hair conditioner",
      "coconut milk conditioner"
    ],
    "brands": [
      "TRESemme",
      "L'Oreal",
      "Dove"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "pain_relief_balm_strong",
    "name": "Pain Relief Balm Strong",
    "tamilName": "வலி நிவாரண தைலம்",
    "category": "Personal Care & Hygiene",
    "subCategory": "Health & Wellness",
    "productType": "Balm",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 50.0,
    "customQuantities": [
      30.0,
      50.0
    ],
    "commonNames": [
      "amrutanjan balm",
      "pain relief balm",
      "thailam"
    ],
    "aliases": [
      "amrutanjan balm",
      "pain relief balm",
      "thailam"
    ],
    "brands": [
      "Amrutanjan Strong",
      "Zandu Balm",
      "Tiger Balm"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "fast_pain_relief_spray_55g",
    "name": "Fast Pain Relief Spray 55g",
    "tamilName": "வலி நிவாரண ஸ்ப்ரே",
    "category": "Personal Care & Hygiene",
    "subCategory": "Health & Wellness",
    "productType": "Spray",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 55.0,
    "customQuantities": [
      55.0
    ],
    "commonNames": [
      "moov spray",
      "volini spray",
      "pain spray"
    ],
    "aliases": [
      "moov spray",
      "volini spray",
      "pain spray"
    ],
    "brands": [
      "Moov Spray",
      "Volini Spray",
      "Relispray"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "adhesive_first_aid_bandages_pack_of_20",
    "name": "Adhesive First Aid Bandages Pack of 20",
    "tamilName": "பேண்டேஜ் ஸ்ட்ரிப்ஸ் (20 எண்ணிக்கை)",
    "category": "Personal Care & Hygiene",
    "subCategory": "Health & Wellness",
    "productType": "First Aid",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Medicine Box",
    "minimumQuantity": 20.0,
    "customQuantities": [
      20.0,
      100.0
    ],
    "commonNames": [
      "band aid",
      "adhesive bandage"
    ],
    "aliases": [
      "band aid",
      "adhesive bandage"
    ],
    "brands": [
      "Band-Aid Johnson's",
      "Hansaplast"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "prickly_heat_cooling_menthol_powder",
    "name": "Prickly Heat Cooling Menthol Powder",
    "tamilName": "வேர்க்குரு பவுடர் (கூலிங்)",
    "category": "Personal Care & Hygiene",
    "subCategory": "Bath & Body Care",
    "productType": "Talc",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Dressing Table",
    "minimumQuantity": 150.0,
    "customQuantities": [
      150.0
    ],
    "commonNames": [
      "dermi cool powder",
      "nycil prickly heat"
    ],
    "aliases": [
      "dermi cool powder",
      "nycil prickly heat"
    ],
    "brands": [
      "Dermi Cool",
      "Nycil Cool Herbal",
      "BoroPlus"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "personal_care"
  },
  {
    "id": "baby_diaper_pants_extra_large_xl_32s",
    "name": "Baby Diaper Pants Extra Large XL 32s",
    "tamilName": "குழந்தை டயபர் - எக்ஸ்ட்ரா லார்ஜ் (32 எண்ணிக்கை)",
    "category": "Baby Care",
    "subCategory": "Baby Hygiene & Wellness",
    "productType": "Diapers",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Baby Care Shelf",
    "minimumQuantity": 32.0,
    "customQuantities": [
      32.0,
      56.0
    ],
    "commonNames": [
      "baby diaper xl",
      "pampers xl"
    ],
    "aliases": [
      "baby diaper xl",
      "pampers xl"
    ],
    "brands": [
      "Pampers XL Pants",
      "MamyPoko XL",
      "Huggies XL"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "baby_care"
  },
  {
    "id": "baby_diaper_pants_small_s_42s",
    "name": "Baby Diaper Pants Small S 42s",
    "tamilName": "குழந்தை டயபர் - ஸ்மால் (42 எண்ணிக்கை)",
    "category": "Baby Care",
    "subCategory": "Baby Hygiene & Wellness",
    "productType": "Diapers",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Baby Care Shelf",
    "minimumQuantity": 42.0,
    "customQuantities": [
      42.0
    ],
    "commonNames": [
      "baby diaper small",
      "pampers small"
    ],
    "aliases": [
      "baby diaper small",
      "pampers small"
    ],
    "brands": [
      "Pampers Small Pants",
      "MamyPoko S"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "baby_care"
  },
  {
    "id": "fragrance_free_baby_water_wipes_72_wipes",
    "name": "Fragrance Free Baby Water Wipes 72 Wipes",
    "tamilName": "குழந்தை வாட்டர் வைப்ஸ் (72 எண்ணிக்கை)",
    "category": "Baby Care",
    "subCategory": "Baby Hygiene & Wellness",
    "productType": "Wipes",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Baby Care Shelf",
    "minimumQuantity": 72.0,
    "customQuantities": [
      72.0
    ],
    "commonNames": [
      "baby water wipes",
      "pure water wipes"
    ],
    "aliases": [
      "baby water wipes",
      "pure water wipes"
    ],
    "brands": [
      "Mother Sparsh 99% Pure Water",
      "Himalaya Wipes"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "baby_care"
  },
  {
    "id": "gentle_baby_body_wash_head_to_toe_200ml",
    "name": "Gentle Baby Body Wash Head to Toe 200ml",
    "tamilName": "குழந்தை ஹெட் டூ டோ வாஷ்",
    "category": "Baby Care",
    "subCategory": "Baby Hygiene & Wellness",
    "productType": "Baby Wash",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Baby Care Shelf",
    "minimumQuantity": 200.0,
    "customQuantities": [
      200.0,
      500.0
    ],
    "commonNames": [
      "baby wash head to toe",
      "johnson baby wash"
    ],
    "aliases": [
      "baby wash head to toe",
      "johnson baby wash"
    ],
    "brands": [
      "Johnson's Top-to-Toe",
      "Sebamed Baby",
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
    "id": "baby_feeding_bottle_bpa_free_250ml",
    "name": "Baby Feeding Bottle BPA Free 250ml",
    "tamilName": "குழந்தை பால் பாட்டில் (250 மி.லி)",
    "category": "Baby Care",
    "subCategory": "Baby Feeding",
    "productType": "Bottle",
    "defaultUnit": "piece",
    "soldBy": "piece",
    "storageLocation": "Baby Care Shelf",
    "minimumQuantity": 1.0,
    "customQuantities": [
      1.0
    ],
    "commonNames": [
      "baby feeding bottle",
      "paal bottle"
    ],
    "aliases": [
      "baby feeding bottle",
      "paal bottle"
    ],
    "brands": [
      "Pigeon BPA Free",
      "Philips Avent",
      "Chicco"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "baby_care"
  },
  {
    "id": "liquid_cleanser_for_baby_bottles_nipples_500ml",
    "name": "Liquid Cleanser for Baby Bottles & Nipples 500ml",
    "tamilName": "பால் பாட்டில் கிளீனிங் லிக்விட்",
    "category": "Baby Care",
    "subCategory": "Baby Feeding",
    "productType": "Cleanser",
    "defaultUnit": "ml",
    "soldBy": "volume",
    "storageLocation": "Kitchen Cabinet",
    "minimumQuantity": 500.0,
    "customQuantities": [
      500.0
    ],
    "commonNames": [
      "baby bottle cleanser liquid",
      "nipple wash"
    ],
    "aliases": [
      "baby bottle cleanser liquid",
      "nipple wash"
    ],
    "brands": [
      "Pigeon Liquid Cleanser",
      "Mee Mee Cleanser"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "baby_care"
  },
  {
    "id": "puppy_dry_food_chicken_egg_1_2kg",
    "name": "Puppy Dry Food Chicken & Egg 1.2kg",
    "tamilName": "குட்டி நாய் உலர் உணவு (சிக்கன் & முட்டை)",
    "category": "Pet Care",
    "subCategory": "Pet Food",
    "productType": "Dog Food",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Pet Care Shelf",
    "minimumQuantity": 1.2,
    "customQuantities": [
      1.2,
      3.0
    ],
    "commonNames": [
      "puppy food",
      "pedigree puppy dry"
    ],
    "aliases": [
      "puppy food",
      "pedigree puppy dry"
    ],
    "brands": [
      "Pedigree Puppy",
      "Drools Puppy"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pets"
  },
  {
    "id": "wet_dog_food_pouch_chicken_gravy_100g",
    "name": "Wet Dog Food Pouch Chicken Gravy 100g",
    "tamilName": "நாய் ஈர உணவு (சிக்கன் கிரேவி பாக்கெட்)",
    "category": "Pet Care",
    "subCategory": "Pet Food",
    "productType": "Dog Food",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pet Care Shelf",
    "minimumQuantity": 100.0,
    "customQuantities": [
      100.0
    ],
    "commonNames": [
      "wet dog food pouch",
      "pedigree gravy pouch"
    ],
    "aliases": [
      "wet dog food pouch",
      "pedigree gravy pouch"
    ],
    "brands": [
      "Pedigree Pouch Gravy",
      "Drools Pouch"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pets"
  },
  {
    "id": "rawhide_dog_chew_bones_4_inch_pack_of_4",
    "name": "Rawhide Dog Chew Bones 4 Inch Pack of 4",
    "tamilName": "நாய் மெல்லும் எலும்பு (4 எண்ணிக்கை)",
    "category": "Pet Care",
    "subCategory": "Pet Food",
    "productType": "Pet Treats",
    "defaultUnit": "piece",
    "soldBy": "package",
    "storageLocation": "Pet Care Shelf",
    "minimumQuantity": 4.0,
    "customQuantities": [
      4.0
    ],
    "commonNames": [
      "dog chew bones",
      "rawhide bones"
    ],
    "aliases": [
      "dog chew bones",
      "rawhide bones"
    ],
    "brands": [
      "Gnawlers Bones",
      "Meat Up"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pets"
  },
  {
    "id": "adult_cat_wet_food_pouch_tuna_in_jelly_85g",
    "name": "Adult Cat Wet Food Pouch Tuna in Jelly 85g",
    "tamilName": "பூனை ஈர உணவு (டுனா மீன் பாக்கெட்)",
    "category": "Pet Care",
    "subCategory": "Pet Food",
    "productType": "Cat Food",
    "defaultUnit": "g",
    "soldBy": "weight",
    "storageLocation": "Pet Care Shelf",
    "minimumQuantity": 85.0,
    "customQuantities": [
      85.0
    ],
    "commonNames": [
      "cat wet food pouch",
      "whiskas tuna pouch"
    ],
    "aliases": [
      "cat wet food pouch",
      "whiskas tuna pouch"
    ],
    "brands": [
      "Whiskas Tuna Jelly",
      "Sheba Pouch"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pets"
  },
  {
    "id": "clumping_bentonite_cat_litter_sand_5kg",
    "name": "Clumping Bentonite Cat Litter Sand 5kg",
    "tamilName": "பூனை மணல் (லிட்டர் 5 கிலோ)",
    "category": "Pet Care",
    "subCategory": "Pet Hygiene",
    "productType": "Cat Litter",
    "defaultUnit": "kg",
    "soldBy": "weight",
    "storageLocation": "Utility Shelf",
    "minimumQuantity": 5.0,
    "customQuantities": [
      5.0,
      10.0
    ],
    "commonNames": [
      "cat litter sand",
      "bentonite cat litter"
    ],
    "aliases": [
      "cat litter sand",
      "bentonite cat litter"
    ],
    "brands": [
      "Emily Pets Litter",
      "Intersand"
    ],
    "barcodeSupport": true,
    "barcodeType": "EAN_13",
    "barcodes": [],
    "isLoose": false,
    "isPackaged": true,
    "iconKey": "pets"
  }
]"""

def get_matrix_catalog():
    return json.loads(_DATA)

if __name__ == "__main__":
    items = get_matrix_catalog()
    print(f"Loaded {len(items)} matrix expansion items.")
