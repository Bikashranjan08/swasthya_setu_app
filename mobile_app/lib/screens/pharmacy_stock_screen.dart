
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:mobile_app/screens/cart_screen.dart';

// Data model for a medicine
class Medicine {
  final int id;
  final String name;
  final String brand;
  final bool isPrescription;
  final String description;
  final List<String> categories;
  final String stockStatus;
  final double price;
  final String location;
  final String dosage;
  final String expires;
  final String sideEffects;
  final String drugInteractions;

  Medicine({
    required this.id,
    required this.name,
    required this.brand,
    required this.isPrescription,
    required this.description,
    required this.categories,
    required this.stockStatus,
    required this.price,
    required this.location,
    required this.dosage,
    required this.expires,
    required this.sideEffects,
    required this.drugInteractions,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      isPrescription: json['isPrescription'],
      description: json['description'],
      categories: List<String>.from(json['categories']),
      stockStatus: json['stockStatus'],
      price: json['price'].toDouble(),
      location: json['location'],
      dosage: json['dosage'],
      expires: json['expires'],
      sideEffects: json['sideEffects'],
      drugInteractions: json['drugInteractions'],
    );
  }
}

class PharmacyStockScreen extends StatefulWidget {
  const PharmacyStockScreen({super.key});

  @override
  _PharmacyStockScreenState createState() => _PharmacyStockScreenState();
}

class _PharmacyStockScreenState extends State<PharmacyStockScreen> {
  final List<Medicine> _cartItems = [];
  String _searchQuery = '';
  String _selectedCategory = 'All Medicines';
  String _sortOption = 'Sort by Name (A-Z)';
  bool _prescriptionOnly = false;

  final List<Medicine> _medicines = sampleMedicines;

