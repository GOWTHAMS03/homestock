#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Helper generator script to compile comprehensive Non-Food household items:
Cleaning, Laundry, Dishwashing, Pest Control, Paper, Pooja, Personal Care,
Baby Care, Pet Care, and Utility.
Target: ~200-250 authentic household items.
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

# --- DISHWASHING ---
dishwash_data = [
    ("dishwash_bar_lemon_green", "Dishwash Bar Lemon & Neem", "பாத்திரம் கழுவும் பார் சோப்பு", "Dishwash Bar", "g", "weight", "Utility Shelf", 200.0, [200.0, 500.0], ["Dishwash Bar", "Vim Bar", "Bartan Soap"], ["Vim", "Exo", "Pril"]),
    ("dishwash_liquid_gel_lemon", "Dishwash Gel Liquid Lemon", "பாத்திரம் கழுவும் திரவம்", "Dishwash Liquid", "ml", "volume", "Utility Shelf", 500.0, [250.0, 500.0, 750.0, 2000.0], ["Dishwash Liquid", "Vim Gel", "Bartan Liquid"], ["Vim", "Pril", "Exo"]),
    ("dishwash_scrubber_sponge_pad", "Dual Action Scrubber Sponge Pad", "பாத்திரம் துலக்கும் ஸ்பாஞ்ச் ஸ்க்ரப்பர்", "Scrubber", "piece", "piece", "Utility Shelf", 1.0, [1.0, 2.0, 3.0, 5.0], ["Scrub Sponge", "Scotch Brite Sponge", "Dish Sponge"], ["Scotch-Brite", "Gala"]),
    ("stainless_steel_wire_scrubber", "Heavy Duty Stainless Steel Wire Scrubber", "ஸ்டீல் கம்பி நார்", "Scrubber", "piece", "piece", "Utility Shelf", 1.0, [1.0, 2.0, 4.0], ["Steel Scrubber", "Wire Scrub", "Bartan Juna"], ["Scotch-Brite", "Gala"]),
    ("coconut_coir_dish_scrubber", "Natural Coconut Coir Dish Scrubber", "தேங்காய் நார் ஸ்க்ரப்பர்", "Scrubber", "piece", "piece", "Utility Shelf", 2.0, [2.0, 5.0], ["Coir Scrubber", "Thengai Naar Scrub"], ["EcoClean", "Local Artisans"]),
    ("dishwasher_detergent_tablets_all_in_one", "All-in-One Automatic Dishwasher Tablets", "டிஷ்வாஷர் மாத்திரைகள்", "Dishwasher Tablet", "piece", "package", "Utility Shelf", 15.0, [15.0, 30.0, 60.0], ["Dishwasher Tablets", "Finish Tablets"], ["Finish", "Fortune"]),
    ("dishwasher_rinse_aid_liquid", "Automatic Dishwasher Rinse Aid Liquid", "டிஷ்வாஷர் ரின்ஸ் எய்ட்", "Dishwasher Rinse Aid", "ml", "volume", "Utility Shelf", 400.0, [400.0, 800.0], ["Rinse Aid", "Dishwasher Shine Liquid"], ["Finish", "Fortune"]),
    ("dishwasher_regenerating_salt", "Automatic Dishwasher Water Softening Salt", "டிஷ்வாஷர் உப்பு", "Dishwasher Salt", "kg", "weight", "Utility Shelf", 1.0, [1.0, 2.0], ["Dishwasher Salt", "Water Softener Salt"], ["Finish", "Fortune"])
]

for item_id, name, tamil, ptype, unit, sold_by, loc, min_q, q_list, common, brands in dishwash_data:
    add(item_id, name, tamil, "Household & Cleaning", "Dishwashing", ptype, unit, sold_by, loc, min_q, q_list, common, [c.lower() for c in common], brands, True, "EAN_13", False, True, "cleaning")

