# OVSR rapport-huisstijl: "Ter attentie van" weg, "Leverancier:" ipv "Aanwezig leverancier:"

## Status

**Gedaan (bestandswijzigingen, klaar om te compileren/deployen):**
- `database\tables\icca_clients.tab` — kolom `report_brand varchar2(20) default
  'ICCA' not null` toegevoegd aan de CREATE-DDL, plus commentaar-`alter`-regels
  (zelfde conventie als `audit_report_type`) voor de live `ALTER TABLE` +
  check-constraint. Toegestane waarden: `ICCA`, `OVSR`, en (gereserveerd voor
  later) `BLINCK` — die laatste is nog niet functioneel: `icca_pdf_blinck_data.pkb`
  en `BLINCK_RAPPORT.hbs` lezen `report_brand` nog niet, ook al bevat die template
  dezelfde twee regels. Pas aan zoals bij de andere drie zodra Blinck een
  vergelijkbare wijziging vraagt.
- `database\package_bodies\icca_pdf_icca_data.pkb`,
  `icca_pdf_fase_control_data.pkb`, `icca_pdf_icca_zonder_cijfers_data.pkb` —
  `f_get_audit_info` zet nu ook `toon_ter_attentie_van` (boolean) en
  `leverancier_label` in de JSON, afgeleid van `report_brand`.
- `GeneratePdf\templates\ICCA_RAPPORT.hbs`, `FASE_CONTROL.hbs`,
  `ICCA_ZONDER_CIJFERS.hbs` — "Ter attentie van" alleen nog binnen
  `{{#if audit_info.toon_ter_attentie_van}}`, label is nu
  `{{audit_info.leverancier_label}}:`.

**Nog te doen (door Rewiesh, buiten deze sessie — geen DDL/compiles/live-data
door mij):**
1. `ALTER TABLE`/check-constraint uit `icca_clients.tab` (regels bij de
   bestaande commentaarblok) op de live DB draaien, en de drie `.pkb`'s +
   `icca_pdf_generator` herompileren.
2. Live query + update (stap 4 hieronder) om de ~22 OVSR-klanten en COA
   Midden Zuid op `report_brand = 'OVSR'` te zetten.
3. `.hbs`-wijzigingen deployen naar de GeneratePdf-service en
   `/templates/refresh` aanroepen (of service herstarten) i.v.m. de
   template-cache.
4. (Optioneel) `P8006_REPORT_BRAND`-item op de Client Form.

## Context

ICCA genereert schoonmaak-audit PDF-rapportages voor haar klanten. **OVSR is geen
losse klant, maar een tussenpersoon**: Roel ter Burg (info@ovsr.nl) staat als
`contact_person` op ~22 eigen eindklanten in `icca_clients` (Hsv, Educatis, Spog,
**Coa Midden Zuid**, Artez, Dyn, Scpo, Stanisla, Galb, Henkel, Blick, Oomn, Saam,
Vrijs, Svv, Ijmond, ...).

OVSR heeft via ICCA Advies twee kleine tekstuele wijzigingen gevraagd op het
voorblad van *al zijn* rapportages:

1. "Ter attentie van: `<naam>`" moet weg.
2. "Aanwezig leverancier:" moet "Leverancier:" worden.

Daarnaast wil Roel dat **COA Midden Zuid** dezelfde (nieuwe) OVSR-opmaak krijgt
als zijn andere klanten — "al mijn klanten moeten mijn lay-out hebben".

**Waarom dit niet een simpele 1-regel-fix is:** OVSR's klanten zitten niet op
één rapportsjabloon. Ze zitten verspreid over minstens drie bestaande
`audit_report_type`-waarden (ICCA, FASE_CONTROL, ICCA_ZONDER_CIJFER) — dezelfde
typen die ook door *niet-OVSR*-klanten van ICCA gebruikt worden. Een
ongeconditioneerde tekstwijziging in die templates zou dus per ongeluk ook het
voorblad van alle andere ICCA-klanten op datzelfde rapporttype veranderen.

