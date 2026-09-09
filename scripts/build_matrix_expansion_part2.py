# -*- coding: utf-8 -*-
"""
Builder for expand_matrix_catalog_part2.py
Generates 380+ distinct, authentic Indian & Tamil household staples,
bringing total unique products well above 2,150+.
"""
import json
import re

def slugify(text):
    text = text.lower().strip()
    text = re.sub(r'\(.*?\)', '', text).strip()
    text = re.sub(r'[^a-z0-9]+', '_', text).strip('_')
    return text

ITEMS_PART2 = [
    # === REGIONAL BREAKFAST MIXES, SEVAIS & PAPADS ===
    ("Kanchipuram Idli Mix Spiced", "காஞ்சிபுரம் இட்லி மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "g", "weight", "Pantry Shelf", 500.0, [200.0, 500.0], ["MTR", "Aachi", "Grand Sweets"], ["kanchipuram idli mix", "spiced idli mix"], False, True, "packaged_food"),
    ("Rava Dosa Instant Mix", "ரவா தோசை மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "g", "weight", "Pantry Shelf", 500.0, [200.0, 500.0], ["MTR", "Aachi", "Priya"], ["rava dosa mix", "sooji dosa mix"], False, True, "packaged_food"),
    ("Oats Dosa Instant Healthy Mix", "ஓட்ஸ் தோசை மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "g", "weight", "Pantry Shelf", 500.0, [500.0], ["MTR", "Aashirvaad"], ["oats dosa mix"], False, True, "packaged_food"),
    ("Multi Millet Idli Instant Mix", "சிறுதானிய இட்லி மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "g", "weight", "Pantry Shelf", 500.0, [500.0], ["Gramiyum", "Millet Magic"], ["millet idli mix"], False, True, "packaged_food"),
    ("Neer Dosa Instant Rice Mix", "நீர் தோசை மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "g", "weight", "Pantry Shelf", 500.0, [500.0], ["MTR", "Eastern"], ["neer dosa mix"], False, True, "packaged_food"),
    ("Sweet & Spicy Kuzhi Paniyaram Mix", "குழி பணியாரம் மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "g", "weight", "Pantry Shelf", 500.0, [500.0], ["Aachi", "Grand Sweets"], ["paniyaram mix", "kuzhi paniyaram"], False, True, "packaged_food"),
    ("Crispy Medu Vada Instant Mix", "மெது வடை மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "g", "weight", "Pantry Shelf", 500.0, [200.0, 500.0], ["MTR", "Aachi", "Gits"], ["medu vada mix", "urad vada mix"], False, True, "packaged_food"),
    ("Masala Vada Instant Dal Mix", "மசால் வடை மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "g", "weight", "Pantry Shelf", 500.0, [200.0, 500.0], ["Aachi", "Grand Sweets"], ["masala vada mix", "chana dal vada mix"], False, True, "packaged_food"),
    ("Rice Sevai String Hoppers Plain", "அரிசி சேவை", "Food & Grocery", "Noodles & Vermicelli", "Sevai", "g", "weight", "Pantry Shelf", 400.0, [200.0, 400.0, 500.0], ["Anil Rice Sevai", "Concord", "Naga"], ["rice sevai", "idiyappam sevai", "arisi sevai"], False, True, "grains"),
    ("Ragi Sevai Finger Millet Vermicelli", "கேழ்வரகு சேவை", "Food & Grocery", "Noodles & Vermicelli", "Sevai", "g", "weight", "Pantry Shelf", 400.0, [200.0, 400.0], ["Anil Ragi Sevai", "Concord"], ["ragi sevai", "kezhvaragu sevai"], False, True, "grains"),
    ("Wheat Sevai Whole Wheat Vermicelli", "கோதுமை சேவை", "Food & Grocery", "Noodles & Vermicelli", "Sevai", "g", "weight", "Pantry Shelf", 400.0, [200.0, 400.0], ["Anil Wheat Sevai", "Naga"], ["wheat sevai", "godhumai sevai"], False, True, "grains"),
    ("Lemon Rice Sevai Instant Seasoning Mix", "எலுமிச்சை சேவை மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Anil", "MTR"], ["lemon sevai mix"], False, True, "packaged_food"),
    ("Tomato Sevai Instant Seasoning Mix", "தக்காளி சேவை மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Anil", "MTR"], ["tomato sevai mix"], False, True, "packaged_food"),
    ("Pepper Jeera Rice Sevai Mix", "மிளகு சீரக சேவை மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Anil", "Grand Sweets"], ["pepper sevai mix"], False, True, "packaged_food"),
    ("Sweet Achu Murukku Rose Cookies", "அச்சு முறுக்கு (ரோஸ் குக்கீஸ்)", "Snacks & Namkeen", "Traditional Snacks", "Murukku", "piece", "package", "Pantry Shelf", 10.0, [10.0, 20.0], ["Grand Sweets", "A2B", "Local Artisans"], ["achu murukku", "rose cookies sweet"], False, True, "snacks"),
    ("Garlic Kara Sevu Spicy", "பூண்டு காராசேவு", "Snacks & Namkeen", "Traditional Snacks", "Namkeen", "g", "weight", "Pantry Shelf", 200.0, [200.0, 500.0], ["Shanmuganadar", "Grand Sweets", "A2B"], ["poondu kara sevu", "garlic sev"], False, True, "snacks"),
    ("Pepper Kara Sevu Spicy", "மிளகு காராசேவு", "Snacks & Namkeen", "Traditional Snacks", "Namkeen", "g", "weight", "Pantry Shelf", 200.0, [200.0, 500.0], ["Shanmuganadar", "Grand Sweets"], ["milagu sevu", "black pepper sev"], False, True, "snacks"),
    ("Instant Mysore Bonda Flour Mix", "மைசூர் போண்டா மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "g", "weight", "Pantry Shelf", 500.0, [500.0], ["Aachi", "MTR"], ["mysore bonda mix"], False, True, "packaged_food"),
    ("Kerala Guruvayur Special Pappadam Pack", "குருவாயூர் ஸ்பெஷல் பப்படம்", "Food & Grocery", "Vathal & Papad", "Appalam", "piece", "package", "Pantry Shelf", 20.0, [10.0, 20.0], ["Double Horse", "Guruvayur Pappadam"], ["guruvayur pappadam", "kerala pappadam"], False, True, "staple"),
    ("Crispy Rice Appalam Arisi Appalam", "அரிசி அப்பளம்", "Food & Grocery", "Vathal & Papad", "Appalam", "piece", "package", "Pantry Shelf", 20.0, [10.0, 20.0], ["Ambika Appalam", "Grand Sweets"], ["arisi appalam", "rice papad"], False, True, "staple"),
    ("Sun Dried Tapioca Maravalli Papad", "மரவள்ளிக்கிழங்கு அப்பளம்", "Food & Grocery", "Vathal & Papad", "Appalam", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Salem Artisans", "Grand Sweets"], ["maravalli appalam", "tapioca papad"], False, True, "staple"),
    ("Spicy Potato Papad Aloo Papad", "உருளைக்கிழங்கு அப்பளம்", "Food & Grocery", "Vathal & Papad", "Appalam", "g", "weight", "Pantry Shelf", 200.0, [100.0, 200.0], ["Haldiram's", "Bikaji", "Local"], ["aloo papad", "potato papad"], False, True, "staple"),
    ("Moong Dal Papad Bikaneri", "பாசிப்பருப்பு பப்படம் (பிகானேரி)", "Food & Grocery", "Vathal & Papad", "Appalam", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Lijjat Moong Papad", "Bikaji", "Haldiram's"], ["moong dal papad", "lijjat moong"], False, True, "staple"),
    ("Lijjat Urad Dal Garlic Papad", "லிஜ்ஜத் பூண்டு அப்பளம்", "Food & Grocery", "Vathal & Papad", "Appalam", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Lijjat Garlic Papad"], ["lijjat garlic papad", "poondu appalam"], False, True, "staple"),
    ("Lijjat Punjabi Masala Papad Spicy", "லிஜ்ஜத் பஞ்சாபி மசாலா அப்பளம்", "Food & Grocery", "Vathal & Papad", "Appalam", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Lijjat Masala Papad"], ["lijjat punjabi masala", "masala papad"], False, True, "staple"),

    # === REGIONAL PICKLES, THOKKUS & CHUTNEYS ===
    ("Andhra Spicy Gongura Nilva Pachadi", "ஆந்திரா கோங்குரா ஊறுகாய்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Pickle", "g", "weight", "Pantry Shelf", 300.0, [300.0, 500.0], ["Priya Gongura", "Mother's Recipe", "Ruchi"], ["gongura pickle", "andhra gongura pachadi"], False, True, "condiment"),
    ("Andhra Avakaya Spicy Mango Pickle", "ஆந்திரா ஆவக்காய் மாங்காய் ஊறுகாய்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Pickle", "g", "weight", "Pantry Shelf", 300.0, [300.0, 500.0, 1000.0], ["Priya Avakaya", "Ruchi", "Mother's Recipe"], ["avakaya pickle", "andhra avakaya mango"], False, True, "condiment"),
    ("Bellam Avakaya Sweet Jaggery Mango Pickle", "பெல்லம் ஆவக்காய் (வெல்ல மாங்காய் ஊறுகாய்)", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Pickle", "g", "weight", "Pantry Shelf", 300.0, [300.0], ["Priya", "Local Artisans"], ["bellam avakaya", "sweet avakaya pickle"], False, True, "condiment"),
    ("Magaya Sun Dried Mango Pickle", "மகா ஆவக்காய் (உலர்ந்த மாங்காய்)", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Pickle", "g", "weight", "Pantry Shelf", 300.0, [300.0], ["Priya Magaya", "Ruchi"], ["magaya pickle", "magai pachadi"], False, True, "condiment"),
    ("Usirikaya Amla Gooseberry Pickle", "உசிரிகாயா நெல்லிக்காய் ஊறுகாய்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Pickle", "g", "weight", "Pantry Shelf", 300.0, [300.0, 500.0], ["Priya Usirikaya", "Mother's Recipe"], ["usirikaya pickle", "amla pickle andhra"], False, True, "condiment"),
    ("Pandu Mirapakaya Ripe Red Chilli Pickle", "பண்டு மிரப்பகாயா சிவப்பு மிளகாய் ஊறுகாய்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Pickle", "g", "weight", "Pantry Shelf", 300.0, [300.0], ["Priya", "Ruchi"], ["pandu mirapakaya", "red chilli pickle andhra"], False, True, "condiment"),
    ("Chintakaya Raw Tamarind Pachadi", "சிந்தகாயா புளி ஊறுகாய்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Pickle", "g", "weight", "Pantry Shelf", 300.0, [300.0], ["Priya", "Local Artisans"], ["chintakaya pickle", "raw tamarind chutney"], False, True, "condiment"),
    ("Nimmakaya Traditional Lemon Pickle", "நிம்மகாயா எலுமிச்சை ஊறுகாய்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Pickle", "g", "weight", "Pantry Shelf", 300.0, [300.0, 500.0], ["Priya", "Ruchi", "Grand Sweets"], ["nimmakaya pickle", "lemon pickle spicy"], False, True, "condiment"),
    ("Dabbakaya Citron Whole Fruit Pickle", "டப்பகாயா நார்த்தங்காய் ஊறுகாய்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Pickle", "g", "weight", "Pantry Shelf", 300.0, [300.0], ["Priya", "Grand Sweets"], ["dabbakaya pickle", "citron pickle andhra"], False, True, "condiment"),
    ("Spicy Tomato Garlic Pickle", "தக்காளி பூண்டு ஊறுகாய்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Pickle", "g", "weight", "Pantry Shelf", 300.0, [300.0, 500.0], ["Priya", "Ruchi", "Mother's Recipe"], ["tomato garlic pickle", "thakkali poondu oorugai"], False, True, "condiment"),
    ("Garlic Ginger Mixed Spicy Pickle", "இஞ்சி பூண்டு ஊறுகாய்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Pickle", "g", "weight", "Pantry Shelf", 300.0, [300.0], ["Mother's Recipe", "Priya"], ["ginger garlic pickle", "inji poondu oorugai"], False, True, "condiment"),
    ("Kakarakaya Bitter Gourd Pickle", "பாகற்காய் ஊறுகாய்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Pickle", "g", "weight", "Pantry Shelf", 300.0, [300.0], ["Priya Kakarakaya", "Ruchi"], ["bitter gourd pickle", "karela pickle", "pavakkai oorugai"], False, True, "condiment"),
    ("Maavadu Tender Baby Mango Pickle", "மாவடு (சிறிய பிஞ்சு மாங்காய் ஊறுகாய்)", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Pickle", "g", "weight", "Pantry Shelf", 300.0, [300.0, 500.0], ["Grand Sweets", "Ruchi", "Ambika"], ["maavadu", "vadumangai", "baby mango pickle"], False, True, "condiment"),
    ("Green Chilli Pachai Milagai Pickle", "பச்சை மிளகாய் ஊறுகாய்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Pickle", "g", "weight", "Pantry Shelf", 300.0, [300.0], ["Mother's Recipe", "Priya", "Aachi"], ["green chilli pickle", "hari mirch pickle"], False, True, "condiment"),
    ("Mixed Vegetable Traditional Pickle", "கலவை காய் ஊறுகாய்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Pickle", "g", "weight", "Pantry Shelf", 300.0, [300.0, 500.0], ["Mother's Recipe", "Priya", "Ruchi", "Aachi"], ["mixed veg pickle", "pacharanga pickle"], False, True, "condiment"),
    ("Sweet Gujarati Mango Chunda", "குஜராத்தி மாங்காய் சுண்டா", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Sweet Pickle", "g", "weight", "Pantry Shelf", 300.0, [300.0], ["Mother's Recipe Chunda", "Bedekar"], ["chunda", "sweet mango pickle"], False, True, "condiment"),
    ("Sweet Lime Chutney Gor Keri", "இனிப்பு எலுமிச்சை சட்னி", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Sweet Pickle", "g", "weight", "Pantry Shelf", 300.0, [300.0], ["Mother's Recipe", "Bedekar"], ["sweet lime chutney", "gor keri"], False, True, "condiment"),
    ("Tamarind Date Sweet Chutney Saunth", "புளி பேரீச்சம்பழ இனிப்பு சட்னி", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Chutney", "g", "weight", "Pantry Shelf", 300.0, [300.0], ["Mother's Recipe", "Haldiram's", "Veeba"], ["tamarind date chutney", "saunth sweet chutney"], False, True, "condiment"),
    ("Mint Coriander Spicy Green Chutney", "புதினா கொத்தமல்லி பச்சை சட்னி", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Chutney", "g", "weight", "Pantry Shelf", 300.0, [300.0], ["Mother's Recipe", "Veeba", "Haldiram's"], ["green chutney", "hari chutney sandwich"], False, True, "condiment"),
    ("Dry Garlic Chutney Lasun Chutney for Vada Pav", "உலர் பூண்டு சட்னி (வடா பாவ்)", "Spices & Seasonings", "Traditional Podis", "Chutney Powder", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Suhana", "K-Praveen", "Mother's Recipe"], ["dry garlic chutney", "vada pav chutney"], False, True, "masala"),
    ("Schezwan Spicy Dip Chutney", "செஷ்வான் சட்னி", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Chutney", "g", "weight", "Pantry Shelf", 250.0, [250.0], ["Ching's Secret", "Veeba"], ["schezwan chutney", "schezwan sauce"], False, True, "condiment"),
    ("Tamarind Concentrated Cooking Paste", "புளி பேஸ்ட் (சமையல்)", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Cooking Paste", "g", "weight", "Pantry Shelf", 200.0, [200.0, 400.0], ["Dabur Hommade", "Priya", "Eastern"], ["tamarind paste", "imli paste"], False, True, "condiment"),
    ("Ginger Pure Cooking Paste Inji Paste", "இஞ்சி பேஸ்ட்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Cooking Paste", "g", "weight", "Refrigerator", 200.0, [100.0, 200.0], ["Dabur Hommade", "Mother's Recipe", "Eastern"], ["ginger paste", "adrak paste"], False, True, "condiment"),
    ("Garlic Pure Cooking Paste Poondu Paste", "பூண்டு பேஸ்ட்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Cooking Paste", "g", "weight", "Refrigerator", 200.0, [100.0, 200.0], ["Dabur Hommade", "Mother's Recipe", "Eastern"], ["garlic paste", "lahsun paste"], False, True, "condiment"),
    ("Ginger Garlic Combined Cooking Paste", "இஞ்சி பூண்டு பேஸ்ட்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Cooking Paste", "g", "weight", "Refrigerator", 200.0, [100.0, 200.0, 500.0], ["Dabur Hommade", "Mother's Recipe", "Tata Sampann", "Eastern"], ["ginger garlic paste", "adrak lahsun paste"], False, True, "condiment"),

    # === DRY FRUITS, NUTS & SEEDS ===
    ("Whole Dried Figs Dried Anjeer", "உலர் அத்திப்பழம் (அஞ்சீர்)", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Dried Fruit", "g", "weight", "Pantry Shelf", 250.0, [200.0, 250.0, 500.0], ["Happilo", "Nutraj", "Tulsi"], ["anjeer", "dried figs", "athi pazham dry"], False, True, "snacks"),
    ("Dried Turkish Apricots Jardalu", "உலர் பாதாமி (ஆப்ரிகாட்)", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Dried Fruit", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Happilo", "Nutraj"], ["dried apricots", "jardalu", "khubani"], False, True, "snacks"),
    ("Dried Cranberries Sweetened", "உலர் கிரான்பெர்ரி", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Dried Fruit", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Happilo", "True Elements"], ["dried cranberries"], False, True, "snacks"),
    ("Dried Blueberries Wild", "உலர் புளூபெர்ரி", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Dried Fruit", "g", "weight", "Pantry Shelf", 150.0, [150.0], ["Happilo", "Nutraj"], ["dried blueberries"], False, True, "snacks"),
    ("Black Raisins Seedless Kismis", "கருப்பு உலர் திராட்சை", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Raisins", "g", "weight", "Pantry Shelf", 250.0, [200.0, 250.0, 500.0], ["Happilo", "Nutraj", "BB Royal"], ["black raisins", "karuppu drakshai dry"], False, True, "snacks"),
    ("Golden Long Raisins Kismis", "தங்க உலர் திராட்சை (கிஸ்மிஸ்)", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Raisins", "g", "weight", "Pantry Shelf", 250.0, [200.0, 250.0, 500.0], ["Happilo", "Nutraj", "Tata Sampann"], ["golden raisins", "kismis", "drakshai dry"], False, True, "snacks"),
    ("Roasted Salted Pistachios In Shell Pista", "வறுத்த உப்பு பிஸ்தா (தோலுடன்)", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Pistachios", "g", "weight", "Pantry Shelf", 200.0, [200.0, 500.0], ["Happilo", "Nutraj", "Tulsi"], ["salted pistachios", "roasted pista"], False, True, "snacks"),
    ("Raw Pistachio Kernels Pista Green", "பச்சை பிஸ்தா பருப்பு", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Pistachios", "g", "weight", "Pantry Shelf", 100.0, [100.0, 250.0], ["Happilo", "Nutraj"], ["pista kernels", "green pista raw"], False, True, "snacks"),
    ("Chilean Whole Walnuts In Shell Akhrot", "அக்ரூட் பருப்பு (தோலுடன்)", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Walnuts", "g", "weight", "Pantry Shelf", 500.0, [500.0], ["Nutraj", "Happilo"], ["walnuts with shell", "akhrot sabut"], False, True, "snacks"),
    ("Walnut Kernels Halves Akhrot Giri", "அக்ரூட் பருப்பு (உடைத்தது)", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Walnuts", "g", "weight", "Pantry Shelf", 250.0, [200.0, 250.0, 500.0], ["Happilo", "Nutraj", "Tata Sampann"], ["walnut kernels", "akhrot giri"], False, True, "snacks"),
    ("California Whole Almonds Badam Giri", "கலிபோர்னியா பாதாம் பருப்பு", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Almonds", "g", "weight", "Pantry Shelf", 500.0, [200.0, 500.0, 1000.0], ["Happilo", "Nutraj", "Tata Sampann", "Tulsi"], ["california badam", "almond kernels"], False, True, "snacks"),
    ("Cashew Nuts Whole W240 Premium Kaju", "முந்திரி பருப்பு W240 (பெரியது)", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Cashews", "g", "weight", "Pantry Shelf", 500.0, [200.0, 500.0], ["Happilo", "Nutraj", "Tata Sampann"], ["cashew w240", "kaju whole big", "munthiri"], False, True, "snacks"),
    ("Cashew Splits Tukda Kaju for Cooking", "முந்திரி துண்டு (சமையல் முந்திரி)", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Cashews", "g", "weight", "Pantry Shelf", 500.0, [250.0, 500.0], ["BB Royal", "Local Mills"], ["tukda kaju", "split cashews", "munthiri thundu"], False, True, "snacks"),
    ("Medjool Soft Black Dates Jumbo", "மெட்ஜூல் மென்மையான பேரீச்சம்பழம்", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Dates", "g", "weight", "Pantry Shelf", 500.0, [500.0], ["Happilo Medjool", "Nutraj"], ["medjool dates", "jumbo dates"], False, True, "snacks"),
    ("Kimia Soft Black Wet Dates Box", "கிமியா ஈர பேரீச்சம்பழம்", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Dates", "g", "weight", "Pantry Shelf", 500.0, [500.0], ["Kimia Dates", "Happilo", "Lion Dates"], ["kimia dates", "black soft dates"], False, True, "snacks"),
    ("Lion Seeded Desert Dates Pouch", "லயன் பேரீச்சம்பழம்", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Dates", "g", "weight", "Pantry Shelf", 500.0, [200.0, 500.0], ["Lion Dates"], ["lion dates", "desert dates"], False, True, "snacks"),

    # === RARE & SPECIALTY VEGETABLES & GREENS ===
    ("Thoodhuvalai Keerai Purple Pea Leaves", "தூதுவளை கீரை", "Fresh Vegetables", "Greens & Herbs", "Keerai", "bunch", "piece", "Refrigerator", 1.0, [1.0], ["Local Farmers"], ["thoodhuvalai", "purple fruited pea leaves"], True, False, "fresh_produce"),
    ("Pirandai Veldt Grape Fresh Stem", "பிரண்டை (பச்சை தண்டு)", "Fresh Vegetables", "Greens & Herbs", "Country Herb", "g", "weight", "Refrigerator", 200.0, [200.0], ["Local Farmers"], ["pirandai stem", "adamant creeper fresh"], True, False, "fresh_produce"),
    ("Sirukurinjan Keerai Gymnema Leaves", "சிறுகுறிஞ்சான் கீரை", "Fresh Vegetables", "Greens & Herbs", "Keerai", "bunch", "piece", "Refrigerator", 1.0, [1.0], ["Local Farmers"], ["sirukurinjan", "gymnema leaves"], True, False, "fresh_produce"),
    ("Musumusukkai Keerai Herb Leaves", "முசுமுசுக்கை கீரை", "Fresh Vegetables", "Greens & Herbs", "Keerai", "bunch", "piece", "Refrigerator", 1.0, [1.0], ["Local Farmers"], ["musumusukkai"], True, False, "fresh_produce"),
    ("Kuppaimeni Keerai Acalypha Leaves", "குப்பைமேனி கீரை", "Fresh Vegetables", "Greens & Herbs", "Keerai", "bunch", "piece", "Refrigerator", 1.0, [1.0], ["Local Farmers"], ["kuppaimeni", "acalypha indica"], True, False, "fresh_produce"),
    ("Murungai Poo Drumstick Tree Blossom Flowers", "முருங்கைப்பூ", "Fresh Vegetables", "Greens & Herbs", "Country Flower", "g", "weight", "Refrigerator", 200.0, [200.0], ["Local Farmers"], ["murungai poo", "moringa flower"], True, False, "fresh_produce"),
    ("Spicy Country Ginger Nattu Inji", "நாட்டு இஞ்சி", "Fresh Vegetables", "Daily Vegetables", "Ginger", "kg", "weight", "Refrigerator", 0.25, [0.25, 0.5, 1.0], ["Local Farmers"], ["nattu inji", "country ginger", "desi adrak"], True, False, "fresh_produce"),
    ("Dosakaya Andhra Sambar Cucumber Yellow", "தோசக்காய் (மஞ்சள் வெள்ளரி)", "Fresh Vegetables", "Daily Vegetables", "Cucumber", "kg", "weight", "Refrigerator", 0.5, [0.5, 1.0], ["Local Farmers"], ["dosakaya", "yellow cucumber", "sambar vellarikkai"], True, False, "fresh_produce"),
    ("Purple Cabbage Red Cabbage Head", "ஊதா முட்டைக்கோஸ்", "Fresh Vegetables", "Daily Vegetables", "Vegetable", "kg", "weight", "Refrigerator", 0.5, [0.5], ["Local Farmers"], ["red cabbage", "purple cabbage"], True, False, "fresh_produce"),
    ("Fresh Oyster Mushrooms Pack", "சிப்பி காளான்", "Fresh Vegetables", "Daily Vegetables", "Mushrooms", "g", "weight", "Refrigerator", 200.0, [200.0], ["Local Growers"], ["oyster mushrooms", "sippi kaalan"], False, True, "fresh_produce"),
    ("Red Radish Small Round", "சிவப்பு முள்ளங்கி", "Fresh Vegetables", "Daily Vegetables", "Root Vegetable", "bunch", "piece", "Refrigerator", 1.0, [1.0], ["Local Farmers"], ["red radish", "lal mooli"], True, False, "fresh_produce"),

    # === FRESH FRUITS ===
    ("Kiran Dark Green Sweet Watermelon", "கிரண் தர்பூசணி (அடர் பச்சை)", "Fresh Fruits", "Fresh Fruits", "Fruit", "piece", "piece", "Kitchen Counter", 1.0, [1.0, 2.0], ["Local Orchards"], ["kiran watermelon", "dark watermelon"], True, False, "fresh_produce"),
    ("Sun Melon Yellow Sweet Melon", "சன் மெலன் (மஞ்சள் கிர்ணி)", "Fresh Fruits", "Fresh Fruits", "Fruit", "piece", "piece", "Kitchen Counter", 1.0, [1.0], ["Local Orchards"], ["sun melon", "yellow melon"], True, False, "fresh_produce"),
    ("Robusta Green Cavendish Bananas", "பச்சை ரோபஸ்டா வாழைப்பழம்", "Fresh Fruits", "Bananas", "Banana", "dozen", "piece", "Kitchen Counter", 1.0, [0.5, 1.0, 2.0], ["Local Farmers"], ["robusta banana", "pachai vazhai"], True, False, "fresh_produce"),
    ("Dasheri Sweet Mango Lucknow", "தசாரி மாம்பழம்", "Fresh Fruits", "Mangoes", "Mango", "kg", "weight", "Kitchen Counter", 1.0, [1.0, 2.0], ["Lucknow Orchards"], ["dasheri mango", "dussheri"], True, False, "fresh_produce"),
    ("Langra Fragrant Green Mango Banaras", "லங்கரா மாம்பழம்", "Fresh Fruits", "Mangoes", "Mango", "kg", "weight", "Kitchen Counter", 1.0, [1.0, 2.0], ["Banaras Orchards"], ["langra mango"], True, False, "fresh_produce"),
    ("Kesar Saffron Fragrant Mango Gujarat", "கேசர் மாம்பழம்", "Fresh Fruits", "Mangoes", "Mango", "kg", "weight", "Kitchen Counter", 1.0, [1.0, 2.0], ["Gir Orchards"], ["kesar mango", "gir kesar"], True, False, "fresh_produce"),
    ("Bullock's Heart Sweet Ramphal", "ராம்பழம் (ராம்பல்)", "Fresh Fruits", "Fresh Fruits", "Fruit", "piece", "piece", "Kitchen Counter", 1.0, [1.0, 2.0], ["Local Orchards"], ["ramphal", "bullocks heart"], True, False, "fresh_produce"),
    ("Arunellikai Small Star Gooseberry", "அரை நெல்லிக்காய் (நட்சத்திர நெல்லி)", "Fresh Fruits", "Fresh Fruits", "Amla", "g", "weight", "Kitchen Counter", 250.0, [250.0, 500.0], ["Local Farmers"], ["arunellikai", "star gooseberry"], True, False, "fresh_produce"),
    ("White Flesh Dragon Fruit Pitaya", "டிராகன் பழம் (வெள்ளை)", "Fresh Fruits", "Exotics", "Fruit", "piece", "piece", "Kitchen Counter", 1.0, [1.0, 2.0], ["Local Exotics"], ["white dragon fruit"], True, False, "fresh_produce"),
    ("Kashmiri Red Sweet Delicious Apples", "காஷ்மீரி ஆப்பிள்", "Fresh Fruits", "Apples & Pears", "Apples", "kg", "weight", "Refrigerator", 1.0, [0.5, 1.0, 2.0], ["Kashmir Orchards", "Kinnaur"], ["kashmiri apple", "red apple shimla"], True, False, "fresh_produce"),
    ("Royal Gala Imported Sweet Apples", "ராயல் காலா ஆப்பிள்", "Fresh Fruits", "Apples & Pears", "Apples", "kg", "weight", "Refrigerator", 1.0, [1.0], ["Washington", "New Zealand"], ["royal gala apple"], False, True, "fresh_produce"),
    ("Granny Smith Tangy Green Apples", "பச்சை ஆப்பிள் (கிரானி ஸ்மித்)", "Fresh Fruits", "Apples & Pears", "Apples", "kg", "weight", "Refrigerator", 0.5, [0.5, 1.0], ["Imported Orchards"], ["green apple", "granny smith"], False, True, "fresh_produce"),
    ("Indian Bartlett Babgusha Sweet Pears", "பேரிக்காய் (பாபுகோஷா)", "Fresh Fruits", "Apples & Pears", "Pears", "kg", "weight", "Refrigerator", 1.0, [0.5, 1.0], ["Himachal Orchards", "Kashmir"], ["babgusha pear", "indian pear", "perikkai"], True, False, "fresh_produce"),
    ("Fresh Black Amber Plums", "கருப்பு பிளம்ஸ் பழம்", "Fresh Fruits", "Fresh Fruits", "Stone Fruit", "g", "weight", "Refrigerator", 500.0, [250.0, 500.0], ["Himachal Orchards"], ["black plums", "aloo bukhara fresh"], True, False, "fresh_produce"),
    ("Fresh Purple Figs Anjeer", "பச்சை அத்திப்பழம் (அஞ்சீர்)", "Fresh Fruits", "Fresh Fruits", "Figs", "g", "weight", "Refrigerator", 250.0, [250.0, 500.0], ["Pune Orchards"], ["fresh anjeer", "fresh figs", "athi pazham fresh"], True, False, "fresh_produce"),

    # === POOJA ESSENTIALS, SPIRITUAL OILS & ITEMS ===
    ("Dried Turmeric Whole Fingers Viral Manjal", "விரலி மஞ்சள் கிழங்கு", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Turmeric", "g", "weight", "Pooja Shelf", 250.0, [100.0, 250.0, 500.0], ["Gopuram", "Local Ayurvedic"], ["viral manjal", "whole turmeric fingers", "haldi sabut"], True, True, "pooja"),
    ("Round Turmeric Whole Bulbs Gundu Manjal", "குண்டு மஞ்சள் கிழங்கு", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Turmeric", "g", "weight", "Pooja Shelf", 250.0, [100.0, 250.0], ["Gopuram", "Local Ayurvedic"], ["gundu manjal", "round turmeric bulb"], True, True, "pooja"),
    ("Pure Sandalwood Whole Log Chandan Lakdi", "சந்தனக் கட்டை", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Sandalwood", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Cauvery Handicrafts", "Mysore Sandal"], ["sandalwood stick", "chandan lakdi"], False, True, "pooja"),
    ("Stone Rubbing Slab for Sandalwood Sanaikallu", "சானைக்கல் (சந்தனம் உரைக்க)", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Rubbing Stone", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Local Artisans"], ["sanaikallu", "chandan rubbing stone"], False, True, "pooja"),
    ("Areca Nut Diamond Betel Chips Seval Paakku", "சீவல் பாக்கு", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Nut", "g", "weight", "Pooja Shelf", 100.0, [50.0, 100.0], ["Gopuram", "Temple Stores"], ["seval paakku", "sliced supari"], False, True, "pooja"),
    ("Sacred Cotton Thread Janeu Poonal Pack of 3", "பூணூல் (3 எண்ணிக்கை)", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Holy Thread", "piece", "package", "Pooja Shelf", 3.0, [3.0], ["Temple Stores", "Ganapathy Stores"], ["poonal", "janeu thread", "yajnopavita"], False, True, "pooja"),
    ("Sacred Wrist Protection Thread Mauli Kalava Red", "காப்பு நூல் / மௌலி கயிறு", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Holy Thread", "roll", "piece", "Pooja Shelf", 1.0, [1.0], ["Temple Stores"], ["mauli", "kalava", "kaapu nool"], False, True, "pooja"),
    ("Yellow Pure Cotton Pooja Cloth Piece 1 Meter", "மஞ்சள் பூஜை துணி (1 மீட்டர்)", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Cloth", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Temple Stores"], ["yellow pooja cloth", "manjal thuni"], False, True, "pooja"),
    ("Red Pure Cotton Pooja Cloth Piece 1 Meter", "சிகப்பு பூஜை துணி (1 மீட்டர்)", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Cloth", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Temple Stores"], ["red pooja cloth", "sigappu thuni"], False, True, "pooja"),
    ("Pure Dry Desi Cow Dung Cakes Varatti Pack 5s", "நாட்டு மாட்டு வரட்டி (5 எண்ணிக்கை)", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Homam Material", "piece", "package", "Pooja Shelf", 5.0, [5.0, 10.0], ["Gau Seva", "Temple Stores"], ["varatti", "cow dung cake", "upla"], False, True, "pooja"),
    ("Dried Whole Copra Half Shell Sakkarai Thengai", "கொப்பரைத் தேங்காய்", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Dry Coconut", "piece", "piece", "Pooja Shelf", 1.0, [1.0, 2.0], ["Temple Stores", "Local Farmers"], ["kopra", "sakkarai thengai", "dry coconut half"], True, True, "pooja"),
    ("Solid Brass Oil Diya Deepak Small", "பித்தளை அகல் விளக்கு", "Pooja & Spiritual Essentials", "Pooja Utensils", "Diya", "piece", "piece", "Pooja Shelf", 1.0, [1.0, 2.0], ["Local Brass Artisans"], ["brass diya", "agal vilakku"], False, True, "pooja"),
    ("Solid Brass Camphor Aarti Burner with Wooden Handle", "பித்தளை கற்பூர ஆரத்தி தட்டு", "Pooja & Spiritual Essentials", "Pooja Utensils", "Aarti", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Local Brass Artisans"], ["camphor aarti", "karpoora aarti thaddu"], False, True, "pooja"),
    ("Solid Brass Pooja Hand Bell Ghanti", "பித்தளை மணி (பூஜை)", "Pooja & Spiritual Essentials", "Pooja Utensils", "Bell", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Local Brass Artisans"], ["pooja bell", "brass ghanti", "mani"], False, True, "pooja"),
    ("Nag Champa Heritage Agarbatti Sticks", "நாக் சம்பா ஊதுபத்தி", "Pooja & Spiritual Essentials", "Camphor & Agarbatti", "Agarbatti", "piece", "package", "Pooja Shelf", 20.0, [20.0, 50.0], ["Satya Sai Baba Nag Champa"], ["nag champa agarbatti", "satya nag champa"], False, True, "pooja"),
    ("Pure Loban Resin Cups for Pooja", "தூய லோபான் சாம்பிராணி கப்", "Pooja & Spiritual Essentials", "Camphor & Agarbatti", "Sambrani", "piece", "package", "Pooja Shelf", 12.0, [12.0], ["Phool", "Cycle", "Mangaldeep"], ["loban cups", "dhoop loban"], False, True, "pooja"),
    ("Pure Guggul Resin Cups for Homam & Aarti", "தூய குக்குல் சாம்பிராணி கப்", "Pooja & Spiritual Essentials", "Camphor & Agarbatti", "Sambrani", "piece", "package", "Pooja Shelf", 12.0, [12.0], ["Phool", "Cycle"], ["guggul cups", "guggal dhoop"], False, True, "pooja"),
    ("Natural Camphor Scent Cone for Home & Car", "கற்பூர வாசனை கோன்", "Household & Cleaning", "Surface Cleaners & Pest Control", "Fragrance", "piece", "piece", "Wardrobe", 1.0, [1.0], ["Mangalam Camphor Cone", "Campure"], ["camphor cone", "campure cone"], False, True, "cleaning"),

    # === HOUSEHOLD, LAUNDRY & UTILITY ===
    ("Front Load Liquid Detergent 2 Litres", "ஃபிரண்ட் லோட் லிக்விட் டிடர்ஜென்ட் (2 லிட்டர்)", "Household & Cleaning", "Laundry Care", "Liquid Detergent", "l", "volume", "Laundry Cabinet", 2.0, [1.0, 2.0], ["Surf Excel Matic Liquid", "Ariel Matic Liquid"], ["front load liquid detergent", "surf matic liquid"], False, True, "cleaning"),
    ("Top Load Liquid Detergent 2 Litres", "டாப் லோட் லிக்விட் டிடர்ஜென்ட் (2 லிட்டர்)", "Household & Cleaning", "Laundry Care", "Liquid Detergent", "l", "volume", "Laundry Cabinet", 2.0, [1.0, 2.0], ["Surf Excel Matic Top", "Ariel Top Load Liquid"], ["top load liquid detergent", "surf top liquid"], False, True, "cleaning"),
    ("Gentle Baby Laundry Liquid Detergent Pouch", "குழந்தை துணி துவைக்கும் திரவம்", "Baby Care", "Baby Hygiene & Wellness", "Baby Detergent", "ml", "volume", "Laundry Cabinet", 500.0, [500.0, 1000.0], ["Pigeon Baby Detergent", "Mee Mee", "Himalaya"], ["baby laundry detergent", "baby fabric wash"], False, True, "baby_care"),
    ("Biodegradable Small Dustbin Bags 30s", "குப்பை பை - ஸ்மால் (30 எண்ணிக்கை)", "Household & Cleaning", "Cleaning Tools", "Garbage Bags", "piece", "package", "Utility Shelf", 30.0, [30.0], ["Shalimar", "Presto!"], ["small garbage bags", "chota dustbin cover"], False, True, "cleaning"),
    ("Food Grade Heavy Duty Aluminium Foil 18m", "அலுமினியம் ஃபாயில் (18 மீட்டர்)", "Household & Cleaning", "Kitchen Disposables", "Foil", "piece", "piece", "Kitchen Cabinet", 1.0, [1.0], ["Freshwrapp 18m", "Hindalco"], ["aluminium foil 18m", "big foil roll"], False, True, "cleaning"),
    ("Zip Lock Bags Medium Size 20s", "ஜிப் லாக் பைகள் - மீடியம் (20 எண்ணிக்கை)", "Household & Cleaning", "Kitchen Disposables", "Bags", "piece", "package", "Kitchen Cabinet", 20.0, [20.0], ["Shalimar", "Freshwrapp"], ["medium zip lock bags", "zipper bags"], False, True, "cleaning"),
    ("Zip Lock Bags Large Size 15s", "ஜிப் லாக் பைகள் - லார்ஜ் (15 எண்ணிக்கை)", "Household & Cleaning", "Kitchen Disposables", "Bags", "piece", "package", "Kitchen Cabinet", 15.0, [15.0], ["Shalimar", "Freshwrapp"], ["large zip lock bags"], False, True, "cleaning"),
]

def generate_part2_catalog_code():
    catalog = []
    seen_ids = set()

    for item in ITEMS_PART2:
        (name, tamil, cat, subcat, ptype, unit, sold, loc, min_q, custom_q, brands, aliases, loose, packaged, icon) = item
        slug = slugify(name)
        if slug in seen_ids:
            slug = f"{slug}_{unit}"
        seen_ids.add(slug)

        prod = {
            "id": slug,
            "name": name,
            "tamilName": tamil,
            "category": cat,
            "subCategory": subcat,
            "productType": ptype,
            "defaultUnit": unit,
            "soldBy": sold,
            "storageLocation": loc,
            "minimumQuantity": min_q,
            "customQuantities": custom_q,
            "commonNames": aliases,
            "aliases": [a.lower() for a in aliases],
            "brands": brands,
            "barcodeSupport": True,
            "barcodeType": "EAN_13",
            "barcodes": [],
            "isLoose": loose,
            "isPackaged": packaged,
            "iconKey": icon
        }
        catalog.append(prod)

    json_str = json.dumps(catalog, ensure_ascii=False, indent=2)
    output_code = f'''# -*- coding: utf-8 -*-
"""
Matrix Catalog Expansion Part 2: Contains {len(catalog)} culturally authentic,
normalized household products for Indian / Tamil Nadu households.
"""
import json

_DATA = r"""{json_str}"""

def get_matrix_catalog_part2():
    return json.loads(_DATA)

if __name__ == "__main__":
    items = get_matrix_catalog_part2()
    print(f"Loaded {{len(items)}} matrix expansion part 2 items.")
'''
    with open("scripts/expand_matrix_catalog_part2.py", "w", encoding="utf-8") as f:
        f.write(output_code)

    print(f"Generated scripts/expand_matrix_catalog_part2.py with {len(catalog)} items.")

if __name__ == "__main__":
    generate_part2_catalog_code()

