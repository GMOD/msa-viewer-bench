import puppeteer from 'puppeteer'
import fs from 'fs'

const browser = await puppeteer.launch({
  args: [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-features=HttpsFirstBalancedModeAutoEnable',
  ],
})
const page = await browser.newPage()
const url = process.argv[2]

let fastaRequestStart = 0
let fastaDownloadTime = 0

page.on('request', request => {
  if (request.url().includes('.fa')) {
    fastaRequestStart = Date.now()
  }
})

page.on('response', response => {
  if (response.url().includes('.fa') && fastaRequestStart > 0) {
    fastaDownloadTime = Date.now() - fastaRequestStart
  }
})

const navStart = Date.now()
await page.goto(url, { waitUntil: 'load' })
const pageLoadTime = Date.now() - navStart

await page.setViewport({ width: 1080, height: 1024 })

const renderStart = Date.now()
await page.waitForSelector('.biojs_msa_seqblock', {
  timeout: 120000,
})
const renderTime = Date.now() - renderStart
const totalTime = Date.now() - navStart

const ret = await page.$eval('canvas', (val: HTMLCanvasElement) =>
  val.toDataURL().replace(/^data:image\/\w+;base64,/, ''),
)
fs.mkdirSync('screenshots', { recursive: true })
fs.mkdirSync('timings', { recursive: true })
const match = url.match(/(\d+_\d+)\.fa/)
const sizeLabel = match ? match[1] : 'unknown'
await page.screenshot({
  path: `screenshots/biojsmsa-fullpage-${sizeLabel}.png`,
})
fs.writeFileSync(
  `screenshots/biojsmsa-fragment-${sizeLabel}.png`,
  Buffer.from(ret, 'base64'),
)
fs.appendFileSync(
  `timings/biojsmsa.jsonl`,
  JSON.stringify({ pageLoadTime, fastaDownloadTime, renderTime, totalTime, url }) + '\n',
)

await browser.close()
