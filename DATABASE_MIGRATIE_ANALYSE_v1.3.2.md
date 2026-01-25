# Database Migratie Impact Analyse - Versie 1.3.2
**Datum:** 25 januari 2026  
**Feature:** Opmerkingen functionaliteit (tb_remark tabel)  
**Impact:** Bestaande gebruikers met versie ≤ 1.3.1

---

## 📊 Situatie Overzicht

### Huidige Status
- **Productie versie:** 1.3.1 (bij gebruikers)
- **Nieuwe versie:** 1.3.2 (met `tb_remark` tabel)
- **Nieuwe tabel:** `tb_remark` (voor opmerkingen functionaliteit)

### Deployment Scenario
1. Gebruiker heeft versie 1.3.1 geïnstalleerd
2. App Store update naar 1.3.2 beschikbaar
3. Gebruiker installeert update
4. App start met nieuwe code, MAAR oude database schema

---

## ⚠️ Potentiële Problemen

### 🔴 KRITIEK - App Crash bij Eerste Gebruik

**Scenario:**
```
1. Gebruiker update app naar v1.3.2
2. Gebruiker opent app (ZONDER opnieuw in te loggen)
3. Gebruiker navigeert naar AuditErrorList screen
4. Screen probeert remarks te laden: getAllRemarksByFormId()
5. Query op niet-bestaande tabel: SELECT * FROM tb_remark WHERE...
6. ❌ SQLite error: "no such table: tb_remark"
7. ❌ APP CRASH
```

**Code locatie:**
- `app/screens/AuditErrorList/index.js:56`
  ```javascript
  const fetchedRemarks = await database.getAllRemarksByFormId(form.FormId);
  ```

**Risico:** HOOG
- Gebruiker kan app niet gebruiken zonder crash
- Data verlies mogelijk als upload wordt onderbroken
- Negatieve reviews in App Store

---

## ✅ Bescherming Mechanismen (Huidige Implementatie)

### 1. CREATE TABLE IF NOT EXISTS
**Locatie:** `database1.js:304-310`
```sql
CREATE TABLE IF NOT EXISTS tb_remark (
    RemarkId INTEGER PRIMARY KEY AUTOINCREMENT,
    FormId VARCHAR NOT NULL,
    RemarkText TEXT,
    RemarkImg TEXT,
    RemarkImgSent INTEGER DEFAULT 0
);
```

**Effect:** Tabel wordt aangemaakt als deze niet bestaat

### 2. InitializeDatabase Aanroep
**Locatie:** `app/screens/Login.js:91`
```javascript
await database.InitializeDatabase();
```

**Wanneer:** Bij elke succesvolle login

---

## 🚨 Probleem Analyse

### Scenario A: Gebruiker logt opnieuw in
✅ **VEILIG**
1. Gebruiker update naar v1.3.2
2. Gebruiker logt uit en opnieuw in
3. `InitializeDatabase()` wordt aangeroepen
4. `tb_remark` tabel wordt aangemaakt
5. App werkt normaal

### Scenario B: Gebruiker blijft ingelogd
❌ **CRASH RISICO**
1. Gebruiker update naar v1.3.2
2. Gebruiker blijft ingelogd (geen logout)
3. `InitializeDatabase()` wordt NIET aangeroepen
4. `tb_remark` tabel bestaat NIET
5. Bij navigatie naar formulier lijst → `getAllRemarksByFormId()` → CRASH

### Scenario C: Fresh Install
✅ **VEILIG**
1. Nieuwe gebruiker installeert v1.3.2
2. Gebruiker logt in
3. `InitializeDatabase()` maakt alle tabellen
4. App werkt normaal

---

## 📈 Impact Schatting

### Gebruikers Groepen
1. **Actieve gebruikers (blijven ingelogd):** 🔴 HOOG RISICO
   - Percentage: ~70-80%
   - Impact: App crash bij eerste gebruik van formulieren
   
2. **Gebruikers die uitloggen:** 🟢 GEEN RISICO
   - Percentage: ~20-30%
   - Impact: Geen, tabel wordt aangemaakt bij login

3. **Nieuwe gebruikers:** 🟢 GEEN RISICO
   - Impact: Geen, fresh install

---

## 🛡️ Aanbevolen Oplossingen

