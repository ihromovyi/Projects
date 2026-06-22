# Python Geospatial EDA — 1850 Poltava Census

A geospatial exploratory analysis (**pandas · GeoPandas · Altair**) of the 1850 census of the Poltava Governorate: did **Cossack** (*Malorosiyski kozaky*) districts differ from the rest of the province in land allocation and demographics?

**Approach:** cleaned a messy multi-sheet historical Excel file, repaired and joined a GeoJSON of district borders, engineered a Cossack-share ratio, and answered four questions with choropleth maps, rankings, scatter (land) and time-series (reproduction) charts — composed into one dashboard.

**Finding:** a **null result** — Cossack share showed no meaningful correlation with land-per-capita or demographic growth. Reported honestly rather than forced into a story.

**Files:**
- `Poltava_Census_Analysis_EN.ipynb` — full notebook (English)
- `poltava_census_dashboard.html` / `dashboard.svg` — the 2×2 dashboard
- `visualization*.png` — individual charts

**Skills:** pandas · GeoPandas · Altair / Vega-Lite · choropleth maps · multi-sheet Excel cleaning · wide→long reshaping (`melt`) · geospatial joins · honest interpretation.
