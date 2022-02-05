# spk_pdf_to_csv.py
Converts a single Sparkasse bank statement pdf file to csv (VERY specific)
You can actually export a .csv file directly from the web interface. Of course, I only found this after I finished the script..

`python3 spk_pdf_to_csv.py input.pdf > output.csv`

# convert_all_to_csv.sh
Just a helper script that will execute spk_pdf_to_csv.py for every file in a directory

`./convert_all_to_csv.sh > output.csv`

# spk-graphz.R
This is what actually plots and evaluates all the csv data.
It assumes the csv has the structure "date,descr,amount", formats the date to an R date object, filters the rows by keyword(s) in the description and plots some stuff. Maybe I will add command line args in the future ;D

`Rscript spk-graphz.R`
