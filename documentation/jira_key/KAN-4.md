# KAN-4 — Excel Import: Klant Locaties Bulk Toevoegen

**Jira:** [KAN-4](https://icca-qualitycheck.atlassian.net/browse/KAN-4)  
**Type:** Feature Request  
**Prioriteit:** Medium  
**Component:** Oracle APEX Backend — Onderhoud module

---

## 1. Summary

Gebruikers kunnen momenteel alleen handmatig locaties aanmaken via een formulier (pagina 8022).  
Deze feature voegt een **Excel-importfunctie** toe waarmee meerdere locaties tegelijk kunnen worden aangemaakt voor een geselecteerde klant.

---

## 2. Huidige Implementatie — Analyse

### 2.1 Database

| Object | Naam | Beschrijving |
|---|---|---|
| **Tabel** | `icca_client_locations` | Hoofdtabel voor locaties |
| **Trigger** | `icca_cln_biur` | BEFORE INSERT OR UPDATE — vult `created_by`, `created_date`, `modified_by`, `modified_date` automatisch |
| **Index** | `icca_cln_cnt_id_idx` | Index op `cnt_id` |
| **Constraint** | `icca_cln_cnt_fk1` | FK naar `icca_clients(id)` |
| **Error message** | `ICCA_CLN_NAME_UK_IDX1` | "Er bestaat al een locatie met deze naam." |

### 2.2 Kolommen `icca_client_locations`

| Kolom | Type | Verplicht | Opmerking |
|---|---|---|---|
| `id` | NUMBER (identity) | Ja | PK, auto-generated |
| `cnt_id` | NUMBER | Ja | FK naar `icca_clients` |
| `name` | VARCHAR2(255) | Ja | Locatienaam |
| `location_size` | NUMBER | Ja | Omvang (m²) |
| `contact_person` | VARCHAR2(255) | Nee* | *Verplicht in APEX validatie |
| `country` | VARCHAR2(255) | Nee | Land |
| `city` | VARCHAR2(255) | Nee* | *Verplicht in APEX validatie |
| `province` | VARCHAR2(255) | Nee | Provincie |
| `street_name` | VARCHAR2(255) | Nee* | *Verplicht in APEX validatie |
| `phone_number` | VARCHAR2(255) | Nee | Telefoonnummer |
| `mobile_number` | VARCHAR2(255) | Nee | Mobiel nummer |
| `email` | VARCHAR2(4000) | Nee* | *Verplicht + regex validatie in APEX |
| `active` | VARCHAR2(1) | Ja | Default 'Y' |
| `migrated_data` | VARCHAR2(1) | Ja | Default 'N' |
| `created_date` | DATE | Ja | Via trigger |
| `created_by` | VARCHAR2(50) | Ja | Via trigger |

### 2.3 APEX Pagina's

| Pagina | Naam | Functie |
|---|---|---|
| **8021** | Onderhoud: Klant Locaties | Overzichtspagina — links klanten-lijst, rechts IR met locaties |
| **8022** | Onderhoud: Klant Locaties Form | Modal dialog — formulier voor INSERT/UPDATE/DELETE van één locatie |

### 2.4 Bestaande Validaties (pagina 8022)

1. `Contact Person cannot be null` → ITEM_NOT_NULL
2. `City cannot be null` → ITEM_NOT_NULL
3. `Street Name cannot be null` → ITEM_NOT_NULL
4. `Validate Email Format` → REGULAR_EXPRESSION: `[^\s@]+@[^\s@]+\.[^\s@]+`
5. `ICCA_CLN_NAME_UK_IDX1` → Unieke locatienaam controle (database-niveau, al verwijderd als index maar error message bestaat nog)

### 2.5 Gerelateerde objecten

- **Building size scales:** `icca_cat_buildingsize_scales` — definieert schalen (0-249, 250-499, 500+)
- **View:** `icca_cities_provinces_vw` — LOV data voor land/provincie/stad cascade selects

---

## 3. Technische Aanpak

### 3.1 Gekozen Oplossing: `apex_data_parser` + Custom PL/SQL

**Waarom `apex_data_parser`?**
- Ingebouwd in APEX 19.2+ — geen externe dependencies
- Ondersteunt `.xlsx`, `.csv`, `.xls`
- Parseert Excel naar rijen/kolommen die direct in PL/SQL verwerkt kunnen worden
- Geen Data Load Wizard nodig (die is minder flexibel voor custom validatie)

### 3.2 Architectuur

```
[Upload pagina]
     │
     ▼
[APEX File Browse item] → BLOB opslag in apex_application_temp_files
     │
     ▼
[apex_data_parser.parse()] → Parsed rijen naar collection / temp tabel
     │
     ▼
[Preview Interactive Report] → Gebruiker ziet parsed data + validatiestatus
     │
     ▼
[PL/SQL Validatie] → Per-rij validatie (verplichte velden, email, duplicaten)
     │
     ▼
[Bevestiging] → Gebruiker bevestigt import
     │
     ▼
[Bulk INSERT] → Alleen valide rijen worden ingevoegd
     │
     ▼
[Resultaat rapport] → X geslaagd, Y mislukt, details van fouten
```

### 3.3 PL/SQL Package

**Package:** `icca_location_import_pkg`

```sql
create or replace package icca_location_import_pkg
as
    -- parse excel en vul staging collection
    procedure p_parse_excel(
        p_file_blob     in blob
    ,   p_file_name     in varchar2
    ,   p_cnt_id        in number
    );

    -- valideer alle rijen in staging collection
    procedure p_validate_rows(
        p_cnt_id        in number
    );

    -- voer de import uit (alleen valide rijen)
    procedure p_execute_import(
        p_cnt_id        in number
    ,   p_inserted       out number
    ,   p_skipped        out number
    );
end icca_location_import_pkg;
```

### 3.4 Staging via APEX Collection

Gebruik `APEX_COLLECTION` met collectienaam `LOCATION_IMPORT`:

| Collection kolom | Mapping | Beschrijving |
|---|---|---|
| `c001` | `name` | Locatienaam |
| `c002` | `contact_person` | Contactpersoon |
| `c003` | `city` | Stad |
| `c004` | `street_name` | Straatnaam |
| `c005` | `email` | E-mailadres |
| `c006` | `active` | Ja/Nee → Y/N |
| `n001` | `location_size` | Omvang |
| `c007` | `validation_status` | OK / ERROR |
| `c008` | `validation_message` | Foutmelding(en) |
| `n002` | `row_number` | Excel rijnummer |

### 3.5 Validatie Logica (per rij)

```sql
-- in p_validate_rows:
-- 1. name is verplicht
-- 2. contact_person is verplicht
-- 3. city is verplicht
-- 4. street_name is verplicht
-- 5. email is verplicht + regex check
-- 6. location_size is verplicht + must be number > 0
-- 7. active moet 'Ja' of 'Nee' zijn (of 'Y'/'N')
-- 8. duplicaat check: bestaat name + street_name + city al voor deze cnt_id?
```

---

## 4. UX Flow

### 4.1 Flow Diagram

```
Stap 1: Upload        → Gebruiker selecteert Excel bestand
Stap 2: Preview       → Parsed data wordt getoond in tabel
Stap 3: Validatie     → Automatisch — fouten worden rood gemarkeerd
Stap 4: Bevestiging   → Knop "Importeer X locaties" (alleen valide rijen)
Stap 5: Resultaat     → Samenvatting: ingevoegd / overgeslagen / fouten
```

### 4.2 Foutweergave

- Elke rij in de preview-tabel krijgt een **status kolom** (✓ OK / ✗ ERROR)
- Bij ERROR staat de foutmelding in een **tooltip of extra kolom**
- Bovenaan de tabel: samenvatting "5 van 8 rijen valide"
- Ongeldige rijen worden **rood gemarkeerd** maar niet verborgen
- Gebruiker kan alleen de valide rijen importeren

---

## 5. Mockup — Schermontwerp

### 5.1 Pagina: Bulk Import (Modal Dialog vanuit pagina 8021)

```
┌─────────────────────────────────────────────────────────────┐
│  Klant Locaties Bulk Toevoegen                          [X] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Klant: [Onderwijsgroep Galilei]          (read-only)       │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  📎 Kies Excel bestand (.xlsx, .csv)    [Bladeren]  │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  [Download Template]                                        │
│                                                             │
│  ─── Preview ───────────────────────────────────────────    │
│                                                             │
│  ℹ️ 5 van 8 rijen valide                                    │
│                                                             │
│  ┌──────┬────────────┬──────────┬────────┬─────┬──────┐    │
│  │ Rij  │ Locatie    │ Contact  │ Stad   │ ... │Status│    │
│  ├──────┼────────────┼──────────┼────────┼─────┼──────┤    │
│  │  1   │ Hoofdgeb.  │ J. Smit  │ Utrecht│ ... │  ✓   │    │
│  │  2   │ Bijgebouw  │ P. Vries │ Utrecht│ ... │  ✓   │    │
│  │  3   │            │ K. Jans  │ A'dam  │ ... │  ✗   │    │
│  │      │            │          │        │     │ Naam │    │
│  │      │            │          │        │     │ ontb.│    │
│  └──────┴────────────┴──────────┴────────┴─────┴──────┘    │
│                                                             │
│                      [Annuleren]  [Importeer 5 locaties]    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 Resultaat (na import)

```
┌─────────────────────────────────────────────────────────────┐
│  Import Resultaat                                       [X] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ✅ 5 locaties succesvol aangemaakt                         │
│  ⚠️ 3 rijen overgeslagen (zie details)                      │
│                                                             │
│  Overgeslagen rijen:                                        │
│  • Rij 3: Locatienaam is verplicht                          │
│  • Rij 6: Ongeldig e-mailadres                              │
│  • Rij 7: Locatie bestaat al (Hoofdgebouw, Utrecht)         │
│                                                             │
│                                            [Sluiten]        │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. Database Wijzigingen

### 6.1 Geen schema wijzigingen nodig

De bestaande tabel `icca_client_locations` hoeft **niet** aangepast te worden.  
De trigger `icca_cln_biur` vult automatisch de audit-kolommen.

### 6.2 Nieuwe objecten

| Object | Naam | Beschrijving |
|---|---|---|
| Package spec | `icca_location_import_pkg.pks` | Package specificatie |
| Package body | `icca_location_import_pkg.pkb` | Implementatie: parse, validate, import |

### 6.3 APEX Componenten

| Component | Beschrijving |
|---|---|
| **Pagina 8023** (nieuw) | Modal Dialog — Bulk Import pagina |
| **File Browse item** | `P8023_FILE` — Excel upload |
| **Hidden item** | `P8023_CNT_ID` — Klant ID (doorgegeven vanuit 8021) |
| **Classic Report / IR** | Preview van parsed data uit APEX Collection |
| **Process: Parse** | Roept `icca_location_import_pkg.p_parse_excel` aan |
| **Process: Validate** | Roept `icca_location_import_pkg.p_validate_rows` aan |
| **Process: Import** | Roept `icca_location_import_pkg.p_execute_import` aan |
| **Button op 8021** | "Klant Locaties Bulk Toevoegen" — opent pagina 8023 |
| **Static file** | Excel template voor download |

---

## 7. Excel Template

Voorzie een downloadbaar template bestand met de juiste kolomnamen:

| Locatie Naam | Contact Persoon | Stad | Straatnaam | Email | Omvang | Actief |
|---|---|---|---|---|---|---|
| Hoofdgebouw | J. de Vries | Rotterdam | Coolsingel 1 | info@voorbeeld.nl | 499 | Ja |
| Bijgebouw A | P. Smit | Rotterdam | Coolsingel 3 | beheer@voorbeeld.nl | 250 | Ja |

---

## 8. Edge Cases & Risico's

### 8.1 Edge Cases

| Case | Afhandeling |
|---|---|
| **Duplicaat locatie** | Check op `cnt_id + upper(name) + upper(street_name) + upper(city)`. Rij markeren als ERROR met melding. |
| **Ongeldig e-mail** | Regex validatie: `[^\s@]+@[^\s@]+\.[^\s@]+`. Rij markeren als ERROR. |
| **Verplicht veld ontbreekt** | Per veld checken. Alle ontbrekende velden in foutmelding opnemen. |
| **Omvang niet numeriek** | `to_number()` met exception handling. ERROR bij niet-numerieke waarden. |
| **Actief veld ongeldig** | Alleen 'Ja'/'Nee'/'Y'/'N' accepteren (case-insensitive). Default 'Y' als leeg. |
| **Leeg bestand** | Melding: "Het Excel bestand bevat geen data." |
| **Verkeerd bestandsformaat** | `apex_data_parser` geeft fout — opvangen met duidelijke melding. |
| **Meer dan 1000 rijen** | Limiet instellen en melding geven. Bulk import is bedoeld voor tientallen/honderden, niet duizenden. |
| **Kolommen in verkeerde volgorde** | Matchen op **kolomnaam** (header), niet op positie. |

### 8.2 Risico's

| Risico | Impact | Mitigatie |
|---|---|---|
| Gebruiker upload verkeerd formaat | Laag | Bestandstype beperken + duidelijke foutmelding |
| Grote bestanden (performance) | Laag | Rij-limiet + `apex_data_parser` is efficiënt |
| Trigger overhead bij bulk insert | Laag | Trigger doet alleen audit-kolommen vullen |
| Gebruiker verwacht dat ongeldige rijen toch worden ingevoegd | Medium | Duidelijke UI feedback + bevestigingsstap |

---

## 9. Uren Schatting

| Fase | Onderdeel | Uren |
|---|---|---|
| **Analyse** | Codebase analyse & technisch ontwerp | 2 |
| **Ontwikkeling** | PL/SQL Package (`icca_location_import_pkg`) | 4 |
| | APEX Pagina 8023 (upload + preview + import) | 4 |
| | Excel template aanmaken | 0.5 |
| | Button toevoegen op pagina 8021 | 0.5 |
| | Foutafhandeling & UX polish | 2 |
| **Testen** | Functioneel testen (happy path) | 1.5 |
| | Edge case testen (duplicaten, lege velden, etc.) | 1.5 |
| | Regressie test bestaande locatie-functionaliteit | 1 |
| | | |
| **Totaal** | | **17 uur** |

---

## 10. Acceptatiecriteria

- [ ] Gebruiker kan Excel bestand uploaden (.xlsx, .csv)
- [ ] Parsed data wordt getoond in een preview tabel
- [ ] Elke rij wordt individueel gevalideerd
- [ ] Ongeldige rijen worden duidelijk gemarkeerd met foutmelding
- [ ] Alleen valide rijen worden ingevoegd na bevestiging
- [ ] Na import wordt een samenvatting getoond (succesvol / overgeslagen)
- [ ] Bestaande handmatige invoer blijft ongewijzigd werken
- [ ] Excel template is beschikbaar voor download
- [ ] Duplicaat locaties worden gedetecteerd en geblokkeerd
