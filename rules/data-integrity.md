# Data Integrity -- Rules Template

Copy this file into your project's `.claude/rules/` directory and fill in the project-specific mechanism.

## Invariants

- New fields added to any persisted data format MUST be backward-compatible. Data produced by previous versions must still load without error.
- Schema changes (database migrations, serialization format changes, API response changes) must be additive. Remove fields only after all consumers have stopped reading them.
- User data must never be silently lost or corrupted by an upgrade, migration, or format change.

## Project-Specific Mechanism

<!--
Fill in how your project achieves backward compatibility. Examples:

- Swift Codable: use `decodeIfPresent` with a fallback default for every new field.
  Add a custom `init(from:)` if the auto-synthesized one would require the new key.
- Database (SQL): Alembic/Flyway migrations. New columns are nullable or have defaults.
  Drop columns only in a migration AFTER the code no longer reads them.
- API responses: new fields are additive. Removed fields go through a deprecation
  period with the old key still present.
- File formats: version header in the file. Reader handles all known versions.
-->

## How to Apply

- Before adding a field to any model that is serialized, persisted, or sent over the wire: verify that old data without the field still loads.
- Before removing a field: verify that no consumer still reads it. For APIs, this means checking all client versions in the wild.
- Test deserialization against fixture data that does NOT contain the new field before shipping.

## Common Mistakes

- Adding a required field to a serialized model (old data fails to decode)
- Dropping a database column in the same deploy that removes the code reading it
- Changing a JSON key name without supporting both old and new keys during transition
- Assuming all clients update simultaneously (mobile apps have version skew)
