#!/usr/bin/env bash

FILES="2022/*"

echo "date,descr,amount"
for f in $FILES
do
    python3 pdf_to_txt.py $f --nohead
done