  List<Medicine> get _filteredAndSortedMedicines {
    List<Medicine> filtered = _medicines;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((m) =>
              m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              m.brand.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Category filter
    if (_selectedCategory != 'All Medicines') {
      filtered = filtered
          .where((m) => m.categories.contains(_selectedCategory))
          .toList();
    }

    // Prescription filter
    if (_prescriptionOnly) {
      filtered = filtered.where((m) => m.isPrescription).toList();
    }

    // Sorting
    switch (_sortOption) {
      case 'Sort by Name (A-Z)':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Sort by Price (Low to High)':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Sort by Stock':
        filtered.sort((a, b) => _stockStatusValue(a.stockStatus)
            .compareTo(_stockStatusValue(b.stockStatus)));
        break;
      case 'Sort by Expiry':
        filtered.sort((a, b) => a.expires.compareTo(b.expires));
        break;
    }

    return filtered;
  }

  int _stockStatusValue(String status) {
    switch (status) {
      case 'In Stock':
        return 0;
      case 'Limited':
        return 1;
      case 'Low Stock':
        return 2;
      case 'Out of Stock':
        return 3;
      default:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Stock'),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(cartItems: _cartItems),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart),
                  const SizedBox(width: 5),
                  Text('Cart (${_cartItems.length})'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildCategoryFilters(),
          _buildSortingAndPrescriptionControls(),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredAndSortedMedicines.length,
              itemBuilder: (context, index) {
                final medicine = _filteredAndSortedMedicines[index];
                return MedicineCard(
                  medicine: medicine,
                  onAddToCart: () {
                    setState(() {
                      _cartItems.add(medicine);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        'Find and manage medicines available in your inventory',
        style: TextStyle(fontSize: 16, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: const InputDecoration(
          hintText: 'Search by name or brand...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = [
      'All Medicines', 'Pain Relief', 'Fever', 'Cold & Flu', 'Digestive',
      'Cardiac', 'Diabetic', 'Antibiotic', 'Vitamins', 'Skin Care'
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text(category),
                selected: _selectedCategory == category,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategory = category;
                    }
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSortingAndPrescriptionControls() {
    final sortOptions = [
      'Sort by Name (A-Z)', 'Sort by Price (Low to High)',
      'Sort by Stock', 'Sort by Expiry'
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<String>(
            value: _sortOption,
            onChanged: (String? newValue) {
              setState(() {
                _sortOption = newValue!;
              });
            },
            items: sortOptions.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          Row(
            children: [
              const Text('Rx Only'),
              Switch(
                value: _prescriptionOnly,
                onChanged: (value) {
                  setState(() {
                    _prescriptionOnly = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onAddToCart;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopSection(),
            const SizedBox(height: 12),
            _buildDetailsSection(),
            const SizedBox(height: 12),
            _buildActionSection(),
            const Divider(height: 24),
            _buildFooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                medicine.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (medicine.isPrescription)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Rx',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
        Text(
          'Brand: ${medicine.brand}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(medicine.description),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6.0,
          runSpacing: 4.0,
          children: medicine.categories.map((category) {
            return Chip(
              label: Text(category),
              backgroundColor: Colors.blue.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        _buildStockStatus(),
        const SizedBox(height: 8),
        Text(
          '₹${medicine.price.toStringAsFixed(2)} per unit',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(medicine.location, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildStockStatus() {
    Color dotColor;
    switch (medicine.stockStatus) {
      case 'In Stock':
        dotColor = Colors.green;
        break;
      case 'Limited':
        dotColor = Colors.yellow;
        break;
      case 'Low Stock':
        dotColor = Colors.orange;
        break;
      case 'Out of Stock':
        dotColor = Colors.red;
        break;
      default:
        dotColor = Colors.grey;
    }
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(medicine.stockStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionSection() {
    bool isOutOfStock = medicine.stockStatus == 'Out of Stock';
    return Center(
      child: ElevatedButton(
        onPressed: isOutOfStock ? null : onAddToCart,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutOfStock ? Colors.grey : Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(isOutOfStock ? 'Out of Stock' : 'Add to Cart'),
      ),
    );
  }

  Widget _buildFooterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFooterRow('Dosage', medicine.dosage),
        _buildFooterRow('Expires', medicine.expires),
        _buildFooterRow('Side Effects', medicine.sideEffects),
        _buildFooterRow('Drug Interactions', medicine.drugInteractions),
      ],
    );
  }

  Widget _buildFooterRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// Sample Data
final List<Medicine> sampleMedicines = [
  {
    "id": 1,
    "name": "Acetaminophen",
    "brand": "Tylenol",
    "isPrescription": false,
    "description": "Pain reliever and fever reducer.",
    "categories": ["Pain Relief", "Fever"],
    "stockStatus": "In Stock",
    "price": 35.0,
    "location": "Walgreens - Oak Ave",
    "dosage": "500mg - every 6 hours",
    "expires": "2026-08-20",
    "sideEffects": "Rare liver damage with overdose.",
    "drugInteractions": "Avoid with alcohol."
  },
  {
    "id": 2,
    "name": "Amoxicillin",
    "brand": "Novamox",
    "isPrescription": true,
    "description": "Broad-spectrum penicillin antibiotic.",
    "categories": ["Antibiotic"],
    "stockStatus": "Limited",
    "price": 85.0,
    "location": "Apollo Pharmacy - Central Plaza",
    "dosage": "500mg - 1 capsule 3 times daily",
    "expires": "2025-06-30",
    "sideEffects": "Diarrhea, nausea, rash.",
    "drugInteractions": "Avoid with methotrexate."
  },
  {
    "id": 3,
    "name": "Lisinopril",
    "brand": "Zestril",
    "isPrescription": true,
    "description": "ACE inhibitor for high blood pressure.",
    "categories": ["Cardiac"],
    "stockStatus": "In Stock",
    "price": 120.5,
    "location": "CVS - Main St",
    "dosage": "10mg - once daily",
    "expires": "2027-01-15",
    "sideEffects": "Cough, dizziness, headache.",
    "drugInteractions": "Avoid with potassium supplements."
  },
  {
    "id": 4,
    "name": "Metformin",
    "brand": "Glucophage",
    "isPrescription": true,
    "description": "Manages blood sugar in type 2 diabetes.",
    "categories": ["Diabetic"],
    "stockStatus": "Low Stock",
    "price": 60.0,
    "location": "Rite Aid - 5th Ave",
    "dosage": "850mg - twice daily with meals",
    "expires": "2025-11-01",
    "sideEffects": "Stomach upset, diarrhea.",
    "drugInteractions": "Iodinated contrast agents."
  },
  {
    "id": 5,
    "name": "Ibuprofen",
    "brand": "Advil",
    "isPrescription": false,
    "description": "NSAID for pain, fever, and inflammation.",
    "categories": ["Pain Relief", "Fever"],
    "stockStatus": "In Stock",
    "price": 45.0,
    "location": "Walgreens - Oak Ave",
    "dosage": "200mg - every 4-6 hours",
    "expires": "2026-05-10",
    "sideEffects": "Stomach pain, heartburn.",
    "drugInteractions": "Avoid with aspirin."
  },
  {
    "id": 6,
    "name": "Cetirizine",
    "brand": "Zyrtec",
    "isPrescription": false,
    "description": "Antihistamine for allergy relief.",
    "categories": ["Cold & Flu"],
    "stockStatus": "Out of Stock",
    "price": 75.0,
    "location": "CVS - Main St",
    "dosage": "10mg - once daily",
    "expires": "2025-09-22",
    "sideEffects": "Drowsiness, dry mouth.",
    "drugInteractions": "Avoid with sedatives."
  },
  {
    "id": 7,
    "name": "Omeprazole",
    "brand": "Prilosec",
    "isPrescription": false,
    "description": "Proton-pump inhibitor for acid reflux.",
    "categories": ["Digestive"],
    "stockStatus": "Limited",
    "price": 95.0,
    "location": "Apollo Pharmacy - Central Plaza",
    "dosage": "20mg - once daily before a meal",
    "expires": "2026-12-30",
    "sideEffects": "Headache, stomach pain.",
    "drugInteractions": "Clopidogrel."
  },
  {
    "id": 8,
    "name": "Atorvastatin",
    "brand": "Lipitor",
    "isPrescription": true,
    "description": "Statin to lower cholesterol.",
    "categories": ["Cardiac"],
    "stockStatus": "In Stock",
    "price": 150.0,
    "location": "Rite Aid - 5th Ave",
    "dosage": "20mg - once daily",
    "expires": "2027-03-14",
    "sideEffects": "Muscle pain, diarrhea.",
    "drugInteractions": "Grapefruit juice."
  },
  {
    "id": 9,
    "name": "Azithromycin",
    "brand": "Zithromax",
    "isPrescription": true,
    "description": "Macrolide antibiotic for infections.",
    "categories": ["Antibiotic"],
    "stockStatus": "In Stock",
    "price": 110.0,
    "location": "Walgreens - Oak Ave",
    "dosage": "500mg - once daily for 3 days",
    "expires": "2025-08-19",
    "sideEffects": "Nausea, vomiting, diarrhea.",
    "drugInteractions": "Antacids containing aluminum."
  },
  {
    "id": 10,
    "name": "Vitamin D3",
    "brand": "Nature's Best",
    "isPrescription": false,
    "description": "Supplement for bone health.",
    "categories": ["Vitamins"],
    "stockStatus": "In Stock",
    "price": 30.0,
    "location": "CVS - Main St",
    "dosage": "1000 IU - once daily",
    "expires": "2028-01-01",
    "sideEffects": "Generally safe.",
    "drugInteractions": "Steroids."
  },
  {
    "id": 11,
    "name": "Hydrocortisone Cream",
    "brand": "Cortizone-10",
    "isPrescription": false,
    "description": "Topical steroid for skin irritation.",
    "categories": ["Skin Care"],
    "stockStatus": "Limited",
    "price": 55.0,
    "location": "Apollo Pharmacy - Central Plaza",
    "dosage": "Apply thin layer 2-3 times daily",
    "expires": "2026-04-25",
    "sideEffects": "Skin thinning with prolonged use.",
    "drugInteractions": "None significant."
  },
  {
    "id": 12,
    "name": "Guaifenesin",
    "brand": "Mucinex",
    "isPrescription": false,
    "description": "Expectorant for chest congestion.",
    "categories": ["Cold & Flu"],
    "stockStatus": "In Stock",
    "price": 65.0,
    "location": "Rite Aid - 5th Ave",
    "dosage": "600mg - every 12 hours",
    "expires": "2025-10-30",
    "sideEffects": "Dizziness, headache.",
    "drugInteractions": "No major interactions."
  },
  {
    "id": 13,
    "name": "Loperamide",
    "brand": "Imodium",
    "isPrescription": false,
    "description": "Used to treat diarrhea.",
    "categories": ["Digestive"],
    "stockStatus": "Low Stock",
    "price": 40.0,
    "location": "Walgreens - Oak Ave",
    "dosage": "4mg initially, then 2mg after each loose stool",
    "expires": "2026-07-11",
    "sideEffects": "Constipation, dizziness.",
    "drugInteractions": "Certain antibiotics."
  },
  {
    "id": 14,
    "name": "Aspirin",
    "brand": "Bayer",
    "isPrescription": false,
    "description": "Pain reliever and anti-inflammatory.",
    "categories": ["Pain Relief", "Cardiac"],
    "stockStatus": "In Stock",
    "price": 25.0,
    "location": "CVS - Main St",
    "dosage": "81mg - once daily for heart protection",
    "expires": "2027-05-20",
    "sideEffects": "Stomach upset, bleeding.",
    "drugInteractions": "Ibuprofen, blood thinners."
  },
  {
    "id": 15,
    "name": "Insulin Glargine",
    "brand": "Lantus",
    "isPrescription": true,
    "description": "Long-acting insulin for diabetes.",
    "categories": ["Diabetic"],
    "stockStatus": "Limited",
    "price": 350.0,
    "location": "Apollo Pharmacy - Central Plaza",
    "dosage": "As prescribed by doctor",
    "expires": "2025-04-15",
    "sideEffects": "Low blood sugar, injection site reactions.",
    "drugInteractions": "Beta-blockers."
  },
  {
    "id": 16,
    "name": "Ciprofloxacin",
    "brand": "Cipro",
    "isPrescription": true,
    "description": "Fluoroquinolone antibiotic.",
    "categories": ["Antibiotic"],
    "stockStatus": "In Stock",
    "price": 90.0,
    "location": "Rite Aid - 5th Ave",
    "dosage": "500mg - every 12 hours",
    "expires": "2026-02-28",
    "sideEffects": "Nausea, diarrhea, tendon rupture (rare).",
    "drugInteractions": "Theophylline, dairy products."
  },
  {
    "id": 17,
    "name": "Multivitamin",
    "brand": "Centrum",
    "isPrescription": false,
    "description": "General wellness supplement.",
    "categories": ["Vitamins"],
    "stockStatus": "Out of Stock",
    "price": 100.0,
    "location": "Walgreens - Oak Ave",
    "dosage": "1 tablet daily",
    "expires": "2027-09-01",
    "sideEffects": "Upset stomach.",
    "drugInteractions": "None significant."
  },
  {
    "id": 18,
    "name": "Clotrimazole",
    "brand": "Lotrimin",
    "isPrescription": false,
    "description": "Antifungal cream for skin infections.",
    "categories": ["Skin Care"],
    "stockStatus": "In Stock",
    "price": 60.0,
    "location": "CVS - Main St",
    "dosage": "Apply to affected area twice daily",
    "expires": "2025-12-01",
    "sideEffects": "Burning, stinging.",
    "drugInteractions": "None."
  },
  {
    "id": 19,
    "name": "Naproxen",
    "brand": "Aleve",
    "isPrescription": false,
    "description": "NSAID for pain and inflammation.",
    "categories": ["Pain Relief"],
    "stockStatus": "Limited",
    "price": 50.0,
    "location": "Apollo Pharmacy - Central Plaza",
    "dosage": "220mg - every 8-12 hours",
    "expires": "2026-10-18",
    "sideEffects": "Stomach upset, heartburn.",
    "drugInteractions": "Blood thinners."
  },
  {
    "id": 20,
    "name": "Paracetamol",
    "brand": "Crocin",
    "isPrescription": false,
    "description": "Common pain and fever reducer.",
    "categories": ["Pain Relief", "Fever"],
    "stockStatus": "In Stock",
    "price": 20.0,
    "location": "Rite Aid - 5th Ave",
    "dosage": "650mg - every 6 hours",
    "expires": "2026-08-30",
    "sideEffects": "Safe in recommended doses.",
    "drugInteractions": "Avoid with other paracetamol products."
  },
  {
    "id": 21,
    "name": "Metoprolol",
    "brand": "Lopressor",
    "isPrescription": true,
    "description": "Beta-blocker for high blood pressure and chest pain.",
    "categories": ["Cardiac"],
    "stockStatus": "In Stock",
    "price": 130.0,
    "location": "Walgreens - Oak Ave",
    "dosage": "50mg - twice daily",
    "expires": "2027-02-20",
    "sideEffects": "Fatigue, dizziness.",
    "drugInteractions": "Digoxin, verapamil."
  },
  {
    "id": 22,
    "name": "Sitagliptin",
    "brand": "Januvia",
    "isPrescription": true,
    "description": "DPP-4 inhibitor for type 2 diabetes.",
    "categories": ["Diabetic"],
    "stockStatus": "Low Stock",
    "price": 280.0,
    "location": "CVS - Main St",
    "dosage": "100mg - once daily",
    "expires": "2025-07-25",
    "sideEffects": "Headache, stuffy nose.",
    "drugInteractions": "Digoxin."
  },
  {
    "id": 23,
    "name": "Doxycycline",
    "brand": "Vibramycin",
    "isPrescription": true,
    "description": "Tetracycline antibiotic for various infections.",
    "categories": ["Antibiotic"],
    "stockStatus": "In Stock",
    "price": 95.0,
    "location": "Apollo Pharmacy - Central Plaza",
    "dosage": "100mg - twice daily",
    "expires": "2026-01-10",
    "sideEffects": "Sun sensitivity, nausea.",
    "drugInteractions": "Antacids, iron supplements."
  },
  {
    "id": 24,
    "name": "Vitamin C",
    "brand": "Limcee",
    "isPrescription": false,
    "description": "Immune system support.",
    "categories": ["Vitamins"],
    "stockStatus": "In Stock",
    "price": 35.0,
    "location": "Rite Aid - 5th Ave",
    "dosage": "500mg - once daily",
    "expires": "2027-11-11",
    "sideEffects": "High doses can cause stomach upset.",
    "drugInteractions": "Estrogens."
  },
  {
    "id": 25,
    "name": "Salicylic Acid Cleanser",
    "brand": "Neutrogena",
    "isPrescription": false,
    "description": "Facial cleanser for acne.",
    "categories": ["Skin Care"],
    "stockStatus": "Limited",
    "price": 150.0,
    "location": "Walgreens - Oak Ave",
    "dosage": "Use twice daily",
    "expires": "2026-06-01",
    "sideEffects": "Dryness, peeling.",
    "drugInteractions": "Other topical acne products."
  },
  {
    "id": 26,
    "name": "Pseudoephedrine",
    "brand": "Sudafed",
    "isPrescription": false,
    "description": "Decongestant for cold and allergy symptoms.",
    "categories": ["Cold & Flu"],
    "stockStatus": "In Stock",
    "price": 80.0,
    "location": "CVS - Main St",
    "dosage": "60mg - every 4-6 hours",
    "expires": "2025-09-15",
    "sideEffects": "Nervousness, restlessness.",
    "drugInteractions": "MAO inhibitors."
  },
  {
    "id": 27,
    "name": "Famotidine",
    "brand": "Pepcid",
    "isPrescription": false,
    "description": "H2 blocker for acid reflux and ulcers.",
    "categories": ["Digestive"],
    "stockStatus": "In Stock",
    "price": 70.0,
    "location": "Apollo Pharmacy - Central Plaza",
    "dosage": "20mg - twice daily",
    "expires": "2026-10-05",
    "sideEffects": "Headache, dizziness.",
    "drugInteractions": "Tizanidine."
  },
  {
    "id": 28,
    "name": "Tramadol",
    "brand": "Ultram",
    "isPrescription": true,
    "description": "Opioid analgesic for moderate to severe pain.",
    "categories": ["Pain Relief"],
    "stockStatus": "Low Stock",
    "price": 110.0,
    "location": "Rite Aid - 5th Ave",
    "dosage": "50mg - every 6 hours as needed",
    "expires": "2025-05-30",
    "sideEffects": "Dizziness, nausea, constipation.",
    "drugInteractions": "SSRIs, MAO inhibitors."
  },
  {
    "id": 29,
    "name": "Fexofenadine",
    "brand": "Allegra",
    "isPrescription": false,
    "description": "Antihistamine for seasonal allergies.",
    "categories": ["Cold & Flu"],
    "stockStatus": "In Stock",
    "price": 90.0,
    "location": "Walgreens - Oak Ave",
    "dosage": "180mg - once daily",
    "expires": "2027-04-12",
    "sideEffects": "Headache, back pain.",
    "drugInteractions": "Fruit juices (apple, orange, grapefruit)."
  },
  {
    "id": 30,
    "name": "Rosuvastatin",
    "brand": "Crestor",
    "isPrescription": true,
    "description": "Statin to lower cholesterol and triglycerides.",
    "categories": ["Cardiac"],
    "stockStatus": "In Stock",
    "price": 180.0,
    "location": "CVS - Main St",
    "dosage": "10mg - once daily",
    "expires": "2027-08-08",
    "sideEffects": "Muscle aches, headache.",
    "drugInteractions": "Cyclosporine, gemfibrozil."
  }
].map((e) => Medicine.fromJson(e)).toList();
