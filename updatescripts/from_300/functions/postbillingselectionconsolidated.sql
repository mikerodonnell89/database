CREATE OR REPLACE FUNCTION postBillingSelectionConsolidated(INTEGER) RETURNS INTEGER AS $$
DECLARE
  pCustid ALIAS FOR $1;
  _invcheadid INTEGER;
  _invcitemid INTEGER;
  _qtyToInvoice	NUMERIC;
  _r		RECORD;
  _s		RECORD;
  _c		RECORD;
  _i		RECORD;
  _count      INTEGER;
  _invcnumber INTEGER;
  _lastlinenumber INTEGER;

BEGIN
  _count := 0;

  FOR _c IN SELECT min(cobmisc_id) AS cobmisc_id, count(*) AS cnt,
-- there are the key values for consolidation
                   cohead_billtoname, cohead_billtoaddress1,
                   cohead_billtoaddress2, cohead_billtoaddress3,
                   cohead_billtocity, cohead_billtostate,
                   cohead_billtozipcode, cust_phone,
                   cohead_billtocountry,
                   cohead_salesrep_id, cohead_commission,
                   cohead_tax_id, cohead_terms_id,
                   cobmisc_misc_accnt_id,
                   cohead_prj_id, cobmisc_curr_id,
                   cobmisc_taxauth_id, cobmisc_tax_curr_id,
                   cobmisc_adjtax_id, cobmisc_adjtaxtype_id,
                   cobmisc_adjtax_pcta, cobmisc_adjtax_pctb, cobmisc_adjtax_pctc,
                   cobmisc_freighttax_id, cobmisc_freighttaxtype_id,
                   cobmisc_freighttax_pcta, cobmisc_freighttax_pctb, cobmisc_freighttax_pctc,