# --- LAUNDRY CARE ---
laundry_data = [
    ("detergent_powder_front_load_matic", "Front Load Matic Washing Machine Detergent Powder", "துணி துவைக்கும் பவுடர் (ஃபிரண்ட் லோட்)", "Detergent Powder", "kg", "weight", "Laundry Cabinet", 1.0, [1.0, 2.0, 4.0], ["Front Load Powder", "Surf Excel Matic Front", "Ariel Matic"], ["Surf Excel", "Ariel"]),
    ("detergent_powder_top_load_matic", "Top Load Matic Washing Machine Detergent Powder", "துணி துவைக்கும் பவுடர் (டாப் லோட்)", "Detergent Powder", "kg", "weight", "Laundry Cabinet", 1.0, [1.0, 2.0, 4.0], ["Top Load Powder", "Surf Excel Matic Top", "Ariel Top Load"], ["Surf Excel", "Ariel", "Tide"]),
    ("detergent_powder_bucket_hand_wash", "Regular Hand Wash Detergent Powder", "வழக்கமான சலவை பவுடர்", "Detergent Powder", "kg", "weight", "Laundry Cabinet", 1.0, [1.0, 2.0, 4.0, 5.0], ["Bucket Wash Powder", "Washing Powder", "Surf Excel Quick Wash", "Rin Powder", "Tide Plus"], ["Surf Excel", "Ariel", "Tide", "Rin", "Ghadi", "Wheel"]),
    ("liquid_detergent_front_top_load", "Matic Liquid Detergent for Washing Machines", "துணி துவைக்கும் திரவம்", "Liquid Detergent", "ml", "volume", "Laundry Cabinet", 1000.0, [500.0, 1000.0, 2000.0], ["Liquid Detergent", "Surf Excel Liquid", "Ariel Liquid Matic"], ["Surf Excel", "Ariel", "Genteel"]),
    ("liquid_detergent_delicate_wool_silk", "Delicate Wool & Silk Liquid Detergent Wash", "மென்மையான துணி துவைக்கும் திரவம்", "Liquid Detergent", "ml", "volume", "Laundry Cabinet", 500.0, [500.0, 1000.0], ["Ezee Liquid", "Wool Detergent", "Silk Wash"], ["Ezee", "Genteel"]),
    ("fabric_conditioner_softener_blue", "Fabric Conditioner & Softener Spring Floral", "துணி மென்மையாக்கும் திரவம்", "Fabric Conditioner", "ml", "volume", "Laundry Cabinet", 860.0, [400.0, 860.0, 2000.0], ["Fabric Conditioner", "Comfort Fabric Softener"], ["Comfort"]),
    ("laundry_bar_soap_collar_stain", "Laundry Detergent Bar Soap for Tough Stains", "சலவை சோப்பு பார்", "Laundry Bar", "g", "weight", "Laundry Cabinet", 250.0, [150.0, 250.0], ["Laundry Bar", "Rin Bar", "Vanish Soap", "Kapde Dhone Ka Sabun"], ["Rin", "Surf Excel", "Henko", "555"]),
    ("fabric_whitener_liquid_blue_neel", "Fabric Whitener Liquid Blue / Neel", "சலவை நீலம்", "Fabric Whitener", "ml", "volume", "Laundry Cabinet", 100.0, [100.0, 250.0], ["Liquid Blue", "Ujala Supreme", "Neel"], ["Ujala", "Robin"]),
    ("fabric_stiffener_starch_powder", "Instant Cold Water Fabric Starch Powder", "துணி கஞ்சி மாவு", "Fabric Starch", "g", "weight", "Laundry Cabinet", 200.0, [200.0, 400.0], ["Fabric Starch", "Kapde Ki Kalaf", "Revive Starch"], ["Revive"]),
    ("stain_remover_powder_oxi_action", "Oxi Action Color Safe Fabric Stain Remover", "துணி கறை நீக்கி பவுடர்", "Stain Remover", "g", "weight", "Laundry Cabinet", 200.0, [200.0, 400.0], ["Stain Remover", "Vanish Oxi Action"], ["Vanish"])
]

for item_id, name, tamil, ptype, unit, sold_by, loc, min_q, q_list, common, brands in laundry_data:
    add(item_id, name, tamil, "Household & Cleaning", "Laundry Care", ptype, unit, sold_by, loc, min_q, q_list, common, [c.lower() for c in common], brands, True, "EAN_13", False, True, "cleaning")