`audit_report_type` is vandaag de **enige** as die bepaalt welk sjabloon een
klant krijgt, en die as vermengt twee dingen: (a) welke *inhoud* het rapport
toont (cijfers wel/niet, welke grafieken), en (b) voor Blinck/Buro Hennie Dekker
ook impliciet het *merk/de huisstijl* (want dat zijn 1-op-1 klantsjablonen).
Er bestaat nergens in het ICCA-schema of de packages al een apart
"reseller/merk"-concept — dat moet er dus bij komen, los van
`audit_report_type`, zodat de OVSR-wijziging alléén OVSR's eigen klanten raakt.

## Architectuur (zoals vastgesteld)

Pipeline: `icca_pdf_generator.f_generate_audit_pdf(p_adt_id)` →
1. Leest `icca_clients.audit_report_type` → bepaalt `l_template_name`.
2. Roept op basis daarvan één van de vijf "data"-packages aan
   (`icca_pdf_icca_data`, `icca_pdf_fase_control_data`,
   `icca_pdf_icca_zonder_cijfers_data`, `icca_pdf_blinck_data`,
   `icca_pdf_buro_hennie_dekker_data`), elk met dezelfde publieke functie
   `f_get_main_json(p_adt_id) return clob`, die een JSON `{template_name, data:
   {audit_info: {...}, ...}}` opbouwt.
3. POST't die JSON naar de losse Node/Puppeteer/Handlebars-service in
   `C:\sr_repo\GeneratePdf`, die `templates/<template_name>.hbs` laadt en
   rendert naar PDF.

De drie relevante data-packages (`icca_pdf_icca_data.pkb`,
`icca_pdf_fase_control_data.pkb`, `icca_pdf_icca_zonder_cijfers_data.pkb`) zijn
bijna-identieke klonen van elkaar; elk heeft een `f_get_audit_info` die o.a.
`ter_attentie_van` en `aanwezig_leverancier` vult vanuit
`l_client_rec.contact_person` (`l_client_rec` = `icca_clients%rowtype`).
De tekst zelf staat als hardcoded label in vier Handlebars-bestanden
(`ICCA_RAPPORT.hbs`, `FASE_CONTROL.hbs`, `ICCA_ZONDER_CIJFERS.hbs`,
`BLINCK_RAPPORT.hbs`) — elk een volledig zelfstandig HTML-document, geen
gedeelde partial. `BURO_HENNIE_DEKKER.hbs` heeft deze velden niet.

Er bestaat al een oudere, losstaande AS_PDF3-package
(`icca_kwaliteits_meting_pdf.pkb` / `icca_kwaliteits_meting_pdf_template.pkb`)
met dezelfde twee labels, maar die is **niet** het pad dat gemailde
klantrapportages genereert (dat gaat via `icca_pdf_generator`) en bevat
onafgemaakte/hardcoded testwaarden. **Buiten scope** — niet aanraken.

## Aanpak

Eén nieuwe, orthogonale klant-vlag naast `audit_report_type`, zelfde patroon:

**1. Nieuwe kolom** `icca_clients.report_brand varchar2(20) default 'ICCA' not
null` + check-constraint `check (report_brand in ('ICCA','OVSR'))`.
Omdat de data-packages al `select cnt.* into l_client_rec ...` doen, is de
kolom automatisch beschikbaar zonder query-wijziging.
→ bestand: `c:\sr_repo\ICCA\database\tables\icca_clients.tab`

**2. Twee afgeleide velden in de JSON**, berekend in PL/SQL (niet in
Handlebars) zodat de sjablonen dom/generiek blijven en de regel op één plek
staat:
```sql
l_obj.put('toon_ter_attentie_van', l_client_rec.report_brand != 'OVSR');  -- json boolean
l_obj.put('leverancier_label',
    case when l_client_rec.report_brand = 'OVSR' then 'Leverancier'
         else 'Aanwezig leverancier' end);
```
Toevoegen aan `f_get_audit_info` in alle drie:
- `icca_pdf_icca_data.pkb`
- `icca_pdf_fase_control_data.pkb`
- `icca_pdf_icca_zonder_cijfers_data.pkb`

(Blinck en Buro Hennie Dekker blijven ongemoeid — geen OVSR-klant zit op die
sjablonen.)

