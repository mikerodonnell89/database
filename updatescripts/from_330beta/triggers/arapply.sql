CREATE OR REPLACE FUNCTION _arapplyTrigger() RETURNS TRIGGER AS $$
DECLARE
  _tpaid NUMERIC;

BEGIN

-- get the exchange rate for the doc date
  IF (TG_OP = 'INSERT') THEN
    IF (NEW.arapply_target_doctype != 'K') THEN 
      SELECT round(currtocurr(NEW.arapply_curr_id,aropen_curr_id,NEW.arapply_applied,NEW.arapply_postdate),2) 
        INTO _tpaid
      FROM aropen
      WHERE ( aropen_id=NEW.arapply_target_aropen_id );
    ELSE
      SELECT round(currtocurr(NEW.arapply_curr_id,aropen_curr_id,NEW.arapply_applied,NEW.arapply_postdate),2) 
        INTO _tpaid
      FROM aropen
      WHERE ( aropen_id=NEW.arapply_source_aropen_id );
    END IF;
    IF (FOUND) THEN
      NEW.arapply_target_paid := _tpaid;
    ELSE
      RAISE EXCEPTION 'Error calculating paid amount on application';
    END IF;
  END IF;

  RETURN NEW;

END;

$$ LANGUAGE 'plpgsql';

SELECT dropifexists('TRIGGER', 'arapplyTrigger');
CREATE TRIGGER arapplyTrigger BEFORE INSERT OR UPDATE ON arapply FOR EACH ROW EXECUTE PROCEDURE _arapplyTrigger();