# --- SURFACE CLEANERS, DISINFECTANTS & PEST CONTROL ---
surface_data = [
    ("floor_cleaner_liquid_citrus_pine", "Disinfectant Surface Floor Cleaner Citrus / Pine", "தரை துடைக்கும் திரவம்", "Floor Cleaner", "ml", "volume", "Cleaning Shelf", 500.0, [500.0, 1000.0, 2000.0], ["Floor Cleaner", "Lizol Citrus", "Pocha Liquid"], ["Lizol", "Dettol", "Colin", "Nimyle"]),
    ("floor_cleaner_herbal_neem_nimyle", "Herbal Neem Natural Floor Cleaner", "வேப்பிலை தரை சுத்தப்படுத்தி", "Floor Cleaner", "ml", "volume", "Cleaning Shelf", 1000.0, [1000.0, 2000.0], ["Neem Floor Cleaner", "Nimyle Herbal"], ["Nimyle", "Patanjali"]),
    ("toilet_cleaner_liquid_thick_power", "Thick Disinfectant Power Toilet Cleaner", "கழிப்பறை சுத்தப்படுத்தி", "Toilet Cleaner", "ml", "volume", "Bathroom Shelf", 500.0, [500.0, 1000.0], ["Toilet Cleaner", "Harpic Blue", "Toilet Acid Safe"], ["Harpic", "Domex"]),
    ("bathroom_tile_cleaner_liquid", "Bathroom Wall & Floor Tile Cleaner Liquid", "குளியலறை டைல்ஸ் கிளீனர்", "Tile Cleaner", "ml", "volume", "Bathroom Shelf", 500.0, [500.0, 1000.0], ["Bathroom Cleaner", "Harpic Red", "Tile Cleaner"], ["Harpic", "Cif"]),
    ("glass_cleaner_spray_colin", "Glass and Shiny Surfaces Cleaner Spray", "கண்ணாடி துடைக்கும் ஸ்ப்ரே", "Glass Cleaner", "ml", "volume", "Cleaning Shelf", 500.0, [500.0, 1000.0], ["Glass Cleaner", "Colin Spray", "Window Cleaner"], ["Colin", "Dettol", "Mr Muscle"]),
    ("kitchen_degreaser_spray_oil_stain", "Kitchen Oil & Grease Cleaner Spray", "சமையலறை எண்ணெய் கறை நீக்கி", "Degreaser", "ml", "volume", "Kitchen Cabinet", 500.0, [500.0], ["Kitchen Degreaser", "Chimney Cleaner Spray"], ["Cif", "Mr Muscle", "Colin"]),
    ("drain_cleaner_crystals_powder", "Instant Sink & Drain Declogger Crystals", "குழாய் அடைப்பு நீக்கும் பவுடர்", "Drain Cleaner", "g", "weight", "Utility Shelf", 50.0, [50.0, 100.0], ["Drain Cleaner", "Kiwi Dranex", "Drain Declogger"], ["Dranex", "Mr Muscle"]),
    ("mosquito_vaporiser_liquid_refill", "Liquid Mosquito Vaporiser Refill Bottle", "கொசு திரவ ரீஃபில்", "Mosquito Repellent", "piece", "package", "Utility Shelf", 1.0, [1.0, 2.0, 4.0], ["Mosquito Refill", "All Out Refill", "Good Knight Liquid"], ["Good knight", "All Out", "Mortein"]),
    ("mosquito_vaporiser_machine_with_refill", "Mosquito Repellent Vaporiser Machine with Refill", "கொசு விரட்டும் மெஷின் + ரீஃபில்", "Repellent Machine", "piece", "piece", "Utility Shelf", 1.0, [1.0], ["Mosquito Machine", "Good Knight Machine"], ["Good knight", "All Out"]),
    ("mosquito_coils_spiral_pack", "Fast Action Spiral Mosquito Coils", "கொசு சுருள்", "Mosquito Coil", "piece", "package", "Utility Shelf", 10.0, [10.0], ["Mosquito Coils", "Kachhua Chhap Coil"], ["Good knight", "Mortein", "Comfort"]),
    ("flying_insect_killer_spray", "Instant Flying Insect & Mosquito Killer Spray", "பூச்சி விரட்டும் ஸ்ப்ரே", "Insecticide", "ml", "volume", "Cleaning Shelf", 400.0, [250.0, 400.0], ["Hit Spray", "Mosquito Spray", "Kaala Hit"], ["Hit", "Mortein", "Baygon"]),
    ("cockroach_killer_gel_syringe", "Cockroach Control Nest Elimination Bait Gel", "கரப்பான் பூச்சி ஜெல்", "Pest Control", "g", "weight", "Utility Shelf", 20.0, [20.0, 40.0], ["Cockroach Gel", "Red Hit Gel", "Lal Hit Syringe"], ["Hit", "Godrej"]),
    ("cockroach_chalk_line", "Cockroach Repellent Insecticide Chalk", "கரப்பான் பூச்சி சாக்பீஸ்", "Pest Control", "piece", "piece", "Utility Shelf", 1.0, [1.0, 2.0], ["Laxman Rekha", "Cockroach Chalk"], ["Laxman Rekha", "Hit"]),
    ("naphthalene_balls_white_camphor", "Pure White Naphthalene Moth Balls", "நாப்தலீன் ரச கற்பூரம் உருண்டை", "Moth Repellent", "g", "weight", "Wardrobe Shelf", 100.0, [100.0, 200.0, 500.0], ["Naphthalene Balls", "Moth Balls", "Kapoor Goli"], ["Tiger", "Odonil", "Bengal Chemicals"]),
    ("air_freshener_pocket_bathroom", "Long Lasting Bathroom Air Freshener Gel Pocket", "பாத்ரூம் ஏர் ஃப்ரெஷ்னர் பாக்கெட்", "Air Freshener", "piece", "piece", "Bathroom Shelf", 1.0, [1.0, 3.0, 5.0], ["Air Freshener Pocket", "Odonil Block", "Godrej Aer Pocket"], ["Godrej aer", "Odonil", "Ambi Pur"])
]

for item_id, name, tamil, ptype, unit, sold_by, loc, min_q, q_list, common, brands in surface_data:
    add(item_id, name, tamil, "Household & Cleaning", "Surface Cleaners & Pest Control", ptype, unit, sold_by, loc, min_q, q_list, common, [c.lower() for c in common], brands, True, "EAN_13", False, True, "cleaning")