-- the following are consolidated values to use in creating the header
                   MIN(cohead_number) AS cohead_number,
                   MIN(cohead_orderdate) AS cohead_orderdate,
                   MIN(cobmisc_invcdate) AS cobmisc_invcdate,
                   MIN(cobmisc_shipdate) AS cobmisc_shipdate,
                   SUM(cobmisc_freight) AS cobmisc_freight,
                   COALESCE(SUM(cobmisc_tax), 0) AS cobmisc_tax,
                   SUM(cobmisc_tax_ratea) AS cobmisc_tax_ratea,
                   SUM(cobmisc_tax_rateb) AS cobmisc_tax_rateb,
                   SUM(cobmisc_tax_ratec) AS cobmisc_tax_ratec,
                   SUM(cobmisc_misc) AS cobmisc_misc,
                   SUM(cobmisc_payment) AS cobmisc_payment,
                   SUM(cobmisc_adjtax_ratea) AS cobmisc_adjtax_ratea,
                   SUM(cobmisc_adjtax_rateb) AS cobmisc_adjtax_rateb,
                   SUM(cobmisc_adjtax_ratec) AS cobmisc_adjtax_ratec,
                   SUM(cobmisc_freighttax_ratea) AS cobmisc_freighttax_ratea,
                   SUM(cobmisc_freighttax_rateb) AS cobmisc_freighttax_rateb,
                   SUM(cobmisc_freighttax_ratec) AS cobmisc_freighttax_ratec
              FROM cobmisc, cohead, cust
             WHERE((cobmisc_cohead_id=cohead_id)
               AND (cohead_cust_id=cust_id)
               AND (NOT cobmisc_posted)
               AND (cohead_cust_id=pCustid))
          GROUP BY cohead_billtoname, cohead_billtoaddress1,
                   cohead_billtoaddress2, cohead_billtoaddress3,
                   cohead_billtocity, cohead_billtostate,
                   cohead_billtozipcode, cust_phone,
                   cohead_billtocountry,
                   cohead_salesrep_id, cohead_commission,
                   cohead_tax_id, cohead_terms_id,
                   cobmisc_misc_accnt_id,
                   cohead_prj_id, cobmisc_curr_id,
                   cobmisc_taxauth_id, cobmisc_tax_curr_id,
                   cobmisc_adjtax_id, cobmisc_adjtaxtype_id,
                   cobmisc_adjtax_pcta, cobmisc_adjtax_pctb, cobmisc_adjtax_pctc,
                   cobmisc_freighttax_id, cobmisc_freighttaxtype_id,
                   cobmisc_freighttax_pcta, cobmisc_freighttax_pctb, cobmisc_freighttax_pctc LOOP

    IF(_c.cnt = 1) THEN
      PERFORM postBillingSelection(_c.cobmisc_id);
      _count := (_count + 1);
    ELSE
      SELECT NEXTVAL('invchead_invchead_id_seq'), fetchInvcNumber() INTO _invcheadid, _invcnumber;
  
  --  Create the Invoice header
      INSERT INTO invchead
      ( invchead_id, invchead_cust_id, invchead_shipto_id,
        invchead_ordernumber, invchead_orderdate,
        invchead_posted, invchead_printed,
        invchead_invcnumber, invchead_invcdate, invchead_shipdate,
        invchead_ponumber, invchead_shipvia, invchead_fob,
        invchead_billto_name, invchead_billto_address1,
        invchead_billto_address2, invchead_billto_address3,
        invchead_billto_city, invchead_billto_state,
        invchead_billto_zipcode, invchead_billto_phone,
        invchead_billto_country,
        invchead_shipto_name, invchead_shipto_address1,
        invchead_shipto_address2, invchead_shipto_address3,
        invchead_shipto_city, invchead_shipto_state,
        invchead_shipto_zipcode, invchead_shipto_phone,
        invchead_shipto_country,
        invchead_salesrep_id, invchead_commission,
        invchead_terms_id,
        invchead_freight, invchead_tax,
        invchead_tax_ratea, invchead_tax_rateb, invchead_tax_ratec,
        invchead_misc_amount, invchead_misc_descrip, invchead_misc_accnt_id,
        invchead_payment, invchead_paymentref,
        invchead_notes, invchead_prj_id, invchead_curr_id,
        invchead_taxauth_id, invchead_tax_curr_id,
        invchead_adjtax_id, invchead_adjtaxtype_id,
        invchead_adjtax_pcta, invchead_adjtax_pctb, invchead_adjtax_pctc,
        invchead_adjtax_ratea, invchead_adjtax_rateb, invchead_adjtax_ratec,
        invchead_freighttax_id, invchead_freighttaxtype_id,
        invchead_freighttax_pcta, invchead_freighttax_pctb, invchead_freighttax_pctc,
        invchead_freighttax_ratea, invchead_freighttax_rateb, invchead_freighttax_ratec )
      VALUES(_invcheadid,
             pCustid, -1,
             NULL, _c.cohead_orderdate,
             FALSE, FALSE,
             _invcnumber, _c.cobmisc_invcdate, _c.cobmisc_shipdate,
             'MULTIPLE', '', '',
             _c.cohead_billtoname, _c.cohead_billtoaddress1,
             _c.cohead_billtoaddress2, _c.cohead_billtoaddress3,
             _c.cohead_billtocity, _c.cohead_billtostate,
             _c.cohead_billtozipcode, _c.cust_phone,
             _c.cohead_billtocountry,
             '', '', '', '', '', '', '', '', '',
             _c.cohead_salesrep_id, COALESCE(_c.cohead_commission, 0),
             _c.cohead_terms_id,
             _c.cobmisc_freight, _c.cobmisc_tax,
             _c.cobmisc_tax_ratea, _c.cobmisc_tax_rateb, _c.cobmisc_tax_ratec,
             _c.cobmisc_misc, CASE WHEN(_c.cobmisc_misc <> 0) THEN 'Multiple' ELSE '' END,
             _c.cobmisc_misc_accnt_id,
             _c.cobmisc_payment, '',
             'Multiple Sales Order # Invoice', _c.cohead_prj_id, _c.cobmisc_curr_id,
             _c.cobmisc_taxauth_id, _c.cobmisc_tax_curr_id,
             _c.cobmisc_adjtax_id, _c.cobmisc_adjtaxtype_id,
             _c.cobmisc_adjtax_pcta, _c.cobmisc_adjtax_pctb, _c.cobmisc_adjtax_pctc,
             _c.cobmisc_adjtax_ratea, _c.cobmisc_adjtax_rateb, _c.cobmisc_adjtax_ratec,
             _c.cobmisc_freighttax_id, _c.cobmisc_freighttaxtype_id,
             _c.cobmisc_freighttax_pcta, _c.cobmisc_freighttax_pctb, _c.cobmisc_freighttax_pctc,
             _c.cobmisc_freighttax_ratea, _c.cobmisc_freighttax_rateb, _c.cobmisc_freighttax_ratec);
  
    _lastlinenumber := 0;
    FOR _i IN SELECT cobmisc_id
                FROM cobmisc, cohead, cust
               WHERE((cobmisc_cohead_id=cohead_id)
                 AND (cohead_cust_id=cust_id)
                 AND (NOT cobmisc_posted)
                 AND (cohead_cust_id=pCustid)
                 AND (COALESCE(cohead_billtoname,'')         = COALESCE(_c.cohead_billtoname,''))
                 AND (COALESCE(cohead_billtoaddress1,'')     = COALESCE(_c.cohead_billtoaddress1,''))
                 AND (COALESCE(cohead_billtoaddress2,'')     = COALESCE(_c.cohead_billtoaddress2,''))
                 AND (COALESCE(cohead_billtoaddress3,'')     = COALESCE(_c.cohead_billtoaddress3,''))
                 AND (COALESCE(cohead_billtocity,'')         = COALESCE(_c.cohead_billtocity,''))
                 AND (COALESCE(cohead_billtostate,'')        = COALESCE(_c.cohead_billtostate,''))
                 AND (COALESCE(cohead_billtozipcode,'')      = COALESCE(_c.cohead_billtozipcode,''))
                 AND (COALESCE(cust_phone,'')                = COALESCE(_c.cust_phone,''))
                 AND (COALESCE(cohead_billtocountry,'')      = COALESCE(_c.cohead_billtocountry,''))
                 AND (COALESCE(cohead_salesrep_id, 0)        = COALESCE(_c.cohead_salesrep_id, 0))
                 AND (COALESCE(cohead_commission, 0)         = COALESCE(_c.cohead_commission, 0))
                 AND (COALESCE(cohead_tax_id, 0)             = COALESCE(_c.cohead_tax_id, 0))
                 AND (COALESCE(cohead_terms_id, 0)           = COALESCE(_c.cohead_terms_id, 0))
                 AND (COALESCE(cobmisc_misc_accnt_id, 0)     = COALESCE(_c.cobmisc_misc_accnt_id, 0))
                 AND (COALESCE(cohead_prj_id, 0)             = COALESCE(_c.cohead_prj_id, 0))
                 AND (COALESCE(cobmisc_curr_id, 0)           = COALESCE(_c.cobmisc_curr_id, 0))
                 AND (COALESCE(cobmisc_taxauth_id, 0)        = COALESCE(_c.cobmisc_taxauth_id, 0))
                 AND (COALESCE(cobmisc_tax_curr_id, 0)       = COALESCE(_c.cobmisc_tax_curr_id, 0))
                 AND (COALESCE(cobmisc_adjtax_id, 0)         = COALESCE(_c.cobmisc_adjtax_id, 0))
                 AND (COALESCE(cobmisc_adjtaxtype_id, 0)     = COALESCE(_c.cobmisc_adjtaxtype_id, 0))
                 AND (COALESCE(cobmisc_adjtax_pcta, 0)       = COALESCE(_c.cobmisc_adjtax_pcta, 0))
                 AND (COALESCE(cobmisc_adjtax_pctb, 0)       = COALESCE(_c.cobmisc_adjtax_pctb, 0))
                 AND (COALESCE(cobmisc_adjtax_pctc, 0)       = COALESCE(_c.cobmisc_adjtax_pctc, 0))
                 AND (COALESCE(cobmisc_freighttax_id, 0)     = COALESCE(_c.cobmisc_freighttax_id, 0))
                 AND (COALESCE(cobmisc_freighttaxtype_id, 0) = COALESCE(_c.cobmisc_freighttaxtype_id, 0))
                 AND (COALESCE(cobmisc_freighttax_pcta, 0)   = COALESCE(_c.cobmisc_freighttax_pcta, 0))
                 AND (COALESCE(cobmisc_freighttax_pctb, 0)   = COALESCE(_c.cobmisc_freighttax_pctb, 0))
                 AND (COALESCE(cobmisc_freighttax_pctc, 0)   = COALESCE(_c.cobmisc_freighttax_pctc, 0))) LOOP

    --  Give this selection a number if it has not been assigned one
        UPDATE cobmisc
           SET cobmisc_invcnumber=_invcnumber
         WHERE(cobmisc_id=_i.cobmisc_id);
      
    --  Create the Invoice items
        FOR _r IN SELECT coitem_id, coitem_linenumber, coitem_custpn,
                         coitem_qtyord, cobill_qty,
                         coitem_qty_uom_id, coitem_qty_invuomratio,
                         coitem_custprice, coitem_price,
                         coitem_price_uom_id, coitem_price_invuomratio,
                         coitem_memo,
                         itemsite_item_id, itemsite_warehous_id,
                         cobill_tax_id, cobill_taxtype_id,
                         cobill_tax_pcta, cobill_tax_pctb, cobill_tax_pctc,
                         cobill_tax_ratea, cobill_tax_rateb, cobill_tax_ratec
                    FROM coitem, cobill, itemsite
                   WHERE((cobill_coitem_id=coitem_id)
                     AND (coitem_itemsite_id=itemsite_id)
                     AND (cobill_cobmisc_id=_i.cobmisc_id) ) LOOP
      
          SELECT NEXTVAL('invcitem_invcitem_id_seq') INTO _invcitemid;
          INSERT INTO invcitem
          ( invcitem_id, invcitem_invchead_id,
            invcitem_linenumber, invcitem_item_id, invcitem_warehous_id,
            invcitem_custpn, invcitem_number, invcitem_descrip,
            invcitem_ordered, invcitem_billed,
            invcitem_qty_uom_id, invcitem_qty_invuomratio,
            invcitem_custprice, invcitem_price,
            invcitem_price_uom_id, invcitem_price_invuomratio,
            invcitem_notes,
            invcitem_tax_id, invcitem_taxtype_id,
            invcitem_tax_pcta, invcitem_tax_pctb, invcitem_tax_pctc,
            invcitem_tax_ratea, invcitem_tax_rateb, invcitem_tax_ratec,
            invcitem_coitem_id )
          VALUES
          ( _invcitemid, _invcheadid,
            _lastlinenumber + _r.coitem_linenumber, _r.itemsite_item_id, _r.itemsite_warehous_id,
            _r.coitem_custpn, '', '',
            _r.coitem_qtyord, _r.cobill_qty,
            _r.coitem_qty_uom_id, _r.coitem_qty_invuomratio,
            _r.coitem_custprice, _r.coitem_price,
            _r.coitem_price_uom_id, _r.coitem_price_invuomratio,
            _r.coitem_memo,
            _r.cobill_tax_id, _r.cobill_taxtype_id,
            _r.cobill_tax_pcta, _r.cobill_tax_pctb, _r.cobill_tax_pctc,
            _r.cobill_tax_ratea, _r.cobill_tax_rateb, _r.cobill_tax_ratec,
            _r.coitem_id );
      
      --  Find and mark any Lot/Serial invdetail records associated with this bill
          UPDATE invdetail SET invdetail_invcitem_id = _invcitemid
           WHERE (invdetail_id IN (SELECT invdetail_id
                                     FROM coitem, cohead, invhist, invdetail
                                    WHERE ((coitem_cohead_id=cohead_id)
                                      AND  (invdetail_invhist_id=invhist_id)
                                      AND  (invhist_ordnumber = text(cohead_number||'-'||coitem_linenumber))
                                      AND  (invdetail_invcitem_id IS NULL)
                                      AND  (coitem_id=_r.coitem_id)) ) );
      
      --  Mark any shipped, uninvoiced shipitems for the current coitem as invoiced
          _qtyToInvoice :=  _r.cobill_qty;
          FOR _s IN SELECT shipitem.*, shipitem_qty = _r.cobill_qty AS matched
	            FROM shipitem, shiphead
	            WHERE ((shipitem_shiphead_id=shiphead_id)
	              AND  (shipitem_orderitem_id=_r.coitem_id)
	              AND  (shiphead_shipped)
		      AND  (shiphead_order_type='SO')
	              AND  (NOT shipitem_invoiced))
	            ORDER BY matched DESC, shipitem_qty DESC FOR UPDATE LOOP
            IF (_qtyToInvoice >= _s.shipitem_qty) THEN
	      UPDATE shipitem
	      SET shipitem_invoiced=TRUE, shipitem_invcitem_id=_invcitemid
	      WHERE (shipitem_id=_s.shipitem_id);
	      _qtyToInvoice := _qtyToInvoice - _s.shipitem_qty;
            END IF;
            IF (_qtyToInvoice <= 0) THEN
	      EXIT;
            END IF;
          END LOOP;
    
        END LOOP;
    
        UPDATE cobill SET cobill_invcnum=cobmisc_invcnumber,
		          cobill_invcitem_id=invcitem_id
        FROM invcitem, coitem, cobmisc
        WHERE ((invcitem_linenumber=(_lastlinenumber + coitem_linenumber))
          AND  (coitem_id=cobill_coitem_id)
          AND  (cobmisc_id=cobill_cobmisc_id)
          AND  (cobill_cobmisc_id=_i.cobmisc_id)
          AND  (invcitem_invchead_id=_invcheadid));
  
      --  Close all requested coitem's
        IF ( ( SELECT cobmisc_closeorder
               FROM cobmisc
               WHERE (cobmisc_id=_i.cobmisc_id) ) ) THEN
          UPDATE coitem
          SET coitem_status='C'
          FROM cobmisc
          WHERE ( (coitem_status NOT IN ('C', 'X'))
           AND (coitem_cohead_id=cobmisc_cohead_id)
           AND (cobmisc_id=_i.cobmisc_id) );
        ELSE
          UPDATE coitem
          SET coitem_status='C'
          FROM cobill
          WHERE ( (cobill_coitem_id=coitem_id)
           AND (coitem_status <> 'X')
           AND (cobill_toclose)
           AND (cobill_cobmisc_id=_i.cobmisc_id) );
        END IF;
      
      --  Mark the cobmisc as posted
        UPDATE cobmisc
        SET cobmisc_posted=TRUE, cobmisc_invchead_id=_invcheadid
        WHERE (cobmisc_id=_i.cobmisc_id);

      SELECT COALESCE(max(invcitem_linenumber),0) INTO _lastlinenumber
        FROM invcitem
       WHERE(invcitem_invchead_id=_invcheadid);
    
      --  All done
        _count := (_count + 1);
      END LOOP;
    END IF;
  END LOOP;
  RETURN _count;
END;
$$ LANGUAGE 'plpgsql';
