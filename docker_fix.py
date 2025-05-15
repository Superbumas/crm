#!/usr/bin/env python3
"""
Quick fix for the products page in Docker container.
This script adds conditional checks for product_columns in the template.
Copy and paste this into a Docker exec bash session.
"""

# Replace the following line with this content in the template
template_path = '/app/lt_crm/app/templates/main/products.html'

# Read the template file
with open(template_path, 'r') as f:
    content = f.read()

# Add condition checks for the product_columns variable
fixed_content = content.replace(
    '{% for col_id, col_info in product_columns.items() %}',
    '{% if product_columns is defined %}{% for col_id, col_info in product_columns.items() %}'
)

fixed_content = fixed_content.replace(
    '{% endfor %}',
    '{% endfor %}{% else %}<!-- Default columns -->{% set default_cols = [("sku", "SKU"), ("name", "Pavadinimas"), ("category", "Kategorija"), ("price_final", "Kaina"), ("quantity", "Likutis")] %}{% for col_id, col_name in default_cols %}<label class="label cursor-pointer justify-start"><input type="checkbox" class="checkbox checkbox-sm checkbox-primary mr-2" data-column-id="{{ col_id }}" {% if col_id in ["sku", "name"] %}disabled checked{% else %}checked{% endif %} /><span class="label-text">{{ col_name }}</span></label>{% endfor %}{% endif %}',
    1  # Replace only the first occurrence
)

# Fix table headers section
fixed_content = fixed_content.replace(
    '{% for col in selected_columns %}',
    '{% if selected_columns is defined %}{% for col in selected_columns %}'
)

fixed_content = fixed_content.replace(
    '{% endfor %}',
    '{% endfor %}{% else %}<th>Kategorija</th><th>Kaina</th><th>Likutis</th>{% endif %}',
    1  # Replace the first occurrence that comes after the headers section
)

# Write the fixed template back
with open(template_path, 'w') as f:
    f.write(fixed_content)

print("Fixed the products template successfully!") 