# --- PAPER PRODUCTS & DISPOSABLES ---
paper_data = [
    ("toilet_paper_rolls_pack_4", "Soft 2-Ply Toilet Paper Rolls (Pack of 4)", "டாய்லெட் பேப்பர் ரோல் (4 எண்ணிக்கை)", "Toilet Paper", "piece", "package", "Bathroom Shelf", 4.0, [4.0, 6.0, 12.0], ["Toilet Paper", "Toilet Roll 4s", "Bathroom Tissue"], ["Origami", "Paseo", "Premier", "Selpak"]),
    ("kitchen_paper_towel_rolls_pack_2", "Absorbent 2-Ply Kitchen Paper Towel Rolls (Pack of 2)", "கிச்சன் பேப்பர் டவல் ரோல் (2 எண்ணிக்கை)", "Paper Towel", "piece", "package", "Kitchen Shelf", 2.0, [2.0, 4.0], ["Kitchen Towel Roll", "Kitchen Paper", "Origami Towel"], ["Origami", "Premier", "Paseo"]),
    ("facial_tissue_box_200_pulls", "Soft 2-Ply Facial Tissue Box (200 Pulls)", "ஃபேசியல் டிஷ்யூ பாக்ஸ்", "Facial Tissue", "piece", "package", "Living Room Shelf", 1.0, [1.0, 2.0], ["Facial Tissue Box", "Tissue Box", "Car Tissue"], ["Origami", "Premier", "Paseo"]),
    ("aluminium_foil_roll_18m", "Heavy Duty Food Grade Aluminium Foil (18 Metres)", "அலுமினியம் ஃபாயில் ரோல்", "Foil", "piece", "piece", "Kitchen Drawer", 1.0, [1.0, 2.0], ["Aluminium Foil", "Food Foil Roll", "Hindalco Freshwrap"], ["Freshwrapp", "Origami", "Hindalco"]),
    ("baking_parchment_butter_paper_roll", "Non-Stick Food Grade Parchment / Butter Paper Roll", "பட்டர் பேப்பர் ரோல்", "Butter Paper", "piece", "piece", "Kitchen Drawer", 1.0, [1.0], ["Butter Paper Roll", "Baking Paper", "Parchment Paper"], ["Oddy Uniwraps", "Origami"]),
    ("food_wrap_cling_film_30m", "Food Grade Stretchable Cling Wrap Film (30 Metres)", "க்ளிங் ஃபிலிம் ரோல்", "Cling Wrap", "piece", "piece", "Kitchen Drawer", 1.0, [1.0], ["Cling Wrap", "Food Wrap Film", "Stretch Wrap"], ["Origami", "Freshwrapp"]),
    ("garbage_bags_medium_pack_30", "Biodegradable Garbage Trash Bags Medium 19x21 Inches (Pack of 30)", "குப்பை பை - மீடியம் (30 எண்ணிக்கை)", "Garbage Bag", "piece", "package", "Utility Shelf", 30.0, [30.0, 60.0], ["Garbage Bags Medium", "Trash Bags", "Dustbin Bags"], ["Shalimar", "Origami", "Presto!"]),
    ("garbage_bags_large_pack_30", "Biodegradable Garbage Trash Bags Large 24x32 Inches (Pack of 30)", "குப்பை பை - லார்ஜ் (30 எண்ணிக்கை)", "Garbage Bag", "piece", "package", "Utility Shelf", 30.0, [30.0, 60.0], ["Garbage Bags Large", "Dustbin Bags Large"], ["Shalimar", "Origami", "Presto!"]),
    ("paper_napkins_serviettes_pack_100", "Table Paper Napkins / Dinner Serviettes (Pack of 100)", "பேப்பர் நாப்கின் (100 எண்ணிக்கை)", "Paper Napkin", "piece", "package", "Dining Table", 100.0, [100.0, 200.0], ["Paper Napkins", "Table Tissues", "Serviettes"], ["Origami", "Premier", "Paseo"])
]

for item_id, name, tamil, ptype, unit, sold_by, loc, min_q, q_list, common, brands in paper_data:
    add(item_id, name, tamil, "Household & Cleaning", "Paper & Disposables", ptype, unit, sold_by, loc, min_q, q_list, common, [c.lower() for c in common], brands, True, "EAN_13", False, True, "cleaning")

