# 🚀 Quick Start - OSM Address Picker

## Installation (2 minutes)

### Step 1: Get Dependencies
```bash
cd d:\magiil_mart\magiil-mart-flutter
flutter pub get
```

### Step 2: (Optional) Update Database Schema
```bash
# Open Supabase SQL Editor and run:
# Copy contents from: OSM_ADDRESS_PICKER_DB_SCHEMA.sql
```

### Step 3: Run the App
```bash
flutter run
```

---

## Usage (User Perspective)

1. **Add items to cart**
2. **Go to Checkout**
3. **Click the 🗺️ Map icon** (next to address field)
4. **Map opens** → Move to select location
5. **Address updates live** as you move the map
6. **Click "Confirm Location"** → Back to checkout
7. **Address auto-fills** → Optional manual edit
8. **Place Order** → Coordinates saved in database

---

## What Changed?

| File | Change | Status |
|------|--------|--------|
| `pubspec.yaml` | Added 4 packages | ✅ Done |
| `lib/screens/checkout/osm_address_picker.dart` | **NEW** - Full map picker | ✅ Done |
| `lib/screens/checkout_screen.dart` | Added map button & integration | ✅ Done |
| `lib/models/admin_order.dart` | Added lat/lng fields | ✅ Done |
| Supabase Schema | **OPTIONAL** - Add 2 columns | ⏳ Optional |

---

## Data Flow

```
Checkout Screen
    ↓
[User clicks Map Icon]
    ↓
OSM Address Picker Screen Opens
    ↓
[User moves map, confirms location]
    ↓
Returns: { address, lat, lng }
    ↓
Checkout updates address field
    ↓
[User places order]
    ↓
Order saved with: delivery_address, delivery_latitude, delivery_longitude
```

---

## Testing

✅ **On Checkout Screen**
- Can you see the map icon button next to address field?
- Click it → Does map appear?
- Move map → Does address update?
- Click confirm → Does it return to checkout?
- Is address field populated?
- Place order → Does it succeed?

✅ **No Regressions**
- Can you browse products? Yes
- Can you add to cart? Yes
- Can you view orders? Yes
- Can admin see orders? Yes
- Can you edit profile? Yes

---

## Dependencies Breakdown

| Package | Purpose | Size |
|---------|---------|------|
| `flutter_map` | OpenStreetMap widget | ~2MB |
| `latlong2` | Lat/Lng data type | ~100KB |
| `geocoding` | Reverse geocoding | ~500KB |
| `geolocator` | Location detection (future) | ~1MB |

**Total**: ~3.6MB (one-time download)

---

## Default Location

The map opens centered at **Delhi** (India's center).

To change, edit `lib/screens/checkout/osm_address_picker.dart` line ~44:
```dart
_selectedLocation = widget.initialLocation ?? 
    const LatLng(YOUR_LAT, YOUR_LNG);  // ← Change here
```

---

## Troubleshooting

**Q: Map is blank?**
A: Check internet connection. OSM needs network to load tiles.

**Q: "Error loading package"?**
A: Run `flutter clean` then `flutter pub get`

**Q: Address not showing?**
A: Geocoding might be slow. Wait 2-3 seconds after moving map.

**Q: Button not visible?**
A: Run `flutter pub get` and hot-reload (R key).

---

## Next Steps (Optional)

Once working, you can add:
- 📍 Auto-detect user's current location
- 🚚 Calculate delivery distance & fees
- ⏱️ Estimate delivery time
- 🗺️ Live order tracking on map

All **without affecting** the current implementation!

---

## Files to Know

- 📝 **Full Docs**: `OSM_ADDRESS_PICKER_INTEGRATION.md`
- 🗄️ **DB Schema**: `OSM_ADDRESS_PICKER_DB_SCHEMA.sql`
- 🎨 **Map Picker Code**: `lib/screens/checkout/osm_address_picker.dart`
- ✏️ **Checkout Edit**: `lib/screens/checkout_screen.dart`

---

## Support

All changes follow Flutter best practices:
- ✅ No global state pollution
- ✅ Proper resource disposal (MapController)
- ✅ Error handling for network issues
- ✅ Responsive UI (works on phones & tablets)
- ✅ Android & Web compatible

**You're ready to go!** 🎉
