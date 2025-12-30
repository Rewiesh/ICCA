import smtplib
from email.mime.text import MIMEText

# Vul hier je gegevens in:
smtp_server = "smtp.transip.email"
port = 465  # Correcte poort voor SSL
# username = "info@iccaadvies.eu"
username = "kwaliteit@iccaadvies.eu"
# password = "zyrpeb-nipraF-9fyppo" # rorzaQ-kiz
# password = "jQ5wp8JAOQGG" # rorzaQ-kiz
password = "Carla412jaguar" # rorzaQ-kiz
from_addr = "kwaliteit@iccaadvies.eu"
to_addr = "diewish0@gmail.com"   # testmail naar je eigen adres

msg = MIMEText("Dit is een SMTP testmail vanaf Python!")
msg["Subject"] = "SMTP test TransIP"
msg["From"] = from_addr
msg["To"] = to_addr

try:
    server = smtplib.SMTP_SSL(smtp_server, port)  # Gebruik SMTP_SSL
    server.login(username, password)
    server.sendmail(from_addr, [to_addr], msg.as_string())
    server.quit()
    print("Mail verzonden ✅")
except Exception as e:
    print("Fout:", e)

# TransIP SMTP gegevens:
# SMTP server: smtp.transip.email
# gebruikersnaam: ICCA
# sadmEw-bunko5-kesqof

# wachtwoord: Dytsex-kajkek-cufve7
# info@iccaadvies.eu
# wachtwoord: basnyz-qotWa3-cujsak

