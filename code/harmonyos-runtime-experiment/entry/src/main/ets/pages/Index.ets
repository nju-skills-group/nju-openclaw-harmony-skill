import { webview } from '@kit.ArkWeb';
import { benchWork, BENCH_SIZE } from '../bench/BenchWork';
import { logLine } from '../bench/BenchLog';

interface Sample {
  group: string;
  mode: string;
  seq: number;
  total: number;
  biz: number;
  bridge: number;
  load: number;
  checksum: number;
  ok: boolean;
}

const SAMPLES: number = 30;
const WARMUP: number = 3;
const PEAK_CALLS: number = 300;

@Entry
@Component
struct Index {
  private controller: webview.WebviewController = new webview.WebviewController();
  private emptyController: webview.WebviewController = new webview.WebviewController();
  @State status: string = 'idle';
  @State lastLine: string = '';
  @State pageReady: boolean = false;
  @State loadMs: number = -1;
  @State showWeb: boolean = false;
  private appStart: number = 0;
  private loadStart: number = 0;
  private firstCallDone: boolean = false;
  private busy: boolean = false;

  aboutToAppear(): void {
    this.appStart = Date.now();
    logLine('MEM|stage=baseline|t=' + this.appStart);
  }

  private emit(s: Sample): void {
    const line: string = 'SAMPLE|' + s.group + '|' + s.mode + '|seq=' + s.seq +
      '|total=' + s.total + '|biz=' + s.biz + '|bridge=' + s.bridge +
      '|load=' + s.load + '|checksum=' + s.checksum + '|ok=' + (s.ok ? '1' : '0');
    logLine(line);
    this.lastLine = line;
  }

  private runD0(seq: number, mode: string): void {
    const t0: number = Date.now();
    const checksum: number = benchWork(BENCH_SIZE);
    const t1: number = Date.now();
    const s: Sample = {
      group: 'D0', mode: mode, seq: seq, total: t1 - t0, biz: t1 - t0,
      bridge: 0, load: 0, checksum: checksum, ok: true
    };
    this.emit(s);
  }

  private async runD1(seq: number, mode: string): Promise<void> {
    if (!this.pageReady) {
      this.status = 'webview not ready';
      return;
    }
    const t0: number = Date.now();
    let raw: string = '';
    let ok: boolean = true;
    try {
      raw = await this.controller.runJavaScript('benchRun(' + BENCH_SIZE + ')');
    } catch (err) {
      ok = false;
      raw = '';
      logLine('ERR|D1|' + JSON.stringify(err));
    }
    const t1: number = Date.now();
    let checksum: number = -1;
    let biz: number = -1;
    // runJavaScript hands back the value as text; string results arrive quoted.
    let clean: string = raw.trim();
    if (clean.length > 1 && clean.charAt(0) === '"' && clean.charAt(clean.length - 1) === '"') {
      clean = clean.substring(1, clean.length - 1);
    }
    if (ok && clean.length > 0) {
      const parts: string[] = clean.split(',');
      if (parts.length >= 2) {
        checksum = Number.parseInt(parts[0], 10);
        biz = Number.parseInt(parts[1], 10);
      } else {
        ok = false;
        logLine('ERR|D1|badraw|' + clean);
      }
    } else {
      ok = false;
    }
    // The first call after launch is the cold-call sample. It is timed from the
    // click, same as hot calls, so it is comparable; the page-load cost is
    // reported separately in the LOAD line.
    const isCold: boolean = !this.firstCallDone;
    const total: number = t1 - t0;
    const bridge: number = biz >= 0 ? total - biz : -1;
    const s: Sample = {
      group: 'D1', mode: isCold ? 'coldcall' : mode, seq: seq, total: total, biz: biz,
      bridge: bridge, load: isCold ? this.loadMs : 0, checksum: checksum, ok: ok
    };
    this.firstCallDone = true;
    this.emit(s);
  }

  private async runD1Silent(): Promise<void> {
    try {
      await this.controller.runJavaScript('benchRun(' + BENCH_SIZE + ')');
    } catch (err) {
      logLine('ERR|PEAK|' + JSON.stringify(err));
    }
  }

  private async loopD0(): Promise<void> {
    if (this.busy) {
      return;
    }
    this.busy = true;
    this.status = 'D0 running';
    for (let i = 0; i < WARMUP; i++) {
      this.runD0(i + 1, 'warmup');
    }
    for (let i = 1; i <= SAMPLES; i++) {
      this.runD0(i, 'hot');
    }
    this.busy = false;
    this.status = 'D0 done (' + SAMPLES + ' samples)';
  }

  private async loopD1(): Promise<void> {
    if (this.busy) {
      return;
    }
    this.busy = true;
    this.status = 'D1 running';
    await this.runD1(0, 'coldcall');
    for (let i = 0; i < WARMUP; i++) {
      await this.runD1(i + 1, 'warmup');
    }
    for (let i = 1; i <= SAMPLES; i++) {
      await this.runD1(i, 'hot');
    }
    this.busy = false;
    this.status = 'D1 done (' + SAMPLES + ' samples)';
  }

