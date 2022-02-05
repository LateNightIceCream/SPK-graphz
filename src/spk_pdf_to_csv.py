#!/usr/bin/env python3
# coding: utf-8 -*-
import fitz
import csv
from sys import stdout, argv
from datetime import datetime
import argparse

import warnings
warnings.filterwarnings("ignore")

DATE_FORMAT = '%d.%m.%Y'
suppress_header = False

# =============================================================================

class Account_Entry:
    def __init__(self, date, descr, amount):
        self.date   = date
        self.descr  = descr
        self.amount = amount

    def display(self):
        print('==============')
        print('Account Entry')
        print('Date: '   + str(self.date))
        print('Descr: '  + self.descr)
        print('Amount: ' + str(self.amount))
        print('==============')

    def get_list(self):
        return [self.date, self.descr, self.amount]

# =============================================================================

def get_pdf_string(file):
    with fitz.open(file) as doc:
        pdf_string = ''
        for page in doc:
            pdf_string += page.getText()

    return pdf_string

# =============================================================================

def get_entries_from_pdf_string(pdf_string):
    entries = []
    pdf_lines = pdf_string.splitlines()
    i = 0
    while i < len(pdf_lines):
        line = pdf_lines[i]

        datetime_object = None
        try:
            # assuming line always starts with the date, split by
            # space because otherwise get 'unconverted data remains' error
            split = line.split(' ')[0]
            datetime_object = datetime.strptime(split, DATE_FORMAT).date()

            # if that succeeded, next (few) line(s) are description
            descr = ''
            while True:
                line = pdf_lines[i].strip()
                try:
                    amount = float(line.replace(',', '.').strip('-'))
                    break
                except:
                    # str->float conversion failed
                    i += 1
                    descr += line;
                    continue

            entries.append(Account_Entry(datetime_object, descr, amount))

        except ValueError:
            i+=1
            pass

    return entries

# =============================================================================

def write_entries_to_csv(entries, filename, nohead = False):
    try:
        with open(filename, 'w+') as csvfile:
                writer = csv.writer(csvfile, delimiter = ',')
                if not nohead:
                    writer.writerow(['date', 'descr', 'amount'])
                for entry in entries:
                    writer.writerow(entry.get_list())
    except:
        writer = csv.writer(stdout, delimiter = ',')
        if not nohead:
            writer.writerow(['date', 'descr', 'amount'])
        for entry in entries:
            writer.writerow(entry.get_list())

# =============================================================================
#
def print_usage():
    print('\033[91musage: ' + argv[0] + ' filename [outputfile]\033[0m')

# =============================================================================
def main():

    parser = argparse.ArgumentParser(description='OSPA pdf to csv')
    parser.add_argument('input', type=str, help='input pdf file')
    parser.add_argument('--output', type=str, help='output csv file')
    parser.add_argument('--nohead', action='store_true', help='suppress csv header')
    parser.set_defaults(nohead=True)
    args = parser.parse_args()

    outfile = ''

    pdf_string = get_pdf_string(args.input)
    entries = get_entries_from_pdf_string(pdf_string)

    write_entries_to_csv(entries, args.output, args.nohead)

    # for entry in entries:
    #     entry.display()
    #     pass

# =============================================================================

if __name__ == "__main__":
    main()
