-- Template: Audit rapport gegenereerd
merge into icca_mail_templates t
using (
    select 
        'AUDIT_REPORT_GENERATED' as system_name,
        'Audit rapport gegenereerd' as name,
        'Mail die verstuurd wordt naar klant wanneer audit rapport is gegenereerd' as description,
        'Uw kwaliteitsrapport is klaar' as subject,
        null as body_plain,
        '<html><head><style>' ||
        'body{font-family:Arial,sans-serif;font-size:14px;color:#333;margin:0;padding:0;background-color:#f4f6f9}' ||
        '.container{max-width:600px;margin:0 auto;background:white}' ||
        '.logo-container{width:100%;overflow:hidden;max-height:200px;background-color:#f8f9fa}' ||
        '.logo{width:100%;height:200px;object-fit:cover;object-position:center}' ||
        '.title{background-color:#fff;padding:30px 25px;text-align:center}' ||
        '.title h1{margin:0;font-size:28px;color:#1e40af}' ||
        '.greeting{padding:25px;background:#fff}' ||
        '.info-box{background-color:#3b82f6;padding:25px;color:white;margin:20px 0}' ||
        '.info-box h2{margin:0 0 15px 0;color:white;font-size:20px}' ||
        '.info-box p{margin:8px 0;font-size:15px}' ||
        '.content{padding:25px}' ||
        'table{width:100%;border-collapse:collapse;margin:20px 0;background:white}' ||
        'th,td{border:none;padding:14px 16px;text-align:left}' ||
        'th{background-color:#3b82f6;color:white;font-weight:600;text-transform:uppercase;font-size:12px;letter-spacing:0.5px}' ||
        'th:last-child,td:last-child{text-align:right}' ||
        'tr:nth-child(even){background:#f8f9fa}' ||
        '.footer{background:#f7fafc;padding:20px;font-size:11px;color:#1d2022;text-align:center;border-top:1px solid #e1e8ed}' ||
        '.company{color:#3b82f6;font-weight:bold}' ||
        'a{color:#3b82f6;text-decoration:none}' ||
        '</style></head><body>' ||
        '<div class="container">' ||
        '<div class="logo-container">' ||
        '<img src="https://icca-dashboard.maxapex.net/uploads/iccamaillogo.jpg" alt="ICCA Advies" class="logo">' ||
        '</div>' ||
        '<div class="greeting">' ||
        '<p><strong>Beste #P4#,</strong></p>' ||
        '<p>Het kwaliteitsrapport van uw locatie <strong>#P2#</strong> is gereed en bijgevoegd aan deze mail.</p>' ||
        '</div>' ||
        '<div class="info-box">' ||
        '<h2>Rapportgegevens</h2>' ||
        '<p><strong>Audit nummer:</strong> #P1#</p>' ||
        '<p><strong>Locatie:</strong> #P2#</p>' ||
        '<p><strong>Controledatum:</strong> #P3#</p>' ||
        '</div>' ||
        '<div class="content">' ||
        '<p>Heeft u vragen over de resultaten? Neem gerust contact met ons op via <a href="mailto:info@iccaadvies.eu">info@iccaadvies.eu</a></p>' ||
        '<p>Met vriendelijke groet,<br><br><strong>Het ICCA Kwaliteitsteam</strong></p>' ||
        '</div>' ||
        '<div class="footer">' ||
        '<p><span class="company">ICCA Advies</span><br>Kwaliteitscontrole &amp; Advies</p>' ||
        '<p>E-mail: <a href="mailto:info@iccaadvies.eu">info@iccaadvies.eu</a></p>' ||
        '<p>Verzonden: #P3#</p>' ||
        '</div>' ||
        '</div>' ||
        '</body></html>' as body_html
    from dual
) s
on (t.system_name = s.system_name)
when matched then
    update set 
        t.name = s.name,
        t.description = s.description,
        t.subject = s.subject,
        t.body_plain = s.body_plain,
        t.body_html = s.body_html,
        t.modified_date = sysdate,
        t.modified_by = 'SYSTEM'
when not matched then
    insert (system_name, name, description, subject, body_plain, body_html, created_by)
    values (s.system_name, s.name, s.description, s.subject, s.body_plain, s.body_html, 'SYSTEM');

