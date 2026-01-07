#!/bin/bash
node gather.ts >out.tsv
node gather-timings.ts >timings.tsv
Rscript plot.R
