create or replace view icca_provinces_vw as
with province_data as (
    -- Nederland
    select 'Nederland' as country, 'Drenthe' as province from dual union all
    select 'Nederland', 'Flevoland' from dual union all
    select 'Nederland', 'Friesland' from dual union all
    select 'Nederland', 'Gelderland' from dual union all
    select 'Nederland', 'Groningen' from dual union all
    select 'Nederland', 'Limburg' from dual union all
    select 'Nederland', 'Noord-Brabant' from dual union all
    select 'Nederland', 'Noord-Holland' from dual union all
    select 'Nederland', 'Overijssel' from dual union all
    select 'Nederland', 'Utrecht' from dual union all
    select 'Nederland', 'Zeeland' from dual union all
    select 'Nederland', 'Zuid-Holland' from dual

    -- België
    union all
    select 'België', 'Antwerpen' from dual union all
    select 'België', 'Limburg' from dual union all
    select 'België', 'Oost-Vlaanderen' from dual union all
    select 'België', 'Vlaams-Brabant' from dual union all
    select 'België', 'West-Vlaanderen' from dual union all
    select 'België', 'Brussels Hoofdstedelijk Gewest' from dual union all
    select 'België', 'Waals-Brabant' from dual union all
    select 'België', 'Henegouwen' from dual union all
    select 'België', 'Luik' from dual union all
    select 'België', 'Luxemburg' from dual union all
    select 'België', 'Namen' from dual

    -- Duitsland (Bundesländer)
    union all
    select 'Duitsland', 'Baden-Württemberg' from dual union all
    select 'Duitsland', 'Bayern' from dual union all
    select 'Duitsland', 'Berlin' from dual union all
    select 'Duitsland', 'Brandenburg' from dual union all
    select 'Duitsland', 'Bremen' from dual union all
    select 'Duitsland', 'Hamburg' from dual union all
    select 'Duitsland', 'Hessen' from dual union all
    select 'Duitsland', 'Mecklenburg-Vorpommern' from dual union all
    select 'Duitsland', 'Niedersachsen' from dual union all
    select 'Duitsland', 'Nordrhein-Westfalen' from dual union all
    select 'Duitsland', 'Rheinland-Pfalz' from dual union all
    select 'Duitsland', 'Saarland' from dual union all
    select 'Duitsland', 'Sachsen' from dual union all
    select 'Duitsland', 'Sachsen-Anhalt' from dual union all
    select 'Duitsland', 'Schleswig-Holstein' from dual union all
    select 'Duitsland', 'Thüringen' from dual

    -- Verenigd Koninkrijk (UK) regio's
    union all
    select 'Verenigd Koninkrijk', 'England' from dual union all
    select 'Verenigd Koninkrijk', 'Scotland' from dual union all
    select 'Verenigd Koninkrijk', 'Wales' from dual union all
    select 'Verenigd Koninkrijk', 'Northern Ireland' from dual

    -- Frankrijk regio's (enkele grote)
    union all
    select 'Frankrijk', 'Île-de-France' from dual union all
    select 'Frankrijk', q'[Provence-Alpes-Côte Azur]' from dual union all
    select 'Frankrijk', 'Auvergne-Rhône-Alpes' from dual union all
    select 'Frankrijk', 'Nouvelle-Aquitaine' from dual union all
    select 'Frankrijk', 'Occitanie' from dual union all
    select 'Frankrijk', 'Grand Est' from dual union all

    -- Luxemburg (landen/regio's klein, maar als provincie opgegeven)
    select 'Luxemburg', 'Luxemburg' from dual
)
select  *
from    province_data
order by country, province
;
