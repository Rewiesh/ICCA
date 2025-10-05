-- Als SYSDBA of user met CREATE ANY DIRECTORY rechten:
CREATE OR REPLACE DIRECTORY ICCA_UPLOADS AS '/home/icca-dashboard/public_html/uploads';

-- Geef rechten aan je schema
GRANT READ, WRITE ON DIRECTORY ICCA_UPLOADS TO ICCA;

-- Verificatie (als ICCA_DASHBOARD user):
SELECT directory_name, directory_path 
FROM all_directories 
WHERE directory_name = 'ICCA_UPLOADS';