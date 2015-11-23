\i config.sql

-- a table with matching of default language to country
drop table if exists country_languages;
create table country_languages (
    a2    text,
    lang  text,
    lang2 text
);
comment on table country_languages is '[IN][i18n] country code to language code mapping';

\copy country_languages from 'data/country_languages.csv' with csv header
delete from country_languages
where lang is null or a2 is null;
create index on country_languages (a2, lang);


create or replace function osm_localize(tags hstore, lang text, country text default '')
    returns text
language plpgsql
stable strict
as $function$
declare
    string       text;
    default_lang text;
begin
    if lang = 'pt_BR'
    then lang = 'pt'; end if;
    if lang = 'zh_CN'
    then lang = 'zh'; end if;
    if lang = 'es_AR'
    then lang = 'es'; end if;
    string = (tags -> ('name:' || lang));
    if string is not null
    then return string; end if;

    default_lang = (select c.lang
                    from country_languages c
                    where a2 = country);

    if default_lang is not null
    then
        string =
        translate_text(
            coalesce(
                tags -> ('name:' || default_lang),
                tags -> 'name'
            ),
            default_lang,
            lang
        );
        if string is not null
        then return string; end if;
    end if;
--     if lang = 'ru'
--     then
--         string =
--         translate_text(
--             unidecode(
--                 coalesce(
--                     tags -> 'name:en',
--                     tags -> 'name:de',
--                     tags -> 'int_name',
--                     tags -> 'name'
--                 )
--             ),
--             'es',
--             lang
--         );
--         if string is not null
--         then return string; end if;
--     end if;
    if lang = 'en'
    then
        if default_lang in ('es', 'fr', 'de', 'nl', 'it', 'pl', 'id', 'tr', 'cz', 'pt')
        then
            string = coalesce(
                tags -> 'name:' || default_lang,
                tags -> 'name'
            );
            if string is not null
            then return string; end if;
        end if;
        string = unidecode(
            coalesce(
                tags -> 'name:en',
                --tags->'name:de',
                tags -> 'int_name',
                tags -> 'name'
            )
        );
        if string is not null
        then return string; end if;
    end if;

    return string;
end
$function$;

create or replace function osm_unwarp_languages(tags hstore, country text default '', p_osm_id text default '')
    returns hstore
language plpgsql
stable
as $function$
declare
    string    text;
    language  text;
    localized hstore;
begin
    localized = '';
    if p_osm_id != ''
    then
        localized = coalesce(
            (
                select name
                from wgnl_localizations w
                where w.osm_id = p_osm_id
            ),
            ''
        );
    end if;

    if country != '' and tags ? 'name'
    then
        string = ( select lang from country_languages where a2 = country);
        if not tags ? ('name:'||string) then
            localized = localized || hstore(string, tags -> 'name');
        end if;
    end if;

for language in (select skeys(tags)) loop
    if language like 'name:%'
    then
        string = tags -> language;
        language = replace(language, 'name:', '');
    else continue;
    end if;
    if not localized ? language then
        localized = localized || hstore(language, string);
    end if;
end loop;

if not localized?'en' then
    if tags ?'int_name' then
        localized = localized || hstore('en', tags -> 'int_name');
    end if;
    if (tags->'name') = unidecode(tags->'name') then
        localized = localized || hstore('en', tags -> 'name');
    end if;
end if;

if localized = ''
    then return null;
    else return localized;
end if;
end
$function$;


create or replace function wgcw_localize(tags hstore, country text default '', p_osm_id text default '')
    returns hstore
language plpgsql
stable
as $function$
declare
    string    text;
    language  text;
    localized hstore;
begin
    localized = osm_unwarp_languages(tags, country, p_osm_id);
    --if p_osm_id != ''
--     then
--         localized =  coalesce((select name
--                               from wgnl_localizations w
--                               where w.osm_id = p_osm_id), '');
--     end if;
    for language in (
        select unnest(
            array ['en', 'de', 'fr', 'es', 'cs', 'pl', 'tr', 'pt_BR', 'es_AR', 'ja', 'th', 'zh_TW', 'zh_CN', 'vi', 'be', 'ko', 'ru']
        )
    ) loop
        if (localized -> language) is null and
           language in ('pt_BR', 'es_AR', 'zh_TW')
        then
            if language = 'pt_BR' and localized ?'pt' then
                localized = localized || hstore(language, localized->'pt');
            end if;
            if language = 'es_AR' and localized ?'es' then
                localized = localized || hstore( language, localized->'es');
            end if;
            if language = 'zh_CN' and localized ?'zh' then
                localized = localized || hstore( language, localized->'zh');
            end if;
        end if;

        if (localized -> language) is null
        then
            string = osm_localize(tags, language, country);
        else
            string = localized->language;
        end if;
-- remove everything in brackets
        string = regexp_replace(string, '\(.*?\)', '', 'g');
-- remove everything after /
        string = split_part(string, '/', 1);
        string = split_part(string, ';', 1);
        string = split_part(string, ',', 1);
        string = split_part(string, '(', 1);
-- remove special characters
        string = regexp_replace(string, '[]@#_[?]', '', 'g');
        string = replace(string, '—', '-');
        string = replace(string, '--', '-');
        string = replace(string, '<<', '"');
        string = replace(string, '>>', '"');

        string = trim(from string);
        string = trim('-' from string);

        if string is null and language not in ('ru', 'ja', 'th', 'zh_TW', 'zh_CN', 'vi', 'be', 'ko') then
            string = localized -> 'en';
        end if;
        if string is null and language = 'ru' then
            string = translate_text(localized->'es', 'es', 'ru');
        end if;
        if string is null and language = 'ru' then
            string = translate_text(localized->'en', 'en', 'ru');
        end if;

        if string is not null
        then
            localized = localized || hstore(language, string);
        end if;
    end loop;

if localized = ''
    then return null;
    else return localized;
end if;
end
$function$;