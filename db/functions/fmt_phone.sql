-- =============================================================================
-- FUNCTION: FMT_PHONE
-- =============================================================================
-- Formats a raw phone string to (XXX) XXX-XXXX.
-- Strips non-digits, handles optional leading 1, returns as-is if not 10 digits.
-- DETERMINISTIC for Oracle query caching.
-- =============================================================================

CREATE OR REPLACE FUNCTION fmt_phone(p_raw VARCHAR2) RETURN VARCHAR2 DETERMINISTIC IS
    v_digits VARCHAR2(20);
BEGIN
    IF p_raw IS NULL THEN RETURN NULL; END IF;
    v_digits := REGEXP_REPLACE(p_raw, '[^0-9]', '');
    IF LENGTH(v_digits) = 11 AND SUBSTR(v_digits, 1, 1) = '1' THEN
        v_digits := SUBSTR(v_digits, 2);
    END IF;
    IF LENGTH(v_digits) = 10 THEN
        RETURN '(' || SUBSTR(v_digits, 1, 3) || ') '
            || SUBSTR(v_digits, 4, 3) || '-'
            || SUBSTR(v_digits, 7);
    END IF;
    RETURN p_raw;
END fmt_phone;
/