commit;

-- Template: Wachtwoord reset 
merge into icca_mail_templates t
using (
    select 
        'PASSWORD_RESET' as system_name,
        'Wachtwoord reset' as name,
        'Mail die verstuurd wordt wanneer gebruiker wachtwoord reset aanvraagt' as description,
        'Uw nieuwe wachtwoord voor ICCA Dashboard' as subject,
        null as body_plain,
        '<html><head><style>' ||
        'body{font-family:Arial,sans-serif;font-size:14px;color:#333;margin:0;padding:0;background-color:#f4f6f9}' ||
        '.container{max-width:600px;margin:0 auto;background:white}' ||
        '.logo-container{width:100%;overflow:hidden;max-height:200px;background-color:#f8f9fa}' ||
        '.logo{width:100%;height:200px;object-fit:cover;object-position:center}' ||
        '.greeting{padding:25px;background:#fff}' ||
        '.credentials-box{background-color:#3b82f6;padding:25px;color:white;margin:20px 25px;border-radius:8px}' ||
        '.credentials-box h2{margin:0 0 20px 0;color:white;font-size:20px;text-align:center}' ||
        '.credentials-box p{margin:12px 0;font-size:15px}' ||
        '.credentials-box .label{font-size:13px;opacity:0.9;margin-bottom:5px}' ||
        '.credentials-box .value{font-family:monospace;font-size:20px;font-weight:bold;background:rgba(255,255,255,0.2);padding:12px;border-radius:4px;letter-spacing:1px;word-break:break-all}' ||
        '.content{padding:25px}' ||
        '.footer{background:#f7fafc;padding:20px;font-size:11px;color:#1d2022;text-align:center;border-top:1px solid #e1e8ed}' ||
        '.company{color:#3b82f6;font-weight:bold}' ||
        'a{color:#3b82f6;text-decoration:none}' ||
        '</style></head><body>' ||
        '<div class="container">' ||
        '<div class="logo-container">' ||
        '<img src="https://icca-dashboard.maxapex.net/uploads/iccamaillogo.jpg" alt="ICCA Advies" class="logo">' ||
        '</div>' ||
        '<div class="greeting">' ||
        '<p><strong>Beste gebruiker,</strong></p>' ||
        '<p>U heeft een nieuw wachtwoord aangevraagd voor uw ICCA Dashboard account.</p>' ||
        '</div>' ||
        '<div class="credentials-box">' ||
        '<h2>Uw inloggegevens</h2>' ||
        '<div class="label">Gebruikersnaam</div>' ||
        '<div class="value">#P1#</div>' ||
        '<div class="label" style="margin-top:20px">Wachtwoord</div>' ||
        '<div class="value">#P2#</div>' ||
        '</div>' ||
        '<div class="content">' ||
        '<p>U kunt nu inloggen op het <a href="https://icca-dashboard.maxapex.net/ords/r/icca/icca/login-page">ICCA Dashboard</a> met bovenstaande gegevens.</p>' ||
        '<p>Heeft u deze aanvraag niet gedaan? Neem dan direct contact met ons op via <a href="mailto:info@iccaadvies.eu">info@iccaadvies.eu</a></p>' ||
        '<p>Met vriendelijke groet,<br><br><strong>Het ICCA Team</strong></p>' ||
        '</div>' ||
        '<div class="footer">' ||
        '<p><span class="company">ICCA Advies</span><br>Kwaliteitscontrole &amp; Advies</p>' ||
        '<p>E-mail: <a href="mailto:info@iccaadvies.eu">info@iccaadvies.eu</a></p>' ||
        '<p>Deze mail is automatisch gegenereerd</p>' ||
        '</div>' ||
        '</div>' ||
        '</body></html>' as body_html
    from dual
) s
on (t.system_name = s.system_name)
when matched then
    update set 
        t.name = s.name,
        t.description = s.description,
        t.subject = s.subject,
        t.body_plain = s.body_plain,
        t.body_html = s.body_html,
        t.modified_date = sysdate,
        t.modified_by = 'SYSTEM'
when not matched then
    insert (system_name, name, description, subject, body_plain, body_html, created_by)
    values (s.system_name, s.name, s.description, s.subject, s.body_plain, s.body_html, 'SYSTEM');
commit;