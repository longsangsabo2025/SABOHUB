## 🧪 MANUFACTURING PAGES TEST CHECKLIST

Dev Server: http://localhost:8080/

### Test Pages:

1. **Suppliers** - http://localhost:8080/manufacturing/suppliers
   - [ ] Page loads without errors
   - [ ] Can view empty table
   - [ ] "Add Supplier" button visible
   - [ ] Search/filter controls present

2. **Materials** - http://localhost:8080/manufacturing/materials
   - [ ] Page loads without errors
   - [ ] Can view empty materials list
   - [ ] Category filter works
   - [ ] Add material button present

3. **BOM** - http://localhost:8080/manufacturing/bom
   - [ ] Page loads without errors
   - [ ] BOM list displays
   - [ ] Can view BOM details
   - [ ] Add/edit BOM available

4. **Purchase Orders** - http://localhost:8080/manufacturing/purchase-orders
   - [ ] Page loads without errors
   - [ ] Order list visible
   - [ ] Status filters work
   - [ ] Create PO button works

5. **Production Orders** - http://localhost:8080/manufacturing/production-orders
   - [ ] Page loads without errors
   - [ ] Production orders list
   - [ ] Can view order details
   - [ ] Create order available

6. **Payables** - http://localhost:8080/manufacturing/payables
   - [ ] Page loads without errors
   - [ ] Payables list displays
   - [ ] Payment status visible
   - [ ] Add payable works

### Common Checks for ALL Pages:
- [ ] No console errors
- [ ] Loading states work
- [ ] Empty states show properly
- [ ] Navigation works
- [ ] User auth required

### Database Tables Verified:
✅ manufacturing_suppliers
✅ manufacturing_materials
✅ manufacturing_material_categories
✅ manufacturing_bom
✅ manufacturing_bom_items
✅ manufacturing_purchase_orders
✅ manufacturing_purchase_order_items
✅ manufacturing_production_orders
✅ manufacturing_production_materials
✅ manufacturing_payables
⚠️  manufacturing_production_output (optional - for advanced features)
⚠️  manufacturing_payable_payments (optional - for payment tracking)

### Expected Behavior:
- All pages should load successfully
- Empty tables should display with "No data" messages
- Add/Create buttons should open dialogs
- Tables should be responsive
- No 500 or database errors

### If Errors Occur:
1. Open Browser DevTools (F12)
2. Check Console tab for JavaScript errors
3. Check Network tab for API errors (400/500)
4. Screenshot and report specific error messages