### Optie 1: Database Migratie bij App Start (AANBEVOLEN)
**Implementatie:**
```javascript
// In App.js of index.js - VOOR navigatie
useEffect(() => {
  const initApp = async () => {
    const isLoggedIn = await userManager.isLoggedIn();
    if (isLoggedIn) {
      await database.InitializeDatabase(); // Maak missende tabellen
    }
  };
  initApp();
}, []);
```

**Voordelen:**
- ✅ Werkt voor alle gebruikers
- ✅ Geen crash risico
- ✅ Eenmalige check bij app start

**Nadelen:**
- ⚠️ Extra database call bij elke app start
- ⚠️ Kleine vertraging (~50-100ms)

---

### Optie 2: Try-Catch met Lazy Table Creation
**Implementatie:**
```javascript
async function getAllRemarksByFormId(FormId) {
  try {
    const query = "SELECT * FROM tb_remark WHERE FormId = ? ORDER BY RemarkId DESC";
    const params = [FormId];
    return await executeSelect(query, params);
  } catch (error) {
    // Als tabel niet bestaat, maak deze aan
    if (error.message.includes('no such table')) {
      await InitializeDatabase();
      return await executeSelect(query, params);
    }
    throw error;
  }
}
```

**Voordelen:**
- ✅ Geen performance impact als tabel bestaat
- ✅ Automatische recovery

**Nadelen:**
- ⚠️ Complexer error handling
- ⚠️ Moet bij elke database functie geïmplementeerd worden

---

### Optie 3: Versie Check + Geforceerde Logout
**Implementatie:**
```javascript
// Bij app start
const APP_VERSION = '1.3.2';
const LAST_SCHEMA_VERSION = await AsyncStorage.getItem('SCHEMA_VERSION');

if (LAST_SCHEMA_VERSION !== APP_VERSION) {
  await userManager.logout();
  await AsyncStorage.setItem('SCHEMA_VERSION', APP_VERSION);
  // Redirect naar login
}
```

**Voordelen:**
- ✅ Simpel te implementeren
- ✅ Garandeert verse database schema

**Nadelen:**
- ❌ Slechte gebruikerservaring (geforceerde logout)
- ❌ Mogelijke data verlies als upload in progress

---

## 🎯 Aanbeveling

### **KIES: Optie 1 - Database Migratie bij App Start**

**Implementeer in:** `App.js` of hoofdnavigatie component

**Stappen:**
1. Voeg database init toe bij app mount (als gebruiker ingelogd is)
2. Show loading screen tijdens init
3. Test met bestaande database (zonder tb_remark)

**Geschatte implementatie tijd:** 15 minuten  
**Risico na implementatie:** LAAG  
**Impact op gebruikers:** MINIMAAL

---

## 📝 Testing Checklist

### Pre-Deployment Tests
- [ ] Test update scenario: v1.3.1 → v1.3.2 (blijf ingelogd)
- [ ] Test fresh install v1.3.2
- [ ] Test met bestaande audits/formulieren
- [ ] Test opmerkingen CRUD functionaliteit
- [ ] Test upload met opmerkingen + foto's

### Database Verificatie
- [ ] Verificeer `tb_remark` tabel bestaat na update
- [ ] Verificeer oude data blijft behouden
- [ ] Verificeer geen crashes bij navigatie
- [ ] Verificeer upload werkt met nieuwe velden

---

## 🚀 Deployment Plan

### Voor Deployment
1. Implementeer Optie 1 (database init bij app start)
2. Test grondig met simulator + test device
3. Maak beta build voor testgebruikers

### Bij Deployment
1. Release v1.3.2 naar App Store / Play Store
2. Monitor crash reports eerste 24-48 uur
3. Bereid rollback voor (indien nodig)

### Na Deployment
1. Monitoor feedback
2. Verificeer uploads met opmerkingen in backend
3. Check database logs voor errors

---

## 🎓 Lessen voor Toekomst

### Implementeer Database Versioning
```javascript
const DB_VERSION = 3; // Verhoog bij schema wijzigingen
const CURRENT_DB_VERSION = await AsyncStorage.getItem('DB_VERSION');

if (CURRENT_DB_VERSION < DB_VERSION) {
  await runMigrations(CURRENT_DB_VERSION, DB_VERSION);
  await AsyncStorage.setItem('DB_VERSION', DB_VERSION.toString());
}
```

### Altijd Check Tabel Existentie
```javascript
const tableExists = await checkTableExists('tb_remark');
if (!tableExists) await createTable();
```

### Automated Testing
- Unit tests voor database migraties
- Integration tests voor schema updates
- End-to-end tests voor upgrade scenarios
