.import --csv /Users/mwilson/Documents/GitHub/surveys/data/Education2023.csv edu
.import --csv /Users/mwilson/Documents/GitHub/surveys/data/Unemployment2023.csv emp
.headers on
.mode csv
.once out.csv
select edu.FIPS_code as fips, edu.Attribute as edu,edu.Value as eduval, emp.Attribute as emp,emp.Value as empval from edu inner join emp on edu.FIPS_Code = emp.FIPS_Code limit 10;
.exit
