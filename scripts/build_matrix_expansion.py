# -*- coding: utf-8 -*-
"""
Builder for expand_matrix_catalog.py
Contains comprehensive, rich Indian household catalog expansion
covering grains, pulses, spices, podis, dairy, snacks, beverages,
pooja, household, personal care, baby care, and pet care.
"""
import json
import re

def slugify(text):
    text = text.lower().strip()
    text = re.sub(r'\(.*?\)', '', text).strip()
    text = re.sub(r'[^a-z0-9]+', '_', text).strip('_')
    return text

# We define items as tuples:
# (name, tamilName, category, subCategory, productType, defaultUnit, soldBy, storageLocation, minQty, customQuantities, brands, aliases, isLoose, isPackaged, iconKey)
ITEMS = [
    # === REGIONAL HEIRLOOM RICES & GRAINS ===
    ("Kichili Samba Rice", "கிச்சிலி சம்பா அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0, 25.0], ["Organic Farmers", "Gramiyum", "Bio Basics"], ["kichili samba", "kichili samba rice"], True, True, "rice"),
    ("Thanga Samba Rice", "தங்க சம்பா அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0], ["Bio Basics", "Organic Farmers"], ["thanga samba", "gold rice"], True, True, "rice"),
    ("Garudan Samba Rice", "கருடன் சம்பா அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0], ["B&B Organics", "Bio Basics"], ["garudan samba", "karudan samba"], True, True, "rice"),
    ("Kullakar Rice", "குள்ளக்கார் அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0], ["B&B Organics", "Natureland"], ["kullakar", "red kullakar"], True, True, "rice"),
    ("Poongar Rice", "பூங்கார் அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0], ["B&B Organics", "24 Mantra"], ["poongar", "women rice"], True, True, "rice"),
    ("Karungkuruvai Rice", "கருங்குறுவை அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0], ["Bio Basics", "Gramiyum"], ["karungkuruvai", "black kuruvai"], True, True, "rice"),
    ("Neelam Samba Rice", "நீலம் சம்பா அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0], ["Organic Farmers"], ["neelam samba"], True, True, "rice"),
    ("Kuzhivedichan Rice", "குழிவெடிச்சான் அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0], ["Bio Basics"], ["kuzhivedichan"], True, True, "rice"),
    ("Sornamasuri Handpound Rice", "கைக்குத்தல் சோனா மசூரி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0, 25.0], ["Organic Tattva", "24 Mantra"], ["handpound sona masoori", "kaikuthal arisi"], True, True, "rice"),
    ("Vaigunda Samba Rice", "வைகுண்ட சம்பா அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0], ["Bio Basics"], ["vaigunda samba"], True, True, "rice"),
    ("Illuppai Poo Samba Rice", "இலுப்பைப்பூ சம்பா அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0], ["Gramiyum", "Bio Basics"], ["illuppai poo samba"], True, True, "rice"),
    ("Salem Sanna Rice", "சேலம் சன்னா அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0], ["Local Mills", "Udhayam"], ["salem sanna"], True, True, "rice"),
    ("Athur Kichili Samba Rice", "ஆத்தூர் கிச்சிலி சம்பா", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0], ["Bio Basics"], ["athur kichili"], True, True, "rice"),
    ("Sigappu Kavuni Rice", "சிவப்பு கவுனி அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0], ["B&B Organics"], ["sigappu kavuni", "red kavuni"], True, True, "rice"),
    ("Navara Ayurvedic Rice", "ஞவரா அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 2.0, 5.0], ["Arya Vaidya Sala", "Kerala Ayurveda"], ["navara rice", "njavara arisi"], True, True, "rice"),
    ("Basmati Broken Mogra Rice", "பாஸ்மதி மோக்ரா அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0], ["India Gate", "Daawat", "Fortune"], ["mogra rice", "broken basmati"], True, True, "rice"),
    ("Basmati Tibar Rice", "பாஸ்மதி திபார் அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0], ["Daawat", "India Gate"], ["tibar basmati"], True, True, "rice"),
    ("Basmati Dubar Rice", "பாஸ்மதி துபார் அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0], ["India Gate", "Daawat"], ["dubar basmati"], True, True, "rice"),
    ("Super Basmati Extra Long Rice", "சூப்பர் பாஸ்மதி நீள அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0], ["Daawat", "India Gate", "Lal Qilla"], ["super basmati", "extra long rice"], True, True, "rice"),
    ("Brown Basmati Rice", "பழுப்பு பாஸ்மதி அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0], ["India Gate", "Daawat", "24 Mantra"], ["brown basmati"], True, True, "rice"),
    ("Jeerakasala Kaima Rice", "சீரகசாலா கைமா அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0], ["Double Horse", "Nirapara"], ["jeerakasala", "kaima rice", "thalassery biryani rice"], True, True, "rice"),
    ("Gobindobhog Rice", "கோபிந்தோபோக் அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 2.0, 5.0], ["Fortune", "Organic Tattva"], ["gobindobhog", "payesh rice"], True, True, "rice"),
    ("Wada Kolam Rice", "வாடா கோலம் அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0, 25.0], ["Fortune", "Royal"], ["wada kolam", "kolam rice"], True, True, "rice"),
    ("Ambemohar Rice", "ஆம்பேமோஹர் அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0], ["Organic Tattva"], ["ambemohar"], True, True, "rice"),
    ("Red Raw Rice", "சிவப்பு பச்சரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0], ["24 Mantra", "Double Horse"], ["red raw rice", "kerala pachari"], True, True, "rice"),
    ("Red Boiled Rice", "சிவப்பு புழுங்கல் அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0, 10.0, 25.0], ["Double Horse", "Pavizham", "Nirapara"], ["red boiled rice", "palakkad matta"], True, True, "rice"),
    ("Kerala Matta Broken Rice", "மட்டா நொய் அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0], ["Double Horse", "Brahmins"], ["matta broken", "matta kurunai"], True, True, "rice"),
    ("Raw Rice Kurunai Broken", "பச்சரிசி குறுணை", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0], ["Local Mills", "Udhayam"], ["pachari kurunai", "arisi noiyyi"], True, True, "rice"),
    ("Boiled Rice Kurunai Broken", "புழுங்கல் அரிசி குறுணை", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 5.0], ["Local Mills", "Udhayam"], ["puzhungal kurunai"], True, True, "rice"),
    ("Bamboo Rice / Moongil Arisi", "மூங்கில் அரிசி", "Food & Grocery", "Rice & Grains", "Rice", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["B&B Organics", "Natureland"], ["bamboo rice", "moongil arisi"], True, True, "rice"),

    # === MILLET AVAL, PORI & FLAKES ===
    ("Kambu Aval Bajra Flakes", "கம்பு அவல்", "Food & Grocery", "Flours & Grains", "Millet Flakes", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Gramiyum", "B&B Organics"], ["kambu aval", "pearl millet flakes"], True, True, "grains"),
    ("Cholam Aval Jowar Flakes", "சோளம் அவல்", "Food & Grocery", "Flours & Grains", "Millet Flakes", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Gramiyum", "24 Mantra"], ["cholam aval", "jowar flakes"], True, True, "grains"),
    ("Kuthiraivali Aval Barnyard Flakes", "குதிரைவாலி அவல்", "Food & Grocery", "Flours & Grains", "Millet Flakes", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["B&B Organics", "Gramiyum"], ["kuthiraivali aval"], True, True, "grains"),
    ("Thinai Aval Foxtail Flakes", "தினை அவல்", "Food & Grocery", "Flours & Grains", "Millet Flakes", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["B&B Organics", "Natureland"], ["thinai aval", "foxtail flakes"], True, True, "grains"),
    ("Varagu Aval Kodo Flakes", "வரகு அவல்", "Food & Grocery", "Flours & Grains", "Millet Flakes", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["B&B Organics", "Gramiyum"], ["varagu aval"], True, True, "grains"),
    ("Samai Aval Little Millet Flakes", "சாமை அவல்", "Food & Grocery", "Flours & Grains", "Millet Flakes", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["B&B Organics", "Gramiyum"], ["samai aval"], True, True, "grains"),
    ("Ragi Pori Puffed Finger Millet", "கேழ்வரகு பொரி", "Food & Grocery", "Flours & Grains", "Puffed Grains", "g", "weight", "Pantry Shelf", 200.0, [200.0, 500.0], ["Gramiyum", "Local Artisans"], ["ragi pori", "kezhvaragu pori"], True, True, "grains"),
    ("Cholam Pori Puffed Jowar", "சோளப் பொரி", "Food & Grocery", "Flours & Grains", "Puffed Grains", "g", "weight", "Pantry Shelf", 200.0, [200.0, 500.0], ["Gramiyum", "Local Artisans"], ["cholam pori", "jowar dhani"], True, True, "grains"),
    ("Kambu Pori Puffed Bajra", "கம்புப் பொரி", "Food & Grocery", "Flours & Grains", "Puffed Grains", "g", "weight", "Pantry Shelf", 200.0, [200.0, 500.0], ["Gramiyum", "Local Artisans"], ["kambu pori"], True, True, "grains"),
    ("Nel Pori Arisi Malar Puffed Paddy", "நெல் பொரி / நெல் மலர்", "Food & Grocery", "Flours & Grains", "Puffed Grains", "g", "weight", "Pantry Shelf", 200.0, [200.0, 500.0], ["Local Mills", "Pooja Stores"], ["nel pori", "arisi malar", "karthigai pori"], True, True, "grains"),

    # === DALS, LEGUMES, SUNDAL & PULSES ===
    ("Dried Green Peas Sukha Vatana", "பச்சை பட்டாணி (உலர்ந்தது)", "Food & Grocery", "Dals & Pulses", "Legumes", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0, 2.0], ["Tata Sampann", "BB Royal"], ["dried green peas", "pachai pattani dry"], True, True, "dal"),
    ("Dried White Peas Safed Vatana", "வெள்ளை பட்டாணி (உலர்ந்தது)", "Food & Grocery", "Dals & Pulses", "Legumes", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0, 2.0], ["Tata Sampann", "BB Royal"], ["white peas", "safed vatana", "vellai pattani"], True, True, "dal"),
    ("Nattu Kala Chana Brown Chickpeas", "நாட்டு கருப்பு கொண்டைக்கடலை", "Food & Grocery", "Dals & Pulses", "Chickpeas", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0, 2.0], ["Tata Sampann", "Fortune", "Udhayam"], ["nattu konda kadalai", "desi chana", "kala chana"], True, True, "dal"),
    ("Green Chickpeas Hara Chana Dry", "பச்சை கொண்டைக்கடலை", "Food & Grocery", "Dals & Pulses", "Chickpeas", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Tata Sampann", "BB Royal"], ["green chickpeas", "hara chana"], True, True, "dal"),
    ("Fresh Mochai Field Beans", "பச்சை மொச்சை", "Fresh Vegetables", "Beans & Pods", "Fresh Legume", "kg", "weight", "Refrigerator", 0.5, [0.5, 1.0], ["Local Farmers"], ["pachai mochai", "fresh avarekalu"], True, False, "fresh_produce"),
    ("Dried White Mochai Field Beans", "வெள்ளை மொச்சை (உலர்ந்தது)", "Food & Grocery", "Dals & Pulses", "Legumes", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["BB Royal", "Udhayam"], ["vellai mochai", "dry mochai"], True, True, "dal"),
    ("Dried Black Mochai Beans", "கருப்பு மொச்சை", "Food & Grocery", "Dals & Pulses", "Legumes", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Local Farmers", "BB Royal"], ["karuppu mochai", "black field beans"], True, True, "dal"),
    ("Split Mochai Dal Val Dal", "மொச்சைப் பருப்பு", "Food & Grocery", "Dals & Pulses", "Dals", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Udhayam", "BB Royal"], ["mochai paruppu", "val dal"], True, True, "dal"),
    ("Whole Horsegram Kollu Kulthi", "கொள்ளு", "Food & Grocery", "Dals & Pulses", "Pulses", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0, 2.0], ["Udhayam", "Tata Sampann", "24 Mantra"], ["kollu", "horsegram", "kulthi dal"], True, True, "dal"),
    ("Roasted Horsegram Dal", "வறுத்த கொள்ளுப் பருப்பு", "Food & Grocery", "Dals & Pulses", "Pulses", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Gramiyum", "Local Artisans"], ["roasted kollu", "varutha kollu"], True, True, "dal"),
    ("Red Cowpeas Sigappu Karamani", "சிவப்பு காராமணி", "Food & Grocery", "Dals & Pulses", "Pulses", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Tata Sampann", "Udhayam"], ["sigappu karamani", "red lobia"], True, True, "dal"),
    ("White Cowpeas Vellai Karamani", "வெள்ளை காராமணி", "Food & Grocery", "Dals & Pulses", "Pulses", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Tata Sampann", "Udhayam"], ["vellai karamani", "white lobia"], True, True, "dal"),
    ("Black Eye Cowpeas Karamani", "கருப்புக்கண் காராமணி", "Food & Grocery", "Dals & Pulses", "Pulses", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0, 2.0], ["Tata Sampann", "Fortune"], ["black eyed peas", "lobia", "karamani payaru"], True, True, "dal"),
    ("Whole Green Moong Sabut", "முழு பச்சை பயறு", "Food & Grocery", "Dals & Pulses", "Dals", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0, 2.0], ["Tata Sampann", "Fortune", "Udhayam"], ["sabut moong", "pachai payaru"], True, True, "dal"),
    ("Sprouted Green Gram Pachai Payaru", "முளைகட்டிய பச்சை பயறு", "Fresh Vegetables", "Sprouts", "Sprouts", "g", "weight", "Refrigerator", 200.0, [200.0, 400.0], ["Local Fresh", "Organic"], ["moong sprouts", "mulaikattiya payaru"], False, True, "fresh_produce"),
    ("Sprouted Horsegram Kollu", "முளைகட்டிய கொள்ளு", "Fresh Vegetables", "Sprouts", "Sprouts", "g", "weight", "Refrigerator", 200.0, [200.0, 400.0], ["Local Fresh"], ["kollu sprouts"], False, True, "fresh_produce"),
    ("Sprouted Kala Chana Desi", "முளைகட்டிய கொண்டைக்கடலை", "Fresh Vegetables", "Sprouts", "Sprouts", "g", "weight", "Refrigerator", 200.0, [200.0, 400.0], ["Local Fresh"], ["chana sprouts", "sprouted kala chana"], False, True, "fresh_produce"),
    ("Split Green Moong Chilka", "உடைத்த பச்சை பயறு (தோலுடன்)", "Food & Grocery", "Dals & Pulses", "Dals", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Tata Sampann", "Fortune"], ["chilka moong", "split green gram with skin"], True, True, "dal"),
    ("Split Black Urad Chilka", "உடைத்த கருப்பு உளுந்து (தோலுடன்)", "Food & Grocery", "Dals & Pulses", "Dals", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Tata Sampann", "Udhayam"], ["chilka urad", "split black gram with skin"], True, True, "dal"),
    ("Whole Black Urad Sabut", "முழு கருப்பு உளுந்து", "Food & Grocery", "Dals & Pulses", "Dals", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0, 2.0], ["Tata Sampann", "Udhayam"], ["sabut urad", "karuppu ulundhu muzhu"], True, True, "dal"),
    ("Moth Beans Matki Nari Payaru", "நரிப்பயறு / மட்கி", "Food & Grocery", "Dals & Pulses", "Pulses", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Tata Sampann", "BB Royal"], ["moth beans", "matki", "nari payaru"], True, True, "dal"),
    ("Whole Soyabeans", "முழு சோயாபீன்ஸ்", "Food & Grocery", "Dals & Pulses", "Pulses", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Tata Sampann", "Nutrela"], ["soyabeans", "soya beans whole"], True, True, "dal"),
    ("Rajma Chitra Speckled Kidney Beans", "சித்ரா ராஜ்மா", "Food & Grocery", "Dals & Pulses", "Beans", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Tata Sampann", "Fortune"], ["rajma chitra", "spotted rajma"], True, True, "dal"),
    ("Rajma Kashmiri Red Kidney Beans", "காஷ்மீரி சிவப்பு ராஜ்மா", "Food & Grocery", "Dals & Pulses", "Beans", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Tata Sampann", "Fortune"], ["kashmiri rajma", "red kidney beans"], True, True, "dal"),
    ("Rajma Black Kidney Beans", "கருப்பு ராஜ்மா", "Food & Grocery", "Dals & Pulses", "Beans", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["BB Royal", "Organic Tattva"], ["black rajma", "black kidney beans"], True, True, "dal"),
    ("Masoor Malka Split Red Lentils", "மைசூர் பருப்பு", "Food & Grocery", "Dals & Pulses", "Dals", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0, 2.0], ["Tata Sampann", "Fortune", "Udhayam"], ["masoor malka", "red lentils", "mysore paruppu"], True, True, "dal"),
    ("Whole Masoor Brown Lentils Sabut", "முழு மைசூர் பருப்பு", "Food & Grocery", "Dals & Pulses", "Dals", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Tata Sampann", "Fortune"], ["sabut masoor", "whole brown masoor"], True, True, "dal"),
    ("Roasted Fried Gram Pottukadalai", "பொட்டுக்கடலை", "Food & Grocery", "Dals & Pulses", "Dals", "kg", "weight", "Pantry Shelf", 0.5, [0.25, 0.5, 1.0], ["Udhayam", "BB Royal"], ["pottukadalai", "chutney dal", "roasted gram"], True, True, "dal"),
    ("Raw Groundnuts Peanuts Shelled", "பச்சை வேர்க்கடலை (உடைத்தது)", "Food & Grocery", "Dals & Pulses", "Nuts", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0, 2.0], ["Tata Sampann", "Udhayam", "Fortune"], ["raw groundnuts", "pachai verkadalai", "singdana"], True, True, "dal"),
    ("Groundnuts In Shell Pods", "வேர்க்கடலை (தோலுடன்)", "Food & Grocery", "Dals & Pulses", "Nuts", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 2.0], ["Local Farmers"], ["groundnuts with shell", "shell verkadalai"], True, True, "dal"),
    ("Double Beans Lima Beans Dried", "டபுள் பீன்ஸ்", "Food & Grocery", "Dals & Pulses", "Beans", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["BB Royal", "Tata Sampann"], ["double beans", "lima beans"], True, True, "dal"),
    ("Soya Chunks Regular Size", "சோயா மீல் மேக்கர்", "Food & Grocery", "Dals & Pulses", "Soya", "g", "weight", "Pantry Shelf", 200.0, [200.0, 1000.0], ["Nutrela", "Fortune"], ["soya chunks", "meal maker", "bari"], False, True, "packaged_food"),
    ("Mini Soya Chunks", "மினி சோயா துண்டுகள்", "Food & Grocery", "Dals & Pulses", "Soya", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Nutrela", "Fortune"], ["mini soya chunks", "chota meal maker"], False, True, "packaged_food"),
    ("Soya Granules Keema", "சோயா கீமா கிரானியூல்ஸ்", "Food & Grocery", "Dals & Pulses", "Soya", "g", "weight", "Pantry Shelf", 200.0, [200.0], ["Nutrela"], ["soya granules", "soya keema"], False, True, "packaged_food"),
    ("Barley Grains Varchu Arisi", "பார்லி அரிசி", "Food & Grocery", "Rice & Grains", "Grains", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["24 Mantra", "BB Royal"], ["barley grains", "varchu arisi"], True, True, "grains"),
    ("Rolled Oats Whole Grain", "ரோல்டு ஓட்ஸ்", "Food & Grocery", "Flours & Grains", "Oats", "kg", "weight", "Pantry Shelf", 1.0, [0.5, 1.0], ["Quaker", "Kellogg's", "Saffola"], ["rolled oats", "whole grain oats"], False, True, "grains"),
    ("Instant Oats Quick Cooking", "இன்ஸ்டன்ட் ஓட்ஸ்", "Food & Grocery", "Flours & Grains", "Oats", "kg", "weight", "Pantry Shelf", 1.0, [0.5, 1.0, 2.0], ["Quaker", "Saffola", "Kellogg's"], ["instant oats", "quick oats"], False, True, "grains"),
    ("Steel Cut Oats", "ஸ்டீல் கட் ஓட்ஸ்", "Food & Grocery", "Flours & Grains", "Oats", "g", "weight", "Pantry Shelf", 500.0, [500.0], ["True Elements", "Urban Platter"], ["steel cut oats"], False, True, "grains"),
    ("Raw Chia Seeds Black", "சியா விதைகள்", "Dry Fruits, Nuts & Seeds", "Seeds", "Seeds", "g", "weight", "Pantry Shelf", 250.0, [100.0, 250.0], ["True Elements", "Neuherbs"], ["chia seeds", "black chia"], False, True, "grains"),
    ("Raw Flax Seeds Alividhai", "ஆளி விதைகள்", "Dry Fruits, Nuts & Seeds", "Seeds", "Seeds", "g", "weight", "Pantry Shelf", 250.0, [250.0, 500.0], ["True Elements", "24 Mantra"], ["flax seeds", "ali vidhai", "alsi"], False, True, "grains"),
    ("Raw Pumpkin Seeds Kaddu Beej", "பூசணி விதைகள்", "Dry Fruits, Nuts & Seeds", "Seeds", "Seeds", "g", "weight", "Pantry Shelf", 250.0, [100.0, 250.0], ["True Elements", "BB Royal"], ["pumpkin seeds", "poosani vidhai"], False, True, "grains"),
    ("Raw Sunflower Seeds", "சூரியகாந்தி விதைகள்", "Dry Fruits, Nuts & Seeds", "Seeds", "Seeds", "g", "weight", "Pantry Shelf", 250.0, [100.0, 250.0], ["True Elements", "BB Royal"], ["sunflower seeds"], False, True, "grains"),
    ("Watermelon Seeds Magaz", "தர்பூசணி பருப்பு (மகாஸ்)", "Dry Fruits, Nuts & Seeds", "Seeds", "Seeds", "g", "weight", "Pantry Shelf", 100.0, [100.0, 250.0], ["Catch", "BB Royal"], ["magaz", "watermelon kernels"], False, True, "grains"),
    ("Sabja Basil Seeds Tukmaria", "சப்ஜா விதைகள்", "Dry Fruits, Nuts & Seeds", "Seeds", "Seeds", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Urban Platter", "BB Royal"], ["sabja seeds", "basil seeds", "tukmaria"], False, True, "grains"),
    ("Phool Makhana Fox Nuts", "தாமரை விதை / மகானா", "Dry Fruits, Nuts & Seeds", "Dry Fruits & Nuts", "Makhana", "g", "weight", "Pantry Shelf", 100.0, [100.0, 250.0, 500.0], ["BB Royal", "Urban Platter"], ["phool makhana", "fox nuts", "lotus seeds"], False, True, "snacks"),
    ("Nylon Javvarisi Small Sago", "நைலான் ஜவ்வரிசி (சிறியது)", "Food & Grocery", "Flours & Grains", "Sago", "g", "weight", "Pantry Shelf", 500.0, [250.0, 500.0], ["Salem Sago", "BB Royal"], ["nylon javvarisi", "small sago pearls", "chota sabudana"], True, True, "grains"),
    ("Maavu Javvarisi Big Sabudana", "மாவு ஜவ்வரிசி (பெரியது)", "Food & Grocery", "Flours & Grains", "Sago", "g", "weight", "Pantry Shelf", 500.0, [250.0, 500.0], ["Salem Sago", "BB Royal"], ["maavu javvarisi", "bada sabudana", "tapioca pearls"], True, True, "grains"),

    # === FLOURS, RAVAS & READY MIXES ===
    ("Samba Broken Wheat Rava Dalia", "சம்பா கோதுமை ரவை", "Food & Grocery", "Flours & Grains", "Rava", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0, 2.0], ["Naga", "Anil", "Udhayam"], ["samba godhumai ravai", "broken wheat", "dalia"], True, True, "grains"),
    ("Fine Bansi Sooji Rava", "ஃபைன் பன்சி ரவை", "Food & Grocery", "Flours & Grains", "Rava", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Naga", "Anil"], ["bansi rava", "fine sooji"], True, True, "grains"),
    ("Coarse Bombay Rava Sooji", "பம்பாய் ரவை", "Food & Grocery", "Flours & Grains", "Rava", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0, 2.0], ["Naga", "Aashirvaad", "Fortune"], ["bombay rava", "coarse rava", "upma rava"], True, True, "grains"),
    ("Chiroti Rava Fine Semolina", "சிரோட்டி ரவை", "Food & Grocery", "Flours & Grains", "Rava", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Naga", "Anil"], ["chiroti rava", "fine semolina"], True, True, "grains"),
    ("Roasted Semolina Rava Bhuna Sooji", "வறுத்த ரவை", "Food & Grocery", "Flours & Grains", "Rava", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["MTR", "Aashirvaad"], ["roasted rava", "roasted sooji", "varutha ravai"], False, True, "grains"),
    ("Rice Rava Idli Rava", "இட்லி ரவை / அரிசி ரவை", "Food & Grocery", "Flours & Grains", "Rava", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 2.0, 5.0], ["Naga", "Udhayam", "Priya"], ["idli rava", "rice rava", "arisi ravai"], True, True, "grains"),
    ("Ragi Flour Kezhvaragu Maavu", "கேழ்வரகு மாவு", "Food & Grocery", "Flours & Grains", "Atta & Flour", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0, 2.0], ["Naga", "Anil", "Aashirvaad"], ["ragi flour", "finger millet flour", "kezhvaragu maavu"], True, True, "grains"),
    ("Kambu Flour Bajra Atta", "கம்பு மாவு", "Food & Grocery", "Flours & Grains", "Atta & Flour", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Naga", "Gramiyum", "Organic Tattva"], ["kambu maavu", "bajra flour"], True, True, "grains"),
    ("Jowar Flour Cholam Maavu", "சோள மாவு", "Food & Grocery", "Flours & Grains", "Atta & Flour", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Gramiyum", "Organic Tattva"], ["cholam maavu", "jowar flour"], True, True, "grains"),
    ("Thinai Flour Foxtail Millet Flour", "தினை மாவு", "Food & Grocery", "Flours & Grains", "Atta & Flour", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["B&B Organics", "Gramiyum"], ["thinai maavu", "foxtail flour"], True, True, "grains"),
    ("Varagu Flour Kodo Millet Flour", "வரகு மாவு", "Food & Grocery", "Flours & Grains", "Atta & Flour", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["B&B Organics", "Gramiyum"], ["varagu maavu", "kodo flour"], True, True, "grains"),
    ("Samai Flour Little Millet Flour", "சாமை மாவு", "Food & Grocery", "Flours & Grains", "Atta & Flour", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["B&B Organics", "Gramiyum"], ["samai maavu", "little millet flour"], True, True, "grains"),
    ("Kuthiraivali Flour Barnyard Flour", "குதிரைவாலி மாவு", "Food & Grocery", "Flours & Grains", "Atta & Flour", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["B&B Organics", "Gramiyum"], ["kuthiraivali maavu", "barnyard flour"], True, True, "grains"),
    ("Roasted Idiyappam Flour Rice", "இடியாப்ப மாவு", "Food & Grocery", "Flours & Grains", "Atta & Flour", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Anil", "Double Horse", "Nirapara"], ["idiyappam flour", "sevai maavu"], False, True, "grains"),
    ("Pathiri Podi White Rice Flour", "பத்திரி பொடி", "Food & Grocery", "Flours & Grains", "Atta & Flour", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Double Horse", "Eastern", "Nirapara"], ["pathiri podi", "kerala pathiri flour"], False, True, "grains"),
    ("Puttu Podi Steamed Rice Powder", "புட்டு மாவு", "Food & Grocery", "Flours & Grains", "Atta & Flour", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Anil", "Double Horse", "Eastern"], ["puttu podi", "arisi puttu maavu"], False, True, "grains"),
    ("Ragi Puttu Podi", "கேழ்வரகு புட்டு மாவு", "Food & Grocery", "Flours & Grains", "Atta & Flour", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Anil", "Double Horse", "Brahmins"], ["ragi puttu podi", "kezhvaragu puttu maavu"], False, True, "grains"),
    ("Wheat Puttu Podi", "கோதுமை புட்டு மாவு", "Food & Grocery", "Flours & Grains", "Atta & Flour", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Double Horse", "Eastern"], ["wheat puttu podi", "godhumai puttu"], False, True, "grains"),
    ("Kozhukattai Maavu Modak Flour", "கொழுக்கட்டை மாவு", "Food & Grocery", "Flours & Grains", "Atta & Flour", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Anil", "Udhayam"], ["kozhukattai maavu", "modak flour"], False, True, "grains"),
    ("Adai Flour Mix Multi Lentil", "அடை மாவு மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["MTR", "Aachi", "Grand Sweets"], ["adai mix", "adai maavu"], False, True, "packaged_food"),
    ("Pesarattu Green Moong Dosa Mix", "பெசரட்டு மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "g", "weight", "Pantry Shelf", 500.0, [200.0, 500.0], ["MTR", "Priya"], ["pesarattu mix", "moong dal dosa mix"], False, True, "packaged_food"),
    ("Bajji Bonda Flour Mix", "பஜ்ஜி போண்டா மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "g", "weight", "Pantry Shelf", 500.0, [200.0, 500.0], ["Aachi", "Sakthi", "MTR"], ["bajji bonda mix", "pakoda mix"], False, True, "packaged_food"),
    ("Murukku Flour Mix", "முறுக்கு மாவு மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "g", "weight", "Pantry Shelf", 500.0, [500.0, 1000.0], ["Anil", "Aachi", "Grand Sweets"], ["murukku mix", "murukku flour"], False, True, "packaged_food"),
    ("Seedai Flour Mix", "சீடை மாவு மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "g", "weight", "Pantry Shelf", 500.0, [500.0], ["Anil", "Grand Sweets"], ["seedai mix", "seedai maavu"], False, True, "packaged_food"),
    ("Thattai Flour Mix", "தட்டை மாவு மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "g", "weight", "Pantry Shelf", 500.0, [500.0], ["Anil", "Grand Sweets"], ["thattai mix", "thattai flour"], False, True, "packaged_food"),
    ("Appam Batter Mix Vellayappam", "ஆப்ப மாவு மிக்ஸ்", "Instant & Ready-to-Cook", "Breakfast & Mixes", "Instant Mix", "kg", "weight", "Pantry Shelf", 0.5, [0.5, 1.0], ["Double Horse", "Eastern", "Nirapara"], ["appam mix", "vellayappam podi"], False, True, "packaged_food"),
    ("Fresh Idli Dosa Batter Pouch", "இட்லி தோசை மாவு", "Dairy & Refrigerated", "Batters & Fresh", "Fresh Batter", "kg", "weight", "Refrigerator", 1.0, [1.0], ["iD Fresh", "MTR", "Asal"], ["idli dosa batter", "ready batter", "id batter"], False, True, "dairy"),
    ("Ragi Idli Dosa Batter Pouch", "கேழ்வரகு இட்லி தோசை மாவு", "Dairy & Refrigerated", "Batters & Fresh", "Fresh Batter", "kg", "weight", "Refrigerator", 1.0, [1.0], ["iD Fresh", "Asal"], ["ragi batter", "ragi idli batter"], False, True, "dairy"),
    ("Multi Millet Dosa Batter Pouch", "சிறுதானிய தோசை மாவு", "Dairy & Refrigerated", "Batters & Fresh", "Fresh Batter", "kg", "weight", "Refrigerator", 1.0, [1.0], ["iD Fresh", "Millet Magic"], ["millet batter", "sirudhaniyam batter"], False, True, "dairy"),
    ("Corn Starch Cornflour White", "சோள மாவு கார்ன்பிளவர்", "Food & Grocery", "Flours & Grains", "Starch", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0, 500.0], ["Weikfield", "Brown & Polson"], ["corn flour", "cornstarch"], False, True, "grains"),
    ("Custard Powder Vanilla Flavor", "கஸ்டர்ட் பவுடர் (வெனிலா)", "Food & Grocery", "Baking Ingredients", "Dessert Mix", "g", "weight", "Pantry Shelf", 100.0, [100.0, 500.0], ["Weikfield", "Brown & Polson"], ["custard powder", "vanilla custard"], False, True, "packaged_food"),
    ("Baking Powder Double Action", "பேக்கிங் பவுடர்", "Food & Grocery", "Baking Ingredients", "Baking Agent", "g", "weight", "Pantry Shelf", 100.0, [100.0], ["Weikfield", "Puratos"], ["baking powder"], False, True, "packaged_food"),
    ("Baking Soda Sodium Bicarbonate", "சமையல் சோடா", "Food & Grocery", "Baking Ingredients", "Baking Agent", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Tata Salt", "Weikfield"], ["baking soda", "meetha soda", "samayal soda"], False, True, "packaged_food"),
    ("Active Dry Yeast Granules", "உலர் ஈஸ்ட்", "Food & Grocery", "Baking Ingredients", "Baking Agent", "g", "weight", "Pantry Shelf", 50.0, [50.0, 100.0], ["Urban Platter", "Puratos"], ["dry yeast", "active yeast"], False, True, "packaged_food"),

    # === SPICE POWDERS, PODIS & MASALAS ===
    ("Idli Milagai Podi Gunpowder", "இட்லி மிளகாய் பொடி", "Spices & Seasonings", "Traditional Podis", "Spice Blend", "g", "weight", "Pantry Shelf", 200.0, [100.0, 200.0, 500.0], ["MTR", "Aachi", "Grand Sweets", "Sakthi"], ["idli podi", "gunpowder"], False, True, "masala"),
    ("Kollu Idli Podi Horsegram", "கொள்ளு இட்லி பொடி", "Spices & Seasonings", "Traditional Podis", "Spice Blend", "g", "weight", "Pantry Shelf", 200.0, [100.0, 200.0], ["Grand Sweets", "Aachi"], ["kollu idli podi", "horsegram podi"], False, True, "masala"),
    ("Curry Leaves Idli Podi Karuveppilai", "கருவேப்பிலை இட்லி பொடி", "Spices & Seasonings", "Traditional Podis", "Spice Blend", "g", "weight", "Pantry Shelf", 200.0, [100.0, 200.0], ["Grand Sweets", "Aachi"], ["karuveppilai podi", "curry leaf podi"], False, True, "masala"),
    ("Garlic Idli Podi Poondu", "பூண்டு இட்லி பொடி", "Spices & Seasonings", "Traditional Podis", "Spice Blend", "g", "weight", "Pantry Shelf", 200.0, [100.0, 200.0], ["Grand Sweets", "Aachi"], ["poondu idli podi", "garlic podi"], False, True, "masala"),
    ("Flaxseed Idli Podi Alividhai", "ஆளி விதை இட்லி பொடி", "Spices & Seasonings", "Traditional Podis", "Spice Blend", "g", "weight", "Pantry Shelf", 200.0, [100.0, 200.0], ["Organic Farmers", "Grand Sweets"], ["flaxseed podi", "ali vidhai idli podi"], False, True, "masala"),
    ("Murungai Keerai Podi Drumstick Leaf", "முருங்கைக்கீரை சாதப் பொடி", "Spices & Seasonings", "Traditional Podis", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["B&B Organics", "Grand Sweets"], ["moringa podi", "murungai keerai podi"], False, True, "masala"),
    ("Pirandai Rice Podi Cissus", "பிரண்டை சாதப் பொடி", "Spices & Seasonings", "Traditional Podis", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["B&B Organics", "Bio Basics"], ["pirandai podi"], False, True, "masala"),
    ("Angaya Podi Digestive Health", "அங்காயப் பொடி", "Spices & Seasonings", "Traditional Podis", "Digestive Spice", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Grand Sweets", "Ambika Appalam"], ["angaya podi", "postpartum powder"], False, True, "masala"),
    ("Paruppu Podi Roasted Dal Rice Powder", "பருப்பு பொடி", "Spices & Seasonings", "Traditional Podis", "Spice Blend", "g", "weight", "Pantry Shelf", 200.0, [100.0, 200.0, 500.0], ["Grand Sweets", "MTR", "Aachi", "Ambika"], ["paruppu podi", "kandi podi", "dal podi"], False, True, "masala"),
    ("Kothamalli Rice Podi Coriander", "கொத்தமல்லி சாதப் பொடி", "Spices & Seasonings", "Traditional Podis", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Grand Sweets", "Aachi"], ["kothamalli podi", "coriander rice powder"], False, True, "masala"),
    ("Pudina Rice Podi Mint", "புதினா சாதப் பொடி", "Spices & Seasonings", "Traditional Podis", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Grand Sweets", "Aachi"], ["pudina podi", "mint rice podi"], False, True, "masala"),
    ("Ellu Sadham Podi Sesame Rice Powder", "எள்ளு சாதப் பொடி", "Spices & Seasonings", "Traditional Podis", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Grand Sweets", "Ambika"], ["ellu podi", "sesame rice powder"], False, True, "masala"),
    ("Bisibelebath Powder Spice Blend", "பிசிபேளேபாத் பொடி", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["MTR", "Aachi", "Eastern"], ["bisibelebath powder"], False, True, "masala"),
    ("Vangi Bath Powder Brinjal Rice Spice", "வாங்கி பாத் பொடி", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["MTR", "Aachi"], ["vangi bath powder"], False, True, "masala"),
    ("Traditional Rasam Powder", "பாரம்பரிய ரசப் பொடி", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0, 500.0], ["MTR", "Aachi", "Sakthi", "Eastern"], ["rasam powder", "rasapodi"], False, True, "masala"),
    ("Mysore Rasam Powder Spice Blend", "மைசூர் ரசப் பொடி", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["MTR", "Grand Sweets"], ["mysore rasam powder"], False, True, "masala"),
    ("Madras Sambar Powder", "மெட்ராஸ் சாம்பார் பொடி", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 200.0, [100.0, 200.0, 500.0], ["Aachi", "Sakthi", "MTR", "Tata Sampann"], ["madras sambar powder", "sambar podi"], False, True, "masala"),
    ("Arachuvitta Sambar Powder", "அரைத்துவிட்ட சாம்பார் பொடி", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Grand Sweets", "MTR"], ["arachuvitta sambar powder"], False, True, "masala"),
    ("Fish Curry Masala Meen Kuzhambu Podi", "மீன் குழம்பு மசாலா", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Aachi", "Sakthi", "Eastern"], ["fish curry masala", "meen kuzhambu podi"], False, True, "masala"),
    ("Mutton Curry Masala Powder", "மட்டன் கறி மசாலா", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Aachi", "Sakthi", "Everest", "Eastern"], ["mutton masala", "mutton curry powder"], False, True, "masala"),
    ("Chicken Chettinad Masala Powder", "செட்டிநாடு சிக்கன் மசாலா", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Aachi", "Sakthi", "Eastern"], ["chettinad chicken masala"], False, True, "masala"),
    ("Egg Curry Masala Powder", "முட்டை கறி மசாலா", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Eastern", "Aachi", "Everest"], ["egg curry masala"], False, True, "masala"),
    ("Royal Biryani Masala Powder", "ராயல் பிரியாணி மசாலா", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [50.0, 100.0, 200.0], ["Aachi", "Sakthi", "Everest", "Shan"], ["biryani masala", "briyani podi"], False, True, "masala"),
    ("Chana Masala Powder", "சன்னா மசாலா தூள்", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Everest", "MDH", "Catch"], ["chana masala", "chole masala"], False, True, "masala"),
    ("Pav Bhaji Masala Powder", "பாவ் பாஜி மசாலா தூள்", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Everest", "MDH", "Catch", "Badshah"], ["pav bhaji masala"], False, True, "masala"),
    ("Kitchen King All Purpose Masala", "கிச்சன் கிங் மசாலா", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["MDH", "Everest", "Catch"], ["kitchen king masala"], False, True, "masala"),
    ("Chaat Masala Tangy Seasoning", "சாட் மசாலா", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [50.0, 100.0], ["Catch", "Everest", "MDH"], ["chaat masala"], False, True, "masala"),
    ("Dry Mango Powder Amchur", "மாங்காய்த் தூள் (ஆம்சூர்)", "Spices & Seasonings", "Spices & Masalas", "Spice Powder", "g", "weight", "Pantry Shelf", 100.0, [100.0], ["Catch", "Everest", "MDH"], ["amchur powder", "dry mango powder"], False, True, "masala"),
    ("Kasuri Methi Dried Fenugreek", "கசூரி மேத்தி", "Spices & Seasonings", "Spices & Masalas", "Dried Herb", "g", "weight", "Pantry Shelf", 50.0, [25.0, 50.0, 100.0], ["Kasuri Methi MDH", "Everest", "Catch"], ["kasuri methi", "dried fenugreek leaves"], False, True, "masala"),
    ("Black Salt Kala Namak Powder", "கருப்பு உப்பு (காலா நமக்)", "Salt, Sugar & Sweeteners", "Salt & Sweeteners", "Salt", "g", "weight", "Pantry Shelf", 200.0, [100.0, 200.0], ["Catch", "Tata Salt", "Urban Platter"], ["kala namak", "black salt powder"], False, True, "masala"),
    ("Himalayan Pink Rock Salt Fine", "இந்துப்பு பொடி (ஹிமாலயன்)", "Salt, Sugar & Sweeteners", "Salt & Sweeteners", "Salt", "kg", "weight", "Pantry Shelf", 1.0, [0.5, 1.0], ["Tata Salt", "24 Mantra", "Natureland"], ["pink salt", "sendha namak", "indhuppu"], False, True, "masala"),
    ("Crystal Sea Salt Kalluppu", "கல் உப்பு", "Salt, Sugar & Sweeteners", "Salt & Sweeteners", "Salt", "kg", "weight", "Pantry Shelf", 1.0, [1.0, 2.0], ["Tata Salt", "Aashirvaad"], ["kallu uppu", "crystal salt"], True, True, "masala"),
    ("Iodized Table Salt Thool Uppu", "தூள் உப்பு (அயோடின்)", "Salt, Sugar & Sweeteners", "Salt & Sweeteners", "Salt", "kg", "weight", "Pantry Shelf", 1.0, [1.0], ["Tata Salt", "Aashirvaad", "Annapurna"], ["thool uppu", "table salt"], False, True, "masala"),
    ("Low Sodium Lite Salt", "குறைந்த சோடியம் உப்பு (லைட்)", "Salt, Sugar & Sweeteners", "Salt & Sweeteners", "Salt", "kg", "weight", "Pantry Shelf", 1.0, [1.0], ["Tata Salt Lite", "Saffola Salt"], ["low sodium salt", "lite salt"], False, True, "masala"),
    ("Kootu Podi Tamil Brahmin Style", "கூட்டுப் பொடி", "Spices & Seasonings", "Traditional Podis", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Grand Sweets", "Ambika Appalam"], ["kootu podi"], False, True, "masala"),
    ("Poriyal Curry Powder", "பொரியல் மசாலா தூள்", "Spices & Seasonings", "Traditional Podis", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Aachi", "Grand Sweets"], ["poriyal podi", "curry powder"], False, True, "masala"),
    ("Milagu Rasam Podi Black Pepper Rasam", "மிளகு ரசப் பொடி", "Spices & Seasonings", "Traditional Podis", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Grand Sweets", "Aachi"], ["milagu rasam podi", "pepper rasam powder"], False, True, "masala"),
    ("Poondu Rasam Podi Garlic Rasam", "பூண்டு ரசப் பொடி", "Spices & Seasonings", "Traditional Podis", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Grand Sweets", "Aachi"], ["poondu rasam podi", "garlic rasam powder"], False, True, "masala"),
    ("Goda Masala Maharashtrian Spice", "கோடா மசாலா", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0], ["Suhana", "K-Praveen"], ["goda masala", "kala masala"], False, True, "masala"),
    ("Kolhapuri Kanda Lasun Masala", "கோல்ஹாபூரி மசாலா", "Spices & Seasonings", "Spices & Masalas", "Spice Blend", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Suhana", "Badshah"], ["kanda lasun masala", "kolhapuri masala"], False, True, "masala"),
    ("Shenga Chutney Pudi Peanut Chutney Powder", "வேர்க்கடலை சட்னி பொடி", "Spices & Seasonings", "Traditional Podis", "Chutney Powder", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["MTR", "Aachi", "Grand Sweets"], ["shenga chutney pudi", "peanut chutney powder", "verkadalai podi"], False, True, "masala"),
    ("Gurellu Niger Seed Chutney Powder", "குரேள்ளு சட்னி பொடி", "Spices & Seasonings", "Traditional Podis", "Chutney Powder", "g", "weight", "Pantry Shelf", 100.0, [100.0], ["MTR", "Uchellu"], ["gurellu pudi", "niger seed powder"], False, True, "masala"),
    ("Dry Coconut Kobbari Chutney Pudi", "தேங்காய் சட்னி பொடி", "Spices & Seasonings", "Traditional Podis", "Chutney Powder", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["MTR", "Grand Sweets"], ["kobbari chutney pudi", "copra chutney powder"], False, True, "masala"),
    ("Pure Ashwagandha Powder Withania", "அஸ்வகந்தா பொடி", "Spices & Seasonings", "Ayurvedic Powders", "Herbal Powder", "g", "weight", "Medicine Box", 100.0, [100.0, 200.0], ["Patanjali", "Baidyanath", "Kerala Ayurveda"], ["ashwagandha powder", "amukkara kizhangu"], False, True, "masala"),
    ("Triphala Churna Digestive Powder", "திரிபலா சூரணம்", "Spices & Seasonings", "Ayurvedic Powders", "Herbal Powder", "g", "weight", "Medicine Box", 100.0, [100.0, 200.0], ["Dabur", "Baidyanath", "Patanjali"], ["triphala churna", "triphala powder"], False, True, "masala"),
    ("Athimathuram Licorice Root Powder", "அதிமதுரம் பொடி", "Spices & Seasonings", "Ayurvedic Powders", "Herbal Powder", "g", "weight", "Medicine Box", 100.0, [100.0], ["Local Ayurvedic", "Gopuram"], ["athimathuram", "licorice powder", "mulethi"], False, True, "masala"),
    ("Thippili Long Pepper Powder", "திப்பிலி பொடி", "Spices & Seasonings", "Ayurvedic Powders", "Herbal Powder", "g", "weight", "Medicine Box", 50.0, [50.0, 100.0], ["Local Ayurvedic"], ["thippili", "long pepper powder", "pippali"], False, True, "masala"),
    ("Chitharathai Galangal Powder", "சித்தரத்தை பொடி", "Spices & Seasonings", "Ayurvedic Powders", "Herbal Powder", "g", "weight", "Medicine Box", 50.0, [50.0, 100.0], ["Local Ayurvedic"], ["chitharathai", "lesser galangal powder"], False, True, "masala"),
    ("Sukku Malli Coffee Powder", "சுக்கு மல்லி காபி தூள்", "Beverages", "Herbal Drinks", "Herbal Drink Mix", "g", "weight", "Pantry Shelf", 100.0, [100.0, 200.0], ["Grand Sweets", "Aachi", "Local Artisans"], ["sukku malli coffee", "dry ginger coriander coffee"], False, True, "beverage"),

    # === DAIRY, BAKERY & BREAKFAST ===
    ("Buffalo Fresh Milk Pouch", "எருமைப் பால்", "Dairy & Refrigerated", "Dairy Products", "Milk", "ml", "volume", "Refrigerator", 500.0, [500.0, 1000.0], ["Aavin", "Amul", "Nandini"], ["buffalo milk", "eruma paal"], False, True, "dairy"),
    ("Standardized Cow Milk Pouch 4.5% Fat", "பசும்பால் (ஆவின் பச்சை)", "Dairy & Refrigerated", "Dairy Products", "Milk", "ml", "volume", "Refrigerator", 500.0, [500.0, 1000.0], ["Aavin Green", "Amul Taaza", "Nandini"], ["standard milk", "green aavin", "pasum paal"], False, True, "dairy"),
    ("Full Cream Rich Milk Pouch 6% Fat", "முழு கொழுப்பு பால் (ஆவின் ஆரஞ்சு)", "Dairy & Refrigerated", "Dairy Products", "Milk", "ml", "volume", "Refrigerator", 500.0, [500.0, 1000.0], ["Aavin Orange", "Amul Gold", "Mother Dairy"], ["full cream milk", "gold milk", "orange aavin"], False, True, "dairy"),
    ("Toned Cow Milk Pouch 3% Fat", "டோன்டு பால் (ஆவின் நீலம்)", "Dairy & Refrigerated", "Dairy Products", "Milk", "ml", "volume", "Refrigerator", 500.0, [500.0, 1000.0], ["Aavin Blue", "Amul Taaza", "Nandini"], ["toned milk", "blue aavin"], False, True, "dairy"),
    ("Skimmed Diet Milk Pouch 0.5% Fat", "கொழுப்பு நீக்கிய பால் (ஆவின் சிகப்பு)", "Dairy & Refrigerated", "Dairy Products", "Milk", "ml", "volume", "Refrigerator", 500.0, [500.0], ["Aavin Diet", "Amul Slim 'n' Trim"], ["skimmed milk", "diet milk"], False, True, "dairy"),
    ("Fresh Set Curd Tub Dahi", "செட் தயிர்", "Dairy & Refrigerated", "Dairy Products", "Curd", "g", "weight", "Refrigerator", 400.0, [200.0, 400.0, 1000.0], ["Milky Mist", "Amul Masti", "Aavin"], ["set curd", "curd tub", "dahi"], False, True, "dairy"),
    ("Probiotic Cup Curd", "புரோபயாடிக் தயிர்", "Dairy & Refrigerated", "Dairy Products", "Curd", "g", "weight", "Refrigerator", 200.0, [200.0, 400.0], ["Amul Probiotic", "Epigamia"], ["probiotic curd", "probiotic dahi"], False, True, "dairy"),
    ("Spiced Buttermilk Neer Mor Pouch", "மசாலா மோர் / நீர்மோர்", "Dairy & Refrigerated", "Dairy Products", "Buttermilk", "ml", "volume", "Refrigerator", 200.0, [200.0, 500.0], ["Aavin", "Amul Masti Spiced", "Milky Mist"], ["neer mor", "spiced buttermilk", "chaas"], False, True, "dairy"),
    ("Sweet Mango Lassi Bottle", "மாம்பழ லஸ்ஸி", "Dairy & Refrigerated", "Dairy Products", "Lassi", "ml", "volume", "Refrigerator", 200.0, [200.0], ["Amul", "Mother Dairy", "Aavin"], ["mango lassi", "sweet lassi"], False, True, "dairy"),
    ("Fresh Malai Paneer Block", "மசாலா மலாய் பன்னீர்", "Dairy & Refrigerated", "Dairy Products", "Paneer", "g", "weight", "Refrigerator", 200.0, [200.0, 500.0, 1000.0], ["Amul Malai Paneer", "Milky Mist", "Aavin"], ["paneer block", "malai paneer"], False, True, "dairy"),
    ("Low Fat Paneer Block", "குறைந்த கொழுப்பு பன்னீர்", "Dairy & Refrigerated", "Dairy Products", "Paneer", "g", "weight", "Refrigerator", 200.0, [200.0], ["Milky Mist Slim", "Amul Light Paneer"], ["low fat paneer", "slim paneer"], False, True, "dairy"),
    ("Unsweetened Khoya Mawa Fresh", "கோவா / மாவா (இனிப்பில்லாதது)", "Dairy & Refrigerated", "Dairy Products", "Khoya", "g", "weight", "Refrigerator", 200.0, [200.0, 500.0], ["Amul Khoya", "Milky Mist"], ["khoya", "mawa unsweetened", "palkova raw"], False, True, "dairy"),
    ("Sweetened Condensed Milk Tin", "இனிப்பூட்டப்பட்ட கண்டென்ஸ்டு மில்க்", "Dairy & Refrigerated", "Dairy Products", "Condensed Milk", "g", "weight", "Pantry Shelf", 400.0, [200.0, 400.0], ["Nestle Milkmaid", "Amul Mithai Mate"], ["milkmaid", "condensed milk", "mithai mate"], False, True, "dairy"),
    ("Fresh Dairy Cooking Cream 25% Fat", "சமையல் பிரெஷ் கிரீம்", "Dairy & Refrigerated", "Dairy Products", "Cream", "ml", "volume", "Refrigerator", 250.0, [250.0, 1000.0], ["Amul Fresh Cream"], ["fresh cream", "cooking cream", "amul cream"], False, True, "dairy"),
    ("Processed Cheese Slices Pack 10s", "சீஸ் ஸ்லைஸ் (10 எண்ணிக்கை)", "Dairy & Refrigerated", "Dairy Products", "Cheese", "g", "weight", "Refrigerator", 200.0, [100.0, 200.0, 480.0], ["Amul", "Britannia", "Milky Mist"], ["cheese slices", "amul cheese slice"], False, True, "dairy"),
    ("Mozzarella Diced Pizza Cheese", "மொசரெல்லா பிட்சா சீஸ்", "Dairy & Refrigerated", "Dairy Products", "Cheese", "g", "weight", "Refrigerator", 200.0, [200.0, 500.0], ["Milky Mist Mozzarella", "Amul Pizza Cheese", "Go Cheese"], ["mozzarella cheese", "pizza cheese diced"], False, True, "dairy"),
    ("Cheddar Cheese Block", "செடார் சீஸ் பிளாக்", "Dairy & Refrigerated", "Dairy Products", "Cheese", "g", "weight", "Refrigerator", 200.0, [200.0], ["Milky Mist Cheddar", "Amul"], ["cheddar cheese"], False, True, "dairy"),
    ("Cheese Spread Plain Classic", "சீஸ் ஸ்ப்ரெட்", "Dairy & Refrigerated", "Dairy Products", "Cheese", "g", "weight", "Refrigerator", 200.0, [200.0], ["Amul Cheese Spread", "Britannia"], ["cheese spread", "amul spread"], False, True, "dairy"),
    ("Whole Wheat Brown Bread Loaf", "முழு கோதுமை பிரெட்", "Bakery & Breads", "Breads & Buns", "Bread", "g", "weight", "Kitchen Counter", 400.0, [400.0], ["Britannia 100% Whole Wheat", "Modern", "English Oven"], ["brown bread", "whole wheat bread loaf"], False, True, "packaged_food"),
    ("Classic White Sandwich Bread Loaf", "வெள்ளை சாண்ட்விச் பிரெட்", "Bakery & Breads", "Breads & Buns", "Bread", "g", "weight", "Kitchen Counter", 400.0, [400.0], ["Britannia Daily Fresh", "Modern", "Bonn"], ["white bread", "sandwich bread"], False, True, "packaged_food"),
    ("Multigrain Fiber Bread Loaf", "மல்டிகிரைன் பிரெட்", "Bakery & Breads", "Breads & Buns", "Bread", "g", "weight", "Kitchen Counter", 400.0, [400.0], ["Britannia Multigrain", "English Oven", "Modern"], ["multigrain bread"], False, True, "packaged_food"),
    ("Fresh Pav Buns Pack of 6", "பாவ் பன் (6 எண்ணிக்கை)", "Bakery & Breads", "Breads & Buns", "Buns", "piece", "package", "Kitchen Counter", 6.0, [6.0], ["Modern", "Britannia", "Local Bakery"], ["pav buns", "ladi pav"], False, True, "packaged_food"),
    ("Burger Buns Pack of 4", "பர்கர் பன் (4 எண்ணிக்கை)", "Bakery & Breads", "Breads & Buns", "Buns", "piece", "package", "Kitchen Counter", 4.0, [4.0], ["Modern", "Britannia", "English Oven"], ["burger buns"], False, True, "packaged_food"),
    ("Readymade Pizza Base Pack of 2", "பிட்சா பேஸ் (2 எண்ணிக்கை)", "Bakery & Breads", "Breads & Buns", "Buns", "piece", "package", "Kitchen Counter", 2.0, [2.0], ["Modern", "English Oven"], ["pizza base pack"], False, True, "packaged_food"),
    ("Sweet Coconut Bun Bakery Special", "தேங்காய் பன்", "Bakery & Breads", "Breads & Buns", "Sweet Bun", "piece", "piece", "Kitchen Counter", 1.0, [1.0, 2.0], ["Local Bakery", "Iyengar Bakery"], ["coconut bun", "dilkush bun"], False, True, "packaged_food"),
    ("Milk Rusk Toast Crunchy 200g", "மில்க் ரஸ்க் டோஸ்ட்", "Bakery & Breads", "Rusks & Toasts", "Rusk", "g", "weight", "Pantry Shelf", 200.0, [200.0, 400.0], ["Britannia Toastea", "Parle Rusk", "Sunfeast"], ["milk rusk", "crisp toast", "toastea"], False, True, "packaged_food"),
    ("Cake Rusk Double Baked", "கேக் ரஸ்க்", "Bakery & Breads", "Rusks & Toasts", "Rusk", "g", "weight", "Pantry Shelf", 300.0, [300.0], ["Bikaji", "Haldiram's", "Local Bakery"], ["cake rusk", "sweet rusk"], False, True, "packaged_food"),

    # === BISCUITS, COOKIES & CRACKERS ===
    ("Glucose Energy Biscuits", "குளுக்கோஸ் பிஸ்கட்", "Snacks & Namkeen", "Biscuits & Cookies", "Biscuits", "g", "weight", "Pantry Shelf", 250.0, [100.0, 250.0, 800.0], ["Parle-G", "Sunfeast Glucose", "Tiger"], ["parle g", "glucose biscuits"], False, True, "snacks"),
    ("Marie Gold Tea Biscuits", "மேரி கோல்ட் பிஸ்கட்", "Snacks & Namkeen", "Biscuits & Cookies", "Biscuits", "g", "weight", "Pantry Shelf", 300.0, [120.0, 300.0, 1000.0], ["Britannia Marie Gold", "Sunfeast Marie Light", "Parle Marie"], ["marie gold", "tea biscuits marie"], False, True, "snacks"),
    ("Bourbon Chocolate Cream Biscuits", "போர்பன் சாக்லேட் பிஸ்கட்", "Snacks & Namkeen", "Biscuits & Cookies", "Biscuits", "g", "weight", "Pantry Shelf", 150.0, [150.0], ["Britannia Bourbon", "Sunfeast Dark Fantasy Bourbon", "Parle"], ["bourbon biscuits", "chocolate biscuits"], False, True, "snacks"),
    ("Dark Fantasy Choco Fills Cookies", "டார்க் ஃபேண்டசி சோகோ ஃபில்ஸ்", "Snacks & Namkeen", "Biscuits & Cookies", "Cookies", "g", "weight", "Pantry Shelf", 75.0, [75.0, 300.0], ["Sunfeast Dark Fantasy"], ["dark fantasy", "choco fills cookies"], False, True, "snacks"),
    ("Maska Chaska Butter Herb Crackers 50-50", "மஸ்கா சஸ்கா 50-50 பிஸ்கட்", "Snacks & Namkeen", "Biscuits & Cookies", "Crackers", "g", "weight", "Pantry Shelf", 120.0, [120.0], ["Britannia 50-50"], ["maska chaska", "50 50 biscuit"], False, True, "snacks"),
    ("Monaco Classic Salted Crackers", "மொனாகோ உப்பு பிஸ்கட்", "Snacks & Namkeen", "Biscuits & Cookies", "Crackers", "g", "weight", "Pantry Shelf", 200.0, [75.0, 200.0], ["Parle Monaco"], ["monaco biscuits", "salted crackers"], False, True, "snacks"),
    ("Krackjack Sweet & Salty Crackers", "கிராக்ஜாக் பிஸ்கட்", "Snacks & Namkeen", "Biscuits & Cookies", "Crackers", "g", "weight", "Pantry Shelf", 200.0, [75.0, 200.0], ["Parle Krackjack"], ["krackjack", "sweet and salty biscuits"], False, True, "snacks"),
    ("Good Day Cashew Butter Cookies", "குட் டே முந்திரி பிஸ்கட்", "Snacks & Namkeen", "Biscuits & Cookies", "Cookies", "g", "weight", "Pantry Shelf", 200.0, [100.0, 200.0, 600.0], ["Britannia Good Day Cashew"], ["good day cashew", "kaju biscuit"], False, True, "snacks"),
    ("Good Day Butter Cookies Classic", "குட் டே வெண்ணெய் பிஸ்கட்", "Snacks & Namkeen", "Biscuits & Cookies", "Cookies", "g", "weight", "Pantry Shelf", 200.0, [100.0, 200.0], ["Britannia Good Day Butter"], ["good day butter", "butter cookie"], False, True, "snacks"),
    ("Good Day Pista Badam Cookies", "குட் டே பிஸ்தா பாதாம் பிஸ்கட்", "Snacks & Namkeen", "Biscuits & Cookies", "Cookies", "g", "weight", "Pantry Shelf", 200.0, [100.0, 200.0], ["Britannia Good Day Harmony"], ["good day pista badam"], False, True, "snacks"),
    ("Nice Sugar Sprinkled Coconut Biscuits", "நைஸ் தேங்காய் பிஸ்கட்", "Snacks & Namkeen", "Biscuits & Cookies", "Biscuits", "g", "weight", "Pantry Shelf", 150.0, [150.0], ["Britannia Nice Time", "Parle Nice"], ["nice biscuits", "coconut nice time"], False, True, "snacks"),
    ("Hide & Seek Chocolate Chip Cookies", "ஹைட் அண்ட் சீக் சாக்லேட் சிப்", "Snacks & Namkeen", "Biscuits & Cookies", "Cookies", "g", "weight", "Pantry Shelf", 120.0, [120.0, 350.0], ["Parle Hide & Seek"], ["hide and seek", "choco chip cookies"], False, True, "snacks"),
    ("Little Hearts Sugar Glazed Biscuits", "லிட்டில் ஹார்ட்ஸ் பிஸ்கட்", "Snacks & Namkeen", "Biscuits & Cookies", "Biscuits", "g", "weight", "Pantry Shelf", 75.0, [75.0], ["Britannia Little Hearts"], ["little hearts", "sugar hearts biscuits"], False, True, "snacks"),
    ("High Fibre Digestive Wheat Biscuits", "டைஜெஸ்டிவ் பிஸ்கட்", "Snacks & Namkeen", "Biscuits & Cookies", "Biscuits", "g", "weight", "Pantry Shelf", 250.0, [100.0, 250.0], ["Britannia NutriChoice Digestive", "McVitie's"], ["digestive biscuits", "nutrichoice"], False, True, "snacks"),

    # === BEVERAGES, COFFEE, TEA & SQUASHES ===
    ("Kumbakonam Degree Filter Coffee Powder 80:20", "கும்பகோணம் டிகிரி ஃபில்டர் காபி தூள் (80:20)", "Beverages", "Coffee", "Filter Coffee", "g", "weight", "Pantry Shelf", 500.0, [200.0, 500.0], ["Narasu's", "Leo Coffee", "Cothas", "Bayar's"], ["kumbakonam degree coffee", "filter coffee 80 20"], False, True, "beverage"),
    ("Traditional Filter Coffee Powder 70:30 Chicory Blend", "ஃபில்டர் காபி தூள் (70:30 சிகோரி)", "Beverages", "Coffee", "Filter Coffee", "g", "weight", "Pantry Shelf", 500.0, [200.0, 500.0], ["Narasu's Udhayam", "Leo Coffee", "Cothas Coffee"], ["filter coffee 70 30", "chicory coffee"], False, True, "beverage"),
    ("Pure Arabica 100% Filter Coffee Powder", "அராபிகா ஃபில்டர் காபி தூள் (100% பியூர்)", "Beverages", "Coffee", "Filter Coffee", "g", "weight", "Pantry Shelf", 250.0, [250.0, 500.0], ["Blue Tokai", "Leo Coffee", "Third Wave"], ["pure arabica coffee", "arabica plantation filter"], False, True, "beverage"),
    ("Instant Agglomerated Pure Coffee Glass Jar", "இன்ஸ்டன்ட் காபி தூள் (பியூர்)", "Beverages", "Coffee", "Instant Coffee", "g", "weight", "Pantry Shelf", 100.0, [50.0, 100.0, 200.0], ["Nescafe Classic", "Bru Pure", "Tata Coffee Grand"], ["nescafe classic", "instant coffee pure"], False, True, "beverage"),
    ("Instant Coffee Chicory Blend Jar", "இன்ஸ்டன்ட் காபி சிகோரி மிக்ஸ்", "Beverages", "Coffee", "Instant Coffee", "g", "weight", "Pantry Shelf", 100.0, [50.0, 100.0, 200.0], ["Bru Instant", "Sunrise Instant", "Tata Coffee Gold"], ["bru instant", "sunrise coffee"], False, True, "beverage"),
    ("Strong CTC Dust Tea Powder Tamil Nadu Blend", "சி.டி.சி டஸ்ட் தேயிலைத் தூள்", "Beverages", "Tea", "Tea Powder", "kg", "weight", "Pantry Shelf", 0.5, [0.25, 0.5, 1.0], ["3 Roses Dust", "Chakra Gold", "Kannan Devan", "AVT Premium"], ["dust tea", "3 roses dust", "strong tea powder"], False, True, "beverage"),
    ("Premium CTC Leaf Tea", "சி.டி.சி லீஃப் டீ", "Beverages", "Tea", "Leaf Tea", "g", "weight", "Pantry Shelf", 500.0, [250.0, 500.0], ["Tata Tea Gold", "Red Label Natural Care", "Wagh Bakri"], ["leaf tea", "tata tea gold", "red label tea"], False, True, "beverage"),
    ("Darjeeling Long Leaf Black Tea Tin", "டார்ஜிலிங் லாங் லீஃப் டீ", "Beverages", "Tea", "Leaf Tea", "g", "weight", "Pantry Shelf", 250.0, [100.0, 250.0], ["Twinings Darjeeling", "Tata Tea Gold Care", "Teabox"], ["darjeeling tea", "orthodox black tea"], False, True, "beverage"),
    ("Cardamom Elaichi Tea Bags Box 25s", "ஏலக்காய் டீ பேக்குகள் (25 எண்ணிக்கை)", "Beverages", "Tea", "Tea Bags", "piece", "package", "Pantry Shelf", 25.0, [25.0, 50.0], ["Taj Mahal Elaichi", "Tetley", "Wagh Bakri"], ["elaichi tea bags", "cardamom tea"], False, True, "beverage"),
    ("Green Tea Lemon & Honey Bags Box 25s", "கிரீன் டீ (எலுமிச்சை & தேன், 25 எண்ணிக்கை)", "Beverages", "Tea", "Green Tea", "piece", "package", "Pantry Shelf", 25.0, [25.0, 100.0], ["Lipton Green Tea", "Tetley", "Organic India"], ["green tea bags", "lemon honey green tea"], False, True, "beverage"),
    ("Tulsi Green Tea Detox Bags Box 25s", "துளசி கிரீன் டீ (25 எண்ணிக்கை)", "Beverages", "Tea", "Green Tea", "piece", "package", "Pantry Shelf", 25.0, [25.0], ["Organic India Tulsi Green", "Typhoo"], ["tulsi green tea", "detox tea"], False, True, "beverage"),
    ("Authentic Nannari Sarbath Root Syrup", "நன்னாரி சர்பத் சிரப்", "Beverages", "Syrups & Squashes", "Syrup", "ml", "volume", "Pantry Shelf", 750.0, [500.0, 750.0], ["Mylapore Ganapathy", "Karthik Nannari", "Local Artisans"], ["nannari sarbath", "sarasaparilla syrup"], False, True, "beverage"),
    ("Traditional Rose Milk Flavored Syrup", "ரோஸ் மில்க் சிரப்", "Beverages", "Syrups & Squashes", "Syrup", "ml", "volume", "Pantry Shelf", 750.0, [500.0, 750.0], ["Mapro Rose", "Kalvert", "Mala's"], ["rose syrup", "rose milk essence"], False, True, "beverage"),
    ("Kokum Sharbat Natural Digestive Squash", "கோகம் சர்பத் சிரப்", "Beverages", "Syrups & Squashes", "Syrup", "ml", "volume", "Pantry Shelf", 500.0, [500.0], ["Mapro", "Kokum Natural"], ["kokum syrup", "kokum sharbat"], False, True, "beverage"),
    ("Royal Badam Drink Mix Powder Jar", "பாதாம் பால் மிக்ஸ் பவுடர்", "Beverages", "Health Drinks", "Drink Mix", "g", "weight", "Pantry Shelf", 500.0, [200.0, 500.0], ["MTR Badam Drink Mix", "Aachi Badam", "Everest"], ["badam drink mix", "badam milk powder"], False, True, "beverage"),
    ("Tender Coconut Water Tetra Pack 200ml", "இளநீர் டெட்ரா பேக் (200 மி.லி)", "Beverages", "Juices & Drinks", "Coconut Water", "ml", "volume", "Refrigerator", 200.0, [200.0], ["Raw Pressery", "Paper Boat", "Coco Jal"], ["tender coconut water pack", "packaged elaneer"], False, True, "beverage"),
    ("Pure Aloe Vera Juice Sugar Free 1L", "சோற்றுக்கற்றாழை சாறு", "Beverages", "Health Drinks", "Ayurvedic Juice", "ml", "volume", "Pantry Shelf", 1000.0, [1000.0], ["Kapiva", "Baidyanath", "Patanjali"], ["aloe vera juice", "katrazhai juice"], False, True, "beverage"),
    ("Pure Amla Gooseberry Juice 1L", "நெல்லிக்காய் சாறு (1 லிட்டர்)", "Beverages", "Health Drinks", "Ayurvedic Juice", "ml", "volume", "Pantry Shelf", 1000.0, [1000.0], ["Kapiva Amla Juice", "Baidyanath", "Patanjali"], ["amla juice pure", "nellikai saaru"], False, True, "beverage"),

    # === SWEETS, HALWAS & TRADITIONAL MITHAI ===
    ("Motichoor Laddu Desi Ghee", "மோதிசூர் லட்டு (நெய்)", "Snacks & Namkeen", "Traditional Sweets", "Laddu", "g", "weight", "Pantry Shelf", 250.0, [250.0, 500.0], ["A2B", "Haldiram's", "Bikano"], ["motichoor laddu", "motichur ladoo"], False, True, "snacks"),
    ("Besan Laddu Roasted Gram Sweet", "கடலை மாவு லட்டு (பேசன்)", "Snacks & Namkeen", "Traditional Sweets", "Laddu", "g", "weight", "Pantry Shelf", 250.0, [250.0, 500.0], ["Haldiram's", "A2B", "Bikaji"], ["besan laddu", "besan ladoo"], False, True, "snacks"),
    ("Rava Laddu With Cashews & Raisins", "ரவா லட்டு", "Snacks & Namkeen", "Traditional Sweets", "Laddu", "g", "weight", "Pantry Shelf", 250.0, [250.0, 500.0], ["Grand Sweets", "A2B"], ["rava laddu", "sooji ladoo"], False, True, "snacks"),
    ("Maa Laddu Roasted Gram Flour Sweet", "மாலாடு / பொட்டுக்கடலை லட்டு", "Snacks & Namkeen", "Traditional Sweets", "Laddu", "g", "weight", "Pantry Shelf", 250.0, [250.0], ["Grand Sweets", "A2B"], ["maladu", "maa laddu", "pottukadalai laddu"], False, True, "snacks"),
    ("Kaju Katli Diamond Silver Foil", "காஜு கட்லி முந்திரி கேக்", "Snacks & Namkeen", "Traditional Sweets", "Kaju Sweet", "g", "weight", "Pantry Shelf", 250.0, [250.0, 500.0], ["Haldiram's", "A2B", "Bikano", "Sri Krishna Sweets"], ["kaju katli", "cashew barfi"], False, True, "snacks"),
    ("Doodh Peda Traditional Milk Sweet", "தூத் பேடா", "Snacks & Namkeen", "Traditional Sweets", "Milk Sweet", "g", "weight", "Refrigerator", 250.0, [250.0, 500.0], ["Nandini Peda", "A2B", "Haldiram's"], ["doodh peda", "milk peda", "nandini peda"], False, True, "snacks"),
    ("Rasgulla Canned Tin 1kg", "ரசகுல்லா டின் (1 கிலோ)", "Snacks & Namkeen", "Traditional Sweets", "Canned Sweet", "kg", "weight", "Pantry Shelf", 1.0, [1.0], ["Haldiram's Rasgulla", "Bikano", "KC Das"], ["rasgulla tin", "sponge rasgulla"], False, True, "snacks"),
    ("Gulab Jamun Canned Tin 1kg", "குலாப் ஜாமுன் டின் (1 கிலோ)", "Snacks & Namkeen", "Traditional Sweets", "Canned Sweet", "kg", "weight", "Pantry Shelf", 1.0, [1.0], ["Haldiram's Gulab Jamun", "Bikano", "MTR"], ["gulab jamun tin", "kala jamun canned"], False, True, "snacks"),
    ("Soan Papdi Desi Ghee Flaky Sweet", "சோன் பப்டி (நெய்)", "Snacks & Namkeen", "Traditional Sweets", "Flaky Sweet", "g", "weight", "Pantry Shelf", 250.0, [250.0, 500.0], ["Haldiram's Soan Papdi", "Bikaji", "Patanjali"], ["soan papdi", "patisa"], False, True, "snacks"),
    ("Kasi Halwa White Pumpkin Sweet", "காசி அல்வா (பூசணிக்காய்)", "Snacks & Namkeen", "Traditional Sweets", "Halwa", "g", "weight", "Refrigerator", 250.0, [250.0], ["Grand Sweets", "A2B"], ["kasi halwa", "ash gourd halwa"], False, True, "snacks"),
    ("Fresh Carrot Halwa Gajar Ka Halwa", "கேரட் அல்வா (காஜர் கா அல்வா)", "Snacks & Namkeen", "Traditional Sweets", "Halwa", "g", "weight", "Refrigerator", 250.0, [250.0, 500.0], ["Haldiram's", "A2B", "Bikanervala"], ["gajar halwa", "carrot halwa"], False, True, "snacks"),

    # === CLEANING, UTILITY & HARDWARE ===
    ("Bleaching Powder Disinfectant Calcium Hypochlorite", "ப்ளீச்சிங் பவுடர்", "Household & Cleaning", "Surface Cleaners & Pest Control", "Disinfectant", "g", "weight", "Utility Room", 500.0, [500.0, 1000.0], ["Bengal Chemicals", "Local"], ["bleaching powder", "chuna bleach"], False, True, "cleaning"),
    ("Instant Drain Declogger Drain Cleaner Powder", "ட்ரைன் கிளீனர் பவுடர் (அடைப்பு நீக்கி)", "Household & Cleaning", "Surface Cleaners & Pest Control", "Drain Cleaner", "g", "weight", "Utility Room", 50.0, [50.0, 100.0], ["Kiwi Dranex", "Mr Muscle Drain"], ["drain cleaner", "dranex crystals"], False, True, "cleaning"),
    ("Concentrated Heavy Duty Floor Phenyl White", "வெள்ளை பினாயில் (தரை கழுவ)", "Household & Cleaning", "Surface Cleaners & Pest Control", "Floor Cleaner", "l", "volume", "Utility Room", 1.0, [1.0, 5.0], ["Doctor Brand", "Bengal Chemicals", "Gainda"], ["white phenyl", "floor phenyl"], False, True, "cleaning"),
    ("Fragrant Green Pine Herbal Floor Cleaner", "பச்சை பைன் பினாயில்", "Household & Cleaning", "Surface Cleaners & Pest Control", "Floor Cleaner", "l", "volume", "Utility Room", 1.0, [1.0, 2.0], ["Gainda", "Doctor Brand"], ["green phenyl", "pine oil floor cleaner"], False, True, "cleaning"),
    ("Brass & Copper Vessels Cleaning Powder Pitambari", "பீதாம்பரி பவுடர் (பித்தளை பாத்திரம் கழுவ)", "Household & Cleaning", "Dishwashing", "Metal Cleaner", "g", "weight", "Utility Shelf", 200.0, [100.0, 200.0], ["Pitambari Shining Powder"], ["pitambari powder", "brass cleaner powder"], False, True, "cleaning"),
    ("Silver Shine Liquid Dip Cleaner", "சில்வர் கிளீனர் திரவம் (வெள்ளி பாத்திரம்)", "Household & Cleaning", "Dishwashing", "Metal Cleaner", "ml", "volume", "Utility Shelf", 100.0, [100.0], ["Roopam Silver Shine", "Pitambari"], ["silver dip cleaner", "velli cleaner"], False, True, "cleaning"),
    ("Kitchen Chimney Degreaser Spray 500ml", "சிம்னி கிளீனர் ஸ்ப்ரே", "Household & Cleaning", "Surface Cleaners & Pest Control", "Degreaser", "ml", "volume", "Kitchen Cabinet", 500.0, [500.0], ["Cif Power Pro", "Mr Muscle Kitchen"], ["chimney cleaner", "kitchen degreaser spray"], False, True, "cleaning"),
    ("Tap & Shower Limescale Remover Spray 500ml", "குழாய் உப்புக்கறை நீக்கி ஸ்ப்ரே", "Household & Cleaning", "Surface Cleaners & Pest Control", "Limescale Remover", "ml", "volume", "Bathroom Shelf", 500.0, [500.0], ["Cif Limescale", "Harpic Red Bathroom"], ["tap cleaner spray", "limescale remover"], False, True, "cleaning"),
    ("Washing Machine Drum Descaler Tablets 6 Pack", "வாஷிங் மெஷின் டிரம் கிளீனர் மாத்திரைகள்", "Household & Cleaning", "Laundry Care", "Descaler", "piece", "package", "Utility Shelf", 6.0, [6.0], ["Bosch Descaler", "IFB Scalego", "Fortune"], ["washing machine tablets", "drum descaler"], False, True, "cleaning"),
    ("Spin Mop Bucket Replacement Microfiber Head", "ஸ்பின் மாப் ரீஃபில் தலை", "Household & Cleaning", "Cleaning Tools", "Mop Refill", "piece", "piece", "Utility Room", 1.0, [1.0, 2.0], ["Gala Spin Mop Refill", "Scotch-Brite"], ["spin mop refill head", "mop replacement pad"], False, True, "cleaning"),
    ("Long Handle Bottle Cleaning Brush", "பாட்டில் கிளீனிங் பிரஷ்", "Household & Cleaning", "Cleaning Tools", "Brush", "piece", "piece", "Kitchen Cabinet", 1.0, [1.0], ["Gala", "Scotch-Brite"], ["bottle brush", "flask cleaning brush"], False, True, "cleaning"),
    ("Shoe Polish Black Wax Paste Tin 40g", "கருப்பு ஷூ பாலிஷ் டின்", "Household & Cleaning", "Home Utilities", "Shoe Care", "g", "weight", "Shoe Rack", 40.0, [40.0], ["Cherry Blossom Black", "Kiwi"], ["black shoe polish", "cherry blossom wax"], False, True, "hardware"),
    ("Shoe Shine Instant Sponge Neutral", "ஷூ ஷைன் ஸ்பாஞ்ச்", "Household & Cleaning", "Home Utilities", "Shoe Care", "piece", "piece", "Shoe Rack", 1.0, [1.0], ["Cherry Blossom Express Shine", "Kiwi"], ["shoe shine sponge", "instant shoe polish"], False, True, "hardware"),
    ("Termite Control Insecticide Spray 200ml", "கரையான் மருந்து ஸ்ப்ரே", "Household & Cleaning", "Surface Cleaners & Pest Control", "Pest Control", "ml", "volume", "Utility Shelf", 200.0, [200.0], ["Hit Termite", "Pest Seal"], ["termite spray", "karayan marundhu"], False, True, "cleaning"),
    ("Rat Glue Trap Sticky Board Heavy Duty", "எலி பசை அட்டை (ட்ராப்)", "Household & Cleaning", "Surface Cleaners & Pest Control", "Pest Control", "piece", "piece", "Utility Shelf", 1.0, [1.0, 2.0], ["Trubble Gum Glue Trap", "Hit"], ["rat glue pad", "sticky mouse trap"], False, True, "cleaning"),

    # === PERSONAL CARE, GROOMING & HEALTH ===
    ("Nalangu Maavu Herbal Bath Powder", "நலங்கு மாவு மூலிகை குளியல் பொடி", "Personal Care & Hygiene", "Bath & Body Care", "Herbal Bath Powder", "g", "weight", "Bathroom Shelf", 200.0, [100.0, 200.0, 500.0], ["Local Ayurvedic", "Gramiyum", "Kama Ayurveda"], ["nalangu maavu", "ubtan powder", "herbal bath powder"], False, True, "personal_care"),
    ("Pure Multani Mitti Fuller's Earth Powder", "முல்தானி மிட்டி பவுடர்", "Personal Care & Hygiene", "Skin Care", "Clay Powder", "g", "weight", "Bathroom Shelf", 200.0, [100.0, 200.0], ["Banjara's", "Nature's Tattva", "Patanjali"], ["multani mitti", "fullers earth"], False, True, "personal_care"),
    ("Pure Rose Water Face Toner Spray Bottle", "ரோஸ் வாட்டர் டோனர் ஸ்ப்ரே", "Personal Care & Hygiene", "Skin Care", "Toner", "ml", "volume", "Dressing Table", 200.0, [100.0, 200.0], ["Dabur Gulabari", "Kama Ayurveda"], ["gulabari rose water", "face rose toner"], False, True, "personal_care"),
    ("Pure Glycerin Liquid USP Grade 100g", "கிளிசரின் திரவம்", "Personal Care & Hygiene", "Skin Care", "Moisturizer", "g", "weight", "Bathroom Shelf", 100.0, [100.0], ["Dabur Glycerin", "Local Pharma"], ["pure glycerin", "glycerol"], False, True, "personal_care"),
    ("Pure Petroleum Jelly Tin 50g", "பெட்ரோலியம் ஜெல்லி டின்", "Personal Care & Hygiene", "Skin Care", "Skin Protectant", "g", "weight", "Dressing Table", 50.0, [50.0, 100.0], ["Vaseline Pure Jelly"], ["vaseline jelly", "petroleum jelly"], False, True, "personal_care"),
    ("Pure Aloe Vera Soothing Gel 99%", "கற்றாழை ஜெல் (99%)", "Personal Care & Hygiene", "Skin Care", "Gel", "g", "weight", "Dressing Table", 150.0, [100.0, 150.0], ["Patanjali Kanti Aloe", "Wow Skin", "Mamaearth"], ["aloe vera gel", "katrazhai gel"], False, True, "personal_care"),
    ("Purifying Neem Face Wash Pump Tube", "வேப்பிலை ஃபேஸ் வாஷ்", "Personal Care & Hygiene", "Skin Care", "Face Wash", "ml", "volume", "Bathroom Shelf", 150.0, [100.0, 150.0], ["Himalaya Neem Face Wash", "Clean & Clear"], ["himalaya neem face wash", "neem cleanser"], False, True, "personal_care"),
    ("Herbal Anti Dandruff Shampoo", "மூலிகை பொடுகு நீக்கும் ஷாம்பு", "Personal Care & Hygiene", "Hair Care", "Shampoo", "ml", "volume", "Bathroom Shelf", 180.0, [180.0, 360.0], ["Head & Shoulders", "Himalaya Anti Dandruff"], ["anti dandruff shampoo", "podugu shampoo"], False, True, "personal_care"),
    ("Nourishing Coconut Milk Conditioner", "தேங்காய் பால் ஹேர் கண்டிஷனர்", "Personal Care & Hygiene", "Hair Care", "Conditioner", "ml", "volume", "Bathroom Shelf", 180.0, [180.0], ["TRESemme", "L'Oreal", "Dove"], ["hair conditioner", "coconut milk conditioner"], False, True, "personal_care"),
    ("Pain Relief Balm Strong", "வலி நிவாரண தைலம்", "Personal Care & Hygiene", "Health & Wellness", "Balm", "g", "weight", "Medicine Box", 50.0, [30.0, 50.0], ["Amrutanjan Strong", "Zandu Balm", "Tiger Balm"], ["amrutanjan balm", "pain relief balm", "thailam"], False, True, "personal_care"),
    ("Fast Pain Relief Spray 55g", "வலி நிவாரண ஸ்ப்ரே", "Personal Care & Hygiene", "Health & Wellness", "Spray", "g", "weight", "Medicine Box", 55.0, [55.0], ["Moov Spray", "Volini Spray", "Relispray"], ["moov spray", "volini spray", "pain spray"], False, True, "personal_care"),
    ("Adhesive First Aid Bandages Pack of 20", "பேண்டேஜ் ஸ்ட்ரிப்ஸ் (20 எண்ணிக்கை)", "Personal Care & Hygiene", "Health & Wellness", "First Aid", "piece", "package", "Medicine Box", 20.0, [20.0, 100.0], ["Band-Aid Johnson's", "Hansaplast"], ["band aid", "adhesive bandage"], False, True, "personal_care"),
    ("Prickly Heat Cooling Menthol Powder", "வேர்க்குரு பவுடர் (கூலிங்)", "Personal Care & Hygiene", "Bath & Body Care", "Talc", "g", "weight", "Dressing Table", 150.0, [150.0], ["Dermi Cool", "Nycil Cool Herbal", "BoroPlus"], ["dermi cool powder", "nycil prickly heat"], False, True, "personal_care"),

    # === BABY CARE ===
    ("Baby Diaper Pants Extra Large XL 32s", "குழந்தை டயபர் - எக்ஸ்ட்ரா லார்ஜ் (32 எண்ணிக்கை)", "Baby Care", "Baby Hygiene & Wellness", "Diapers", "piece", "package", "Baby Care Shelf", 32.0, [32.0, 56.0], ["Pampers XL Pants", "MamyPoko XL", "Huggies XL"], ["baby diaper xl", "pampers xl"], False, True, "baby_care"),
    ("Baby Diaper Pants Small S 42s", "குழந்தை டயபர் - ஸ்மால் (42 எண்ணிக்கை)", "Baby Care", "Baby Hygiene & Wellness", "Diapers", "piece", "package", "Baby Care Shelf", 42.0, [42.0], ["Pampers Small Pants", "MamyPoko S"], ["baby diaper small", "pampers small"], False, True, "baby_care"),
    ("Fragrance Free Baby Water Wipes 72 Wipes", "குழந்தை வாட்டர் வைப்ஸ் (72 எண்ணிக்கை)", "Baby Care", "Baby Hygiene & Wellness", "Wipes", "piece", "package", "Baby Care Shelf", 72.0, [72.0], ["Mother Sparsh 99% Pure Water", "Himalaya Wipes"], ["baby water wipes", "pure water wipes"], False, True, "baby_care"),
    ("Gentle Baby Body Wash Head to Toe 200ml", "குழந்தை ஹெட் டூ டோ வாஷ்", "Baby Care", "Baby Hygiene & Wellness", "Baby Wash", "ml", "volume", "Baby Care Shelf", 200.0, [200.0, 500.0], ["Johnson's Top-to-Toe", "Sebamed Baby", "Himalaya"], ["baby wash head to toe", "johnson baby wash"], False, True, "baby_care"),
    ("Baby Feeding Bottle BPA Free 250ml", "குழந்தை பால் பாட்டில் (250 மி.லி)", "Baby Care", "Baby Feeding", "Bottle", "piece", "piece", "Baby Care Shelf", 1.0, [1.0], ["Pigeon BPA Free", "Philips Avent", "Chicco"], ["baby feeding bottle", "paal bottle"], False, True, "baby_care"),
    ("Liquid Cleanser for Baby Bottles & Nipples 500ml", "பால் பாட்டில் கிளீனிங் லிக்விட்", "Baby Care", "Baby Feeding", "Cleanser", "ml", "volume", "Kitchen Cabinet", 500.0, [500.0], ["Pigeon Liquid Cleanser", "Mee Mee Cleanser"], ["baby bottle cleanser liquid", "nipple wash"], False, True, "baby_care"),

    # === PET CARE ===
    ("Puppy Dry Food Chicken & Egg 1.2kg", "குட்டி நாய் உலர் உணவு (சிக்கன் & முட்டை)", "Pet Care", "Pet Food", "Dog Food", "kg", "weight", "Pet Care Shelf", 1.2, [1.2, 3.0], ["Pedigree Puppy", "Drools Puppy"], ["puppy food", "pedigree puppy dry"], False, True, "pets"),
    ("Wet Dog Food Pouch Chicken Gravy 100g", "நாய் ஈர உணவு (சிக்கன் கிரேவி பாக்கெட்)", "Pet Care", "Pet Food", "Dog Food", "g", "weight", "Pet Care Shelf", 100.0, [100.0], ["Pedigree Pouch Gravy", "Drools Pouch"], ["wet dog food pouch", "pedigree gravy pouch"], False, True, "pets"),
    ("Rawhide Dog Chew Bones 4 Inch Pack of 4", "நாய் மெல்லும் எலும்பு (4 எண்ணிக்கை)", "Pet Care", "Pet Food", "Pet Treats", "piece", "package", "Pet Care Shelf", 4.0, [4.0], ["Gnawlers Bones", "Meat Up"], ["dog chew bones", "rawhide bones"], False, True, "pets"),
    ("Adult Cat Wet Food Pouch Tuna in Jelly 85g", "பூனை ஈர உணவு (டுனா மீன் பாக்கெட்)", "Pet Care", "Pet Food", "Cat Food", "g", "weight", "Pet Care Shelf", 85.0, [85.0], ["Whiskas Tuna Jelly", "Sheba Pouch"], ["cat wet food pouch", "whiskas tuna pouch"], False, True, "pets"),
    ("Clumping Bentonite Cat Litter Sand 5kg", "பூனை மணல் (லிட்டர் 5 கிலோ)", "Pet Care", "Pet Hygiene", "Cat Litter", "kg", "weight", "Utility Shelf", 5.0, [5.0, 10.0], ["Emily Pets Litter", "Intersand"], ["cat litter sand", "bentonite cat litter"], False, True, "pets"),
]

def generate_catalog_code():
    catalog = []
    seen_ids = set()

    for item in ITEMS:
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
Matrix Catalog Expansion: Contains {len(catalog)} culturally authentic,
normalized household products for Indian / Tamil Nadu households.
"""
import json

_DATA = r"""{json_str}"""

def get_matrix_catalog():
    return json.loads(_DATA)

if __name__ == "__main__":
    items = get_matrix_catalog()
    print(f"Loaded {{len(items)}} matrix expansion items.")
'''
    with open("scripts/expand_matrix_catalog.py", "w", encoding="utf-8") as f:
        f.write(output_code)

    print(f"Generated scripts/expand_matrix_catalog.py with {len(catalog)} items.")

if __name__ == "__main__":
    generate_catalog_code()

