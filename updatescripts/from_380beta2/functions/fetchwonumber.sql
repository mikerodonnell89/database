CREATE OR REPLACE FUNCTION fetchWoNumber() RETURNS INTEGER AS '
-- Copyright (c) 1999-2011 by OpenMFG LLC, d/b/a xTuple. 
-- See www.xtuple.com/CPAL for the full text of the software license.
DECLARE
  _woNumber INTEGER;
  _test INTEGER;

BEGIN

  LOOP
    SELECT orderseq_number INTO _woNumber
    FROM orderseq
    WHERE (orderseq_name=''WoNumber'');

    UPDATE orderseq
    SET orderseq_number = (orderseq_number + 1)
    WHERE (orderseq_name=''WoNumber'');

    SELECT wo_id INTO _test
    FROM wo
    WHERE (wo_number=_woNumber);

    IF (NOT FOUND) THEN
      EXIT;
    END IF;
  END LOOP;

  RETURN _woNumber;

END;
' LANGUAGE 'plpgsql';
