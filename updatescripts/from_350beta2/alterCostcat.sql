ALTER TABLE costcat ADD COLUMN costcat_exp_accnt_id INTEGER REFERENCES accnt (accnt_id);