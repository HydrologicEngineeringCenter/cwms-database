DROP TYPE test_tsv_array;

CREATE OR REPLACE TYPE test_tsv_type AS OBJECT (date_time DATE, value BINARY_DOUBLE, quality_code NUMBER);
/

CREATE OR REPLACE TYPE test_tsv_array IS TABLE OF test_tsv_type;
/

-- the size of a time series id.
CREATE OR REPLACE TYPE char_183_array_type IS TABLE OF VARCHAR2(183);
/