# --- POOJA ESSENTIALS ---
pooja_data = [
    ("pure_camphor_tablets_round", "Pure White Pooja Camphor Tablets", "பூஜை கற்பூரம்", "Camphor", "g", "weight", "Pooja Shelf", 100.0, [50.0, 100.0, 250.0, 500.0], ["Karpooram", "Kapoor Tablets", "Pure Camphor"], ["Mangaldeep", "Cycle", "CamPure", "Local"]),
    ("edible_pachai_karpooram", "Pure Natural Pachai Karpooram / Edible Green Camphor", "பச்சைக் கற்பூரம்", "Camphor", "g", "weight", "Pooja Shelf", 25.0, [25.0, 50.0, 100.0], ["Pachai Karpooram", "Bhimseni Kapoor", "Edible Camphor"], ["CamPure", "Cycle", "Aura"]),
    ("agarbatti_incense_sticks_sandalwood", "Premium Sandalwood Agarbatti Incense Sticks", "சந்தன ஊதுபத்தி", "Agarbatti", "piece", "package", "Pooja Shelf", 1.0, [1.0, 2.0, 5.0], ["Agarbatti", "Sandal Incense Sticks", "Udhubathi"], ["Cycle Pure", "Mangaldeep", "Zed Black", "Moksh"]),
    ("agarbatti_incense_sticks_mogra_jasmine", "Fragrant Mogra Jasmine Agarbatti Incense Sticks", "மல்லிகை ஊதுபத்தி", "Agarbatti", "piece", "package", "Pooja Shelf", 1.0, [1.0, 2.0], ["Mogra Agarbatti", "Jasmine Incense Sticks"], ["Cycle Pure", "Mangaldeep"]),
    ("computer_sambrani_cups_dhoop", "Ready-to-Light Computer Sambrani Cups", "கம்ப்யூட்டர் சாம்பிராணி கப்", "Sambrani", "piece", "package", "Pooja Shelf", 12.0, [12.0, 24.0], ["Sambrani Cups", "Dhoop Cups", "Guggul Cups"], ["Cycle Pure", "Mangaldeep", "Om Shanthi"]),
    ("paal_sambrani_crystals_resin", "Traditional Paal Sambrani Natural Resin Crystals", "பால் சாம்பிராணி கல்", "Sambrani", "g", "weight", "Pooja Shelf", 100.0, [100.0, 200.0], ["Paal Sambrani", "Benzoin Resin Crystals"], ["Local Artisans", "Om Shanthi"]),
    ("pooja_oil_panchadeepam_blend", "Panchadeepam Pooja Deepam Oil (5 Sacred Oils)", "பஞ்சதீபம் பூஜை எண்ணெய்", "Pooja Oil", "ml", "volume", "Pooja Shelf", 1000.0, [500.0, 1000.0], ["Panchadeepam Oil", "Deepam Oil", "Pooja Oil"], ["Deepam", "Anandam", "Om Shanthi", "Sastha"]),
    ("cotton_wicks_long_neela_thiri", "Pure Long Cotton Deepam Wicks / Neela Thiri", "நீள பஞ்சு திரி", "Wicks", "piece", "package", "Pooja Shelf", 100.0, [100.0, 200.0], ["Neela Thiri", "Long Cotton Wicks", "Diya Batti"], ["Cycle Pure", "Om Shanthi", "Local"]),
    ("cotton_wicks_flower_round_thamarai", "Round Flower Cotton Wicks / Thamarai Thiri", "தாமரை பஞ்சு திரி", "Wicks", "piece", "package", "Pooja Shelf", 100.0, [100.0, 200.0], ["Poo Thiri", "Flower Cotton Wicks", "Round Diya Wicks"], ["Cycle Pure", "Om Shanthi"]),
    ("pure_thazhampoo_kumkum_red", "Traditional Thazhampoo Red Kumkum / Kungumam", "தாழம்பூ குங்குமம்", "Kumkum", "g", "weight", "Pooja Shelf", 50.0, [50.0, 100.0], ["Kungumam", "Kumkum", "Sindoor"], ["Gopuram", "Cycle Pure", "Sri Vijayalakshmi"]),
    ("pure_vibhuti_thiruneeru_holy_ash", "Pure Thiruchendur Vibhuti / Holy Ash", "திருநீறு / விபூதி", "Vibhuti", "g", "weight", "Pooja Shelf", 100.0, [50.0, 100.0, 200.0], ["Vibhuti", "Thiruneeru", "Bhasma"], ["Gopuram", "Aravindh", "Local"]),
    ("pure_sandal_paste_chandanam_tablets", "Pure Sandalwood Chandanam Tablets", "சந்தன மாத்திரை", "Sandalwood", "g", "weight", "Pooja Shelf", 50.0, [50.0, 100.0], ["Chandanam", "Sandal Paste Tablet", "Chandan"], ["Gopuram", "Cauvery", "Cycle"]),
    ("rose_water_fragrant_panneer", "Pure Fragrant Rose Water / Panneer", "வாசனை பன்னீர்", "Rose Water", "ml", "volume", "Pooja Shelf", 200.0, [100.0, 200.0, 500.0], ["Panneer", "Gulab Jal", "Rose Water Pooja"], ["Dabur", "Gopuram", "Patanjali"]),
    ("safety_matchbox_bundle_10s", "Safety Matchbox Bundle (Pack of 10 Boxes)", "தீப்பெட்டி கட்டு (10 எண்ணிக்கை)", "Matches", "piece", "package", "Pooja Shelf", 10.0, [10.0, 20.0], ["Matchbox", "Theepetti", "Safety Matches"], ["Homelite", "AIM", "WIMCO"])
]

for item_id, name, tamil, ptype, unit, sold_by, loc, min_q, q_list, common, brands in pooja_data:
    add(item_id, name, tamil, "Pooja & Spiritual", "Pooja Essentials", ptype, unit, sold_by, loc, min_q, q_list, common, [c.lower() for c in common], brands, True, "EAN_13", False, True, "pooja")

