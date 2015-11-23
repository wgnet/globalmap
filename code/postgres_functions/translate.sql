CREATE OR REPLACE LANGUAGE plpython2u;
CREATE OR REPLACE FUNCTION transcribe_transscriba (string text, from_lang text, to_lang text default 'ru')
  RETURNS text
AS $$
import urllib
import urllib2
import re

langs = {
    'en':   "english",
    'ar':   "arabik", # Арабский
    'my':   "birma", # Бирманский
    'pt_BR':"brasil", # Бразильский
    'hu':   "hungary", # Венгерский
    'vi':   "vietnam", # Вьетнамский
    'nl':   "niderlands", # Голландский
    'el':   "hellenic", # Греческий
    'da':   "danish", # Датский
    'he':   "hebrew", # Иврит
    'es':   "espanol", # Испанский
    'it':   "italiano", # Итальянский
    'zh-pinyin':"chineese", # Китайский (Пинь-ин)
    'zh-weid': "chineeseweid", # Китайский (Уэйд)
    'ko-kp':"nkorean", # Корея (Сев.)
    'ko-kr':"skorean", # Корея (Южн.)
    'mn':   "mongol", # Монгольский
    'de':   "deutsch", # Немецкий
    'no':   "norsk", # Норвежский
    'pl':   "polska", # Польский
    'pt':   "portuguese", # Португальский
    'ro':   "romanian", # Румынский
    'sl':   "slovenska", # Словенский
    'tl':   "tagal", # Тагальский
    'tr':   "turkish", # Турецкий
    'fi':   "suomi", # Финнский
    'fr':   "francais", # Французский
    'hi':   "hindi", # Хинди
    'cz':   "cheska", # Чешский
    'sv':   "swerige", # Шведский
    'ja':   "japan", # Японский
    'ja-hepbern': "hepbern", # Японский (Хепберна)
    'ja-fjapan':"fjapan" # Японский (с доп. латиницей)
}
if to_lang != 'ru':
    return None
if from_lang in langs:
    lang = langs[from_lang]
else:
    return None
text = string.replace("ß", "ss")

try:
    return re.search(
        'id="Label2">(.*)<br>',
        urllib2.urlopen(
            "http://transscriba.keldysh.ru/default.aspx",
            urllib.urlencode({
                'ListBox1': lang,
                'TextBox1': text,
                '__VIEWSTATE':'/wEPDwUKLTgyNDc3Mjg4NA9kFgICAQ9kFgICAQ8QZGQWAGRkMGXYj/uJ5kn8jDCa0tJhEnaon7o=', '__EVENTVALIDATION':'/wEWJAKKv5WHAQKameKJBAKO98nRBwL+naTQCALt99m4CAL/y5u/CALvnYWaBgKrupuyDwKV57K6BAKKqt7OBwLEg8edDQKG0KnxDwK6/83MDALv1o3+AwLh9KacBgL3lLf8AgKCibf8AgKBrP7IDQL38ZCyAwKAnJTpAQLg/P61BwLRm8/YAgL3oa/IBwLjwbrICgK486qpDQLSvd7PBgK2ubj4DALAvLb/AQKkr8LRBwLmyq5zAqnl7OcFAt3q+LEDApKi9IoKAun0/bICAuzRsusGAoznisYG+Z0ZiC5WycrTNtKJofRi2YqVuKU=',
                'Button1': 'Перевести'}),
            timeout = 3
        ).read()).groups()[0].strip()
except (IOError, AttributeError):
    return None
$$ LANGUAGE plpython2u STRICT;

CREATE OR REPLACE FUNCTION transcribe_lebedev (string text, from_lang text, to_lang text default 'ru')
  RETURNS text
AS $$
import urllib
import urllib2
import re

langs = {
    'af': 'afrikaans', # африкаанс
    'bg': 'bulgarian', # болгарский
    'cy': 'welsh', # валлийский
    'hu': 'hungarian', # венгерский
    'es': 'spanish', # испанский
    'it': 'italian', # итальянский
    'de': 'german', # немецкий
    'nl': 'dutch', # нидерландский
    'pl': 'polish', # польский
    'ro': 'romanian', # румынский
    'sr': 'serbian', # сербский
    'sk': 'slovakian', # словацкий
    'tr': 'turkish', # турецкий
    'fi': 'finnish', # финский
    'cr': 'croatian', # хорватский
    'cz': 'czech' # чешский
}
if to_lang != 'ru':
    return None
