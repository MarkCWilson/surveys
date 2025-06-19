.import --csv /Users/mwilson/Documents/GitHub/surveys/data/nhgis0002_csv/nhgis0002_ts_nominal_county.csv rei
.import --csv /Users/mwilson/Documents/GitHub/surveys/data/nhgis0004_csv/nhgis0004_ts_nominal_county.csv agesex
.import --csv /Users/mwilson/Documents/GitHub/surveys/data/nhgis0005_csv/nhgis0005_ts_nominal_county.csv sex

.headers on
.mode csv
.once /Users/mwilson/Documents/GitHub/surveys/data/temp/demo_data_orig.csv
select rei.YEAR as year, rei.STATEFP as state, rei.COUNTYFP as county, B18AA as white, B18AB as black 
,B18AC as nat ,B18AD as aapi, B18AE as mixed, B69AA as elem, B69AB as ass, B69AC as deg, BD5AA as inc, AS0AA
as mage, AS0AB as fage, AV1AA as male, AV1AB as female
from rei inner join agesex using (GISJOIN,YEAR,STATE,STATEFP,STATENH,COUNTY,COUNTYFP,COUNTYNH,NAME) 
inner join sex using (GISJOIN,YEAR,STATE,STATEFP,STATENH,COUNTY,COUNTYFP,COUNTYNH,NAME);
.exit
