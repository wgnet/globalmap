CREATE LANGUAGE plpython2u;
CREATE OR REPLACE FUNCTION unidecode (string text)
  RETURNS text
AS $$
  import unidecode
  return unidecode.unidecode(string.decode('utf-8'))
$$ LANGUAGE plpython2u STRICT;