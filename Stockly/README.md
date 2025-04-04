# Stockly App - CSV Import & Sample Data

## CSV Import Feature

Stockly now supports importing inventory items in bulk using CSV files. This feature allows users to quickly add multiple products to their inventory without having to enter each item manually.

### How to Use CSV Import

1. Navigate to the Inventory tab
2. Tap the "Import" button in the toolbar (next to the barcode scanner)
3. In the CSV Import screen, you can:
   - Tap "Select CSV File" to choose your prepared CSV file
   - Tap "Get Sample CSV" to download a template file

### CSV File Format

Your CSV file must include the following columns:

**Required columns:**
- `Name` - Item name
- `Description` - Item description
- `Category` - Item category
- `SKU` - Product code/SKU (must be unique)
- `Price` - Sales unit price
- `Buy_Price` - Buy unit price
- `Stock_Quantity` - Current stock quantity
- `Min_Stock_Level` - Minimum stock level
- `Measurement_Unit` - Unit type (PCS, KG, LTR, CT, G, M, UNIT, BOX, PAIR)

**Optional columns:**
- `Tax_Rate` - Item tax rate
- `Barcode` - Item barcode

### Example CSV

```csv
Name,Description,Category,SKU,Price,Buy_Price,Stock_Quantity,Min_Stock_Level,Measurement_Unit,Tax_Rate,Barcode
"Diamond Solitaire Ring","14K Gold Diamond Solitaire Ring","Rings","BJ-R001",1299.99,750.00,5,2,PCS,7.5,"4901234567890"
"Sapphire Pendant","18K White Gold Sapphire Pendant","Pendants","BJ-P001",899.99,450.00,8,3,PCS,7.5,"4901234567891"
```

### Tips for Successful Import

- Ensure your SKUs are unique
- Quotes around text fields are recommended, especially if your text contains commas
- Valid measurement units are: PCS, KG, LTR, CT, G, M, UNIT, BOX, PAIR
- Numbers should use period (.) as decimal separator
- Categories that don't exist will be created automatically

## Brunelo Jewellers Sample Data

Stockly includes comprehensive sample data for a fictional jewelry store called "Brunelo Jewellers". This sample data provides a complete demo of the app's capabilities.

### How to Load Sample Data

1. Go to the Settings tab
2. Scroll down to the "Demo Data" section
3. Tap "Generate Brunelo Jewellers Demo Data"
4. Wait for confirmation that the data has been created

### What's Included in Sample Data

The Brunelo Jewellers sample data includes:

**Inventory Items:**
- Various jewelry products across different categories (Rings, Pendants, Necklaces, Earrings, Bracelets)
- Complete with descriptions, prices, stock levels, and other details

**Categories:**
- Rings
- Pendants
- Necklaces
- Earrings
- Bracelets
- Watches

**Clients:**
- John Smith
- Emma Johnson
- Michael Brown
- Sophia Martinez

**Suppliers:**
- Gem Source International
- Gold & Silver Supply Co
- Pacific Pearl Traders

**Invoices:**
- Three sample invoices with different statuses and items

**Estimates:**
- Two sample estimates for different clients

### Use Cases

The sample data demonstrates:
- Inventory management for a jewelry store
- Client and supplier relationships
- Invoice creation and management
- Estimate preparation and tracking

This sample data is perfect for exploring the app's features or for demonstration purposes before adding your own business data.

## Additional Help

For more detailed instructions, refer to the in-app help section:
1. Go to Settings
2. Tap "Help & User Guide"
3. Navigate to the "CSV Import" section for detailed information