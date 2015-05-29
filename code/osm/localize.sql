drop table if exists country_languages;
create table country_languages (a2 text, lang text);
\copy country_languages from 'data/country_languages.csv' with csv header
delete from country_languages where lang is null or a2 is null;
create index on country_languages (a2, lang);

create or replace function osm_localize(tags hstore, lang text, country text default '')
    RETURNS text
    LANGUAGE plpgsql
    STABLE STRICT
AS $function$
DECLARE
    string text;
    default_lang text;
BEGIN
    string = (tags->('name:'||lang));
    if string is not null then return string; end if;

    default_lang = (select c.lang from country_languages c where a2 = country);

    if default_lang is not null then
        string =
            translate_text(
                coalesce(
                    tags->('name:'||default_lang),
                    tags->'name'
                ),
                default_lang,
                lang
            );
        if string is not null then return string; end if;
    end if;
    if lang = 'ru' then
        string =
            translate_text(
                unidecode(
                    coalesce(
                        tags->'name:en',
                        tags->'name:de',
                        tags->'int_name',
                        tags->'name'
                    )
                ),
                'es',
                lang
            );
        if string is not null then return string; end if;
    end if;
    if lang = 'en' then
        if default_lang in ('es', 'fr', 'de', 'nl', 'it', 'pl', 'id', 'tr', 'cz', 'pt') then
            string = coalesce(
                tags->'name:'||default_lang,
                tags->'name'
            );
            if string is not null then return string; end if;
        end if;
        string = unidecode(
                    coalesce(
                        tags->'name:en',
                        tags->'name:de',
                        tags->'int_name',
                        tags->'name'
                    )
                );
        if string is not null then return string; end if;
    end if;

    return string;
END
$function$;