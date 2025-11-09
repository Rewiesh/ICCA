-- Update send_data_to_dashboard naar 'Y' voor specifieke companies
update  icca_clients
set     send_data_to_dashboard  = 'Y'
,       modified_date           = sysdate
,       modified_by             = user
where   company_name in (
            'Blinck Schoon B.V.',
            'BS De Kraal',
            'Sportfondsen Haarlemmermeer Perceel 1',
            'Sportfondsen Haarlemmermeer Perceel 2',
            'Sportfondsen Haarlemmermeer perceel 4',
            'St Spurd',
            'Stichting CPOW Perceel 1',
            'Stichting CPOW perceel 2',
            'Stichting CPOW Perceel 3',
            'Stichting iHUB Onderwijs Noord',
            'Stichting iHUB Onderwijs Zuid',
            'Stichting Kolom',
            'Stichting OPSPOOR perceel 1',
            'Stichting OPSPOOR perceel 2 en 3',
            'Stichting OPSPOOR perceel 3',
            'Stichting OPSPOOR perceel 3 en 5',
            'Stichting Penta perceel 1',
            'Stichting Penta perceel 2',
            'Stichting Tabijn'
        );

-- Toon hoeveel records zijn gewijzigd
select  '✅ ' || sql%rowcount || ' companies updated' as result from dual;

commit;