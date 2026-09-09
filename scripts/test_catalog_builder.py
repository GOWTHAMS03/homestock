#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Test catalog builder to inspect product count and verify data quality.
"""

import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from normalize_existing import get_normalized_existing
from expand_food_grocery import get_food_grocery_expansion
from expand_oils_spices_condiments import get_oils_spices_condiments_expansion

existing = get_normalized_existing()
food = get_food_grocery_expansion()
oils = get_oils_spices_condiments_expansion()

print(f"Existing: {len(existing)}")
print(f"Food & Grocery: {len(food)}")
print(f"Oils & Spices: {len(oils)}")
print(f"Subtotal: {len(existing) + len(food) + len(oils)}")