# --- PERSONAL CARE, BATH & ORAL HYGIENE ---
personal_data = [
    ("mysore_sandal_soap_grade_1", "Mysore Sandal Pure Sandalwood Oil Soap Grade 1", "மைசூர் சாண்டல் சோப்", "Bath Soap", "g", "weight", "Bathroom Shelf", 125.0, [75.0, 125.0, 150.0], ["Mysore Sandal Soap", "Sandal Soap"], ["Mysore Sandal"]),
    ("medimix_ayurvedic_18_herbs_soap", "Medimix Ayurvedic 18 Herbs Classic Green Soap", "மேடிமிக்ஸ் மூலிகை சோப்", "Bath Soap", "g", "weight", "Bathroom Shelf", 125.0, [75.0, 125.0], ["Medimix Soap", "Ayurvedic Soap"], ["Medimix"]),
    ("dettol_antiseptic_bathing_soap", "Dettol Original Germ Protection Bathing Soap", "டெட்டால் ஆன்டிசெப்டிக் சோப்", "Bath Soap", "g", "weight", "Bathroom Shelf", 125.0, [75.0, 125.0], ["Dettol Soap", "Antiseptic Soap"], ["Dettol"]),
    ("pears_pure_gentle_glycerine_soap", "Pears Pure & Gentle Amber Glycerine Soap", "பியர்ஸ் கிளிசரின் சோப்", "Bath Soap", "g", "weight", "Bathroom Shelf", 125.0, [75.0, 125.0], ["Pears Soap", "Glycerine Soap"], ["Pears"]),
    ("dove_cream_beauty_bathing_bar", "Dove White Moisturizing Cream Beauty Bathing Bar", "டவ் மாய்ஸ்ச்சரைசிங் சோப்", "Bath Soap", "g", "weight", "Bathroom Shelf", 100.0, [100.0, 125.0], ["Dove Soap", "Beauty Bar"], ["Dove"]),
    ("liquid_hand_wash_refill_pouch", "Germ Protection Liquid Hand Wash Refill Pouch", "ஹேண்ட் வாஷ் ரீஃபில் பாக்கெட்", "Hand Wash", "ml", "volume", "Bathroom Shelf", 750.0, [180.0, 750.0, 1500.0], ["Hand Wash Refill", "Dettol Handwash", "Lifebuoy Handwash"], ["Dettol", "Lifebuoy", "Savlon", "Palmolive"]),
    ("parachute_100_percent_pure_coconut_hair_oil", "100% Pure Coconut Hair Oil Blue Bottle", "பாரசூட் தேங்காய் எண்ணெய்", "Hair Oil", "ml", "volume", "Dressing Table", 200.0, [100.0, 200.0, 500.0, 1000.0], ["Parachute Oil", "Coconut Hair Oil", "Nariyal Tel"], ["Parachute"]),
    ("dabur_amla_hair_oil", "Dabur Amla Nourishing Herbal Hair Oil", "டாபர் ஆம்லா தலைமுடி எண்ணெய்", "Hair Oil", "ml", "volume", "Dressing Table", 200.0, [100.0, 200.0, 450.0], ["Amla Hair Oil", "Dabur Amla"], ["Dabur"]),
    ("shikakai_herbal_hair_wash_powder", "Authentic Herbal Shikakai Hair Wash Powder", "சிகைக்காய் தூள்", "Hair Cleanser", "g", "weight", "Bathroom Shelf", 200.0, [100.0, 200.0, 500.0], ["Shikakai Powder", "Herbal Hair Powder", "Meera Shikakai"], ["Meera", "Aachi", "Karthika"]),
    ("anti_dandruff_shampoo_cool_menthol", "Anti-Dandruff Cool Menthol Shampoo", "பொடுகு எதிர்ப்பு ஷாம்பு", "Shampoo", "ml", "volume", "Bathroom Shelf", 340.0, [180.0, 340.0, 650.0], ["Head and Shoulders", "Anti Dandruff Shampoo"], ["Head & Shoulders", "Clinic Plus", "Dove", "Pantene"]),
    ("colgate_strong_teeth_toothpaste", "Dental Cavity Protection Fluoride Toothpaste", "கோல்கேட் டூத்பேஸ்ட்", "Toothpaste", "g", "weight", "Bathroom Shelf", 150.0, [100.0, 150.0, 200.0, 500.0], ["Colgate Toothpaste", "Strong Teeth Toothpaste"], ["Colgate", "Pepsodent", "Close Up"]),
    ("dabur_red_ayurvedic_toothpaste", "Dabur Red Clove & Pudina Ayurvedic Toothpaste", "டாபர் ரெட் டூத்பேஸ்ட்", "Toothpaste", "g", "weight", "Bathroom Shelf", 150.0, [100.0, 150.0, 200.0], ["Dabur Red Paste", "Ayurvedic Toothpaste"], ["Dabur"]),
    ("sensodyne_fresh_mint_sensitive_paste", "Sensodyne Fresh Mint Sensitive Relief Toothpaste", "சென்சோடைன் டூத்பேஸ்ட்", "Toothpaste", "g", "weight", "Bathroom Shelf", 100.0, [75.0, 100.0, 150.0], ["Sensodyne Toothpaste", "Sensitive Teeth Paste"], ["Sensodyne"]),
    ("soft_bristle_toothbrush_pack_4", "Soft Bristle Adult Toothbrushes (Pack of 4)", "டூத் பிரஷ் (4 எண்ணிக்கை)", "Toothbrush", "piece", "package", "Bathroom Shelf", 4.0, [4.0], ["Toothbrush Pack", "Colgate Toothbrush"], ["Colgate", "Oral-B"]),
    ("copper_tongue_cleaner", "Pure Ayurvedic Copper Tongue Cleaner", "செப்பு நாக்கு வழிப்பான்", "Oral Care", "piece", "piece", "Bathroom Shelf", 1.0, [1.0, 2.0], ["Copper Tongue Cleaner", "Jibh Chholni"], ["Local", "Patanjali"]),
    ("mouthwash_cool_mint_antibacterial", "Antibacterial Cool Mint Antiseptic Mouthwash", "மவுத்வாஷ்", "Mouthwash", "ml", "volume", "Bathroom Shelf", 250.0, [250.0, 500.0], ["Mouthwash", "Listerine Cool Mint", "Colgate Plax"], ["Listerine", "Colgate Plax"])
]

