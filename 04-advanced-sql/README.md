# Advanced SQL — Optimization, Data Warehouse (SCD2) & Nested JSON

Three graded SQL case studies that go beyond `SELECT … GROUP BY`.

### `01_query_optimization.sql` — MySQL
Generated **1M / 2M / 5M-row** tables, then took a slow query (three separate passes over the order tables + a correlated subquery) and made it fast: a single-pass **CTE**, a `RANK()` **window function** for the first order, conditional aggregation, and **covering indexes** + `USE INDEX` hints. Verified with `EXPLAIN` / `EXPLAIN ANALYZE`.

### `02_data_warehouse_scd2.sql` — BigQuery
A **raw → stage → mart** warehouse with a fact table and dimensions (`Dim_Date`, `Dim_Account`, `Dim_Customer`), including **Slowly-Changing Dimension Type 2** to preserve history (`valid_from` / `valid_to` / `is_active`).

### `03_steam_nested_json.sql` — BigQuery
Parsed **semi-structured** Steam data: flattened nested arrays with `UNNEST` into clean analytical tables, then produced insights (top games by reviews, releases by year, most common genres/categories).

**Skills:** query optimization · window functions · covering & composite indexes · execution plans · dimensional modelling · SCD Type 2 · semi-structured / JSON data.
