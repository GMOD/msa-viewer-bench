import puppeteer from 'puppeteer'
import fs from 'fs'

const browser = await puppeteer.launch({
  args: ['--no-sandbox', '--disable-setuid-sandbox'],
})
const page = await browser.newPage()
const url = process.argv[2]

// Forward page console logs to terminal
page.on('console', msg => console.log('PAGE:', msg.type(), msg.text()))
page.on('pageerror', err => console.error('PAGE ERROR:', err.message))

let fastaRequestStart = 0
let fastaDownloadTime = 0

// Track FASTA request timing
await page.setRequestInterception(true)
page.on('request', request => {
  const reqUrl = request.url()
  if (reqUrl.includes('.fa')) {
    fastaRequestStart = Date.now()
  }
  request.continue()
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

// Debug: take early screenshot
fs.mkdirSync('screenshots', { recursive: true })
await page.screenshot({ path: 'screenshots/jalview-debug-afterload.png' })

const renderStart = Date.now()
try {
  await page.waitForSelector('#testApplet_canvas2', { timeout: 120000 })
} catch (e) {
  // Debug: screenshot on timeout
  await page.screenshot({ path: 'screenshots/jalview-debug-timeout.png' })
  console.error('Timeout waiting for #testApplet_canvas2')
  // List all canvas elements
  const canvases = await page.$$eval('canvas', els =>
    els.map(e => ({ id: e.id, width: e.width, height: e.height })),
  )
  console.error('Canvas elements found:', canvases)
  throw e
}
const renderTime = Date.now() - renderStart
const totalTime = Date.now() - navStart

// Debug: screenshot after selector found
await page.screenshot({ path: 'screenshots/jalview-debug-afterselector.png' })

const ret = await page.$eval('#testApplet_canvas2', (val: HTMLCanvasElement) =>
  val.toDataURL().replace(/^data:image\/\w+;base64,/, ''),
)
fs.mkdirSync('screenshots', { recursive: true })
fs.mkdirSync('timings', { recursive: true })
const match = url.match(/(\d+_\d+)\.fa/)
const sizeLabel = match ? match[1] : 'unknown'
await page.screenshot({
  path: `screenshots/jalview-fullpage-${sizeLabel}.png`,
})
fs.writeFileSync(
  `screenshots/jalview-fragment-${sizeLabel}.png`,
  Buffer.from(ret, 'base64'),
)
fs.appendFileSync(
  `timings/jalview.jsonl`,
  JSON.stringify({
    pageLoadTime,
    fastaDownloadTime,
    renderTime,
    totalTime,
    url,
  }) + '\n',
)

await browser.close()
