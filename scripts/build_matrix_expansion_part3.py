# -*- coding: utf-8 -*-
"""
Builder for expand_matrix_catalog_part3.py
Generates 250+ distinct, authentic Indian & Tamil household staples,
pushing total unique items well beyond 2,150+.
"""
import json
import re

def slugify(text):
    text = text.lower().strip()
    text = re.sub(r'\(.*?\)', '', text).strip()
    text = re.sub(r'[^a-z0-9]+', '_', text).strip('_')
    return text

ITEMS_PART3 = [
    # === TRADITIONAL HERBS, AYURVEDA & SIDDHA REMEDIES ===
    ("Athimathuram Whole Licorice Roots", "அதிமதுரம் வேர் (முழுசு)", "Spices & Seasonings", "Ayurvedic Powders", "Herbal Root", "g", "weight", "Medicine Box", 100.0, [50.0, 100.0, 200.0], ["Local Ayurvedic", "Ganapathy Stores"], ["athimathuram ver", "licorice root whole", "mulethi root"], True, True, "spice"),
    ("Chitharathai Lesser Galangal Rhizome Whole", "சித்தரத்தை (முழுசு)", "Spices & Seasonings", "Ayurvedic Powders", "Herbal Root", "g", "weight", "Medicine Box", 100.0, [50.0, 100.0], ["Local Ayurvedic"], ["chitharathai whole", "galangal rhizome"], True, True, "spice"),
    ("Kandanthippili Dried Wild Pepper Roots", "கண்டந்திப்பிலி வேர்", "Spices & Seasonings", "Ayurvedic Powders", "Herbal Root", "g", "weight", "Medicine Box", 50.0, [50.0, 100.0], ["Local Ayurvedic", "Gopuram"], ["kandanthippili", "long pepper root"], True, True, "spice"),
    ("Arisithippili Long Pepper Spikes Whole", "அரிசித்திப்பிலி (முழுசு)", "Spices & Seasonings", "Ayurvedic Powders", "Herbal Spike", "g", "weight", "Medicine Box", 50.0, [50.0, 100.0], ["Local Ayurvedic"], ["arisithippili", "pippali whole"], True, True, "spice"),
    ("Vettiveru Khus Vetiver Roots Fragrant", "வெட்டிவேர்", "Personal Care & Hygiene", "Bath & Body Care", "Fragrant Root", "g", "weight", "Bathroom Shelf", 50.0, [50.0, 100.0], ["Local Ayurvedic", "Gopuram"], ["vettiveru", "vetiver grass root", "khus"], True, True, "personal_care"),
    ("Vilamichai Ver Fragrant Mallow Roots", "விளாமிச்சை வேர்", "Personal Care & Hygiene", "Bath & Body Care", "Fragrant Root", "g", "weight", "Bathroom Shelf", 50.0, [50.0], ["Local Ayurvedic"], ["vilamichai ver", "fragrant swamp mallow root"], True, True, "personal_care"),
    ("Nannari Ver Sarsaparilla Root Whole", "நன்னாரி வேர் (முழுசு)", "Beverages", "Herbal Drinks", "Herbal Root", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Local Ayurvedic", "Gramiyum"], ["nannari ver", "sarsaparilla root"], True, True, "beverage"),
    ("Kadukkai Whole Haritaki Chebulic Myrobalan", "கடுக்காய் (முழுசு)", "Spices & Seasonings", "Ayurvedic Powders", "Herbal Fruit", "g", "weight", "Medicine Box", 100.0, [100.0, 200.0], ["Local Ayurvedic", "Baidyanath"], ["kadukkai", "haritaki whole", "harad"], True, True, "spice"),
    ("Nellikkai Dried Amla Fruit Pieces", "நெல்லிக்காய் வற்றல் (உலர்ந்தது)", "Spices & Seasonings", "Ayurvedic Powders", "Herbal Fruit", "g", "weight", "Medicine Box", 100.0, [100.0, 200.0], ["Local Ayurvedic", "Baidyanath"], ["dried amla", "nellikai vathal"], True, True, "spice"),
    ("Thandrikkai Whole Bibhitaki", "தான்றிக்காய் (முழுசு)", "Spices & Seasonings", "Ayurvedic Powders", "Herbal Fruit", "g", "weight", "Medicine Box", 100.0, [100.0], ["Local Ayurvedic"], ["thandrikkai", "bibhitaki whole", "baheda"], True, True, "spice"),
    ("Nilavembu Kudineer Churna Decoction Powder", "நிலவேம்பு குடிநீர் சூரணம்", "Spices & Seasonings", "Ayurvedic Powders", "Herbal Powder", "g", "weight", "Medicine Box", 100.0, [50.0, 100.0], ["SKM Siddha", "IMPCOPS", "Local Ayurvedic"], ["nilavembu kudineer", "nilavembu powder"], False, True, "masala"),
    ("Kabasura Kudineer Churna Immunity Powder", "கபசுர குடிநீர் சூரணம்", "Spices & Seasonings", "Ayurvedic Powders", "Herbal Powder", "g", "weight", "Medicine Box", 100.0, [50.0, 100.0], ["IMPCOPS", "SKM Siddha"], ["kabasura kudineer", "kabasuram powder"], False, True, "masala"),
    ("Adathodai Malabar Nut Dried Leaves", "ஆடாதோடை இலை (உலர்ந்தது)", "Spices & Seasonings", "Ayurvedic Powders", "Dried Leaves", "g", "weight", "Medicine Box", 50.0, [50.0], ["Local Ayurvedic"], ["adathodai", "vasaka leaves"], True, True, "spice"),
    ("Karunjeeragam Black Caraway Kalonji Seeds", "கருஞ்சீரகம்", "Spices & Seasonings", "Whole Spices", "Oilseed", "g", "weight", "Pantry Shelf", 100.0, [50.0, 100.0, 250.0], ["Tata Sampann", "BB Royal", "Local Ayurvedic"], ["karunjeeragam", "kalonji", "black seed"], True, True, "spice"),
    ("Poolankizhangu White Turmeric Rhizome", "பூலாங்கிழங்கு (வெள்ளை மஞ்சள்)", "Personal Care & Hygiene", "Bath & Body Care", "Herbal Root", "g", "weight", "Bathroom Shelf", 100.0, [100.0], ["Local Ayurvedic", "Gopuram"], ["poolankizhangu", "white turmeric"], True, True, "personal_care"),
    ("Vasambu Sweet Flag Root Acorus Calamus", "வசம்பு (பேராசான்)", "Personal Care & Hygiene", "Baby Care", "Herbal Root", "piece", "piece", "Medicine Box", 2.0, [1.0, 2.0], ["Local Ayurvedic", "Temple Stores"], ["vasambu", "sweet flag root", "ghoravach"], True, True, "personal_care"),
    ("Aavarampoo Dried Tanner Cassia Flowers", "ஆவாரம்பூ (உலர்ந்த பூக்கள்)", "Beverages", "Herbal Drinks", "Dried Flowers", "g", "weight", "Pantry Shelf", 100.0, [50.0, 100.0], ["Local Ayurvedic", "Gramiyum"], ["aavarampoo", "tanner cassia flowers"], True, True, "beverage"),
    ("Sembaruthi Poo Dried Hibiscus Flower Petals", "செம்பருத்திப் பூ (உலர்ந்த இதழ்கள்)", "Beverages", "Herbal Drinks", "Dried Flowers", "g", "weight", "Pantry Shelf", 100.0, [50.0, 100.0], ["Gramiyum", "Local Ayurvedic"], ["sembaruthi poo", "hibiscus petals dry"], True, True, "beverage"),
    ("Dried Country Rose Petals Panneer Roja", "பன்னீர் ரோஜா உலர்ந்த இதழ்கள்", "Food & Grocery", "Baking Ingredients", "Dried Petals", "g", "weight", "Pantry Shelf", 50.0, [50.0, 100.0], ["Local Ayurvedic", "Urban Platter"], ["dried rose petals", "panneer roja idhazh"], True, True, "spice"),
    ("Chyawanprash Ayurvedic Immunity Paste 1kg", "சியவன்பிராஷ் லேகியம் (1 கிலோ)", "Personal Care & Hygiene", "Health & Wellness", "Herbal Jam", "kg", "weight", "Pantry Shelf", 1.0, [0.5, 1.0], ["Dabur Chyawanprash", "Baidyanath", "Patanjali"], ["chyawanprash", "chyawanprash 1kg"], False, True, "personal_care"),

    # === SPECIALTY DAIRY, GREEK YOGURT & DESSERTS ===
    ("Plain Unsweetened Greek Yogurt Cup 100g", "கிரேக்க யோகர்ட் (இனிப்பில்லாதது)", "Dairy & Refrigerated", "Dairy Products", "Yogurt", "g", "weight", "Refrigerator", 100.0, [100.0, 400.0], ["Epigamia Greek Yogurt", "Milky Mist"], ["greek yogurt plain", "unsweetened yogurt"], False, True, "dairy"),
    ("Strawberry Flavored Greek Yogurt Cup", "ஸ்ட்ராபெரி கிரேக்க யோகர்ட்", "Dairy & Refrigerated", "Dairy Products", "Yogurt", "g", "weight", "Refrigerator", 90.0, [90.0], ["Epigamia", "Milky Mist"], ["strawberry yogurt", "greek yogurt fruit"], False, True, "dairy"),
    ("Blueberry Flavored Greek Yogurt Cup", "புளூபெரி கிரேக்க யோகர்ட்", "Dairy & Refrigerated", "Dairy Products", "Yogurt", "g", "weight", "Refrigerator", 90.0, [90.0], ["Epigamia", "Milky Mist"], ["blueberry greek yogurt"], False, True, "dairy"),
    ("Traditional Terracotta Cup Mishti Doi Sweet Curd", "மிஷ்டி தோய் (பெங்காலி இனிப்பு தயிர்)", "Dairy & Refrigerated", "Dairy Products", "Sweet Curd", "g", "weight", "Refrigerator", 100.0, [100.0, 200.0], ["Mother Dairy Mishti Doi", "Amul", "Milky Mist"], ["mishti doi", "sweet curd"], False, True, "dairy"),
    ("Kesar Elaichi Shrikhand Tub 200g", "கேசர் ஏலக்காய் ஸ்ரீகண்ட்", "Dairy & Refrigerated", "Dairy Products", "Shrikhand", "g", "weight", "Refrigerator", 200.0, [200.0, 500.0], ["Amul Shrikhand", "Mother Dairy"], ["kesar elaichi shrikhand", "shrikhand"], False, True, "dairy"),
    ("Amrakhand Mango Shrikhand Tub", "ஆம்ரகண்ட் (மாம்பழ ஸ்ரீகண்ட்)", "Dairy & Refrigerated", "Dairy Products", "Shrikhand", "g", "weight", "Refrigerator", 200.0, [200.0], ["Amul Amrakhand", "Mother Dairy"], ["amrakhand", "mango shrikhand"], False, True, "dairy"),
    ("Organic Firm Soya Tofu Block 200g", "சோயா டோஃபு (பன்னீர் மாற்று)", "Dairy & Refrigerated", "Dairy Products", "Tofu", "g", "weight", "Refrigerator", 200.0, [200.0], ["Health on Plants", "Mori-Nu", "Urban Platter"], ["soya tofu", "tofu block", "firm tofu"], False, True, "dairy"),
    ("Gouda Cheese Slices Pack 10s", "கௌடா சீஸ் ஸ்லைஸ்", "Dairy & Refrigerated", "Dairy Products", "Cheese", "g", "weight", "Refrigerator", 150.0, [150.0], ["Milky Mist Gouda", "Amul"], ["gouda cheese slices"], False, True, "dairy"),
    ("Heavy Whipping Cream 35% Milk Fat 250ml", "விப்பிங் கிரீம் (35% கொழுப்பு)", "Dairy & Refrigerated", "Dairy Products", "Cream", "ml", "volume", "Refrigerator", 250.0, [250.0, 1000.0], ["Amul Whipping Cream", "Rich's"], ["heavy whipping cream", "baking cream"], False, True, "dairy"),
    ("Unsweetened Almond Milk Carton 1L", "பாதாம் பால் (சர்க்கரை இல்லாதது, 1 லிட்டர்)", "Dairy & Refrigerated", "Dairy Alternatives", "Plant Milk", "l", "volume", "Pantry Shelf", 1.0, [1.0], ["Raw Pressery", "Epigamia Almond Milk", "Urban Platter"], ["almond milk unsweetened", "vegan almond milk"], False, True, "beverage"),
    ("Unsweetened Soya Milk Carton 1L", "சோயா பால் (1 லிட்டர்)", "Dairy & Refrigerated", "Dairy Alternatives", "Plant Milk", "l", "volume", "Pantry Shelf", 1.0, [1.0], ["Sofit Soya Milk", "Urban Platter"], ["sofit soy milk", "soya milk"], False, True, "beverage"),
    ("Barista Oat Milk Carton 1L", "ஓட்ஸ் பால் (1 லிட்டர்)", "Dairy & Refrigerated", "Dairy Alternatives", "Plant Milk", "l", "volume", "Pantry Shelf", 1.0, [1.0], ["Oatly", "Alt Co", "Urban Platter"], ["oat milk carton", "barista oat milk"], False, True, "beverage"),
    ("Culinary Coconut Milk Carton 200ml", "தேங்காய் பால் டெட்ரா பேக் (200 மி.லி)", "Food & Grocery", "Cooking & Baking", "Coconut Milk", "ml", "volume", "Pantry Shelf", 200.0, [200.0, 1000.0], ["Dabur Hommade Coconut Milk", "Chaokoh"], ["coconut milk tetra pack", "thengai paal"], False, True, "dairy"),
    ("Thick Coconut Cooking Cream Carton 200ml", "கெட்டி தேங்காய் கிரீம் (200 மி.லி)", "Food & Grocery", "Cooking & Baking", "Coconut Cream", "ml", "volume", "Pantry Shelf", 200.0, [200.0], ["Dabur Hommade", "Kara"], ["coconut cream", "thick thengai paal"], False, True, "dairy"),

    # === REGIONAL SNACKS, NAMKEEN & FRYUMS ===
    ("Plain Puffed Rice Pori Muri", "வெள்ளை பொரி", "Food & Grocery", "Flours & Grains", "Puffed Rice", "g", "weight", "Pantry Shelf", 250.0, [250.0, 500.0], ["Local Mills", "Udhayam"], ["pori", "puffed rice plain", "muri", "mamra"], True, True, "grains"),
    ("Aval Pori Beaten Puffed Rice", "அவல் பொரி", "Food & Grocery", "Flours & Grains", "Puffed Rice", "g", "weight", "Pantry Shelf", 200.0, [200.0, 500.0], ["Local Mills", "Grand Sweets"], ["aval pori", "puffed aval"], True, True, "grains"),
    ("Spicy Garlic Masala Pori Fry", "மசாலா பூண்டு பொரி", "Snacks & Namkeen", "Traditional Snacks", "Namkeen", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Grand Sweets", "Local Artisans"], ["masala pori", "garlic spiced puffed rice"], False, True, "snacks"),
    ("Andhra Crunchy Murukku Jantikalu", "ஆந்திரா ஜந்திகலு முறுக்கு", "Snacks & Namkeen", "Traditional Snacks", "Murukku", "g", "weight", "Pantry Shelf", 250.0, [250.0, 500.0], ["Priya Jantikalu", "Grand Sweets"], ["jantikalu", "andhra murukku"], False, True, "snacks"),
    ("Chettinad Handmade Kai Murukku 5s", "செட்டிநாடு கை முறுக்கு (5 எண்ணிக்கை)", "Snacks & Namkeen", "Traditional Snacks", "Murukku", "piece", "package", "Pantry Shelf", 5.0, [5.0, 10.0], ["Chettinad Artisans", "Grand Sweets"], ["chettinad kai murukku"], False, True, "snacks"),
    ("Ring Murukku Chegodilu Rings", "ரிங் முறுக்கு (செகோடிலு)", "Snacks & Namkeen", "Traditional Snacks", "Murukku", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Priya", "Grand Sweets", "A2B"], ["ring murukku", "chegodilu"], False, True, "snacks"),
    ("Crunchy Kodubale Ring Snack", "கொடுபலே", "Snacks & Namkeen", "Traditional Snacks", "Namkeen", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["MTR Kodubale", "Grand Sweets", "A2B"], ["kodubale", "karnataka ring snack"], False, True, "snacks"),
    ("Chettinad Spicy Thattai", "செட்டிநாடு கார தட்டை", "Snacks & Namkeen", "Traditional Snacks", "Thattai", "g", "weight", "Pantry Shelf", 200.0, [200.0, 400.0], ["Chettinad Artisans", "Grand Sweets"], ["chettinad thattai", "kara thattai"], False, True, "snacks"),
    ("Garlic Poondu Thattai", "பூண்டு தட்டை", "Snacks & Namkeen", "Traditional Snacks", "Thattai", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Grand Sweets", "A2B"], ["poondu thattai", "garlic thattai"], False, True, "snacks"),
    ("Andhra Spicy Chekkalu Rice Crackers", "ஆந்திரா செக்கலு (தட்டை)", "Snacks & Namkeen", "Traditional Snacks", "Crackers", "g", "weight", "Pantry Shelf", 250.0, [250.0], ["Priya Chekkalu", "Local Artisans"], ["chekkalu", "andhra rice crackers"], False, True, "snacks"),
    ("Karnataka Spicy Nippattu", "கர்நாடகா நிப்பட்டு", "Snacks & Namkeen", "Traditional Snacks", "Crackers", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["MTR Nippattu", "Grand Sweets"], ["nippattu", "spicy nippat"], False, True, "snacks"),
    ("Sweet Jaggery Banana Chips Sharkara Upperi", "சர்க்கரை வரட்டி (வெல்ல நேந்திரங்காய் சிப்ஸ்)", "Snacks & Namkeen", "Traditional Sweets", "Banana Chips", "g", "weight", "Pantry Shelf", 250.0, [250.0, 500.0], ["A1 Chips", "Double Horse", "Kerala Artisans"], ["sharkara upperi", "jaggery banana chips", "sarkara varatti"], False, True, "snacks"),
    ("Crispy Bitter Gourd Chips Pavakkai Chips", "பாகற்காய் சிப்ஸ்", "Snacks & Namkeen", "Chips & Crisps", "Vegetable Chips", "g", "weight", "Pantry Shelf", 150.0, [150.0], ["Hot Chips", "A1 Chips", "Grand Sweets"], ["pavakkai chips", "karela chips"], False, True, "snacks"),
    ("Crispy Taro Root Chips Arbi Chips", "சேப்பங்கிழங்கு சிப்ஸ்", "Snacks & Namkeen", "Chips & Crisps", "Vegetable Chips", "g", "weight", "Pantry Shelf", 150.0, [150.0], ["Hot Chips", "A1 Chips"], ["arbi chips", "cheppankizhangu chips"], False, True, "snacks"),
    ("Crispy Elephant Yam Chips Senai Chips", "சேனைக்கிழங்கு சிப்ஸ்", "Snacks & Namkeen", "Chips & Crisps", "Vegetable Chips", "g", "weight", "Pantry Shelf", 150.0, [150.0], ["Hot Chips", "A1 Chips"], ["senai chips", "yam chips crispy"], False, True, "snacks"),
    ("Bhuna Chana Roasted Gram with Skin", "வறுத்த கருப்பு கொண்டைக்கடலை (தோலுடன்)", "Snacks & Namkeen", "Traditional Snacks", "Healthy Snack", "g", "weight", "Pantry Shelf", 250.0, [250.0, 500.0], ["Tata Sampann", "Haldiram's"], ["bhuna chana", "roasted chana with skin"], False, True, "snacks"),
    ("Fried Salted Moong Dal Namkeen", "வறுத்த உப்பு பாசிப்பருப்பு", "Snacks & Namkeen", "Traditional Snacks", "Namkeen", "g", "weight", "Pantry Shelf", 200.0, [200.0, 400.0], ["Haldiram's Moong Dal", "Bikano"], ["salted moong dal", "fried moong dal"], False, True, "snacks"),
    ("Crispy Methi Mathri Flaky Crackers", "வெந்தயக்கீரை மத்ரி (கசூரி மேத்தி)", "Snacks & Namkeen", "Traditional Snacks", "Namkeen", "g", "weight", "Pantry Shelf", 250.0, [200.0, 250.0], ["Haldiram's Mathri", "Bikaji"], ["methi mathri", "flaky mathri"], False, True, "snacks"),
    ("Pani Puri Ready-to-Fry Pellets Box 50s", "பானி பூரி பொரிக்கும் அப்பளம் (50 எண்ணிக்கை)", "Snacks & Namkeen", "Traditional Snacks", "Pani Puri", "piece", "package", "Pantry Shelf", 50.0, [50.0, 100.0], ["Bikano", "Ching's", "Urban Platter"], ["pani puri pellets", "fry ready golgappa"], False, True, "snacks"),
    ("Chaat Papdi Crispy Round Discs Box 200g", "சாட் பப்டி தட்டுகள்", "Snacks & Namkeen", "Traditional Snacks", "Chaat", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Haldiram's Papdi", "Bikano"], ["chaat papdi", "sev puri papdi"], False, True, "snacks"),

    # === CONTINENTAL, PASTAS & SAUCES ===
    ("Durum Wheat Penne Rigate Pasta 500g", "பென்னே பாஸ்தா (500 கிராம்)", "Food & Grocery", "Pasta & Noodles", "Pasta", "g", "weight", "Pantry Shelf", 500.0, [500.0], ["Barilla", "Borges", "Disano"], ["penne pasta", "durum wheat penne"], False, True, "packaged_food"),
    ("Durum Wheat Fusilli Spiral Pasta 500g", "ஃபுசில்லி சுருள் பாஸ்தா (500 கிராம்)", "Food & Grocery", "Pasta & Noodles", "Pasta", "g", "weight", "Pantry Shelf", 500.0, [500.0], ["Barilla", "Borges", "Disano"], ["fusilli pasta", "spiral pasta"], False, True, "packaged_food"),
    ("Durum Wheat Elbow Macaroni Pasta 500g", "மேக்ரோனி பாஸ்தா (500 கிராம்)", "Food & Grocery", "Pasta & Noodles", "Pasta", "g", "weight", "Pantry Shelf", 500.0, [500.0], ["Bambino Macaroni", "Disano", "Weikfield"], ["macaroni", "elbow pasta"], False, True, "packaged_food"),
    ("Spaghetti Long Durum Wheat Pasta 500g", "ஸ்பாகெட்டி நீள பாஸ்தா (500 கிராம்)", "Food & Grocery", "Pasta & Noodles", "Pasta", "g", "weight", "Pantry Shelf", 500.0, [500.0], ["Barilla Spaghetti", "Borges", "Disano"], ["spaghetti", "long pasta"], False, True, "packaged_food"),
    ("Hakka Veg Noodles Flat Cake 300g", "ஹக்கா நூடுல்ஸ் கேக் (300 கிராம்)", "Food & Grocery", "Pasta & Noodles", "Noodles", "g", "weight", "Pantry Shelf", 300.0, [300.0], ["Ching's Secret Hakka Noodles", "Smith & Jones"], ["hakka noodles", "veg noodles cake"], False, True, "packaged_food"),
    ("Classic Eggless Mayonnaise Squeeze Bottle 250g", "முட்டையில்லா மயோனைஸ்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Mayonnaise", "g", "weight", "Refrigerator", 250.0, [250.0, 800.0], ["Veeba Eggless Mayo", "FunFoods Dr. Oetker"], ["eggless mayonnaise", "veeba mayo"], False, True, "condiment"),
    ("Mint Herb Eggless Mayonnaise 250g", "புதினா மயோனைஸ்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Mayonnaise", "g", "weight", "Refrigerator", 250.0, [250.0], ["Veeba Mint Mayo", "FunFoods"], ["mint mayo", "hari chutney mayonnaise"], False, True, "condiment"),
    ("Tandoori Spicy Eggless Mayonnaise 250g", "தந்தூரி மயோனைஸ்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Mayonnaise", "g", "weight", "Refrigerator", 250.0, [250.0], ["Veeba Tandoori Mayo", "FunFoods"], ["tandoori mayo"], False, True, "condiment"),
    ("Pizza & Pasta Herb Tomato Sauce Jar 350g", "பிட்சா & பாஸ்தா சாஸ் ஜாடி", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Cooking Sauce", "g", "weight", "Pantry Shelf", 350.0, [350.0], ["Veeba Pizza Pasta Sauce", "Dr. Oetker", "Barilla"], ["pizza pasta sauce", "red pasta sauce"], False, True, "condiment"),
    ("Traditional Bengali Kasundi Mustard Sauce 300g", "காசுந்தி கடுகு சாஸ்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Mustard Sauce", "g", "weight", "Pantry Shelf", 300.0, [300.0], ["Mukharochak Kasundi", "Druk", "Urban Platter"], ["kasundi mustard", "bengali mustard sauce"], False, True, "condiment"),
    ("Synthetic White Vinegar for Cooking 500ml", "வெள்ளை சமையல் வினிகர்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Vinegar", "ml", "volume", "Pantry Shelf", 500.0, [500.0], ["Ching's Secret Vinegar", "Tops", "Disano"], ["white vinegar", "synthetic vinegar"], False, True, "condiment"),
    ("Raw Organic Apple Cider Vinegar with Mother 500ml", "ஆப்பிள் சைடர் வினிகர்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Vinegar", "ml", "volume", "Pantry Shelf", 500.0, [500.0], ["Bragg Apple Cider", "Wow", "Kapiva"], ["apple cider vinegar with mother", "acv"], False, True, "condiment"),

    # === REGIONAL BIRYANI & CURRY MASALAS ===
    ("Dindigul Thalappakatti Biryani Masala", "திண்டுக்கல் தலப்பாகட்டி பிரியாணி மசாலா", "Spices & Seasonings", "Spices & Masalas", "Biryani Masala", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Thalappakatti", "Aachi"], ["dindigul biryani masala", "seeraga samba biryani masala"], False, True, "masala"),
    ("Ambur Star Biryani Masala Powder", "ஆம்பூர் ஸ்டார் பிரியாணி மசாலா", "Spices & Seasonings", "Spices & Masalas", "Biryani Masala", "g", "weight", "Pantry Shelf", 100.0, [100.0], ["Ambur Star", "Aachi"], ["ambur biryani masala"], False, True, "masala"),
    ("Hyderabadi Dum Biryani Pot Masala", "ஹைதராபாதி தம் பிரியாணி மசாலா", "Spices & Seasonings", "Spices & Masalas", "Biryani Masala", "g", "weight", "Pantry Shelf", 100.0, [100.0], ["Shan Hyderabadi Biryani", "Everest", "MDH"], ["hyderabadi biryani masala", "dum biryani masala"], False, True, "masala"),
    ("Kerala Malabar Garam Masala Whole Ground", "கேரளா மலபார் கரம் மசாலா", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0], ["Eastern Malabar Masala", "Kitchen Treasures"], ["malabar garam masala", "kerala garam masala"], False, True, "masala"),
    ("Madurai Mutton Chukka Fry Masala", "மதுரை மட்டன் சுக்கா மசாலா", "Spices & Seasonings", "Spices & Masalas", "Meat Masala", "g", "weight", "Pantry Shelf", 100.0, [100.0], ["Aachi", "Sakthi"], ["mutton chukka masala", "madurai chukka masala"], False, True, "masala"),
    ("Kongunadu Kari Masala Coimbatore Style", "கொங்குநாடு கறி மசாலா", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0], ["Aachi", "Local Spices"], ["kongunadu masala", "coimbatore kari masala"], False, True, "masala"),
    ("Mangalorean Ghee Roast Masala Paste", "மங்களூர் நெய் ரோஸ்ட் மசாலா", "Spices & Seasonings", "Spices & Masalas", "Cooking Paste", "g", "weight", "Pantry Shelf", 100.0, [100.0], ["Chef Pillai", "Eastern"], ["ghee roast masala", "kori ghee roast"], False, True, "masala"),
    ("Chettinad Fish Fry Masala Podi", "செட்டிநாடு மீன் வறுவல் மசாலா", "Spices & Seasonings", "Spices & Masalas", "Fish Masala", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Aachi Fish Fry", "Sakthi", "Eastern"], ["fish fry masala", "meen varuval podi"], False, True, "masala"),
    ("Prawns Pepper Fry Masala Podi", "இறால் மிளகு வறுவல் மசாலா", "Spices & Seasonings", "Spices & Masalas", "Seafood Masala", "g", "weight", "Pantry Shelf", 100.0, [100.0], ["Aachi", "Eastern"], ["prawns masala", "eraal milagu masala"], False, True, "masala"),
    ("Tangy Jaljeera Cumin Drink Mix Powder", "ஜல்ஜீரா பவுடர்", "Beverages", "Instant Drinks", "Drink Mix", "g", "weight", "Pantry Shelf", 100.0, [100.0], ["Catch Jaljeera", "MDH", "Everest"], ["jaljeera powder", "cumin drink mix"], False, True, "beverage"),
    ("Spicy Chaas Buttermilk Seasoning Sprinkler", "மோர் மசாலா தூவல்", "Spices & Seasonings", "Spices & Masalas", "Seasoning", "g", "weight", "Pantry Shelf", 100.0, [100.0], ["Catch Chaas Masala", "MDH"], ["chaas masala", "neer mor podi"], False, True, "masala"),
    ("Peri Peri Chilli Garlic Sprinkler 100g", "பெரி பெரி மசாலா ஸ்பிரிங்க்ளர்", "Spices & Seasonings", "Spices & Masalas", "Seasoning", "g", "weight", "Pantry Shelf", 100.0, [100.0], ["Keya Peri Peri", "Snapin", "Urban Platter"], ["peri peri sprinkler", "peri peri spice mix"], False, True, "masala"),

    # === HOUSEHOLD, POOJA, PETS & GROOMING ===
    ("Brasso Metal Polish Liquid for Brass 100ml", "பிராஸோ பித்தளை பாலிஷ் திரவம்", "Household & Cleaning", "Home Utilities", "Metal Polish", "ml", "volume", "Utility Shelf", 100.0, [100.0], ["Brasso Reckitt"], ["brasso", "brass polish liquid"], False, True, "hardware"),
    ("Silvo Silver Polish Liquid 100ml", "சில்வோ வெள்ளி பாலிஷ் திரவம்", "Household & Cleaning", "Home Utilities", "Metal Polish", "ml", "volume", "Utility Shelf", 100.0, [100.0], ["Silvo Reckitt"], ["silvo", "silver polish liquid"], False, True, "hardware"),
    ("Pure Copper Water Bottle Hammered 1L", "தூய செம்பு தண்ணீர் பாட்டில் (1 லிட்டர்)", "Home Utility & Hardware", "Kitchenware", "Copperware", "piece", "piece", "Kitchen Counter", 1.0, [1.0], ["Prestige Copper", "Local Artisans"], ["copper water bottle", "sembu bottle"], False, True, "hardware"),
    ("Natural Clay Water Pot Matka with Tap", "மண் பானை (குழாயுடன்)", "Home Utility & Hardware", "Kitchenware", "Earthenware", "piece", "piece", "Kitchen Counter", 1.0, [1.0], ["Local Potters"], ["clay water pot", "matka with tap", "manpaanai"], True, False, "hardware"),
    ("Electrical Ceramic Camphor Diffuser Kapurdan", "எலக்ட்ரிக் கற்பூர டிஃப்பியூசர்", "Pooja & Spiritual Essentials", "Camphor & Agarbatti", "Diffuser", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Pure Kapoor", "Local Electricals"], ["electric camphor diffuser", "kapurdan"], False, True, "pooja"),
    ("Rechargeable Electric Mosquito Swatter Racket", "ரீசார்ஜபிள் கொசு பேட்", "Household & Cleaning", "Surface Cleaners & Pest Control", "Electrical Pest Control", "piece", "piece", "Living Room", 1.0, [1.0], ["Hit Mosquito Racket", "Hunter"], ["mosquito racket", "electric mosquito bat"], False, True, "hardware"),
    ("Anti-Tick & Flea Herbal Neem Dog Shampoo 200ml", "நாய் பேன் ஒண்ணி ஷாம்பு", "Pet Care", "Pet Hygiene", "Pet Shampoo", "ml", "volume", "Pet Care Shelf", 200.0, [200.0], ["Himalaya Erina-EP", "Bolfo", "Captain Zack"], ["dog tick shampoo", "erina ep"], False, True, "pets"),
    ("Pet Grooming Slicker Brush for Dogs & Cats", "செல்லப்பிராணி முடி சீவும் பிரஷ்", "Pet Care", "Pet Grooming", "Pet Brush", "piece", "piece", "Pet Care Shelf", 1.0, [1.0], ["Meat Up", "Drools"], ["slicker brush", "dog grooming brush"], False, True, "pets"),
    ("Strong Nylon Dog Walking Leash 1.5m", "நாய் வாக்கிங் லீஷ் கயிறு", "Pet Care", "Pet Accessories", "Pet Leash", "piece", "piece", "Pet Care Shelf", 1.0, [1.0], ["Pets Empire", "Trixie"], ["dog leash", "walking rope dog"], False, True, "pets"),

    # === SWEETS, NUTS, HONEY & NATURAL SWEETENERS ===
    ("Crushed Peanut Chikki Jaggery Bar", "கடலை மிட்டாய் பார் (வெல்லம்)", "Snacks & Namkeen", "Traditional Sweets", "Chikki", "g", "weight", "Pantry Shelf", 200.0, [100.0, 200.0, 400.0], ["Kovilpatti Artisans", "Grand Sweets", "Haldiram's"], ["peanut chikki bar", "crushed kadalai mittai"], False, True, "snacks"),
    ("Dry Fruit Mixed Chikki Honey Jaggery", "ட்ரை ஃப்ரூட் மிக்ஸ்ட் சிக்கி", "Snacks & Namkeen", "Traditional Sweets", "Chikki", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Haldiram's", "Bikano"], ["dry fruit chikki", "mixed nuts chikki"], False, True, "snacks"),
    ("Sesame Til Laddu White Seeds", "வெள்ளை எள் லட்டு", "Snacks & Namkeen", "Traditional Sweets", "Laddu", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Grand Sweets", "Haldiram's"], ["til laddu white", "vellai ellu urundai"], False, True, "snacks"),
    ("Black Sesame Ellu Mittai Crunchy", "கருப்பு எள் மிட்டாய்", "Snacks & Namkeen", "Traditional Sweets", "Candy", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Grand Sweets", "Local Artisans"], ["ellu mittai", "black til chikki"], False, True, "snacks"),
    ("Kamarkat Hard Coconut Jaggery Candy", "கமர்கட் தேங்காய் வெல்ல மிட்டாய்", "Snacks & Namkeen", "Traditional Sweets", "Candy", "g", "weight", "Pantry Shelf", 150.0, [150.0], ["Grand Sweets", "Local Artisans"], ["kamarkat candy", "hard coconut candy"], False, True, "snacks"),
    ("Kadalai Urundai Jaggery Peanut Ball", "கடலை உருண்டை (நாட்டு வெல்லம்)", "Snacks & Namkeen", "Traditional Sweets", "Sweet", "piece", "package", "Pantry Shelf", 6.0, [6.0, 12.0], ["Grand Sweets", "Local Artisans"], ["kadalai urundai", "peanut jaggery ball"], False, True, "snacks"),
    ("Pori Urundai Jaggery Puffed Rice Ball", "பொரி உருண்டை (வெல்லம்)", "Snacks & Namkeen", "Traditional Sweets", "Sweet", "piece", "package", "Pantry Shelf", 6.0, [6.0, 12.0], ["Grand Sweets", "Local Artisans"], ["pori urundai", "puffed rice ball"], False, True, "snacks"),
    ("Roasted Salted Almonds California 200g", "வறுத்த உப்பு பாதாம் பருப்பு", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Almonds", "g", "weight", "Pantry Shelf", 200.0, [200.0, 500.0], ["Happilo", "Nutraj"], ["roasted salted almonds", "salted badam"], False, True, "snacks"),
    ("Roasted Salted Cashews Kaju 200g", "வறுத்த உப்பு முந்திரி பருப்பு", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Cashews", "g", "weight", "Pantry Shelf", 200.0, [200.0, 500.0], ["Happilo", "Nutraj"], ["roasted salted cashews", "salted kaju"], False, True, "snacks"),
    ("Black Pepper Roasted Cashews 200g", "மிளகு வறுத்த முந்திரி பருப்பு", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Cashews", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Happilo", "Nutraj"], ["pepper cashews", "milagu kaju"], False, True, "snacks"),
    ("Roasted Salted Sunflower Seeds 200g", "வறுத்த உப்பு சூரியகாந்தி விதைகள்", "Dry Fruits, Nuts & Seeds", "Seeds", "Seeds", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["True Elements", "Neuherbs"], ["roasted sunflower seeds"], False, True, "grains"),
    ("Roasted Salted Pumpkin Seeds 200g", "வறுத்த உப்பு பூசணி விதைகள்", "Dry Fruits, Nuts & Seeds", "Seeds", "Seeds", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["True Elements", "Neuherbs"], ["roasted pumpkin seeds"], False, True, "grains"),
    ("Spiced Roasted Flax Seeds 200g", "வறுத்த மசாலா ஆளி விதைகள்", "Dry Fruits, Nuts & Seeds", "Seeds", "Seeds", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["True Elements", "Organic Tattva"], ["roasted flax seeds", "mukhwas alsi"], False, True, "grains"),
    ("Organic White Chia Seeds 200g", "வெள்ளை சியா விதைகள்", "Dry Fruits, Nuts & Seeds", "Seeds", "Seeds", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["True Elements", "Neuherbs"], ["white chia seeds"], False, True, "grains"),
    ("Whole Dried Coconut Copra Gola", "முழு கொப்பரை தேங்காய் (கோலா)", "Food & Grocery", "Cooking & Baking", "Dry Coconut", "piece", "piece", "Pantry Shelf", 1.0, [1.0, 2.0], ["Local Mills", "Udhayam"], ["dry copra", "sukha nariyal", "gola"], True, True, "grains"),
    ("Desiccated Coconut Powder Fine", "உலர்ந்த தேங்காய் துருவல் பொடி", "Food & Grocery", "Cooking & Baking", "Coconut Powder", "g", "weight", "Pantry Shelf", 200.0, [200.0, 500.0], ["Urban Platter", "BB Royal"], ["desiccated coconut", "dry coconut powder"], False, True, "grains"),
    ("Pure Cane Sugar Sulphur Free", "கரும்பு சர்க்கரை (சல்பர் இல்லாதது)", "Salt, Sugar & Sweeteners", "Sugar & Sweeteners", "Sugar", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0], ["Dhampure", "Trust", "Mawana"], ["cane sugar", "refined sugar sulphur free", "cheeni"], False, True, "staple"),
    ("Natural Brown Demerara Sugar", "பிரவுன் சுகர் டெமராரா", "Salt, Sugar & Sweeteners", "Sugar & Sweeteners", "Sugar", "kg", "weight", "Pantry Shelf", 1.0, [0.5, 1.0], ["Dhampure", "Trust"], ["brown sugar", "demerara sugar"], False, True, "staple"),
    ("Organic Coconut Palm Jaggery Karupatti", "பனை கருப்பட்டி (சுத்தமானது)", "Salt, Sugar & Sweeteners", "Sugar & Sweeteners", "Jaggery", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Gramiyum", "B&B Organics", "Local Artisans"], ["karupatti", "palm jaggery", "pana karupatti"], True, True, "staple"),
    ("Panakarkandu Palm Sugar Candy Crystals", "பனங்கற்கண்டு", "Salt, Sugar & Sweeteners", "Sugar & Sweeteners", "Sugar Candy", "g", "weight", "Pantry Shelf", 250.0, [250.0, 500.0], ["Local Artisans", "Gramiyum", "Gopuram"], ["panakarkandu", "palm sugar candy", "tal mishri"], True, True, "staple"),
    ("Round Jaggery Balls Mandi Vellam", "மண்டி உருண்டை வெல்லம்", "Salt, Sugar & Sweeteners", "Sugar & Sweeteners", "Jaggery", "kg", "weight", "Pantry Shelf", 1.0, [1.0], ["Udhayam", "Local Mills"], ["round jaggery", "urundai vellam", "gur"], True, True, "staple"),
    ("Nattu Sakkarai Country Sugar Jaggery Powder", "நாட்டுச் சர்க்கரை", "Salt, Sugar & Sweeteners", "Sugar & Sweeteners", "Jaggery Powder", "kg", "weight", "Pantry Shelf", 1.0, [0.5, 1.0], ["Gramiyum", "Udhayam", "24 Mantra"], ["nattu sakkarai", "country sugar", "brown jaggery powder"], False, True, "staple"),
    ("Raw Multi-Flora Forest Honey Squeeze Bottle", "சுத்தமான காட்டுத் தேன்", "Salt, Sugar & Sweeteners", "Sugar & Sweeteners", "Honey", "g", "weight", "Pantry Shelf", 500.0, [250.0, 500.0, 1000.0], ["Dabur Honey", "Patanjali Honey", "Saffola Honey", "Lion Honey"], ["honey", "raw forest honey", "then"], False, True, "staple"),
    ("Pure Himalayan Shilajit Resin 20g", "இமயமலை சிலாஜித் பிசின்", "Personal Care & Hygiene", "Health & Wellness", "Ayurvedic Resin", "g", "weight", "Medicine Box", 20.0, [20.0], ["Kapiva Shilajit", "Upakarma"], ["shilajit resin", "pure shilajit"], False, True, "personal_care"),
    ("Grade 1 Pure Kashmiri Saffron Kesar 1g", "தூய காஷ்மீரி குங்குமப்பூ (1 கிராம்)", "Spices & Seasonings", "Whole Spices", "Saffron", "g", "weight", "Pantry Shelf", 1.0, [1.0], ["Baby Saffron", "Lion Saffron", "Tata Sampann"], ["saffron", "kesar", "kungumapoo"], False, True, "spice"),

    # === POOJA UTENSILS, CLOTHS & BRASS ACCESSORIES ===
    ("Bhimseni Pure Kapoor Crystal Flakes 100g", "பீம்சேனி தூய கற்பூர படிகங்கள்", "Pooja & Spiritual Essentials", "Camphor & Agarbatti", "Camphor", "g", "weight", "Pooja Shelf", 100.0, [100.0], ["Mangalam Bhimseni", "Cycle"], ["bhimseni kapoor", "edible camphor flakes"], False, True, "pooja"),
    ("Aroma Sambrani Dhoop Cups Benzoin 24s", "நறுமண சாம்பிராணி கப் (24 எண்ணிக்கை)", "Pooja & Spiritual Essentials", "Camphor & Agarbatti", "Sambrani", "piece", "package", "Pooja Shelf", 24.0, [24.0], ["Phool", "Cycle"], ["sambrani dhoop cups 24", "fragrant cup dhoop"], False, True, "pooja"),
    ("Traditional Scented Sandalwood Pooja Fragrance Oil", "பூஜை சந்தன வாசனை எண்ணெய்", "Pooja & Spiritual Essentials", "Pooja Oils & Wicks", "Pooja Oil", "ml", "volume", "Pooja Shelf", 10.0, [10.0], ["Cycle Sugandh", "Gopuram"], ["sandalwood pooja oil", "chandan sugandh"], False, True, "pooja"),
    ("Ready Ghee Lamp Dipped Clay Diyas 12s", "நெய் நிரப்பிய மண் விளக்குகள் (12 எண்ணிக்கை)", "Pooja & Spiritual Essentials", "Pooja Oils & Wicks", "Diya", "piece", "package", "Pooja Shelf", 12.0, [12.0], ["Cycle Ghee Diyas", "Pure Desi"], ["clay ghee diyas", "ready diya pack"], False, True, "pooja"),
    ("Terracotta Clay Diyas Natural Pack of 12", "மண் அகல் விளக்குகள் (12 எண்ணிக்கை)", "Pooja & Spiritual Essentials", "Pooja Utensils", "Diya", "piece", "package", "Pooja Shelf", 12.0, [12.0], ["Local Potters"], ["clay diyas", "man vilakku"], False, True, "pooja"),
    ("Cotton Pooja Wicks Long Twisted 100s", "நீட்டு திரி பஞ்சு (100 எண்ணிக்கை)", "Pooja & Spiritual Essentials", "Pooja Oils & Wicks", "Wicks", "piece", "package", "Pooja Shelf", 100.0, [100.0], ["Cycle", "Gopuram"], ["long pooja wicks", "neettu thiri 100"], False, True, "pooja"),
    ("Solid Brass Panchapatra & Udharani Set", "பித்தளை பஞ்சபாத்திரம் & உத்தரணி", "Pooja & Spiritual Essentials", "Pooja Utensils", "Utensil Set", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Local Brass Artisans"], ["panchapatra udharani", "brass theertha pathiram"], False, True, "pooja"),
    ("Pure Copper Panchapatra & Spoon Set", "செம்பு பஞ்சபாத்திரம் & ஸ்பூன்", "Pooja & Spiritual Essentials", "Pooja Utensils", "Utensil Set", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Local Artisans"], ["copper panchapatra"], False, True, "pooja"),
    ("Solid Brass Agarbatti Stand with Ash Catcher", "பித்தளை ஊதுபத்தி ஸ்டாண்ட்", "Pooja & Spiritual Essentials", "Pooja Utensils", "Incense Stand", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Local Brass Artisans"], ["agarbatti stand brass", "incense holder"], False, True, "pooja"),
    ("Solid Brass Kalash Lota for Pooja", "பித்தளை பூர்வ கும்ப கலசம்", "Pooja & Spiritual Essentials", "Pooja Utensils", "Kalash", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Local Brass Artisans"], ["brass kalash", "pooja lota"], False, True, "pooja"),
    ("Pure Copper Kalash Lota for Holy Water", "செம்பு கலச செம்பு", "Pooja & Spiritual Essentials", "Pooja Utensils", "Kalash", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Local Artisans"], ["copper kalash", "sembu kalasam"], False, True, "pooja"),
    ("Solid Brass Aarti Thali Plate 10 Inch", "பித்தளை ஆரத்தி தட்டு (10 இன்ச்)", "Pooja & Spiritual Essentials", "Pooja Utensils", "Plate", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Local Brass Artisans"], ["brass aarti thali", "pooja plate 10 inch"], False, True, "pooja"),
    ("Solid Brass Kuthuvilakku Pair 12 Inch", "பித்தளை குத்துவிளக்கு ஜோடி (12 இன்ச்)", "Pooja & Spiritual Essentials", "Pooja Utensils", "Diya Stand", "piece", "piece", "Pooja Shelf", 2.0, [2.0], ["Nachiar Koil Artisans"], ["kuthuvilakku pair", "brass diya stand pair"], False, True, "pooja"),

    # === HOUSEHOLD UTILITY, CLEANING & MAINTENANCE ===
    ("Vessel Scrubbing Sponge Heavy Duty 3 Pack", "பாத்திரம் கழுவும் ஸ்பாஞ்ச் (3 எண்ணிக்கை)", "Household & Cleaning", "Cleaning Tools", "Sponge", "piece", "package", "Utility Shelf", 3.0, [3.0], ["Scotch-Brite Heavy Duty", "Gala"], ["heavy duty scrubber sponge", "bartan sponge"], False, True, "cleaning"),
    ("Steel Wool Wire Scrubber Heavy Duty Pack 4", "ஸ்டீல் கம்பி நார் (4 எண்ணிக்கை)", "Household & Cleaning", "Cleaning Tools", "Wire Scrubber", "piece", "package", "Utility Shelf", 4.0, [4.0], ["Scotch-Brite Steel Scrubber", "Gala"], ["steel wool pack", "wire juna 4s"], False, True, "cleaning"),
    ("Stainless Steel Kitchen Sink Drain Strainer Mesh", "ஸ்டெயின்லெஸ் ஸ்டீல் சின்க் வடிகட்டி", "Home Utility & Hardware", "Kitchenware", "Sink Strainer", "piece", "piece", "Kitchen Cabinet", 1.0, [1.0, 2.0], ["Presto!", "Local"], ["sink strainer mesh", "kitchen drain filter"], False, True, "hardware"),
    ("Silicone Kitchen Spatula Heat Resistant", "சிலிகான் கிச்சன் ஸ்பேட்டுலா", "Home Utility & Hardware", "Kitchenware", "Kitchen Tool", "piece", "piece", "Kitchen Cabinet", 1.0, [1.0], ["Wonderchef", "Prestige"], ["silicone spatula", "rubber spatula"], False, True, "hardware"),
    ("Natural Neem Wood Cooking Ladle Spatula Set", "வேப்பமர சமையல் கரண்டி செட்", "Home Utility & Hardware", "Kitchenware", "Wooden Ladle", "piece", "package", "Kitchen Cabinet", 3.0, [3.0], ["Local Wood Artisans", "Urban Platter"], ["wooden ladle neem", "marakkai karandi"], False, True, "hardware"),
    ("Plastic Clothes Drying Pegs with Basket 24s", "துணி கிளிப்புகள் கூடடை செட் (24 எண்ணிக்கை)", "Home Utility & Hardware", "Electrical & Utility", "Clips", "piece", "package", "Balcony Shelf", 24.0, [24.0], ["Gala", "Presto!"], ["clothes pegs with basket", "drying clips 24s"], False, True, "hardware"),
    ("Stainless Steel Wire Clothes Drying Pegs 12s", "ஸ்டீல் துணி கிளிப்புகள் (12 எண்ணிக்கை)", "Home Utility & Hardware", "Electrical & Utility", "Clips", "piece", "package", "Balcony Shelf", 12.0, [12.0], ["Gala", "Local"], ["steel clothes pegs", "wire clips"], False, True, "hardware"),
    ("Strong Braided Nylon Clothesline Rope 15m", "நைலான் துணி காயவைக்கும் கயிறு (15 மீட்டர்)", "Home Utility & Hardware", "Electrical & Utility", "Rope", "piece", "piece", "Balcony Shelf", 1.0, [1.0], ["Local", "Presto!"], ["clothesline rope", "drying rope 15m"], False, True, "hardware"),
    ("Plastic Bathroom Bucket Heavy Duty 18L", "பிளாஸ்டிக் குளியலறை வாளி (18 லிட்டர்)", "Home Utility & Hardware", "Bathroom Utilities", "Bucket", "piece", "piece", "Bathroom Shelf", 1.0, [1.0], ["Cello", "Nayasa", "Milton"], ["bathroom bucket 18L", "plastic vaali"], False, True, "hardware"),
    ("Plastic Bathroom Water Mug 1L", "பிளாஸ்டிக் தண்ணீர் குவளை (1 லிட்டர்)", "Home Utility & Hardware", "Bathroom Utilities", "Mug", "piece", "piece", "Bathroom Shelf", 1.0, [1.0], ["Cello", "Milton", "Nayasa"], ["bathroom mug 1L", "thanni mug"], False, True, "hardware"),
    ("Heavy Duty Dustpan with Rubber Lip", "குப்பை முறம் (ரப்பர் விளிம்புடன்)", "Household & Cleaning", "Cleaning Tools", "Dustpan", "piece", "piece", "Utility Room", 1.0, [1.0], ["Gala Dustpan", "Scotch-Brite"], ["dustpan with rubber lip", "kuppai muram"], False, True, "cleaning"),
    ("Herbal Vetiver Bath Loofah Natural", "வெட்டிவேர் குளியல் நார்", "Personal Care & Hygiene", "Bath & Body Care", "Bath Loofah", "piece", "piece", "Bathroom Shelf", 1.0, [1.0, 2.0], ["Gramiyum", "Local Ayurvedic"], ["vetiver loofah", "vettiveru bath scrub"], False, True, "personal_care"),
    ("Natural Coir Body Scrubber Loofah", "தேங்காய் நார் குளியல் ஸ்க்ரப்பர்", "Personal Care & Hygiene", "Bath & Body Care", "Bath Loofah", "piece", "piece", "Bathroom Shelf", 1.0, [1.0], ["Local Artisans"], ["coir bath scrubber", "thengai naar kuliyal scrub"], False, True, "personal_care"),
    ("Pure Neem Wood Wide Tooth Hair Comb", "வேப்பமர அகல பல் சீப்பு", "Personal Care & Hygiene", "Hair Care", "Comb", "piece", "piece", "Dressing Table", 1.0, [1.0], ["The Body Shop", "Local Neem Artisans"], ["neem wood comb", "veppamara seeppu"], False, True, "personal_care"),
    ("Pure Tea Tree Essential Oil Antibacterial 15ml", "டீ ட்ரீ எசென்ஷியல் ஆயில் (15 மி.லி)", "Personal Care & Hygiene", "Skin Care", "Essential Oil", "ml", "volume", "Dressing Table", 15.0, [15.0], ["Soulflower", "Organic Harvest"], ["tea tree oil", "pure tea tree"], False, True, "personal_care"),
    ("Pure Rosemary Essential Oil for Hair Growth 30ml", "ரோஸ்மேரி தலை கூந்தல் எண்ணெய் (30 மி.லி)", "Personal Care & Hygiene", "Hair Care", "Essential Oil", "ml", "volume", "Dressing Table", 30.0, [30.0], ["Soulflower Rosemary", "Biotique"], ["rosemary essential oil", "rosemary hair oil"], False, True, "personal_care"),

    # === FROZEN & READY SPECIALTIES ===
    ("Frozen Green Peas Tender Sweet 500g", "உறைந்த பச்சை பட்டாணி (500 கிராம்)", "Dairy & Refrigerated", "Frozen Foods", "Frozen Vegetables", "g", "weight", "Freezer", 500.0, [500.0, 1000.0], ["Safal Green Peas", "ITC Master Chef", "Godrej Yummiez"], ["frozen green peas", "frozen matar"], False, True, "fresh_produce"),
    ("Frozen Sweet Corn Kernels 500g", "உறைந்த இனிப்பு மக்காச்சோளம் (500 கிராம்)", "Dairy & Refrigerated", "Frozen Foods", "Frozen Vegetables", "g", "weight", "Freezer", 500.0, [500.0], ["Safal Sweet Corn", "ITC Master Chef"], ["frozen sweet corn", "frozen makka"], False, True, "fresh_produce"),
    ("Frozen Mixed Vegetables Pack 500g", "உறைந்த கலவை காய்கறிகள் (500 கிராம்)", "Dairy & Refrigerated", "Frozen Foods", "Frozen Vegetables", "g", "weight", "Freezer", 500.0, [500.0], ["Safal Mix Veg", "ITC Master Chef"], ["frozen mixed vegetables"], False, True, "fresh_produce"),
    ("Frozen French Fries Crispy 400g", "உறைந்த பிரெஞ்சு பிரைஸ் (400 கிராம்)", "Instant & Ready-to-Cook", "Frozen Foods", "Frozen Snack", "g", "weight", "Freezer", 400.0, [400.0, 1000.0], ["McCain French Fries", "ITC Master Chef"], ["french fries frozen", "mccain fries"], False, True, "packaged_food"),
    ("Frozen Veg Burger Patties 4 Pack", "உறைந்த வெஜ் பர்கர் பேட்டி (4 எண்ணிக்கை)", "Instant & Ready-to-Cook", "Frozen Foods", "Frozen Snack", "piece", "package", "Freezer", 4.0, [4.0], ["McCain Veggie Burger Patty", "Godrej Yummiez"], ["burger patty frozen"], False, True, "packaged_food"),
    ("Frozen Spiced Aloo Tikki 400g", "உறைந்த ஆலு டிக்கி (400 கிராம்)", "Instant & Ready-to-Cook", "Frozen Foods", "Frozen Snack", "g", "weight", "Freezer", 400.0, [400.0], ["McCain Aloo Tikki", "Haldiram's"], ["aloo tikki frozen"], False, True, "packaged_food"),
    ("Frozen Flaky Malabar Parotta 5s", "உறைந்த மலபார் பரோட்டா (5 எண்ணிக்கை)", "Instant & Ready-to-Cook", "Frozen Foods", "Frozen Bread", "piece", "package", "Freezer", 5.0, [5.0], ["iD Malabar Parota", "Asal Parotta", "Summosa"], ["frozen malabar parotta", "id parota"], False, True, "packaged_food"),
    ("Frozen Whole Wheat Phulka Roti 10s", "உறைந்த முழு கோதுமை புல்கா (10 எண்ணிக்கை)", "Instant & Ready-to-Cook", "Frozen Foods", "Frozen Bread", "piece", "package", "Freezer", 10.0, [10.0], ["iD Whole Wheat Roti", "Asal Chapati"], ["frozen chapati", "frozen roti phulka"], False, True, "packaged_food"),

    # === SPECIALTY COOKING OILS ===
    ("Extra Virgin Olive Oil Cold Pressed 500ml", "எக்ஸ்ட்ரா வெர்ஜின் ஆலிவ் எண்ணெய் (500 மி.லி)", "Oils & Fats", "Cooking Oils", "Olive Oil", "ml", "volume", "Pantry Shelf", 500.0, [250.0, 500.0, 1000.0], ["Borges Extra Virgin", "Figaro", "Disano"], ["extra virgin olive oil", "evoo olive oil"], False, True, "oil"),
    ("Pure Olive Pomace Oil for Indian Cooking 1L", "ஆலிவ் பொமாஸ் சமையல் எண்ணெய் (1 லிட்டர்)", "Oils & Fats", "Cooking Oils", "Olive Oil", "l", "volume", "Pantry Shelf", 1.0, [1.0, 5.0], ["Borges Pomace", "Figaro", "Disano"], ["olive pomace oil", "cooking olive oil"], False, True, "oil"),
    ("Physically Refined Rice Bran Oil 1L", "ரைஸ் பிரான் தவிட்டு எண்ணெய் (1 லிட்டர்)", "Oils & Fats", "Cooking Oils", "Rice Bran Oil", "l", "volume", "Pantry Shelf", 1.0, [1.0, 5.0], ["Fortune Rice Bran", "Saffola Gold", "Dhara"], ["rice bran oil", "thavittu ennai"], False, True, "oil"),
    ("Heart Care Blended Cooking Oil 1L", "ஹார்ட்கேர் பிளெண்டட் சமையல் எண்ணெய் (1 லிட்டர்)", "Oils & Fats", "Cooking Oils", "Blended Oil", "l", "volume", "Pantry Shelf", 1.0, [1.0, 5.0], ["Saffola Gold", "Saffola Total", "Fortune Vivo"], ["saffola gold oil", "blended cooking oil"], False, True, "oil"),
    ("Pure Canola Cooking Oil 1L", "கனோலா சமையல் எண்ணெய் (1 லிட்டர்)", "Oils & Fats", "Cooking Oils", "Canola Oil", "l", "volume", "Pantry Shelf", 1.0, [1.0], ["Hudson Canola", "Disano Canola", "Jivo"], ["canola oil"], False, True, "oil"),
    ("Refined Corn Oil for Cooking 1L", "சோள சமையல் எண்ணெய் (1 லிட்டர்)", "Oils & Fats", "Cooking Oils", "Corn Oil", "l", "volume", "Pantry Shelf", 1.0, [1.0, 5.0], ["Fortune Corn Oil", "Dhara Corn"], ["corn oil cooking", "makka ennai"], False, True, "oil"),
    ("Refined Soyabean Cooking Oil 1L", "சோயாபீன் சமையல் எண்ணெய் (1 லிட்டர்)", "Oils & Fats", "Cooking Oils", "Soyabean Oil", "l", "volume", "Pantry Shelf", 1.0, [1.0, 5.0], ["Fortune Soya Oil", "Dhara", "Mahakosh"], ["soyabean oil", "refined soya oil"], False, True, "oil"),

    # === TRADITIONAL THUVAIYAL PASTES & CHUTNEYS ===
    ("Traditional Curry Leaf Thuvaiyal Karuveppilai", "கருவேப்பிலை துவையல் பேஸ்ட்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Thuvaiyal", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Grand Sweets", "Local Artisans"], ["karuveppilai thuvaiyal", "curry leaf paste"], False, True, "condiment"),
    ("Traditional Pirandai Thuvaiyal Paste", "பிரண்டை துவையல் பேஸ்ட்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Thuvaiyal", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Grand Sweets", "B&B Organics"], ["pirandai thuvaiyal", "adamant creeper chutney"], False, True, "condiment"),
    ("Traditional Poondu Garlic Thuvaiyal Paste", "பூண்டு துவையல் பேஸ்ட்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Thuvaiyal", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Grand Sweets", "Priya"], ["poondu thuvaiyal", "garlic thuvaiyal"], False, True, "condiment"),
    ("Traditional Inji Ginger Thuvaiyal Paste", "இஞ்சி துவையல் பேஸ்ட்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Thuvaiyal", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Grand Sweets", "Priya"], ["inji thuvaiyal", "ginger thuvaiyal"], False, True, "condiment"),
    ("Traditional Kollu Horsegram Thuvaiyal Paste", "கொள்ளு துவையல் பேஸ்ட்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Thuvaiyal", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Grand Sweets", "Local Artisans"], ["kollu thuvaiyal", "horsegram chutney paste"], False, True, "condiment"),
    ("Traditional Mint Pudina Thuvaiyal Paste", "புதினா துவையல் பேஸ்ட்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Thuvaiyal", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Grand Sweets", "Aachi"], ["pudina thuvaiyal", "mint thuvaiyal"], False, True, "condiment"),
    ("Traditional Thakkali Tomato Thuvaiyal Paste", "தக்காளி துவையல் பேஸ்ட்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Thuvaiyal", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Grand Sweets", "Priya"], ["thakkali thuvaiyal", "tomato thuvaiyal"], False, True, "condiment"),
    ("Traditional Nellikkai Gooseberry Thuvaiyal Paste", "நெல்லிக்காய் துவையல் பேஸ்ட்", "Pickles, Sauces & Condiments", "Pickles & Sauces", "Thuvaiyal", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Grand Sweets", "Local Artisans"], ["nellikai thuvaiyal", "amla thuvaiyal"], False, True, "condiment"),

    # === DESSERT MIXES, CANNED FOODS & POOJA SPECIALTIES ===
    ("Instant Gulab Jamun Ready Mix Powder 200g", "குலாப் ஜாமுன் ரெடி மிக்ஸ் (200 கிராம்)", "Instant & Ready-to-Cook", "Dessert Mixes", "Dessert Mix", "g", "weight", "Pantry Shelf", 200.0, [200.0, 500.0], ["MTR Gulab Jamun Mix", "Gits", "Aachi"], ["gulab jamun mix", "jamun mix"], False, True, "packaged_food"),
    ("Instant Kulfi Falooda Dessert Mix 200g", "குல்ஃபி ஃபாலூடா மிக்ஸ் (200 கிராம்)", "Instant & Ready-to-Cook", "Dessert Mixes", "Dessert Mix", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Weikfield Falooda", "Gits Kulfi"], ["kulfi mix", "falooda mix"], False, True, "packaged_food"),
    ("Canned Sweet Pineapple Slices in Syrup 800g", "அன்னாசிப்பழ துண்டுகள் டின் (800 கிராம்)", "Food & Grocery", "Canned & Preserved", "Canned Fruit", "g", "weight", "Pantry Shelf", 800.0, [800.0], ["Del Monte Pineapple", "Golden Crown"], ["canned pineapple", "pineapple slices tin"], False, True, "packaged_food"),
    ("Canned Sliced Button Mushrooms 400g", "நறுக்கிய காளான் டின் (400 கிராம்)", "Food & Grocery", "Canned & Preserved", "Canned Vegetable", "g", "weight", "Pantry Shelf", 400.0, [400.0], ["Urban Platter", "Golden Crown", "Del Monte"], ["canned mushrooms", "sliced mushrooms tin"], False, True, "packaged_food"),
    ("Canned Baked Beans in Rich Tomato Sauce 400g", "பேக்டு பீன்ஸ் டின் (400 கிராம்)", "Food & Grocery", "Canned & Preserved", "Canned Beans", "g", "weight", "Pantry Shelf", 400.0, [400.0], ["Heinz Baked Beans", "Del Monte"], ["baked beans can", "heinz beans"], False, True, "packaged_food"),
    ("Pooja Red Sandalwood Rakta Chandanam Powder 50g", "இரத்த சந்தனப் பொடி (50 கிராம்)", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Chandanam", "g", "weight", "Pooja Shelf", 50.0, [50.0], ["Local Ayurvedic", "Gopuram"], ["rakta chandanam", "red sandalwood powder"], False, True, "pooja"),
    ("Pooja Holy Basil Tulsi Wood Japa Mala 108 Beads", "துளசி மணி மாலை (108 மணிகள்)", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Japa Mala", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Temple Stores", "Vrindavan Seva"], ["tulsi mala 108", "tulsi japa mala"], False, True, "pooja"),
    ("Pooja Sandalwood Japa Mala 108 Beads", "சந்தன மணி மாலை (108 மணிகள்)", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Japa Mala", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Cauvery", "Mysore Sandal"], ["sandalwood mala", "chandan japa mala"], False, True, "pooja"),
    ("Pooja Lotus Seed Kamal Gatta Mala 108 Beads", "தாமரை மணி மாலை (கமல்கட்டா, 108 மணிகள்)", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Japa Mala", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Temple Stores"], ["kamal gatta mala", "lotus seed mala"], False, True, "pooja"),
    ("Pooja Rudraksha Sacred Japa Mala 108 Beads", "ருத்ராட்ச மாலை (108 மணிகள்)", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Japa Mala", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Isha Life", "Temple Stores"], ["rudraksha mala", "rudraksha 108 beads"], False, True, "pooja"),
    ("Pooja Spatika Crystal Quartz Sphatik Mala 108 Beads", "ஸ்படிக மாலை (108 மணிகள்)", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Japa Mala", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Temple Stores", "Isha Life"], ["spatika mala", "sphatik crystal mala"], False, True, "pooja"),
    ("Pooja Pure Ghee Wicks Pack of 50 Wicks", "நெய் திரி விளக்கு (50 எண்ணிக்கை)", "Pooja & Spiritual Essentials", "Pooja Oils & Wicks", "Wicks", "piece", "package", "Pooja Shelf", 50.0, [50.0, 100.0], ["Cycle Ghee Wicks", "Pure Desi"], ["ghee wicks 50s", "ready ghee batti"], False, True, "pooja"),
    ("Pooja Loban Agarbatti Long Burning 50 Sticks", "லோபான் ஊதுபத்தி (50 எண்ணிக்கை)", "Pooja & Spiritual Essentials", "Camphor & Agarbatti", "Agarbatti", "piece", "package", "Pooja Shelf", 50.0, [50.0], ["Cycle Pure", "Mangaldeep"], ["loban agarbatti", "loban incense sticks"], False, True, "pooja"),
    ("Pooja Pure Kumkum Roli Vermillion Jar 100g", "பூஜை ரோலி குங்குமம் (100 கிராம்)", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Kumkum", "g", "weight", "Pooja Shelf", 100.0, [100.0], ["Cycle Roli", "Gopuram"], ["roli kumkum jar", "pooja roli vermillion"], False, True, "pooja"),
    ("Pooja Scented Chandan Tika Paste Tube 50g", "சந்தன திலகம் பேஸ்ட் (50 கிராம்)", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Chandanam", "g", "weight", "Pooja Shelf", 50.0, [50.0], ["Kasturi Chandan", "Cycle"], ["chandan tika tube", "sandalwood paste tube"], False, True, "pooja"),
    ("Pooja Sacred Holy Thread Yellow Mauli Roll", "மஞ்சள் காப்பு கயிறு ரோல்", "Pooja & Spiritual Essentials", "Pooja Dravyam", "Holy Thread", "roll", "piece", "Pooja Shelf", 1.0, [1.0], ["Temple Stores"], ["yellow mauli roll", "manjal kaapu kayiru"], False, True, "pooja"),
    ("Pooja Brass Single Diya Stand 6 Inch", "பித்தளை ஒற்றை விளக்கு (6 இன்ச்)", "Pooja & Spiritual Essentials", "Pooja Utensils", "Diya Stand", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Local Brass Artisans"], ["brass diya 6 inch", "kuthuvilakku single 6 inch"], False, True, "pooja"),
    ("Pooja Brass Single Diya Stand 8 Inch", "பித்தளை ஒற்றை விளக்கு (8 இன்ச்)", "Pooja & Spiritual Essentials", "Pooja Utensils", "Diya Stand", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Local Brass Artisans"], ["brass diya 8 inch", "kuthuvilakku single 8 inch"], False, True, "pooja"),
    ("Pooja Brass Panchamrit Offering Cup Set 5 Cups", "பித்தளை பஞ்சாமிர்த கிண்ணங்கள் (5 எண்ணிக்கை)", "Pooja & Spiritual Essentials", "Pooja Utensils", "Utensil Set", "piece", "package", "Pooja Shelf", 5.0, [5.0], ["Local Brass Artisans"], ["panchamrit cups brass", "pooja offering bowls"], False, True, "pooja"),
    ("Pooja Brass Handheld Camphor Aarti Deepam", "பித்தளை ஒற்றை கற்பூர தீபாராதனை தட்டு", "Pooja & Spiritual Essentials", "Pooja Utensils", "Aarti", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Local Brass Artisans"], ["brass single aarti deepam", "ek aarti brass"], False, True, "pooja"),
    ("Pooja Brass Ashtalakshmi Diya Oil Lamp", "அஷ்டலட்சுமி விளக்கு (பித்தளை)", "Pooja & Spiritual Essentials", "Pooja Utensils", "Diya", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Local Brass Artisans"], ["ashtalakshmi vilakku", "ashtalakshmi diya brass"], False, True, "pooja"),
    ("Pooja Brass Peacock Diya Single Wick Mayil Vilakku", "பித்தளை மயில் விளக்கு", "Pooja & Spiritual Essentials", "Pooja Utensils", "Diya", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Local Brass Artisans"], ["mayil vilakku", "peacock brass diya"], False, True, "pooja"),
    ("Pooja Brass Elephant Deepam Yanai Vilakku", "பித்தளை யானை விளக்கு", "Pooja & Spiritual Essentials", "Pooja Utensils", "Diya", "piece", "piece", "Pooja Shelf", 1.0, [1.0], ["Local Brass Artisans"], ["yanai vilakku", "elephant brass diya"], False, True, "pooja"),
]




def generate_part3_catalog_code():
    catalog = []
    seen_ids = set()

    for item in ITEMS_PART3:
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
Matrix Catalog Expansion Part 3: Contains {len(catalog)} culturally authentic,
normalized household products for Indian / Tamil Nadu households.
"""
import json

_DATA = r"""{json_str}"""

def get_matrix_catalog_part3():
    return json.loads(_DATA)

if __name__ == "__main__":
    items = get_matrix_catalog_part3()
    print(f"Loaded {{len(items)}} matrix expansion part 3 items.")
'''
    with open("scripts/expand_matrix_catalog_part3.py", "w", encoding="utf-8") as f:
        f.write(output_code)

    print(f"Generated scripts/expand_matrix_catalog_part3.py with {len(catalog)} items.")

if __name__ == "__main__":
    generate_part3_catalog_code()
