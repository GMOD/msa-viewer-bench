#!/bin/bash

ITERS=10
JALVIEW_PORT=8765
JBROWSEMSA_PORT=8766
BIOJSMSA_PORT=8767
MSAFILES_PORT=8768

# Start local servers
echo "Starting local servers..."
npx serve -p $JALVIEW_PORT --cors --no-clipboard -L jalview-js &
JALVIEW_PID=$!
npx serve -p $JBROWSEMSA_PORT --cors --no-clipboard -L ~/src/react-msaview/app/dist &
JBROWSEMSA_PID=$!
npx serve -p $BIOJSMSA_PORT --cors --no-clipboard -L biojs-msa/dist &
BIOJSMSA_PID=$!
npx serve -p $MSAFILES_PORT --cors --no-clipboard -L out &
MSAFILES_PID=$!
sleep 2

# Cleanup function
cleanup() {
  echo "Stopping local servers..."
  kill $JALVIEW_PID $JBROWSEMSA_PID $BIOJSMSA_PID $MSAFILES_PID 2>/dev/null
}
trap cleanup EXIT

function bench() {

  hyperfine -i --export-json json/jalview-$1.json --runs $ITERS "node bench/jalview.ts 'http://localhost:$JALVIEW_PORT/JalviewJS.html?open%20http://localhost:$MSAFILES_PORT/$1'"

  hyperfine -i --export-json json/jbrowsemsa-$1.json --runs $ITERS "node bench/jbrowsemsa.ts 'http://localhost:$JBROWSEMSA_PORT/?data={\"msaview\":{\"msaFilehandle\":{\"uri\":\"http://localhost:$MSAFILES_PORT/$1\"}}}'"

  hyperfine -i --export-json json/wasabi-$1.json --runs $ITERS "node bench/wasabi.ts 'http://was.bi/userID?url=https://jbrowse.org/demos/msabench/$1'"

  hyperfine -i --export-json json/biojsmsa-$1.json --runs $ITERS "node bench/biojsmsa.ts 'http://localhost:$BIOJSMSA_PORT/?file=http://localhost:$MSAFILES_PORT/$1'"
}

for file in out/*.fa; do
  F=$(basename $file)
  echo "TESTING $F"
  bench $F
  echo -e "\n\n\n\n\n"
done
