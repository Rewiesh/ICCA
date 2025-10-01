create or replace view icca_cities_provinces_vw as
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
    select 'Frankrijk', 'Grand Est' from dual

    -- Luxemburg (landen/regio's klein, maar als provincie opgegeven)
    union all
    select 'Luxemburg', 'Luxemburg' from dual
),
city_data as (
    select 'Nederland' as country, 'Noord-Holland' as province, 'Amsterdam' as city from dual union all
    select 'Nederland', 'Zuid-Holland', 'Rotterdam' from dual union all
    select 'Nederland', 'Zuid-Holland', 'Den Haag' from dual union all
    select 'Nederland', 'Utrecht', 'Utrecht' from dual union all
    select 'Nederland', 'Noord-Brabant', 'Eindhoven' from dual union all
    select 'Nederland', 'Groningen', 'Groningen' from dual union all
    select 'Nederland', 'Limburg', 'Maastricht' from dual union all
    select 'Nederland', 'Friesland', 'Leeuwarden' from dual union all
    select 'België', 'Brussels Hoofdstedelijk Gewest', 'Brussel' from dual union all
    select 'België', 'Antwerpen', 'Antwerpen' from dual union all
    select 'Duitsland', 'Berlin', 'Berlijn' from dual union all
    select 'Duitsland', 'Nordrhein-Westfalen', 'Keulen' from dual union all

    -- UK Cities
    select 'Verenigd Koninkrijk', 'England', 'London' from dual union all
    select 'Verenigd Koninkrijk', 'England', 'Manchester' from dual union all
    select 'Verenigd Koninkrijk', 'Scotland', 'Edinburgh' from dual union all
    select 'Verenigd Koninkrijk', 'Wales', 'Cardiff' from dual union all
    select 'Verenigd Koninkrijk', 'Northern Ireland', 'Belfast' from dual

    -- Frankrijk Cities
    union all
    select 'Frankrijk', 'Île-de-France', 'Parijs' from dual union all
    select 'Frankrijk', q'[Provence-Alpes-Côte Azur]', 'Marseille' from dual union all
    select 'Frankrijk', 'Auvergne-Rhône-Alpes', 'Lyon' from dual union all
    select 'Frankrijk', 'Nouvelle-Aquitaine', 'Bordeaux' from dual union all
    select 'Frankrijk', 'Occitanie', 'Toulouse' from dual union all
    select 'Frankrijk', 'Grand Est', 'Strasbourg' from dual

    -- Luxemburg City
    union all
    select 'Luxemburg', 'Luxemburg', 'Luxemburg Stad' from dual
)
select
    c.country,
    c.province,
    c.city
from
    city_data c
    join province_data p on p.country = c.country and p.province = c.province
order by
    c.country,
    c.province,
    c.city;
