CREATE OR REPLACE FUNCTION resetDBObjPerms(TEXT) RETURNS INTEGER AS '
DECLARE
  pObjname      ALIAS FOR $1;
BEGIN
  EXECUTE ''ALTER TABLE ''   || pObjname || '' OWNER TO '' || CURRENT_USER || '';'';
  EXECUTE ''REVOKE ALL ON '' || pObjname || '' FROM PUBLIC;'';
  EXECUTE ''GRANT  ALL ON '' || pObjname || '' TO GROUP openmfg;'';
  RETURN 1;
END;
' LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION resetDBObjPerms() RETURNS INTEGER AS '
DECLARE
  _count        INTEGER := 0;
BEGIN
  SELECT SUM(resetDBObjPerms(nspname || ''.'' || relname)) INTO _count
  FROM pg_catalog.pg_class, pg_catalog.pg_namespace
  WHERE (relkind IN (''r'', ''S'', ''v'')
    AND  (relnamespace=pg_namespace.oid)
    AND  (nspname IN (''public'', ''api'')));

  RETURN _count;
END;
' LANGUAGE 'plpgsql';
