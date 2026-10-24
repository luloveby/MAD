# Equipment in Firestore

Project: `borrowit-5e6c3`. Database: `(default)`.

Home recommendations and the equipment catalog now listen to the `equipment`
collection through `EquipmentService`. The Dart catalog is only the original
import source and a test fixture; changing it does not update live equipment.

## Manage equipment

Open Firebase Console → Firestore → Data → equipment. Documents use stable IDs
`EQ-001` through `EQ-050`. Keep those IDs when renaming products.

Each document contains the name, category, description, bundled image path,
eligible programs, recommended programs, active flag, timestamps and inventory
fields. `recommendedPrograms` determines which recommendation rows include an
item. Set `isActive` to false to hide it from the catalog without deleting it.

The ZIP did not provide real quantities. All imported records therefore have
`inventoryVerified: false`, `totalQuantity: null`, and `availableQuantity: null`.
The app displays **Check availability**, rather than inventing stock counts.

After counting actual stock, edit a document in the console, for example:

```json
{
  "totalQuantity": 5,
  "availableQuantity": 3,
  "inventoryVerified": true
}
```

These are example quantities, not imported values. Both quantities must be
integers, nonnegative, and available quantity must not exceed total quantity.
The app derives availability from verified quantities; the `catalogStatus`
field preserves the old sample value only. Do not edit `status` to manage stock.

Images remain bundled in `assets/equipment/`. No Storage bucket or billing
upgrade is required for these photos. A new image needs to be bundled with the
app before its asset path can be used. Existing bundled photos can be reused.

## Access

Signed-in students can read equipment. Client inventory writes require the
Firebase Authentication custom claim `admin: true`, with field validation.
No student account was promoted to admin. Project owners can manage records
through Firebase Console using their project permissions.

Student profile rules remain unchanged. Borrow-request processing and automatic
stock reservation are not implemented by this catalog setup. Their UI still
shows the existing coming-soon message; there are no fake approvals or reservations.

## Import and deployment tools

`scripts/equipment_seed.json` is the fixed import manifest. Do not regenerate or
reorder it to rename existing records. The importer creates missing IDs only
and does not overwrite existing documents. It uses the existing Firebase CLI
login and does not store tokens in the repository.

```powershell
node scripts/firebase_equipment.cjs inspect
node scripts/firebase_equipment.cjs test-rules
node scripts/firebase_equipment.cjs import
firebase deploy --only firestore:rules --project borrowit-5e6c3
node scripts/firebase_equipment.cjs verify
```

`inspect` backs up equipment and the currently deployed rules under the ignored
`firebase-backups/` directory. Review local rule edits before deploying them.
The rule simulations run through the Firebase Rules API without writing data.
