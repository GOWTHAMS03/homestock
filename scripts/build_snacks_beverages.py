#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Helper generator script to compile comprehensive Snacks, Beverages, Breakfast,
Instant Foods, Bakery, Sweets, Sauces and Pickles expansion items.
Target: ~550 authentic Indian household items.
"""

import json

ITEMS = []

def add(item_id, name, tamil, cat, subcat, ptype, unit, sold_by, loc, min_q, q_list, common, aliases, brands, bc_sup, bc_type, loose, pkg, icon):
    ITEMS.append({
        "id": item_id,
        "name": name,
        "tamilName": tamil,
        "category": cat,
        "subCategory": subcat,
        "productType": ptype,
        "defaultUnit": unit,
        "soldBy": sold_by,
        "storageLocation": loc,
        "minimumQuantity": min_q,
        "customQuantities": q_list,
        "commonNames": common,
        "aliases": aliases,
        "brands": brands,
        "barcodeSupport": bc_sup,
        "barcodeType": bc_type,
        "barcodes": [],
        "isLoose": loose,
        "isPackaged": pkg,
        "iconKey": icon
    })

# --- TRADITIONAL SOUTH INDIAN & INDIAN SAVORY SNACKS (NAMKEEN) ---
namkeen_data = [
    ("kai_murukku_traditional", "Handmade Kai Murukku", "கை முறுக்கு", "Murukku", "Pantry Shelf", ["Kai Murukku", "Hand Rolled Murukku", "Chakli"], ["Grand Sweets", "A2B", "Sri Krishna Sweets"]),
    ("thenkuzhal_murukku", "Thenkuzhal Murukku", "தேன்குழல் முறுக்கு", "Murukku", "Pantry Shelf", ["Thenkuzhal", "Thenkuzhal Murukku"], ["Grand Sweets", "A2B"]),
    ("ribbon_pakoda_nada", "Ribbon Pakoda / Nada", "ரிப்பன் பக்கோடா", "Pakoda", "Pantry Shelf", ["Ribbon Pakoda", "Nada Thenguzhal", "Ribbon Murukku"], ["A2B", "Grand Sweets", "Haldiram's"]),
    ("mullu_murukku_star", "Mullu Murukku / Magizhampoo Murukku", "முள்ளு முறுக்கு", "Murukku", "Pantry Shelf", ["Mullu Murukku", "Star Murukku", "Magizham"], ["Grand Sweets", "A2B"]),
    ("butter_murukku_vennai", "Butter Murukku / Vennai Murukku", "வெண்ணெய் முறுக்கு", "Murukku", "Pantry Shelf", ["Butter Murukku", "Vennai Murukku"], ["Grand Sweets", "A2B", "Anand Sweets"]),
    ("manapparai_murukku", "Manapparai Crispy Murukku", "மணப்பாறை முறுக்கு", "Murukku", "Pantry Shelf", ["Manapparai Murukku", "Crispy Rice Murukku"], ["Local Artisans", "Grand Sweets"]),
    ("thattai_crispy_crackers", "Thattai Crispy Rice Crackers", "தட்டை", "Thattai", "Pantry Shelf", ["Thattai", "Thattu Vadai", "Nippattu"], ["Grand Sweets", "A2B", "Sri Krishna Sweets"]),
    ("thattai_pepper_karuppu_milagu", "Black Pepper Thattai", "மிளகு தட்டை", "Thattai", "Pantry Shelf", ["Milagu Thattai", "Pepper Thattai"], ["Grand Sweets", "A2B"]),
    ("uppu_seedai_crispy", "Uppu Seedai / Salt Seedai", "உப்பு சீடை", "Seedai", "Pantry Shelf", ["Uppu Seedai", "Salted Seedai"], ["Grand Sweets", "A2B"]),
    ("omapodi_ajwain_sev", "Omapodi / Ajwain Sev", "ஓமப்பொடி", "Sev", "Pantry Shelf", ["Omapodi", "Ajwain Sev", "Fine Sev"], ["Grand Sweets", "A2B", "Haldiram's"]),
    ("kara_boondi_spicy", "Spicy Kara Boondi with Curry Leaves", "கார பூந்தி", "Boondi", "Pantry Shelf", ["Kara Boondi", "Spicy Boondi", "Tikha Boondi"], ["Haldiram's", "A2B", "Grand Sweets", "Bikaji"]),
    ("madras_mixture_special", "Madras Mixture Special", "மதராஸ் மிக்சர்", "Mixture", "Pantry Shelf", ["Madras Mixture", "South Indian Mixture"], ["Grand Sweets", "A2B", "Sri Krishna Sweets", "Haldiram's"]),
    ("cornflakes_mixture_spicy", "Spicy Cornflakes Mixture", "கார்ன்ஃபிளேக்ஸ் மிக்சர்", "Mixture", "Pantry Shelf", ["Cornflakes Mixture", "Makka Mixture"], ["Haldiram's", "A2B", "Bikaji"]),
    ("bombay_mixture_special", "Special Bombay Mixture", "பம்பாய் மிக்சர்", "Mixture", "Pantry Shelf", ["Bombay Mixture", "Royal Mixture"], ["Haldiram's", "Bikano"]),
    ("navratan_mixture_tangy", "Navratan Mixture Tangy & Sweet", "நவரத்தன் மிக்சர்", "Mixture", "Pantry Shelf", ["Navratan Mixture", "9 Gems Namkeen"], ["Haldiram's", "Bikano"]),
    ("aloo_bhujia_mint_spiced", "Aloo Bhujia Crispy Sev", "ஆலூ புஜியா", "Bhujia", "Pantry Shelf", ["Aloo Bhujia", "Potato Sev"], ["Haldiram's", "Bikaji", "Balaji"]),
    ("bikaneri_bhujia_moth_dal", "Bikaneri Bhujia Authentic", "பிகானேரி புஜியா", "Bhujia", "Pantry Shelf", ["Bikaneri Bhujia", "Moth Dal Sev"], ["Haldiram's", "Bikaji"]),
    ("moong_dal_salted_fried", "Salted Fried Moong Dal", "வறுத்த பாசிப்பருப்பு", "Namkeen", "Pantry Shelf", ["Salted Moong Dal", "Fried Moong Dal"], ["Haldiram's", "Bikaji", "Balaji"]),
    ("chana_dal_spicy_fried", "Spicy Fried Chana Dal", "காரக் கடலைப்பருப்பு", "Namkeen", "Pantry Shelf", ["Chana Dal Namkeen", "Spicy Fried Gram"], ["Haldiram's", "Bikano"]),
    ("roasted_peanuts_salted", "Roasted Salted Peanuts", "வறுத்த உப்பு வேர்க்கடலை", "Nuts", "Pantry Shelf", ["Salted Peanuts", "Uppu Kadhala"], ["Haldiram's", "Tong Garden", "Balaji"]),
    ("roasted_peanuts_masala", "Spicy Masala Peanuts", "மசாலா வேர்க்கடலை", "Nuts", "Pantry Shelf", ["Masala Peanuts", "Besan Coated Peanuts", "Tasty Nuts"], ["Haldiram's", "A2B", "Balaji"]),
    ("roasted_peanuts_hing_jeera", "Hing Jeera Roasted Peanuts", "பெருங்காய வேர்க்கடலை", "Nuts", "Pantry Shelf", ["Hing Peanuts", "Jeera Peanuts"], ["Haldiram's", "Balaji"]),
    ("roasted_chana_with_skin", "Roasted Black Chana With Skin", "வறுத்த கருப்புக் கொண்டைக்கடலை", "Namkeen", "Pantry Shelf", ["Bhuna Chana", "Roasted Gram With Skin"], ["Local Brand", "Haldiram's"]),
    ("banana_chips_salted_coconut_oil", "Kerala Salted Banana Chips in Coconut Oil", "கேரளா நேந்திரங்காய் சிப்ஸ்", "Chips", "Pantry Shelf", ["Nendran Chips", "Kerala Banana Chips", "Salted Banana Chips"], ["A1 Chips", "Hot Chips", "Grand Sweets"]),
    ("banana_chips_black_pepper", "Black Pepper Banana Chips", "மிளகு நேந்திரங்காய் சிப்ஸ்", "Chips", "Pantry Shelf", ["Pepper Banana Chips", "Milagu Chips"], ["A1 Chips", "Hot Chips"]),
    ("banana_chips_spicy_red_chilli", "Spicy Red Chili Banana Chips", "கார நேந்திரங்காய் சிப்ஸ்", "Chips", "Pantry Shelf", ["Spicy Banana Chips", "Masala Banana Chips"], ["A1 Chips", "Hot Chips"]),
    ("tapioca_chips_salted", "Salted Tapioca / Maravalli Kizhangu Chips", "மரவள்ளிக்கிழங்கு சிப்ஸ்", "Chips", "Pantry Shelf", ["Maravalli Chips", "Tapioca Chips", "Kappa Chips"], ["A1 Chips", "Hot Chips"]),
    ("tapioca_chips_spicy_chilli", "Spicy Red Chili Tapioca Chips", "கார மரவள்ளிக்கிழங்கு சிப்ஸ்", "Chips", "Pantry Shelf", ["Chili Tapioca Chips", "Kara Maravalli Chips"], ["A1 Chips", "Hot Chips"]),
    ("tapioca_sticks_fingers_spicy", "Spicy Tapioca Sticks / Finger Chips", "மரவள்ளி குச்சி சிப்ஸ்", "Chips", "Pantry Shelf", ["Tapioca Sticks", "Kuchi Chips"], ["A1 Chips", "Hot Chips"]),
    ("potato_chips_classic_salted", "Classic Salted Potato Chips", "உருளைக்கிழங்கு சிப்ஸ் - சால்டட்", "Chips", "Pantry Shelf", ["Salted Potato Chips", "Plain Wafers"], ["Lay's", "Balaji", "Bingo"]),
    ("potato_chips_cream_onion", "Sour Cream & Onion Potato Chips", "கிரீம் & ஆனியன் உருளை சிப்ஸ்", "Chips", "Pantry Shelf", ["Cream and Onion Chips", "Green Lay's"], ["Lay's", "Pringles", "Bingo"]),
    ("potato_chips_magic_masala", "India's Magic Masala Potato Chips", "மேஜிக் மசாலா உருளை சிப்ஸ்", "Chips", "Pantry Shelf", ["Magic Masala Chips", "Blue Lay's"], ["Lay's", "Bingo"]),
    ("potato_chips_spanish_tomato", "Spanish Tomato Tango Potato Chips", "ஸ்பானிஷ் டொமேட்டோ சிப்ஸ்", "Chips", "Pantry Shelf", ["Tomato Chips", "Red Lay's"], ["Lay's", "Balaji"]),
    ("potato_wafers_salt_pepper", "Salt & Black Pepper Thin Potato Wafers", "உப்பு மிளகு உருளை வேஃபர்ஸ்", "Chips", "Pantry Shelf", ["Pepper Wafers", "Thin Potato Chips"], ["Balaji", "Chhajed"]),
    ("karela_bitter_gourd_chips", "Crispy Spiced Bitter Gourd Chips", "பாகற்காய் சிப்ஸ்", "Chips", "Pantry Shelf", ["Pavakkai Chips", "Karela Chips"], ["A1 Chips", "Hot Chips"]),
    ("roasted_makhana_himalayan_salt", "Roasted Fox Nuts / Makhana Himalayan Salt", "வறுத்த தாமரை விதை - உப்பு", "Makhana", "Pantry Shelf", ["Roasted Makhana", "Phool Makhana Snack"], ["Farmley", "Happilo", "Tong Garden"]),
    ("roasted_makhana_peri_peri", "Roasted Makhana Peri Peri Spiced", "வறுத்த தாமரை விதை - பெரி பெரி", "Makhana", "Pantry Shelf", ["Peri Peri Makhana", "Spicy Fox Nuts"], ["Farmley", "Happilo"]),
    ("roasted_makhana_cream_onion", "Roasted Makhana Sour Cream & Onion", "வறுத்த தாமரை விதை - கிரீம் ஆனியன்", "Makhana", "Pantry Shelf", ["Cream Onion Makhana"], ["Farmley", "Happilo"]),
    ("chakli_spirals_crispy", "Crispy Spiced Chakli Spirals", "சக்லி", "Chakli", "Pantry Shelf", ["Chakli", "Bhajani Chakli"], ["Haldiram's", "Bikaji", "Chitale Bandhu"]),
    ("dry_fruit_kachori_mini", "Mini Dry Fruit Sweet & Spicy Kachori", "மினி உலர் பழ கச்சோரி", "Kachori", "Pantry Shelf", ["Mini Kachori", "Dry Fruit Kachori"], ["Haldiram's", "Bikaji"]),
    ("dry_samosa_mini", "Mini Cocktail Dry Samosa", "மினி சமோசா", "Samosa", "Pantry Shelf", ["Mini Samosa", "Cocktail Samosa"], ["Haldiram's", "Bikano"])
]

for item_id, name, tamil, ptype, loc, common, brands in namkeen_data:
    add(
        item_id, name, tamil, "Snacks & Branded Foods", "Indian Snacks & Namkeen",
        ptype, "g", "weight", loc, 150.0, [100.0, 150.0, 200.0, 400.0],
        common, [c.lower() for c in common], brands,
        True, "EAN_13", False, True, "snacks"
    )

# --- BISCUITS, COOKIES & RUSK ---
biscuit_data = [
    ("marie_biscuit_classic", "Classic Marie Tea Biscuits", "மேரி பிஸ்கட்", "Biscuits", ["Marie Light", "Marie Gold", "Tea Biscuits"], ["Britannia", "Sunfeast", "Parle"]),
    ("glucose_biscuit_parle_g_style", "Milk & Wheat Glucose Biscuits", "குளுக்கோஸ் பிஸ்கட்", "Biscuits", ["Glucose Biscuits", "Parle G Biscuits"], ["Parle", "Britannia", "Sunfeast"]),
    ("butter_cookies_danish_style", "Rich Butter Cookies", "வெண்ணெய் குக்கீஸ்", "Cookies", ["Butter Cookies", "Good Day Butter"], ["Britannia", "Unibic"]),
    ("cashew_badam_cookies", "Cashew Badam Rich Cookies", "முந்திரி பாதாம் குக்கீஸ்", "Cookies", ["Kaju Badam Cookies", "Good Day Cashew"], ["Britannia", "Sunfeast", "Unibic"]),
    ("pista_badam_cookies", "Pista Badam Crunchy Cookies", "பிஸ்தா பாதாம் குக்கீஸ்", "Cookies", ["Pista Badam Cookies"], ["Britannia", "Unibic"]),
    ("bourbon_chocolate_cream_biscuit", "Chocolate Bourbon Cream Sandwich Biscuits", "போர்பன் சாக்லேட் கிரீம் பிஸ்கட்", "Biscuits", ["Bourbon Biscuits", "Chocolate Cream Biscuit"], ["Britannia", "Sunfeast", "Parle"]),
    ("dark_fantasy_choco_fills", "Choco Fills Molten Core Cookies", "டார்க் ஃபேண்டஸி சோக்கோ ஃபில்ஸ்", "Cookies", ["Choco Fills", "Dark Fantasy Cookies"], ["Sunfeast"]),
    ("digestive_high_fibre_biscuits", "High Fibre Digestive Biscuits", "ஹை ஃபைபர் டைஜெஸ்டிவ் பிஸ்கட்", "Biscuits", ["Digestive Biscuits", "Wheat Biscuits", "NutriChoice"], ["Britannia", "McVitie's", "Sunfeast"]),
    ("oats_almond_digestive_cookies", "Oats and Almond Digestive Cookies", "ஓட்ஸ் பாதாம் குக்கீஸ்", "Cookies", ["Oats Cookies", "NutriChoice Oats"], ["Britannia", "Sunfeast"]),
    ("cream_cracker_salted_biscuits", "Crispy Salted Cream Crackers", "சால்டட் கிரீம் கிராக்கர்", "Crackers", ["Cream Crackers", "Salt Crackers"], ["Britannia", "Sunfeast"]),
    ("monaco_salted_mini_crackers", "Salted Mini Crackers Monaco Style", "மொனாகோ சால்ட் பிஸ்கட்", "Crackers", ["Monaco Crackers", "Salt Biscuits"], ["Parle", "Britannia"]),
    ("fifty_fifty_sweet_and_salty", "Sweet & Salty Light Crackers 50-50", "ஸ்வீட் & சால்ட் கிராக்கர்", "Crackers", ["50 50 Biscuits", "Sweet and Salty"], ["Britannia", "Parle"]),
    ("jeera_cumin_crispy_biscuits", "Jeera Cumin Spiced Light Crackers", "சீரக பிஸ்கட்", "Crackers", ["Jeera Biscuits", "Cumin Crackers"], ["Britannia", "Parle"]),
    ("milk_rusk_crunchy_toast", "Crispy Premium Milk Rusk Toast", "பால் ரஸ்க்", "Rusk", ["Milk Rusk", "Tea Toast", "Rusk"], ["Britannia", "Parle", "Bakefresh"]),
    ("elaichi_cardamom_rusk", "Crispy Elaichi Cardamom Rusk Toast", "ஏலக்காய் ரஸ்க்", "Rusk", ["Elaichi Rusk", "Cardamom Toast"], ["Britannia", "Parle", "Sunfeast"]),
    ("suji_wheat_rusk", "Crispy Suji Wheat Rusk Toast", "ரவா ரஸ்க்", "Rusk", ["Suji Rusk", "Semolina Toast"], ["Britannia", "Bakefresh"]),
    ("osmania_biscuits_hyderabadi", "Authentic Hyderabadi Osmania Biscuits", "உஸ்மானியா பிஸ்கட்", "Biscuits", ["Osmania Biscuits", "Tea Salt Biscuits"], ["Subhan Bakery", "Karachi Bakery"]),
    ("fruit_biscuits_karachi_style", "Tutti Frutti Cashew Fruit Biscuits", "டூட்டி ஃப்ரூட்டி பழ பிஸ்கட்", "Biscuits", ["Fruit Biscuits", "Karachi Biscuits"], ["Karachi Bakery", "Anand Sweets"]),
    ("puffed_khari_puff_pastry", "Crispy Butter Puffed Khari", "மடக்கு காரி பிஸ்கட்", "Bakery", ["Khari Biscuit", "Puff Pastry Biscuit"], ["Bakefresh", "Wibs", "Parle"]),
    ("chocochip_cookies_fresh", "Crispy Chocolate Chip Cookies", "சாக்கோ சிப் குக்கீஸ்", "Cookies", ["Choco Chip Cookies"], ["Unibic", "Britannia", "Sunfeast"])
]

for item_id, name, tamil, ptype, common, brands in biscuit_data:
    add(
        item_id, name, tamil, "Snacks & Branded Foods", "Biscuits & Cookies",
        ptype, "g", "weight", "Pantry Shelf", 120.0, [75.0, 120.0, 200.0, 300.0],
        common, [c.lower() for c in common], brands,
        True, "EAN_13", False, True, "snacks"
    )

# --- TRADITIONAL INDIAN SWEETS, HALWAS & CHIKKI ---
sweet_data = [
    ("motichoor_laddu_pure_ghee", "Pure Desi Ghee Motichoor Laddu", "நெய் மோதிச்சூர் லட்டு", "Laddu", ["Motichoor Laddu", "Ghee Laddu"], ["A2B", "Sri Krishna Sweets", "Haldiram's", "Bikano"]),
    ("boondi_laddu_traditional", "Traditional Boondi Laddu", "பூந்தி லட்டு", "Laddu", ["Boondi Laddu", "Tirupati Style Laddu"], ["Grand Sweets", "A2B", "Sri Krishna Sweets"]),
    ("besan_laddu_pure_ghee", "Pure Desi Ghee Besan Laddu", "கடலை மாவு லட்டு", "Laddu", ["Besan Laddu", "Gram Flour Laddu"], ["Haldiram's", "Bikaji", "A2B"]),
    ("mysore_pak_mysurpa_soft", "Soft Pure Ghee Mysore Pak / Mysurpa", "நெய் மைசூர் பாக்", "Mysore Pak", ["Mysurpa", "Ghee Mysore Pak", "Soft Mysore Pak"], ["Sri Krishna Sweets", "A2B", "Grand Sweets"]),
    ("tirunelveli_wheat_halwa", "Traditional Tirunelveli Wheat Halwa", "திருநெல்வேலி கோதுமை அல்வா", "Halwa", ["Tirunelveli Halwa", "Godhumai Alva", "Wheat Halwa"], ["Iruttu Kadai Halwa", "Shanthi Sweets", "A2B"]),
    ("soan_papdi_desi_ghee", "Desi Ghee Soan Papdi Flaky Sweet", "சோன் பப்டி", "Soan Papdi", ["Soan Papdi", "Flaky Soan Halwa"], ["Haldiram's", "Bikano", "Patanjali", "A2B"]),
    ("kaju_katli_pure_cashew", "Pure Kaju Katli / Cashew Diamond Barfi", "முந்திரி கேக் / காஜு கத்லி", "Barfi", ["Kaju Katli", "Kaju Barfi", "Cashew Sweet"], ["Haldiram's", "A2B", "Sri Krishna Sweets", "Bikanervala"]),
    ("gulab_jamun_tin_can", "Gulab Jamun in Sugar Syrup Tin", "குலாப் ஜாமூன்", "Gulab Jamun", ["Gulab Jamun Tin", "Canned Gulab Jamun"], ["Haldiram's", "Bikano", "MTR", "Gits"]),
    ("rasgulla_tin_can", "Spongy Rasgulla in Sugar Syrup Tin", "ரஸகுல்லா", "Rasgulla", ["Rasgulla Tin", "Bengali Rasgulla"], ["Haldiram's", "KC Das", "Bikano"]),
    ("dharwad_peda_authentic", "Authentic Rich Dharwad Peda", "தார்வாட் பேடா", "Peda", ["Dharwad Peda", "Brown Peda"], ["Mishra Peda", "Nandini", "Anand Sweets"]),
    ("mathura_peda_kesar", "Kesar Mathura Peda Khoya Sweet", "கேசர் பேடா", "Peda", ["Mathura Peda", "Kesar Peda", "Milk Peda"], ["Haldiram's", "A2B", "Brijwasi"]),
    ("jangiri_imarti_pure_ghee", "Traditional Jangiri / Imarti Sweet", "ஜாங்கிரி", "Jangiri", ["Jangiri", "Imarti", "Ghee Jangiri"], ["Grand Sweets", "A2B", "Sri Krishna Sweets"]),
    ("badusha_balushahi", "Desi Ghee Badusha / Balushahi Flaky Sweet", "பாதுஷா", "Badusha", ["Badusha", "Balushahi"], ["Grand Sweets", "A2B", "Sri Krishna Sweets"]),
    ("peanut_chikki_kadala_mittai_bar", "Kovilpatti Peanut Chikki Bar / Kadalai Mittai", "கோவில்பட்டி கடலை மிட்டாய்", "Chikki", ["Kadalai Mittai", "Peanut Chikki", "Shengdana Chikki"], ["Kovilpatti Artisans", "Paper Boat", "Haldiram's"]),
    ("crushed_peanut_chikki", "Crushed Peanut Chikki Crisp", "நொறுக்கு கடலை மிட்டாய்", "Chikki", ["Crushed Chikki", "Peanut Brittle"], ["Paper Boat", "Haldiram's"]),
    ("kamarkat_coconut_jaggery_toffee", "Traditional Coconut Jaggery Toffee / Kamarkat", "கமர்கட்டு", "Candy", ["Kamarkat", "Coconut Jaggery Ball", "Thengai Kamarkat"], ["Local Artisans", "Grand Sweets"]),
    ("pori_urundai_puffed_rice_balls", "Crispy Puffed Rice Jaggery Balls / Pori Urundai", "பொரி உருண்டை", "Sweet", ["Pori Urundai", "Murmura Laddu", "Karthigai Pori Urundai"], ["Grand Sweets", "Local Artisans"]),
    ("ellu_urundai_sesame_jaggery_balls", "Black Sesame Jaggery Balls / Ellu Urundai", "எள்ளு உருண்டை", "Sweet", ["Ellu Urundai", "Til Laddu", "Sesame Balls"], ["Grand Sweets", "A2B", "Sri Krishna Sweets"]),
    ("dairymilk_chocolate_bar", "Smooth Creamy Milk Chocolate Bar", "மில்க் சாக்லேட் பார்", "Chocolate", ["Milk Chocolate", "Dairy Milk", "Chocolate Bar"], ["Cadbury", "Nestle", "Amul"]),
    ("dark_chocolate_bar_70_percent", "Rich 70% Dark Cocoa Chocolate Bar", "டார்க் சாக்லேட்", "Chocolate", ["Dark Chocolate", "70% Cocoa"], ["Amul", "Cadbury Bournville", "Lindt"]),
    ("fruit_and_nut_chocolate_bar", "Cashew Raisin Milk Chocolate Bar", "ஃப்ரூட் & நட் சாக்லேட்", "Chocolate", ["Fruit and Nut Chocolate", "Cadbury Fruit Nut"], ["Cadbury", "Amul"])
]

for item_id, name, tamil, ptype, common, brands in sweet_data:
    add(
        item_id, name, tamil, "Snacks & Branded Foods", "Sweets & Chocolates",
        ptype, "g", "weight", "Pantry Shelf", 200.0, [100.0, 200.0, 250.0, 500.0],
        common, [c.lower() for c in common], brands,
        True, "EAN_13", False, True, "snacks"
    )

# --- FILTER COFFEE, TEA & BEVERAGES ---
beverage_data = [
    ("filter_coffee_powder_degree_blend_80_20", "Traditional South Indian Filter Coffee (80% Coffee 20% Chicory)", "டிகிரி பில்டர் காபித்தூள் (80:20)", "Coffee Powder", ["Filter Coffee Powder", "Degree Coffee", "Kumbakonam Degree Blend"], ["Cothas", "Narasu's", "Leo Coffee", "Bayar's", "Tata Coffee Grand"]),
    ("filter_coffee_powder_70_30", "Strong South Indian Filter Coffee (70% Coffee 30% Chicory)", "ஸ்ட்ராங் பில்டர் காபித்தூள் (70:30)", "Coffee Powder", ["Strong Filter Coffee", "70:30 Blend", "Hotel Blend Coffee"], ["Narasu's", "Cothas", "Leo Coffee"]),
    ("filter_coffee_pure_100_percent_arabica", "100% Pure Plantation Arabica Filter Coffee", "100% சுத்தமான அரேபிகா பில்டர் காபித்தூள்", "Coffee Powder", ["Pure Coffee Powder", "100% Arabica Filter Coffee", "Plantation A Coffee"], ["Blue Tokai", "Cothas", "Devan's", "Leo Coffee"]),
    ("peaberry_filter_coffee_powder", "Pure Single Origin Peaberry Filter Coffee", "பீபெர்ரி பில்டர் காபித்தூள்", "Coffee Powder", ["Peaberry Coffee", "Pure Peaberry Blend"], ["Cothas", "Leo Coffee", "Blue Tokai"]),
    ("instant_coffee_powder_pure", "100% Pure Instant Coffee Granules", "இன்ஸ்டன்ட் காபித்தூள்", "Instant Coffee", ["Pure Instant Coffee", "Nescafe Classic", "Bru Pure Instant"], ["Nescafe", "Bru", "Tata Coffee Grand", "Continental"]),
    ("instant_coffee_chicory_blend", "Instant Coffee Chicory Blend Jar", "இன்ஸ்டன்ட் காபி கலவை", "Instant Coffee", ["Bru Instant", "Chicory Instant Coffee"], ["Bru", "Nescafe Sunrise", "Continental Speciale"]),
    ("freeze_dried_gold_coffee", "Freeze Dried Premium Arabica Coffee Crystals", "ஃப்ரீஸ் டிரைடு கோல்ட் காபி", "Instant Coffee", ["Gold Coffee", "Freeze Dried Coffee", "Nescafe Gold"], ["Nescafe", "Davidoff", "Continental This"]),
    ("ctc_tea_powder_strong_leaf", "Strong CTC Black Tea Leaf Powder", "சிடிசி ஸ்ட்ராங் டீத்தூள்", "Tea Powder", ["CTC Tea", "Chai Powder", "Kadak Chai Leaf"], ["Tata Tea Premium", "Red Label", "Taj Mahal", "AVT Tea", "Kannandevan", "Wagh Bakri"]),
    ("assam_black_tea_orthodox", "Assam Orthodox Whole Leaf Black Tea", "அசாம் கருப்பு தேயிலை", "Tea Leaves", ["Assam Tea", "Assam Orthodox Leaf", "Strong Assam Chai"], ["Twinings", "Tata Tea", "Wagh Bakri", "Vahdam"]),
    ("darjeeling_tea_first_flush", "Darjeeling Single Estate Orthodox Black Tea", "டார்ஜீலிங் தேயிலை", "Tea Leaves", ["Darjeeling Tea", "Champagne of Teas", "First Flush Tea"], ["Taj Mahal", "Twinings", "Goodricke", "Vahdam"]),
    ("nilgiri_highland_black_tea", "Nilgiri Highland Fragrant Black Tea", "நீலகிரி தேயிலை", "Tea Leaves", ["Nilgiri Tea", "Ooty Mountain Tea"], ["AVT", "Glendale", "Tata Tea Gold"]),
    ("masala_chai_blend_tea_leaf", "Spiced Masala Chai Leaf (Cardamom, Clove, Cinnamon, Ginger)", "மசாலா டீத்தூள்", "Tea Powder", ["Masala Chai", "Spiced Tea Powder", "Red Label Natural Care"], ["Red Label", "Wagh Bakri", "Tata Tea Gold Care", "Girnar"]),
    ("elaichi_cardamom_tea_leaf", "Royal Cardamom / Elaichi Infused Chai Leaf", "ஏலக்காய் டீத்தூள்", "Tea Powder", ["Elaichi Tea", "Cardamom Chai"], ["Wagh Bakri", "Tata Tea", "Red Label"]),
    ("green_tea_pure_leaves", "Pure Himalayan Green Tea Leaves / Bags", "பச்சை தேயிலை / கிரீன் டீ", "Green Tea", ["Pure Green Tea", "Green Tea Bags"], ["Tetley", "Twinings", "Organic India", "Lipton", "Girnar"]),
    ("green_tea_lemon_honey", "Lemon and Honey Flavored Green Tea Bags", "எலுமிச்சை தேன் கிரீன் டீ", "Green Tea", ["Lemon Honey Green Tea", "Citrus Green Tea"], ["Tetley", "Lipton", "Organic India", "Twinings"]),
    ("tulsi_holy_basil_green_tea", "Organic Tulsi Green Tea Bags", "துளசி கிரீன் டீ", "Herbal Tea", ["Tulsi Green Tea", "Holy Basil Herbal Tea"], ["Organic India", "Vahdam", "Twinings"]),
    ("chamomile_herbal_sleep_tea", "Pure Calming Chamomile Herbal Flower Tea", "சாமோமைல் மூலிகை டீ", "Herbal Tea", ["Chamomile Tea", "Bedtime Herbal Tea"], ["Twinings", "Organic India", "Vahdam"]),
    ("horlicks_malt_health_drink", "Classic Malt Nutritional Health Food Drink", "ஹார்லிக்ஸ் மால்ட் ஹெல்த் டிரிங்க்", "Health Drink", ["Horlicks", "Classic Malt Drink"], ["Horlicks"]),
    ("boost_energy_health_drink", "Chocolate Energy Health Drink Powder", "பூஸ்ட் சாக்லேட் ஹெல்த் டிரிங்க்", "Health Drink", ["Boost", "Secret of Energy"], ["Boost"]),
    ("bournvita_chocolate_health_drink", "Pro-Health Chocolate Nutrition Drink Mix", "போர்ன்விடா சாக்லேட் மிக்ஸ்", "Health Drink", ["Bournvita", "Cadbury Bournvita"], ["Cadbury Bournvita"]),
    ("badam_milk_drink_mix_powder", "Instant Badam Drink Mix with Real Almond Bits & Saffron", "பாதாம் பால் பவுடர்", "Drink Mix", ["Badam Milk Powder", "Almond Drink Mix", "MTR Badam Drink"], ["MTR", "A2B", "Eastern", "Amul"]),
    ("nannari_sharbat_syrup_concentrate", "Traditional Nannari Roots Sharbat Syrup", "நன்னாரி சர்பத் சிரப்", "Syrup", ["Nannari Syrup", "Sarsaparilla Sharbat", "Sugandhi Drink"], ["Local Artisans", "A2B", "Vanthai", "Udhayam"]),
    ("rose_milk_syrup_concentrate", "Fragrant Rose Milk Syrup Concentrate", "ரோஸ் மில்க் சிரப்", "Syrup", ["Rose Syrup", "Gulab Sharbat", "Rooh Afza"], ["Rooh Afza", "Mapro", "Kalvert", "A2B"]),
    ("khus_vetiver_syrup_concentrate", "Natural Khus / Vetiver Cooling Syrup", "வெட்டிவேர் குஸ் சிரப்", "Syrup", ["Khus Syrup", "Vetiver Sharbat"], ["Mapro", "Rooh Afza", "Hamdard"]),
    ("kokum_syrup_concentrate", "Natural Kokum Sharbat Syrup", "கோகம் சர்பத்", "Syrup", ["Kokum Syrup", "Garcinia Sharbat"], ["Mapro", "Agro Organics"]),
    ("pure_tender_coconut_water_tetra", "100% Pure Tender Coconut Water Pack", "டெட்ரா பேக் இளநீர்", "Coconut Water", ["Packaged Tender Coconut Water", "Real Coconut Water"], ["Raw Pressery", "Paper Boat", "Cocopress"]),
    ("club_soda_sparkling_water", "Carbonated Sparkling Extra Punch Club Soda", "கிளப் சோடா", "Soda", ["Club Soda", "Sparkling Water", "Kinley Soda"], ["Kinley", "Bisleri", "Schweppes"])
]

for item_id, name, tamil, ptype, common, brands in beverage_data:
    unit = "ml" if "syrup" in item_id or "soda" in item_id or "water" in item_id else "g"
    sold = "volume" if unit == "ml" else "weight"
    q_vals = [200.0, 500.0, 1000.0] if unit == "g" else [250.0, 500.0, 750.0, 1000.0]
    add(
        item_id, name, tamil, "Beverages", "Coffee, Tea & Drink Mixes",
        ptype, unit, sold, "Pantry Shelf", 200.0, q_vals,
        common, [c.lower() for c in common], brands,
        True, "EAN_13", False, True, "beverages"
    )

# --- BREAKFAST CEREALS, INSTANT MIXES & READY-TO-EAT ---
breakfast_data = [
    ("fresh_idli_dosa_batter_pouch", "Fresh Stone Ground Idli & Dosa Batter", "இட்லி தோசை மாவு பாக்கெட்", "Batter", ["Idli Dosa Batter", "Fresh Batter Pouch", "Ready Batter"], ["ID Fresh", "Asal", "Shastha", "Gowri"]),
    ("ragi_idli_dosa_batter_fresh", "Fresh Sprouted Ragi Idli & Dosa Batter", "கேழ்வரகு தோசை மாவு பாக்கெட்", "Batter", ["Ragi Batter", "Finger Millet Batter"], ["ID Fresh", "Asal"]),
    ("instant_rava_idli_mix", "Instant Rava Idli Breakfast Mix", "ரவா இட்லி மிக்ஸ்", "Instant Mix", ["Rava Idli Mix", "MTR Rava Idli"], ["MTR", "Gits", "Maiyas"]),
    ("instant_rice_idli_mix", "Instant Rice Idli Mix", "அரிசி இட்லி மிக்ஸ்", "Instant Mix", ["Rice Idli Mix", "Instant Idli Powder"], ["MTR", "Gits", "Aachi"]),
    ("instant_rava_dosa_mix", "Crispy Instant Rava Dosa Breakfast Mix", "ரவா தோசை மிக்ஸ்", "Instant Mix", ["Rava Dosa Mix", "Suji Dosa Powder"], ["MTR", "Gits", "Aachi"]),
    ("instant_medu_vada_mix", "Instant Medu Vada Mix with Spices", "மெது வடை மிக்ஸ்", "Instant Mix", ["Medu Vada Mix", "Urad Dal Vada Powder"], ["MTR", "Gits", "Aachi"]),
    ("instant_upma_breakfast_mix", "Instant Spiced Rava Upma Mix", "ரவா உப்புமா மிக்ஸ்", "Instant Mix", ["Upma Mix", "Breakfast Upma Powder"], ["MTR", "Maiyas"]),
    ("instant_ven_pongal_mix", "Instant Ghee Ven Pongal Breakfast Mix", "வெண் பொங்கல் மிக்ஸ்", "Instant Mix", ["Ven Pongal Mix", "Khichdi Pongal Mix"], ["MTR", "Gits", "Aachi"]),
    ("instant_khaman_dhokla_mix", "Instant Spongy Khaman Dhokla Mix", "கமன் டோக்ளா மிக்ஸ்", "Instant Mix", ["Dhokla Mix", "Khaman Mix"], ["Gits", "MTR"]),
    ("instant_gulab_jamun_mix", "Instant Gulab Jamun Sweet Dessert Mix", "குலாப் ஜாமூன் மிக்ஸ்", "Instant Mix", ["Gulab Jamun Mix", "Instant Jamun Powder"], ["Gits", "MTR", "Aachi", "Maiyas"]),
    ("poha_thick_aval_flattened_rice", "Thick Beaten Rice / Thick Aval / Poha", "கெட்டி அவல்", "Flakes", ["Thick Aval", "Thick Poha", "Mota Poha"], ["Udhayam", "Tata Sampann", "Double Horse"]),
    ("poha_thin_nylon_aval", "Thin Nylon Beaten Rice / Thin Aval", "மெல்லிய அவல்", "Flakes", ["Thin Aval", "Nylon Poha", "Patla Poha"], ["Udhayam", "Tata Sampann"]),
    ("red_rice_aval_flakes", "Red Rice Beaten Flakes / Sigappu Arisi Aval", "சிகப்பரிசி அவல்", "Flakes", ["Red Rice Aval", "Lal Poha"], ["Udhayam", "Organic Tattva", "Double Horse"]),
    ("corn_flakes_original_crisp", "Crispy Golden Corn Flakes", "கார்ன் ஃபிளேக்ஸ்", "Cereal", ["Corn Flakes", "Kellogg's Corn Flakes"], ["Kellogg's", "Bagrry's", "Nestle"]),
    ("corn_flakes_honey_almond", "Honey & Almond Crunchy Corn Flakes", "தேன் பாதாம் கார்ன் ஃபிளேக்ஸ்", "Cereal", ["Honey Almond Flakes"], ["Kellogg's", "Bagrry's"]),
    ("chocos_chocolate_wheat_cereal", "Chocolate Wheat Cereal Scoops / Chocos", "சோக்கோஸ்", "Cereal", ["Chocos", "Chocolate Cereal"], ["Kellogg's", "Nestle"]),
    ("rolled_oats_whole_grain", "100% Whole Grain Rolled Oats", "ரோல்டு ஓட்ஸ்", "Oats", ["Rolled Oats", "Jumbo Oats", "Porridge Oats"], ["Quaker", "Saffola", "Bagrry's", "True Elements"]),
    ("instant_quick_cooking_oats", "Quick Cooking Instant Plain Oats", "இன்ஸ்டன்ட் ஓட்ஸ்", "Oats", ["Instant Oats", "Quick Cooking Oats"], ["Quaker", "Saffola", "Kellogg's"]),
    ("masala_oats_classic_spicy", "Classic Spicy Vegetable Masala Oats", "மசாலா ஓட்ஸ்", "Oats", ["Masala Oats", "Savory Oats"], ["Saffola Masala Oats", "Quaker"]),
    ("roasted_vermicelli_semiya", "Roasted Wheat Vermicelli / Semiya", "வறுத்த சேமியா", "Vermicelli", ["Roasted Semiya", "Roasted Vermicelli"], ["Anil", "MTR", "Bambino", "Aachi"]),
    ("unroasted_vermicelli_semiya", "Unroasted Wheat Vermicelli / Semiya", "வறுக்காத சேமியா", "Vermicelli", ["Raw Semiya", "Plain Vermicelli"], ["Anil", "Bambino", "MTR"]),
    ("ragi_vermicelli_semiya", "Finger Millet Ragi Semiya", "கேழ்வரகு சேமியா", "Vermicelli", ["Ragi Semiya", "Finger Millet Vermicelli"], ["Anil", "Double Horse", "Manna"]),
    ("instant_noodles_masala", "Spicy Masala Instant 2-Minute Noodles", "மசாலா மேகி நூடுல்ஸ்", "Noodles", ["Maggi Masala", "Instant Noodles", "2 Minute Noodles"], ["Maggi", "Yippee", "Top Ramen"]),
    ("hakka_noodles_veg", "Vegetable Hakka Chinese Stir Fry Noodles", "ஹக்கா நூடுல்ஸ்", "Noodles", ["Hakka Noodles", "Ching's Hakka Noodles"], ["Ching's Secret", "Weikfield"]),
    ("instant_soup_mix_sweet_corn_veg", "Sweet Corn Vegetable Instant Soup Mix", "ஸ்வீட் கார்ன் வெஜ் சூப்", "Soup", ["Sweet Corn Soup", "Knorr Sweet Corn Soup"], ["Knorr", "Ching's Secret"]),
    ("instant_soup_mix_tomato_chatpata", "Chatpata Tomato Instant Soup Mix", "டொமேட்டோ சூப்", "Soup", ["Tomato Soup", "Knorr Tomato Soup"], ["Knorr", "Ching's Secret"])
]

for item_id, name, tamil, ptype, common, brands in breakfast_data:
    add(
        item_id, name, tamil, "Breakfast & Instant Foods", "Cereals & Breakfast Mixes",
        ptype, "g", "weight", "Pantry Shelf", 400.0, [200.0, 400.0, 500.0, 1000.0],
        common, [c.lower() for c in common], brands,
        True, "EAN_13", False, True, "groceries"
    )

# --- CONDIMENTS, SAUCES, SPREADS & JAMS ---
condiment_data = [
    ("tomato_ketchup_sweet_spicy", "Sweet & Spicy Rich Tomato Ketchup", "தக்காளி சாஸ் / கெட்சப்", "Ketchup", ["Tomato Ketchup", "Tomato Sauce", "Kissan Ketchup"], ["Kissan", "Maggi", "Heinz", "Del Monte"]),
    ("tomato_sauce_no_onion_no_garlic", "No Onion No Garlic Pure Tomato Sauce", "வெங்காயம் பூண்டு அற்ற தக்காளி சாஸ்", "Ketchup", ["Jain Tomato Sauce", "No Onion Garlic Ketchup"], ["Kissan", "Maggi"]),
    ("green_chili_sauce_spicy", "Spicy Hot Green Chili Sauce", "பச்சை மிளகாய் சாஸ்", "Sauce", ["Green Chili Sauce", "Chilli Sauce"], ["Ching's Secret", "Continental", "Kissan"]),
    ("red_chili_sauce_hot", "Hot Red Chili Sauce", "சிவப்பு மிளகாய் சாஸ்", "Sauce", ["Red Chili Sauce", "Hot Red Sauce"], ["Ching's Secret", "Continental"]),
    ("dark_soy_sauce_stir_fry", "Premium Dark Soy Sauce", "டார்க் சோயா சாஸ்", "Sauce", ["Dark Soy Sauce", "Chinese Soy Sauce"], ["Ching's Secret", "Weikfield", "Lee Kum Kee"]),
    ("schezwan_sauce_chutney_spicy", "Spicy Schezwan Sauce & Dip", "செஸ்வான் சாஸ்", "Sauce", ["Schezwan Chutney", "Schezwan Sauce"], ["Ching's Secret", "Veeba"]),
    ("eggless_mayonnaise_original", "Original Rich Eggless White Mayonnaise", "முட்டையற்ற மயோனைஸ்", "Mayonnaise", ["Eggless Mayo", "White Mayonnaise", "Sandwich Mayo"], ["Veeba", "FunFoods", "Hellmann's", "Del Monte"]),
    ("eggless_garlic_mayonnaise", "Creamy Garlic Eggless Mayonnaise Dip", "பூண்டு மயோனைஸ்", "Mayonnaise", ["Garlic Mayo", "Garlic Eggless Mayonnaise"], ["Veeba", "FunFoods"]),
    ("peanut_butter_crunchy_roasted", "All Natural Crunchy Roasted Peanut Butter", "க்ரன்சி கடலை வெண்ணெய்", "Peanut Butter", ["Crunchy Peanut Butter", "Pintola Peanut Butter"], ["Pintola", "MyFitness", "Disano", "Alpino"]),
    ("peanut_butter_creamy_classic", "All Natural Creamy Smooth Peanut Butter", "கிரீமி கடலை வெண்ணெய்", "Peanut Butter", ["Creamy Peanut Butter", "Smooth Peanut Butter"], ["Pintola", "MyFitness", "Sundrop", "Disano"]),
    ("mixed_fruit_jam_sweet", "Classic Mixed Fruit Jam", "மிக்ஸ்ட் ஃப்ரூட் ஜாம்", "Jam", ["Mixed Fruit Jam", "Kissan Jam"], ["Kissan", "Mapro", "Druk"]),
    ("pineapple_jam_sweet", "Fresh Pineapple Pulp Sweet Jam", "அன்னாசி ஜாம்", "Jam", ["Pineapple Jam", "Pineapple Fruit Spread"], ["Kissan", "Mapro", "Druk"]),
    ("strawberry_fruit_preserve_jam", "Whole Strawberry Fruit Preserve Jam", "ஸ்ட்ராபெர்ரி ஜாம்", "Jam", ["Strawberry Jam", "Strawberry Preserve"], ["Mapro", "Kissan", "St Dalfour"]),
    ("hazelnut_cocoa_spread_nutella", "Creamy Hazelnut Cocoa Spread with Skimmed Milk", "ஹேசல்நட் கோகோ ஸ்பிரெட்", "Spread", ["Nutella Spread", "Hazelnut Spread", "Chocolate Spread"], ["Nutella", "Hershey's"])
]

for item_id, name, tamil, ptype, common, brands in condiment_data:
    add(
        item_id, name, tamil, "Sauces, Spreads & Condiments", "Sauces & Spreads",
        ptype, "g", "weight", "Pantry Shelf", 300.0, [200.0, 350.0, 500.0, 1000.0],
        common, [c.lower() for c in common], brands,
        True, "EAN_13", False, True, "groceries"
    )

# Write out python file
json_str = json.dumps(ITEMS, ensure_ascii=False)
code = f'''#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json

"""
Expansion module for Snacks, Biscuits, Sweets, Beverages, Breakfast, Sauces and Condiments.
Generated with {len(ITEMS)} authentic Indian household items.
"""

_DATA = r"""{json_str}"""

def get_snacks_beverages_expansion():
    return json.loads(_DATA)

if __name__ == "__main__":
    items = get_snacks_beverages_expansion()
    print(f"Loaded {{len(items)}} snack and beverage products.")
'''

with open("scripts/expand_snacks_beverages.py", "w", encoding="utf-8") as f:
    f.write(code)

print(f"Successfully generated scripts/expand_snacks_beverages.py with {len(ITEMS)} items.")
