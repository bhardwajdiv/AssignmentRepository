# Relationship Manager Component

This custom Moqui component implements the assignment requirements for party data modeling, relationships, roles, contact mechanisms, and sample college data.

## Included functionality

- `relationshipmgr.Party`, `relationshipmgr.Person`, `relationshipmgr.Organization`
- `relationshipmgr.PartyRole` for party role association
- `relationshipmgr.PartyRelationship` for relationships between parties
- `relationshipmgr.ContactMech`, `relationshipmgr.PostalAddress`, `relationshipmgr.TelecomNumber`
- `relationshipmgr.PartyContactMech` to link parties with contact mechanisms
- `relationshipmgr.PartyClassification` for party classifications
- Seeded sample data for a college, department, students, and staff
- Contact mechanism samples with email, phone, and postal address
- Web UI at `Relationship Manager` app menu for creating parties, roles, relationships, and contact information

## How to use

1. Start Moqui.
2. Open the `Relationship Manager` screen from the app menu.
3. Create parties, person/organization details, roles, and relationships.
4. Add contact mechanisms and link them to parties using the built-in forms.

## Notes

- The component is available under `component://relationshipmgr`.
- Screens are registered in `MoquiConf.xml`.
- Seed data is stored in `data/RelationshipSeedData.xml`.
