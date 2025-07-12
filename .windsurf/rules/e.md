---
trigger: always_on
---

- Dit project, genaamd ICCA, bestaat uit twee hoofdcomponenten:
    - 1. **Backend:** Een Oracle APEX applicatie die draait op een Oracle Database. Alle business logica, data en API's worden hier beheerd.
    - 2. **Frontend:** Een mobiele applicatie gebouwd in React Native. Deze app is functioneel voltooid en consumeert de API's van de APEX backend. Er is geen actieve ontwikkeling op de frontend.


- Alle nieuwe ontwikkelingen vinden plaats in de Oracle APEX backend.
- Mijn focus ligt nu op het implementeren van:
    - 1. **PDF generatie:** Inclusief het genereren van grafieken (graphs) binnen de PDF's.
    - 2. **E-mail functionaliteit:** Versturen van e-mails vanuit de applicatie.
- **Taal:** Alle backend code is PL/SQL en SQL.
- **Code Stijl:** Schrijf alle code in `lowercase`, behalve string literals en data.
- **Naamgevingsconventies:**
    - **Tabellen:** `icca_<table>.tab`
    - **Views:** `<view_naam>_vw`
    - **Packages:** `icca_<naam>_pkg`
    - **Procedures:** `p_<procedure_naam>`
    - **Functies:** `f_<functie_naam>`
- **Documentatie:** Voorzie nieuwe packages en complexe logica van een duidelijke PL/SQL header.
- **SQL Injection:** Gebruik **altijd** bind variabelen in SQL queries. Genereer nooit SQL met string concatenatie van input.
- **Cross-Site Scripting (XSS):** Zorg ervoor dat alle data die in de UI wordt getoond, wordt ge-escaped, bijvoorbeeld met `apex_escape.html`.

- De React Native codebase is voltooid en er vindt geen actieve ontwikkeling plaats.
- Je rol voor de frontend is beperkt tot het geven van suggesties voor code review en het analyseren van bestaande code. Genereer geen nieuwe features voor de frontend.

- Het project gebruikt een simpele `main` branch workflow. Complexe branch-strategieën zijn niet nodig.