**3. Templates aanpassen** (GeneratePdf-repo), in dezelfde drie bestanden:
```
{{#if audit_info.toon_ter_attentie_van}}
<p>Ter attentie van:<br>{{audit_info.ter_attentie_van}}</p>
{{/if}}
...
<p>{{audit_info.leverancier_label}}:<br>{{audit_info.aanwezig_leverancier}}</p>
```
→ `c:\sr_repo\GeneratePdf\templates\ICCA_RAPPORT.hbs` (regel 610, 625)
→ `c:\sr_repo\GeneratePdf\templates\FASE_CONTROL.hbs` (regel 627, 642)
→ `c:\sr_repo\GeneratePdf\templates\ICCA_ZONDER_CIJFERS.hbs` (regel 656, 671)

Geen wijziging nodig in `template-engine.js` — de bestaande
`preprocessIccaData`-whitelist en `renderTemplate`-flow blijven ongewijzigd,
er komt geen nieuw Handlebars-helper bij (`{{#if}}` op een boolean/`{{veld}}`
volstaat).

**4. Eenmalige datamigratie** — vóór livegang eerst zelf verifiëren met een
live query (niet uit de repo af te leiden):
```sql
select id, company_name, contact_person, audit_report_type, report_brand
from   icca_clients
where  contact_person = 'Roel ter Burg'
   or  upper(company_name) like '%COA MIDDEN ZUID%';
```
Daarna (door jou uit te voeren, geen compile/DDL door mij):
```sql
update icca_clients
set    report_brand = 'OVSR'
where  contact_person = 'Roel ter Burg';   -- of het exacte criterium na de query hierboven
```
Check ook of COA Midden Zuid al hetzelfde `audit_report_type` heeft als de
andere OVSR-klanten (historische migratiedata suggereert van wel — `ReportType
= 0` → `'ICCA'` — maar dit staat nergens actueel in de repo, dus alleen de
live tabel is gezaghebbend). Zo niet, die apart gelijktrekken.

**5. (Aanbevolen, niet blokkerend) Beheer-UI** — `icca_clients.audit_report_type`
is al door staff instelbaar via APEX-pagina 8006 ("Client Form",
item `P8006_AUDIT_REPORT_TYPE`, radiogroup + LOV `LOV_AUDIT_REPORT_TYPES`).
Een tweede item `P8006_REPORT_BRAND` met een kleine LOV (ICCA/OVSR) op dezelfde
pagina toevoegen voorkomt dat nieuwe OVSR-klanten later weer los via SQL
gezet moeten worden. Dit voer jij zelf uit in APEX Builder (of via de
`apex`-skill) — geen losse page-export hiervoor in de ticketmap, zoals
gebruikelijk.

## Niet gedaan / bewust buiten scope

- `icca_kwaliteits_meting_pdf(_template).pkb` (AS_PDF3, dead code pad) —
  onaangeroerd.
- `BLINCK_RAPPORT.hbs` / `BURO_HENNIE_DEKKER.hbs` — geen OVSR-klant hierop,
  geen wijziging nodig.
- `icca_pdf_templates.tab` — ongebruikte stub-tabel, niet relevant.
- Geen nieuwe generieke "brand-config"-abstractie — met maar twee waarden
  (ICCA/OVSR) is een simpele kolom + inline `case` consistent met hoe de
  bestaande drie data-packages nu al dupliceren; bij een derde reseller is
  het de moeite waard dit te centraliseren, nu nog niet.

## Verificatie

1. Live query (stap 4) uitvoeren en de ~22 OVSR-rijen + COA Midden Zuid
   bevestigen vóór de update.
2. Na de wijziging: één audit per rapporttype (ICCA, FASE_CONTROL,
   ICCA_ZONDER_CIJFER) van een OVSR-klant genereren via
   `icca_pdf_generator.f_generate_audit_pdf` en het voorblad visueel
   controleren (geen "Ter attentie van", label "Leverancier:").
3. Eén audit van een **niet**-OVSR-klant op elk van diezelfde drie
   rapporttypes genereren en bevestigen dat daar niets veranderd is
   ("Ter attentie van" nog aanwezig, label nog "Aanwezig leverancier:").
4. `template-engine.js` cache: na het aanpassen van de `.hbs`-bestanden de
   endpoint `/templates/refresh` aanroepen (of de service herstarten) zodat
   de gecachte templates niet de oude versie blijven renderen.

## Plandocument wegzetten

Na goedkeuring van dit plan zet ik de inhoud ook als
`c:\sr_repo\ICCA\documentation\ovsr_template_aanpassingen\plan.md`, zoals
gevraagd.