if from_lang in langs:
    lang = langs[from_lang]
else:
    return None
text = string
if lang == "czech":
    text = text.replace("mě","mně")
    text = text.replace("Mě","Mně")
    text = text.replace("ô","uo")
try:
    return re.search(r'<result>(.*)</result>',
        urllib2.urlopen(
            "http://www.artlebedev.ru/tools/transcriptor/%s/" % lang,
            urllib.urlencode({'mode':'transcribe','text':text}),
            timeout = 3
        ).read(), re.DOTALL).groups()[0].strip().replace('&apos;', "'").strip("'").replace('&quot;', '"')
except IOError:
    return None
$$ LANGUAGE plpython2u STRICT;

create table if not exists translate_cache (string_from text, string_to text, from_lang text, to_lang text, engine text);
-- create index translate_cache_string_idx on translate_cache (string_from);

CREATE OR REPLACE FUNCTION translate_text (p_string text, p_from_lang text, p_to_lang text default 'ru', p_engine text default 'auto')
  RETURNS text
AS $$
DECLARE
    p_string_to text;
BEGIN
    if p_from_lang = p_to_lang then return p_string; end if;

    -- detect engine
    if p_engine = 'auto' then

        -- first try to search in osm data
        p_string_to = (select string_to from translate_cache where string_from = p_string and to_lang = p_to_lang and engine = 'osm' order by from_lang = p_from_lang desc limit 1);
        if p_string_to is not null then
            return p_string_to;
        end if;

        -- let's check if RNN was trained for this
        if not (p_from_lang in ('es', 'fr', 'de', 'nl', 'it', 'pl', 'id', 'tr', 'cz', 'pt') and p_to_lang = 'en') then
            p_string_to = (select string_to from translate_cache where string_from = p_string and to_lang = p_to_lang and engine = 'rnn' order by from_lang = p_from_lang desc limit 1);
            if p_string_to is not null then
                return p_string_to;
            end if;
        end if;
    end if;

    -- localization team tweaks
    if p_engine = 'auto' then
        -- to ru
        -- AZE
        if p_from_lang = 'az' and p_to_lang = 'ru' then
            p_string = replace(replace(replace(p_string, 'ə', 'a'), 'Q', 'Г'), 'c', 'дж');
            p_string = unidecode(p_string);
            p_from_lang = 'es';
            p_engine = 'lebedev';
        end if;
        -- BEL
        if p_from_lang = 'nl' and p_to_lang = 'ru' then
            p_string = replace(replace(replace(replace(p_string, ' ', '-'), 'che', 'ш'), '-en-', '-ан-'), 'gn', 'нь');
        end if;
        -- BIH
        if p_from_lang = 'bs' and p_to_lang = 'ru' then
            p_string = replace(replace(replace(replace(replace(replace(p_string, 'h', 'х'), 'š', 'ш'), 'ć', 'ч'), 'č', 'ч'), 'c', 'ц'), 'j', 'ь');
            p_string = unidecode(p_string);
            p_from_lang = 'es';
            p_engine = 'lebedev';
        end if;
        -- DEU
        if p_from_lang = 'de' and p_to_lang = 'ru' then
            p_string = replace(replace(p_string, ' ', '-'), 'ß', 'сс');
        end if;
        -- DNK
        if p_from_lang = 'da' and p_to_lang = 'ru' then
            p_string = replace(replace(p_string, ' ', '-'), 'æ', 'е');
        end if;