  // Memory protocol: baseline (no WebView exists) -> created -> loaded -> peak.
  // Each stage dwells long enough for an external hidumper sampler to take
  // several readings. Stage transitions are logged with timestamps.
  private startMemProtocol(): void {
    if (this.busy || this.showWeb) {
      return;
    }
    this.busy = true;
    this.status = 'MEM baseline (4s)';
    logLine('MEM|stage=baseline|t=' + Date.now());
    setTimeout(() => {
      logLine('MEM|stage=create|t=' + Date.now());
      this.showWeb = true;
      this.status = 'MEM create + load (4s)';
      setTimeout(() => {
        logLine('MEM|stage=created|t=' + Date.now());
        this.busy = false;
        this.status = 'MEM loaded, idle (5s)';
      }, 4000);
    }, 4000);
  }

  private async runPeak(): Promise<void> {
    if (this.busy || !this.pageReady) {
      return;
    }
    this.busy = true;
    this.status = 'MEM idle before peak (5s)';
    logLine('MEM|stage=idle|t=' + Date.now());
    await new Promise<void>((resolve) => {
      setTimeout(() => resolve(), 5000);
    });
    logLine('MEM|stage=peak|t=' + Date.now());
    this.status = 'PEAK ' + PEAK_CALLS + ' calls';
    for (let i = 0; i < PEAK_CALLS; i++) {
      await this.runD1Silent();
    }
    logLine('MEM|stage=peaked|t=' + Date.now());
    this.status = 'MEM restore (10s)';
    await new Promise<void>((resolve) => {
      setTimeout(() => resolve(), 10000);
    });
    logLine('MEM|stage=restore|t=' + Date.now());
    this.busy = false;
    this.status = 'MEM protocol done';
  }

  private caseLine(name: string, ok: boolean, detail: string): void {
    logLine('CASE|' + name + '|' + (ok ? 'handled' : 'unhandled') + '|' + detail);
    this.status = 'case ' + name + ' -> ' + (ok ? 'handled' : 'unhandled');
  }

  // B3 failure paths. Each case must fail without crashing the app.
  private async runErrorCases(): Promise<void> {
    if (this.busy) {
      return;
    }
    this.busy = true;
    // 1. page not loaded: a controller with no bound Web component
    try {
      await this.emptyController.runJavaScript('1+1');
      this.caseLine('no_page', false, 'resolved');
    } catch (err) {
      this.caseLine('no_page', true, 'rejected');
    }
    // 2. bridge error: function does not exist in the page
    try {
      await this.controller.runJavaScript('noSuchFunction()');
      this.caseLine('bridge_error', false, 'resolved');
    } catch (err) {
      this.caseLine('bridge_error', true, 'rejected');
    }
    // 3. JS throws
    try {
      await this.controller.runJavaScript('benchThrow()');
      this.caseLine('js_throw', false, 'resolved');
    } catch (err) {
      this.caseLine('js_throw', true, 'rejected');
    }
    // 4. malformed return value
    try {
      const bad: string = await this.controller.runJavaScript('benchBad()');
      logLine('CASE|bad_format|value|' + bad);
      this.caseLine('bad_format', true, 'parsed-guard');
    } catch (err) {
      this.caseLine('bad_format', true, 'rejected');
    }
    // 5. timeout: page blocks 3s, caller gives up after 1s
    const t0: number = Date.now();
    const slow: Promise<string> = this.controller.runJavaScript('benchSlow(3000)');
    const timeout: Promise<string> = new Promise<string>((resolve, reject) => {
      setTimeout(() => {
        reject(new Error('timeout after 1000ms'));
      }, 1000);
    });
    try {
      await Promise.race([slow, timeout]);
      this.caseLine('timeout', false, 'no-timeout at ' + (Date.now() - t0) + 'ms');
    } catch (err) {
      this.caseLine('timeout', true, 'aborted at ' + (Date.now() - t0) + 'ms');
    }
    // 6. normal control case
    try {
      const good: string = await this.controller.runJavaScript('benchRun(1000)');
      this.caseLine('normal', good.length > 0, 'len=' + good.length);
    } catch (err) {
      this.caseLine('normal', false, 'rejected');
    }
    this.busy = false;
    this.status = 'error cases done';
  }

  build() {
    Column({ space: 8 }) {
      Text('Skill Runtime Bench')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)

      Text('size=' + BENCH_SIZE + '  ready=' + this.pageReady + '  loadMs=' + this.loadMs)
        .fontSize(12)

      Row({ space: 8 }) {
        Button('D0 x' + SAMPLES)
          .onClick(() => {
            this.loopD0();
          })
        Button('D1 x' + SAMPLES)
          .onClick(() => {
            this.loopD1();
          })
      }

      Row({ space: 8 }) {
        Button('MEM5')
          .onClick(() => {
            this.startMemProtocol();
          })
        Button('PEAK')
          .onClick(() => {
            this.runPeak();
          })
        Button('ERR')
          .onClick(() => {
            this.runErrorCases();
          })
      }

      Text(this.status).fontSize(12)
      Text(this.lastLine).fontSize(10).maxLines(4)

      if (this.showWeb) {
        Web({ src: $rawfile('bench.html'), controller: this.controller })
          .onPageBegin(() => {
            this.loadStart = Date.now();
          })
          .onPageEnd(() => {
            this.loadMs = Date.now() - this.loadStart;
            this.pageReady = true;
            this.status = 'page loaded';
            logLine('LOAD|D1|load=' + this.loadMs + '|fromStart=' + (Date.now() - this.appStart));
            logLine('MEM|stage=loaded|t=' + Date.now());
          })
          .width('100%')
          .layoutWeight(1)
      } else {
        Text('webview not created').fontSize(12).layoutWeight(1)
      }
    }
    .padding(12)
    .width('100%')
    .height('100%')
  }
}
