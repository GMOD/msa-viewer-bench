import fs from 'fs'

const letters = [
  'A',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'K',
  'L',
  'M',
  'N',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'V',
  'W',
  'Y',
]

function gen(rows: number, cols: number, str: fs.WriteStream) {
  for (let i = 0; i < rows; i++) {
    const id = `>seq${i}`
    let seq = ''
    for (let j = 0; j < cols; j++) {
      seq += letters[Math.floor(Math.random() * letters.length)]
    }
    str.write(`${id}\n${seq}\n`)
  }
}

fs.mkdirSync('out', { recursive: true })

// varyXY: Square files (N x N)
for (let n = 128; n <= 16384; n *= 2) {
  console.log('varyXY:', { n })
  const str = fs.createWriteStream(`out/${n}_${n}.fa`)
  gen(n, n, str)
  str.end()
}

// varyX: Varying x (first dimension), fixed y=100
// Files: 128_100.fa, 256_100.fa, ... up to 1048576_100.fa
for (let x = 128; x <= 1048576; x *= 2) {
  console.log('varyX:', { x, y: 100 })
  const str = fs.createWriteStream(`out/${x}_100.fa`)
  gen(x, 100, str)
  str.end()
}

// varyY: Fixed x=100, varying y (second dimension)
// Files: 100_128.fa, 100_256.fa, ... up to 100_1048576.fa
for (let y = 128; y <= 1048576; y *= 2) {
  console.log('varyY:', { x: 100, y })
  const str = fs.createWriteStream(`out/100_${y}.fa`)
  gen(100, y, str)
  str.end()
}