for item_id, name, tamil, ptype, unit, sold_by, loc, min_q, q_list, common, brands in personal_data:
    add(item_id, name, tamil, "Personal Care & Hygiene", "Bath & Body Care", ptype, unit, sold_by, loc, min_q, q_list, common, [c.lower() for c in common], brands, True, "EAN_13", False, True, "personal_care")

# --- BABY CARE ---
baby_data = [
    ("baby_diaper_pants_medium_7_12kg", "Baby Diaper Pants Medium Size 7-12 kg", "குழந்தை டயபர் - மீடியம்", "Diapers", "piece", "package", "Baby Care Shelf", 30.0, [30.0, 54.0, 72.0], ["Baby Diapers Medium", "Pampers Medium", "MamyPoko Medium"], ["Pampers", "MamyPoko", "Huggies"]),
    ("baby_diaper_pants_large_9_14kg", "Baby Diaper Pants Large Size 9-14 kg", "குழந்தை டயபர் - லார்ஜ்", "Diapers", "piece", "package", "Baby Care Shelf", 30.0, [30.0, 50.0, 64.0], ["Baby Diapers Large", "Pampers Large"], ["Pampers", "MamyPoko", "Huggies"]),
    ("baby_wet_wipes_with_lid_72s", "Gentle Hydrating Baby Wet Wipes with Flip Lid (72 Wipes)", "குழந்தை வெட் வைப்ஸ் (72 எண்ணிக்கை)", "Baby Wipes", "piece", "package", "Baby Care Shelf", 72.0, [72.0, 144.0], ["Baby Wipes", "Himalaya Baby Wipes", "Pampers Wipes"], ["Himalaya", "Pampers", "Johnson's"]),
    ("baby_soap_gentle_nourishing", "Gentle Nourishing Baby Bath Soap", "குழந்தை குளியல் சோப்", "Baby Soap", "g", "weight", "Baby Care Shelf", 75.0, [75.0, 100.0], ["Baby Soap", "Himalaya Baby Soap", "Johnson Baby Soap"], ["Himalaya", "Johnson's", "Sebamed"]),
    ("baby_tear_free_shampoo", "Gentle Tear-Free Baby Shampoo", "குழந்தை கண்ணீரில்லா ஷாம்பு", "Baby Shampoo", "ml", "volume", "Baby Care Shelf", 200.0, [100.0, 200.0, 400.0], ["Baby Shampoo", "No More Tears Shampoo"], ["Johnson's", "Himalaya", "Sebamed"]),
    ("baby_massage_oil_almond_sesame", "Nourishing Baby Massage Oil with Almond & Sesame", "குழந்தை மசாஜ் எண்ணெய்", "Baby Oil", "ml", "volume", "Baby Care Shelf", 200.0, [100.0, 200.0], ["Baby Oil", "Baby Massage Oil"], ["Himalaya", "Johnson's", "Dabur Lal Tail"]),
    ("baby_rash_cream_zinc_oxide", "Soothing Zinc Oxide Diaper Rash Cream", "குழந்தை டயபர் ரேஷ் கிரீம்", "Baby Cream", "g", "weight", "Baby Care Shelf", 50.0, [50.0, 100.0], ["Diaper Rash Cream", "Rash Relief Cream"], ["Himalaya", "Sebamed", "SebaMed"]),
    ("gripe_water_ayurvedic_digestion", "Ayurvedic Gripe Water for Infant Digestion & Gas", "கிரைப் வாட்டர்", "Baby Wellness", "ml", "volume", "Medicine Box", 120.0, [120.0, 150.0], ["Gripe Water", "Woodward's Gripe Water"], ["Woodward's", "Dabur"])
]

