"""
Fix for the products.html template to handle missing variables.
Run this script with Docker exec to update the running container.
"""

import sys
import os

# Path to the products.html file in the Docker container
TEMPLATE_FILE = '/app/lt_crm/app/templates/main/products.html'

def update_template_file():
    """Update the products.html template to handle missing variables."""
    if not os.path.exists(TEMPLATE_FILE):
        print(f"Error: Template file not found at {TEMPLATE_FILE}")
        return False
    
    # Read the current file
    with open(TEMPLATE_FILE, 'r') as f:
        content = f.read()
    
    # Find the dropdown section that uses product_columns
    start_marker = '<div tabindex="0" id="column-selector"'
    end_marker = '</div>'
    
    start_pos = content.find(start_marker)
    if start_pos == -1:
        print("Error: Could not find column selector in template")
        return False
    
    # Find the div closing tag that ends this section
    nested_level = 1
    search_pos = start_pos + len(start_marker)
    while nested_level > 0 and search_pos < len(content):
        next_open = content.find('<div', search_pos)
        next_close = content.find('</div>', search_pos)
        
        if next_open != -1 and next_open < next_close:
            nested_level += 1
            search_pos = next_open + 4
        elif next_close != -1:
            nested_level -= 1
            search_pos = next_close + 6
        else:
            break
    
    if nested_level > 0:
        print("Error: Could not find the end of column selector div")
        return False
    
    end_pos = search_pos
    
    # Replace with a safer version that checks if variables exist
    new_dropdown = '''<div tabindex="0" id="column-selector" class="dropdown-content z-[1] menu p-4 bg-base-100 shadow rounded-box w-64">
                    <h3 class="font-bold mb-2">Rodomi stulpeliai</h3>
                    <div class="form-control">
                        {% if product_columns is defined %}
                            {% for col_id, col_info in product_columns.items() %}
                            <label class="label cursor-pointer justify-start">
                                <input type="checkbox" class="checkbox checkbox-sm checkbox-primary mr-2" 
                                       data-column-id="{{ col_id }}" 
                                       {% if selected_columns is defined and col_id in selected_columns %}checked{% endif %}
                                       {% if col_id in ['sku', 'name'] %}disabled{% endif %} />
                                <span class="label-text">{{ col_info.name }}</span>
                            </label>
                            {% endfor %}
                        {% else %}
                            <!-- Default columns when product_columns is not defined -->
                            {% set default_cols = [
                                ('sku', 'SKU'),
                                ('name', 'Pavadinimas'),
                                ('category', 'Kategorija'),
                                ('price_final', 'Kaina'),
                                ('quantity', 'Likutis')
                            ] %}
                            {% for col_id, col_name in default_cols %}
                            <label class="label cursor-pointer justify-start">
                                <input type="checkbox" class="checkbox checkbox-sm checkbox-primary mr-2" 
                                       data-column-id="{{ col_id }}" 
                                       {% if col_id in ['sku', 'name'] %}disabled checked{% else %}checked{% endif %} />
                                <span class="label-text">{{ col_name }}</span>
                            </label>
                            {% endfor %}
                        {% endif %}
                    </div>
                    <div class="mt-4">
                        <button id="save-columns" class="btn btn-primary btn-sm w-full">Išsaugoti</button>
                    </div>
                </div>'''
    
    # Replace the dropdown section
    new_content = content[:start_pos] + new_dropdown + content[end_pos:]
    
    # Also fix the table headers section
    headers_start = new_content.find('<th>Pavadinimas</th>')
    if headers_start != -1:
        headers_end = new_content.find('<th>Veiksmai</th>', headers_start)
        if headers_end != -1:
            dynamic_headers_section = '''<th>Pavadinimas</th>
                        {% if selected_columns is defined %}
                            {% for col in selected_columns %}
                            {% if col not in ['sku', 'name'] %}
                            <th>{{ product_columns[col]['name'] if product_columns is defined and col in product_columns else col|capitalize }}</th>
                            {% endif %}
                            {% endfor %}
                        {% else %}
                            <th>Kategorija</th>
                            <th>Kaina</th>
                            <th>Likutis</th>
                        {% endif %}'''
            
            new_content = new_content[:headers_start] + dynamic_headers_section + new_content[headers_end:]
    
    # Fix the table body section
    body_start = new_content.find('{% for col in selected_columns %}')
    if body_start != -1:
        nested_level = 1
        search_pos = body_start + 10
        while nested_level > 0 and search_pos < len(new_content):
            next_for = new_content.find('{% for', search_pos)
            next_endfor = new_content.find('{% endfor %}', search_pos)
            
            if next_for != -1 and next_for < next_endfor:
                nested_level += 1
                search_pos = next_for + 7
            elif next_endfor != -1:
                nested_level -= 1
                search_pos = next_endfor + 12
            else:
                break
        
        if search_pos < len(new_content):
            body_end = search_pos
            
            dynamic_body_section = '''{% if selected_columns is defined %}
                            {% for col in selected_columns %}
                            {% if col not in ['sku', 'name'] %}
                            <td>
                                {% if col == 'category' %}
                                    {{ product.category or '-' }}
                                {% elif col == 'barcode' %}
                                    {{ product.barcode or '-' }}
                                {% elif col == 'price_final' %}
                                    <div class="font-semibold">{{ product.price_final|euro }}</div>
                                {% elif col == 'price_old' %}
                                    <div class="text-xs line-through opacity-60">{{ product.price_old|euro if product.price_old else '-' }}</div>
                                {% elif col == 'quantity' %}
                                    <span class="badge {% if product.quantity > 10 %}badge-success{% elif product.quantity > 0 %}badge-warning{% else %}badge-error{% endif %}">
                                        {{ product.quantity }} vnt.
                                    </span>
                                {% elif col == 'manufacturer' %}
                                    {{ product.manufacturer or '-' }}
                                {% elif col == 'model' %}
                                    {{ product.model or '-' }}
                                {% elif col == 'delivery_days' %}
                                    {{ product.delivery_days or '-' }} d.
                                {% elif col == 'warranty_months' %}
                                    {{ product.warranty_months or '-' }} mėn.
                                {% elif col == 'weight_kg' %}
                                    {{ product.weight_kg or '-' }} kg
                                {% else %}
                                    {{ getattr(product, col, '-') }}
                                {% endif %}
                            </td>
                            {% endif %}
                            {% endfor %}
                        {% else %}
                            <!-- Default columns when product_columns is not defined -->
                            <td>{{ product.category or '-' }}</td>
                            <td><div class="font-semibold">{{ product.price_final|euro }}</div></td>
                            <td>
                                <span class="badge {% if product.quantity > 10 %}badge-success{% elif product.quantity > 0 %}badge-warning{% else %}badge-error{% endif %}">
                                    {{ product.quantity }} vnt.
                                </span>
                            </td>
                        {% endif %}'''
            
            new_content = new_content[:body_start] + dynamic_body_section + new_content[body_end:]
    
    # Write the updated file
    with open(TEMPLATE_FILE, 'w') as f:
        f.write(new_content)
    
    print("Successfully updated the products template!")
    return True

if __name__ == "__main__":
    sys.exit(0 if update_template_file() else 1) 