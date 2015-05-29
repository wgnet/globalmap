CREATE LANGUAGE plpython2u;
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
except IOError:
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
create index translate_cache_string_idx on translate_cache (string_from);

CREATE OR REPLACE FUNCTION translate_text (p_string text, p_from_lang text, p_to_lang text default 'ru', p_engine text default 'auto')
  RETURNS text
AS $$
DECLARE
    p_string_to text;
BEGIN
    if p_from_lang = p_to_lang then return p_string; end if;
    if p_engine = 'auto' then
        if p_to_lang = 'ru' then
            if p_from_lang in ('af', 'bg', 'cy', 'hu', 'es', 'it', 'de', 'nl', 'pl', 'ro', 'sr', 'sk', 'tr', 'fi', 'cr', 'cz') then
                p_engine = 'lebedev';
            elsif p_from_lang in ('en', '-ar', 'my', 'pt_BR', 'hu', 'vi', 'nl', 'el', 'da', 'he', 'es', 'it', 'zh-pinyin', 'zh-weid', 'ko-kp', 'ko-kr', 'mn', 'de', 'no', 'pl', 'pt', 'ro', 'sl', 'tl', 'tr', 'fi', 'fr', 'hi', 'cz', 'sv', 'ja', 'ja-hepbern', 'ja-fjapan') then
                p_engine = 'transscriba';
            end if;
        end if;
    end if;

    if p_engine = 'auto' then
        -- can't detect lang
        return null;
    end if;

    if p_engine = 'transscriba' and p_from_lang in ('mn', 'ar', 'el', 'hi', 'ko-kr', 'ko-kp', 'ja', 'ja-hepbern', 'ja-fjapan', 'he') then
        p_string = unidecode(p_string);
    end if;

    p_string_to = (select string_to from translate_cache where string_from = p_string and from_lang = p_from_lang and to_lang = p_to_lang and engine = p_engine);
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