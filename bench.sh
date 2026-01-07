#!/bin/bash

ITERS=2
JALVIEW_PORT=8765

# Start local server for Jalview
echo "Starting local Jalview server on port $JALVIEW_PORT..."
python3 -m http.server $JALVIEW_PORT --directory jalview-js > /dev/null 2>&1 &
JALVIEW_PID=$!
sleep 2

# Cleanup function
cleanup() {
  echo "Stopping local Jalview server..."
  kill $JALVIEW_PID 2>/dev/null
}
trap cleanup EXIT

function bench() {

  hyperfine -i --export-json json/jalview-$1.json --runs $ITERS "node bench/jalview.ts 'http://localhost:$JALVIEW_PORT/JalviewJS.html?open%20https://www.jbrowse.org/demos/msabench/$1'"

  hyperfine -i --export-json json/jbrowsemsa-$1.json --runs $ITERS "node bench/jbrowsemsa.ts 'https://gmod.org/JBrowseMSA/?data={\"msaview\":{\"msaFilehandle\":{\"uri\":\"https://jbrowse.org/demos/msabench/$1\"}}}'"

  hyperfine -i --export-json json/wasabi-$1.json --runs $ITERS "node bench/wasabi.ts 'http://was.bi/userID?url=https://jbrowse.org/demos/msabench/$1'"

  hyperfine -i --export-json json/biojsmsa-$1.json --runs $ITERS "node bench/biojsmsa.ts 'https://jbrowse.org/demos/msabench-biojs/?file=https://jbrowse.org/demos/msabench/$1'"
}

for file in out/*.fa; do
  F=$(basename $file)
  echo "TESTING $F"
  bench $F
  echo -e "\n\n\n\n\n"
done
