#!/usr/bin/env python3

import matplotlib.pyplot as plt
import pandas as pd
import argparse
import sys
import os

result_count = 0

def add_to_subplots(df):
    i = 1
    df_grouped = df.groupby("name")
    for title, group in df_grouped:
        ax = plt.subplot(4, 2, i)
        y_axis_label = group.columns[2]
        group.plot(x="timestamp", y=y_axis_label, ax=ax, legend=True, title=title)
        ax.set_xlabel("timestamp (seconds)")
        ax.set_ylabel(y_axis_label)
        i += 1

def createGraph(labels, inputFiles, output):
    plt.figure(figsize=(12, 12))

    for file in inputFiles:
        df = pd.read_csv(file)
        add_to_subplots(df)

    figure_axes = plt.gcf().axes
    handles, old_labels = figure_axes[0].get_legend_handles_labels()
    for ax in figure_axes:
        ax.get_legend().remove()

    plt.tight_layout()
    plt.figlegend(handles, labels, loc='lower right')
    plt.savefig(output)
    result = "created {}, input files used:".format(output)
    for file in inputFiles:
        result += "\n" + file

    return result

def scanCsvFiles(directory, labels, prefix):
    result = []
    directoryContents = os.listdir(directory)
    result_count = 0

    for label in labels:
        for element in directoryContents:
            if element.endswith(".csv"):
                if prefix != None and prefix != "":
                    if (prefix in element) and (label in element):
                        result.append(directory + "/" + element)
                        result_count += 1
                else:
                    if label in element:
                        result.append(directory + "/" + element)
                        result_count += 1

    if len(labels) != result_count:
        print("matching csv files for all labels not found")
        sys.exit(1)

    return result

def parseLabels(labelArg):
    labels = labelArg.split(",")
    for label in labels:
        label.strip()
    return labels

def main():
    parser = argparse.ArgumentParser(description="Get jaeger tracing data.")
    parser.add_argument("directory", help="directory containing output to scan")
    parser.add_argument("-l", "--labels", required=True, help="comma-separated list of labels used in the test setups")
    parser.add_argument("-o", "--output", required=True, help="the output file")
    parser.add_argument("-p", "--prefix", required=False, help="prefix of the output files")
    args = parser.parse_args(sys.argv[1:])

    labels = parseLabels(args.labels)
    inputFiles = scanCsvFiles(args.directory, labels, args.prefix)
    print(createGraph(labels, inputFiles, args.output))

if __name__ == "__main__":
    main()