--         if p_from_lang = 'ar' and p_to_lang = 'ru' then
--             p_string = unidecode(p_string);
--             -- DZA
--             p_string = replace(replace(p_string, ' ', '-'), 'j', 'дж');
--             -- IRN
--             p_string = replace(replace(p_string, 'h', 'х'), 'j', 'дж');
--             -- IRQ
--             p_string = replace(replace(p_string, 'z', 'з'), 'sh', 'ш');
--             p_string = translate_text(p_string, 'es', 'ru');
--             return p_string;
--         end if;
        -- ESP
        if p_from_lang = 'es' and p_to_lang = 'ru' then
            p_string = replace(replace(p_string, ' ', '-'), 'gua', 'гуа');
        end if;
        -- FRA
        if p_from_lang = 'fr' and p_to_lang = 'ru' then
            p_string = replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(p_string, ' ', ' '), '-le-', '-ле-'), 'Saint', 'Сен'), 'Le ', 'Ле '), '-en-', '-ан-'), 'L''', 'Л'''), 'ç', 'с'), 'lle', 'ель'), 'lles', 'ель'), 'ens', 'ан'), 'erre', 'ер'), 'eville', 'виль'), 'éville', 'виль');
        end if;

        if p_from_lang = 'en' and p_to_lang = 'ru' then
            -- GBR
            p_string = replace(replace(replace(p_string, ' ', '-'), '-upon-', '-апон-'), 'burgh', 'боро');
            -- IRL
            p_string = replace(replace(replace(replace(replace(replace(p_string, 'ee', 'и'), 'Kn', 'Н'), 'ey', 'и'), 'Bally', 'Балли'), 'Mount', 'Маунт'), 'Castle', 'Касл');
        end if;
        -- KAZ
        if p_from_lang = 'kz' and p_to_lang = 'ru' then
            p_string = unidecode(p_string);
            p_string = replace(replace(replace(p_string, 'yzy', 'ызы'), 'zh', 'ж'), 'sh', 'ш');
            p_string = translate_text(p_string, 'es', 'ru');
            return p_string;
        end if;
        -- LTU
        if p_from_lang = 'lt' and p_to_lang = 'ru' then
            p_string = replace(p_string, 'š', 'ш');
            p_string = replace(p_string, 'Š', 'Ш');
            p_string = replace(p_string, 'ž', 'з');
            p_string = translate_text(p_string, 'es', 'ru');
            return p_string;
        end if;
        -- LVA
        if p_from_lang = 'lv' and p_to_lang = 'ru' then
            p_string = replace(p_string, 'š', 'ш');
            p_string = replace(p_string, 'Š', 'Ш');
            p_string = replace(p_string, 'ž', 'з');
            p_string = translate_text(p_string, 'es', 'ru');
            return p_string;
        end if;
        -- NOR
        if p_from_lang = 'no' and p_to_lang = 'ru' then
            p_string = replace(replace(p_string, 'o', 'о'), 'nnd', 'ннд');
        end if;
        -- ROU
        if p_from_lang = 'ro' and p_to_lang = 'ru' then
            p_string = replace(replace(p_string, 'ș', 'ш'), 'ț', 'ц');
        end if;
        -- SWE
        if p_from_lang = 'sv' and p_to_lang = 'ru' then
            p_string = replace(replace(replace(replace(p_string, 'rs', 'рс'), 'Lju', 'Лю'), 'y', 'ю'), 'å', 'о');
        end if;
        -- TUR
        if p_from_lang = 'tr' and p_to_lang = 'ru' then
            p_string = replace(replace(p_string, 'ğ', 'й'), 'l', 'ль');
        end if;
        -- CHN
        if p_from_lang = 'zh' and p_to_lang = 'ru' then
            p_string = unidecode(p_string);
            p_string = translate_text(p_string, 'zh-pinyin', 'ru');
            return p_string;
        end if;

        -- to en
        -- BGR
        if p_from_lang = 'bg' and p_to_lang = 'en' then
            p_string = replace(p_string, 'вград', 'vgrad');
            p_string = unidecode(p_string);
            return p_string;
        end if;
        -- DEU
        if p_from_lang = 'de' and p_to_lang = 'en' then
            p_string = replace(p_string, 'ß', 'ss');
        end if;

    end if;



    if p_engine = 'auto' then
        if p_to_lang = 'ru' then
            if p_from_lang in ('af', 'bg', 'cy', 'hu', 'es', 'it', 'de', 'nl', 'pl', 'ro', 'sr', 'sk', 'tr', 'fi', 'cr', 'cz') then
                p_engine = 'lebedev';
            elsif p_from_lang in ('en', 'my', 'pt_BR', 'hu', 'vi', 'nl', 'da', 'he', 'es', 'it', 'zh-pinyin',
            'zh-weid', 'ko-kp', 'ko-kr', 'mn', 'de', 'no', 'pl', 'pt', 'ro', 'sl', 'tl', 'tr', 'fi', 'fr', 'hi', 'cz', 'sv',
            'ja', 'ja-hepbern', 'ja-fjapan') then
                p_engine = 'transscriba';
            end if;
        end if;
    end if;

    if p_engine = 'auto' then
        if p_from_lang = 'ru' and p_to_lang = 'en' then
            return replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
            replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
            translate(p_string, 'абвгдезиклмнопрстуфьАБВГДЕЗИКЛМНОПРСТУФЬ', 'abvgdeziklmnoprstuf’ABVGDEZIKLMNOPRSTUF’'),
            'х','kh'),'Х','Kh'),'ц','ts'),'Ц','Ts'),'ч','ch'),'Ч','Ch'),'ш','sh'),'Ш','Sh'),'щ','shch'),'Щ','Shch'),'ъ','y'),
            'Ъ','Y'),'ё','yo'),'Ё','Yo'),'ы','y'),'Ы','Y'),'э','e'),'Э','E'),'ю','yu'),'Ю','Yu'),'й','y'),'Й','Y'),'я','ya'),
            'Я','Ya'),'ж','zh'),'Ж','Zh');
        end if;
        if p_from_lang = 'be' and p_to_lang = 'en' then
            return replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
            (replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(
            translate(p_string, 'АБВГДЖЗІЙКЛМНОПРСТУЎФЦЧШЫЭабвгджзійклмнопрстуўфцчшыэ', 'ABVHDŽZIJKLMNOPRSTUŬFСČŠYEabvhdžzijklmnoprstuŭfсčšye'),
            'х', 'ch'), 'Х', 'Ch'), 'BЕ', 'BIe'), 'BЁ', 'BIo'), 'BЮ', 'BIu'), 'BЯ', 'BIa'), 'Bе', 'Bie'), 'Bё', 'Bio'),
            'Bю', 'Biu'), 'Bя', 'Bia'), 'VЕ', 'VIe'), 'VЁ', 'VIo'), 'VЮ', 'VIu'), 'VЯ', 'VIa'), 'Vе', 'Vie'), 'Vё', 'Vio'),
            'Vю', 'Viu'), 'Vя', 'Via'), 'HЕ', 'HIe'), 'HЁ', 'HIo'), 'HЮ', 'HIu'), 'HЯ', 'HIa'), 'Hе', 'Hie'), 'Hё', 'Hio'),
            'Hю', 'Hiu'), 'Hя', 'Hia'), 'DЕ', 'DIe'), 'DЁ', 'DIo'), 'DЮ', 'DIu'), 'DЯ', 'DIa'), 'Dе', 'Die'), 'Dё', 'Dio'),
            'Dю', 'Diu'), 'Dя', 'Dia'), 'ŽЕ', 'ŽIe'), 'ŽЁ', 'ŽIo'), 'ŽЮ', 'ŽIu'), 'ŽЯ', 'ŽIa'), 'Žе', 'Žie'), 'Žё', 'Žio'),
            'Žю', 'Žiu'), 'Žя', 'Žia'), 'ZЕ', 'ZIe'), 'ZЁ', 'ZIo'), 'ZЮ', 'ZIu'), 'ZЯ', 'ZIa'), 'Zе', 'Zie'), 'Zё', 'Zio'),
            'Zю', 'Ziu'), 'Zя', 'Zia'), 'JЕ', 'JIe'), 'JЁ', 'JIo'), 'JЮ', 'JIu'), 'JЯ', 'JIa'), 'Jе', 'Jie'), 'Jё', 'Jio'),
            'Jю', 'Jiu'), 'Jя', 'Jia'), 'КЕ', 'КIe'), 'КЁ', 'КIo'), 'КЮ', 'КIu'), 'КЯ', 'КIa'), 'Ке', 'Кie'), 'Кё', 'Кio'),
            'Кю', 'Кiu'), 'Кя', 'Кia'), 'LЕ', 'LIe'), 'LЁ', 'LIo'), 'LЮ', 'LIu'), 'LЯ', 'LIa'), 'Lе', 'Lie'), 'Lё', 'Lio'),
            'Lю', 'Liu'), 'Lя', 'Lia'), 'MЕ', 'MIe'), 'MЁ', 'MIo'), 'MЮ', 'MIu'), 'MЯ', 'MIa'), 'Mе', 'Mie'), 'Mё', 'Mio'),
            'Mю', 'Miu'), 'Mя', 'Mia'), 'NЕ', 'NIe'), 'NЁ', 'NIo'), 'NЮ', 'NIu'), 'NЯ', 'NIa'), 'Nе', 'Nie'), 'Nё', 'Nio'),
            'Nю', 'Niu'), 'Nя', 'Nia'), 'PЕ', 'PIe'), 'PЁ', 'PIo'), 'PЮ', 'PIu'), 'PЯ', 'PIa'), 'Pе', 'Pie'), 'Pё', 'Pio'),
            'Pю', 'Piu'), 'Pя', 'Pia'), 'RЕ', 'RIe'), 'RЁ', 'RIo'), 'RЮ', 'RIu'), 'RЯ', 'RIa'), 'Rе', 'Rie'), 'Rё', 'Rio'),
            'Rю', 'Riu'), 'Rя', 'Ria'), 'SЕ', 'SIe'), 'SЁ', 'SIo'), 'SЮ', 'SIu'), 'SЯ', 'SIa'), 'Sе', 'Sie'), 'Sё', 'Sio'),
            'Sю', 'Siu'), 'Sя', 'Sia'), 'TЕ', 'TIe'), 'TЁ', 'TIo'), 'TЮ', 'TIu'), 'TЯ', 'TIa'), 'Tе', 'Tie'), 'Tё', 'Tio'),
            'Tю', 'Tiu'), 'Tя', 'Tia'), 'ŬЕ', 'ŬIe'), 'ŬЁ', 'ŬIo'), 'ŬЮ', 'ŬIu'), 'ŬЯ', 'ŬIa'), 'Ŭе', 'Ŭie'), 'Ŭё', 'Ŭio'),
            'Ŭю', 'Ŭiu'), 'Ŭя', 'Ŭia'), 'FЕ', 'FIe'), 'FЁ', 'FIo'), 'FЮ', 'FIu'), 'FЯ', 'FIa'), 'Fе', 'Fie'), 'Fё', 'Fio'),
            'Fю', 'Fiu'), 'Fя', 'Fia'), 'СЕ', 'СIe'), 'СЁ', 'СIo'), 'СЮ', 'СIu'), 'СЯ', 'СIa'), 'Се', 'Сie'), 'Сё', 'Сio'),
            'Сю', 'Сiu'), 'Ся', 'Сia'), 'ČЕ', 'ČIe'), 'ČЁ', 'ČIo'), 'ČЮ', 'ČIu'), 'ČЯ', 'ČIa'), 'Čе', 'Čie'), 'Čё', 'Čio'),
            'Čю', 'Čiu'), 'Čя', 'Čia'), 'ŠЕ', 'ŠIe'), 'ŠЁ', 'ŠIo'), 'ŠЮ', 'ŠIu'), 'ŠЯ', 'ŠIa'), 'Šе', 'Šie'), 'Šё', 'Šio'),
            'Šю', 'Šiu'), 'Šя', 'Šia'), 'bЕ', 'bIe'), 'bЁ', 'bIo'), 'bЮ', 'bIu'), 'bЯ', 'bIa'), 'bе', 'bie'), 'bё', 'bio'),
            'bю', 'biu'), 'bя', 'bia'), 'vЕ', 'vIe'), 'vЁ', 'vIo'), 'vЮ', 'vIu'), 'vЯ', 'vIa'), 'vе', 'vie'), 'vё', 'vio'),
            'vю', 'viu'), 'vя', 'via'), 'hЕ', 'hIe'), 'hЁ', 'hIo'), 'hЮ', 'hIu'), 'hЯ', 'hIa'), 'hе', 'hie'), 'hё', 'hio'),
            'hю', 'hiu'), 'hя', 'hia'), 'dЕ', 'dIe'), 'dЁ', 'dIo'), 'dЮ', 'dIu'), 'dЯ', 'dIa'), 'dе', 'die'), 'dё', 'dio'),
            'dю', 'diu'), 'dя', 'dia'), 'žЕ', 'žIe'), 'žЁ', 'žIo'), 'žЮ', 'žIu'), 'žЯ', 'žIa'), 'žе', 'žie'), 'žё', 'žio'),
            'žю', 'žiu'), 'žя', 'žia'), 'zЕ', 'zIe'), 'zЁ', 'zIo'), 'zЮ', 'zIu'), 'zЯ', 'zIa'), 'zе', 'zie'), 'zё', 'zio'),
            'zю', 'ziu'), 'zя', 'zia'), 'jЕ', 'jIe'), 'jЁ', 'jIo'), 'jЮ', 'jIu'), 'jЯ', 'jIa'), 'jе', 'jie'), 'jё', 'jio'),
            'jю', 'jiu'), 'jя', 'jia'), 'кЕ', 'кIe'), 'кЁ', 'кIo'), 'кЮ', 'кIu'), 'кЯ', 'кIa'), 'ке', 'кie'), 'кё', 'кio'),
            'кю', 'кiu'), 'кя', 'кia'), 'lЕ', 'lIe'), 'lЁ', 'lIo'), 'lЮ', 'lIu'), 'lЯ', 'lIa'), 'lе', 'lie'), 'lё', 'lio'),
            'lю', 'liu'), 'lя', 'lia'), 'mЕ', 'mIe'), 'mЁ', 'mIo'), 'mЮ', 'mIu'), 'mЯ', 'mIa'), 'mе', 'mie'), 'mё', 'mio'),
            'mю', 'miu'), 'mя', 'mia'), 'nЕ', 'nIe'), 'nЁ', 'nIo'), 'nЮ', 'nIu'), 'nЯ', 'nIa'), 'nе', 'nie'), 'nё', 'nio'),
            'nю', 'niu'), 'nя', 'nia'), 'pЕ', 'pIe'), 'pЁ', 'pIo'), 'pЮ', 'pIu'), 'pЯ', 'pIa'), 'pе', 'pie'), 'pё', 'pio'),
            'pю', 'piu'), 'pя', 'pia'), 'rЕ', 'rIe'), 'rЁ', 'rIo'), 'rЮ', 'rIu'), 'rЯ', 'rIa'), 'rе', 'rie'), 'rё', 'rio'),
            'rю', 'riu'), 'rя', 'ria'), 'sЕ', 'sIe'), 'sЁ', 'sIo'), 'sЮ', 'sIu'), 'sЯ', 'sIa'), 'sе', 'sie'), 'sё', 'sio'),
            'sю', 'siu'), 'sя', 'sia'), 'tЕ', 'tIe'), 'tЁ', 'tIo'), 'tЮ', 'tIu'), 'tЯ', 'tIa'), 'tе', 'tie'), 'tё', 'tio'),
            'tю', 'tiu'), 'tя', 'tia'), 'ŭЕ', 'ŭIe'), 'ŭЁ', 'ŭIo'), 'ŭЮ', 'ŭIu'), 'ŭЯ', 'ŭIa'), 'ŭе', 'ŭie'), 'ŭё', 'ŭio'),
            'ŭю', 'ŭiu'), 'ŭя', 'ŭia'), 'fЕ', 'fIe'), 'fЁ', 'fIo'), 'fЮ', 'fIu'), 'fЯ', 'fIa'), 'fе', 'fie'), 'fё', 'fio'),
            'fю', 'fiu'), 'fя', 'fia'), 'сЕ', 'сIe'), 'сЁ', 'сIo'), 'сЮ', 'сIu'), 'сЯ', 'сIa'), 'се', 'сie'), 'сё', 'сio'),
            'сю', 'сiu'), 'ся', 'сia'), 'čЕ', 'čIe'), 'čЁ', 'čIo'), 'čЮ', 'čIu'), 'čЯ', 'čIa'), 'čе', 'čie'), 'čё', 'čio'),
            'čю', 'čiu'), 'čя', 'čia'), 'šЕ', 'šIe'), 'šЁ', 'šIo'), 'šЮ', 'šIu'), 'šЯ', 'šIa'), 'šе', 'šie'), 'šё', 'šio'),
            'šю', 'šiu'), 'šя', 'šia'), 'Е', 'Je'), 'Ё', 'Jo'), 'Ю', 'Ju'), 'Я', 'Ja'), 'е', 'je'), 'ё', 'jo'), 'ю', 'ju'),
            'я', 'ja'), 'Ь', '\u0301'), 'ь', '\u0301'),'’', '');
        end if;
        -- can't detect lang
        return null;
    end if;

    if p_engine = 'transscriba' and p_from_lang in ('mn', 'ar', 'hi', 'ko-kr', 'ko-kp', 'ja', 'ja-hepbern', 'ja-fjapan', 'he') then
        p_string = unidecode(p_string);
    end if;

    p_string_to = (select string_to from translate_cache where string_from = p_string and from_lang = p_from_lang and to_lang = p_to_lang and engine = p_engine limit 1);
    if p_string_to is not null then
        return p_string_to;
    end if;

    if p_engine = 'transscriba' then
        p_string_to = transcribe_transscriba(p_string, p_from_lang, p_to_lang);
    elsif p_engine = 'lebedev' then
        p_string_to = transcribe_lebedev(p_string, p_from_lang, p_to_lang);
    end if;

    if p_string_to is not null then
        insert into translate_cache (string_from, string_to, from_lang, to_lang, engine) values (p_string, p_string_to, p_from_lang, p_to_lang, p_engine);
    end if;

    return p_string_to;
END
$$ LANGUAGE plpgsql STRICT;
