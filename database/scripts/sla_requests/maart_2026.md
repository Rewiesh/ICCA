# 🐞 Bugs (hoogste prioriteit)

## 1. Plaatsnaam invoer probleem

**Issue:**
- Tekst verdwijnt na invoer  
- Moet meerdere keren opnieuw ingevuld worden  

**Waarschijnlijk oorzaak (APEX):**
- Dynamic Action / refresh  
- LOV / autocomplete issue  
- Page item wordt gereset  

**To Do:**
- [ ] Reproduce issue (nieuwe klant + locatie)  
- [ ] Check Page Item type (Select List / Autocomplete)  
- [ ] Check Dynamic Actions (refresh / set value)  
- [ ] Check session state behavior  
- [ ] Fix zodat waarde blijft staan na invoer  

👉 **Priority:** 🔴 High (UX killer)  


---

# ✨ Features / Improvements

## 2. Bulk import locaties (Excel upload)

**Vraag klant:**
- Meerdere locaties via Excel importeren  

**To Do:**
- [ ] Maak upload page (File Browse item)  
- [ ] Parse Excel (APEX_DATA_PARSER)  

**Mapping:**
- klant  
- locatie naam  
- adres  
- plaats  

- [ ] Validatie (verplichte velden)  
- [ ] Insert in tabel  
- [ ] Feedback tonen (success / errors)  

👉 **Bonus:**
- [ ] Template Excel aanbieden  

👉 **Priority:** 🟠 High (grote efficiency win)  


---

## 3. Inactieve data verbergen (soft delete / archiving)

**Vraag klant:**
- Niet-actieve klanten/gebouwen/performers niet zichtbaar  

**To Do:**
- [ ] Check of kolom bestaat (bijv. `actief_yn`)  

- [ ] Zo niet → toevoegen:
```sql
ALTER TABLE ... ADD actief_yn CHAR(1) DEFAULT 'Y';