for item_id, name, tamil, ptype, unit, sold_by, loc, min_q, q_list, common, brands in baby_data:
    add(item_id, name, tamil, "Baby Care", "Baby Hygiene & Wellness", ptype, unit, sold_by, loc, min_q, q_list, common, [c.lower() for c in common], brands, True, "EAN_13", False, True, "baby_care")

# --- PET CARE & HOME UTILITY ---
utility_data = [
    ("dry_dog_food_adult_chicken_rice", "Complete Nutrition Adult Dry Dog Food Chicken & Vegetables", "பெரிய நாய் உலர் உணவு", "Dog Food", "kg", "weight", "Pet Care Shelf", 1.0, [1.0, 3.0, 10.0], ["Dog Food", "Pedigree Adult", "Dog Kibble"], ["Pedigree", "Drools", "Royal Canin"]),
    ("dry_cat_food_ocean_fish", "Dry Cat Food Adult Ocean Fish & Salmon", "பூனை உலர் உணவு", "Cat Food", "kg", "weight", "Pet Care Shelf", 1.0, [1.0, 3.0], ["Cat Food", "Whiskas Cat Food"], ["Whiskas", "Drools", "Purepet"]),
    ("aa_alkaline_batteries_pack_4", "AA 1.5V Long Lasting Alkaline Batteries (Pack of 4)", "ஏஏ பேட்டரி (4 எண்ணிக்கை)", "Batteries", "piece", "package", "Tool Drawer", 4.0, [4.0, 8.0], ["AA Batteries", "Duracell AA", "Pencil Cell"], ["Duracell", "Eveready", "Panasonic"]),
    ("aaa_alkaline_batteries_pack_4", "AAA 1.5V Long Lasting Alkaline Batteries (Pack of 4)", "ஏஏஏ பேட்டரி (4 எண்ணிக்கை)", "Batteries", "piece", "package", "Tool Drawer", 4.0, [4.0, 8.0], ["AAA Batteries", "Duracell AAA", "Remote Batteries"], ["Duracell", "Eveready", "Panasonic"]),
    ("led_bulb_9w_b22_cool_white", "Energy Saving 9W LED Light Bulb (B22 Cool Daylight)", "9 வாட் எல்இடி பல்ப்", "Lighting", "piece", "piece", "Utility Shelf", 1.0, [1.0, 2.0, 4.0], ["LED Bulb 9W", "Philips LED", "Crompton Bulb"], ["Philips", "Syska", "Crompton", "Wipro"]),
    ("pvc_insulation_tape_black", "PVC Electrical Insulation Tape Roll Black", "எலக்ட்ரிக்கல் இன்சுலேஷன் டேப்", "Hardware", "piece", "piece", "Tool Drawer", 1.0, [1.0, 2.0], ["Electrical Tape", "Black Tape", "Steelgrip Tape"], ["Steelgrip", "Anchor"]),
    ("clothes_drying_clips_pegs_pack_20", "Strong Plastic Clothes Drying Clips / Pegs (Pack of 20)", "துணி காயவைக்கும் கிளிப்புகள் (20 எண்ணிக்கை)", "Utility", "piece", "package", "Balcony Shelf", 20.0, [20.0, 40.0], ["Clothes Clips", "Drying Pegs", "Kapde Ke Clip"], ["Gala", "Presto!", "Local"]),
    ("emergency_wax_candles_pack_6", "Household Emergency White Wax Candles (Pack of 6)", "மெழுகுவர்த்தி (6 எண்ணிக்கை)", "Candles", "piece", "package", "Utility Shelf", 6.0, [6.0, 12.0], ["Emergency Candles", "White Candles"], ["Local Artisans", "Waxwell"])
]

for item_id, name, tamil, ptype, unit, sold_by, loc, min_q, q_list, common, brands in utility_data:
    cat = "Pet Care" if "dog" in item_id or "cat" in item_id else "Home Utility & Hardware"
    subcat = "Pet Food" if "dog" in item_id or "cat" in item_id else "Electrical & Utility"
    icon = "pets" if "dog" in item_id or "cat" in item_id else "hardware"
    add(item_id, name, tamil, cat, subcat, ptype, unit, sold_by, loc, min_q, q_list, common, [c.lower() for c in common], brands, True, "EAN_13", False, True, icon)

# Write out python file
json_str = json.dumps(ITEMS, ensure_ascii=False)
code = f'''#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json

"""
Expansion module for Non-Food items: Cleaning, Laundry, Paper, Pooja, Personal Care,
Baby Care, Pet Care, and Utility.
Generated with {len(ITEMS)} authentic Indian household items.
"""

_DATA = r"""{json_str}"""

def get_non_food_expansion():
    return json.loads(_DATA)

if __name__ == "__main__":
    items = get_non_food_expansion()
    print(f"Loaded {{len(items)}} non-food products.")
'''

with open("scripts/expand_non_food.py", "w", encoding="utf-8") as f:
    f.write(code)

print(f"Successfully generated scripts/expand_non_food.py with {len(ITEMS)} items.")
