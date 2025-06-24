#!/usr/bin/env python3
"""
Debug script to test CSV parsing of extra_image_urls.
"""

import os
import sys
import pandas as pd
import json
import io

# Add the lt_crm directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'lt_crm'))

from lt_crm.app.services.import_service import try_parse_json, clean_product_dataframe

def test_full_pipeline():
    """Test the full CSV parsing pipeline."""
    
    # Sample CSV data exactly matching your format
    csv_data = '''sku,name,price_final,description,category,quantity,price_old,barcode,manufacturer,model,weight_kg,warranty_months,main_image_url,extra_image_urls,colour,colour_options
KR34-SC,Ranger + AukÅ¡ta sÄ—dynÄ—,629,<p>Description here</p>,Category,0,3499,,Galaxy,,,,,https://cdn.zyrosite.com/cdn-cgi/image/format=auto,w=600,fit=scale-down/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727525232475-421906068_842582494545344_5199539631814790937_n.jpg,"[""https://cdn.zyrosite.com/cdn-cgi/image/format=auto,w=780,h=780,fit=scale-down,q=100/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727525232475-421906068_842582494545344_5199539631814790937_n.jpg"", ""https://cdn.zyrosite.com/cdn-cgi/image/format=auto,w=64,h=64,fit=scale-down/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1727525232475-421906068_842582494545344_5199539631814790937_n.jpg"", ""https://cdn.zyrosite.com/cdn-cgi/image/format=auto,w=64,h=64,fit=scale-down/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1738005588127-IMG_8791.JPG"", ""https://cdn.zyrosite.com/cdn-cgi/image/format=auto,w=64,h=64,fit=scale-down/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1726078401145-ranger.webp"", ""https://cdn.zyrosite.com/cdn-cgi/image/format=auto,w=64,h=64,fit=scale-down/cdn-ecommerce/store_01HHQ22C8YJS266XB4SFF8BSGN%2Fassets%2F1738005588127-IMG_8792.JPG""]",Snow Camo,Snow Camo'''
    
    print("=== FULL PIPELINE TEST ===")
    
    # Step 1: Read CSV
    df = pd.read_csv(io.StringIO(csv_data))
    print(f"Step 1 - Raw CSV: Columns: {list(df.columns)}")
    print(f"Raw extra_image_urls: {repr(df.iloc[0]['extra_image_urls'])}")
    print(f"Raw type: {type(df.iloc[0]['extra_image_urls'])}")
    
    # Step 2: Clean DataFrame (this should parse JSON)
    df_cleaned = clean_product_dataframe(df)
    print(f"\nStep 2 - After cleaning:")
    print(f"Cleaned extra_image_urls: {repr(df_cleaned.iloc[0]['extra_image_urls'])}")
    print(f"Cleaned type: {type(df_cleaned.iloc[0]['extra_image_urls'])}")
    
    # Step 3: Test what happens when we iterate through the DataFrame
    print(f"\nStep 3 - DataFrame iteration:")
    for idx, row in df_cleaned.iterrows():
        extra_urls = row['extra_image_urls']
        print(f"Row iteration - extra_image_urls: {repr(extra_urls)}")
        print(f"Row iteration - type: {type(extra_urls)}")
        print(f"Row iteration - is list: {isinstance(extra_urls, list)}")
        print(f"Row iteration - is pd.NA: {pd.isna(extra_urls)}")
        
        if isinstance(extra_urls, list):
            print(f"List length: {len(extra_urls)}")
            for i, url in enumerate(extra_urls):
                print(f"  URL {i+1}: {url}")

if __name__ == "__main__":
    test_full_pipeline() 