from lt_crm.app import create_app
from lt_crm.app.models.product import Product

app = create_app()

with app.app_context():
    products_with_html = Product.query.filter(
        Product.description_html.isnot(None),
        Product.description_html != ''
    ).all()
    
    if products_with_html:
        print(f"Found {len(products_with_html)} products with HTML descriptions:")
        for p in products_with_html:
            print(f"ID: {p.id}, Name: {p.name}, HTML length: {len(p.description_html or '')}")
    else:
        print("No products with HTML descriptions found in database")
        
    # Let's also save a test product with HTML
    test_html = """<h3><strong>RAILBLAZA Camera Boom 600 R-Lock &ndash; užfiksuokite kiekvieną akimirką i&scaron; tobuliausio kampo!</strong></h3>
<p>&nbsp;</p>
<p><strong>RAILBLAZA Camera Boom 600 R-Lock</strong> &ndash; tai <strong>inovatyvus ir universalus kameros laikiklis</strong>, leidžiantis <strong>lengvai užfiksuoti įspūdingiausias akimirkas</strong> ant vandens. Su <strong>750 mm ilgio reguliuojama strėle ir 4 reguliuojamais jungties ta&scaron;kais</strong>, galėsite nufotografuoti ar nufilmuoti veiksmą i&scaron; <strong>bet kurio kampo</strong>, be papildomos įrangos.</p>"""
    
    # Find a product to update or create one
    product = Product.query.first()
    if product:
        print(f"Updating product ID {product.id} with test HTML")
        product.description_html = test_html
        from lt_crm.app.extensions import db
        db.session.commit()
        print("Update complete. Check product details page to see if HTML renders correctly.") 