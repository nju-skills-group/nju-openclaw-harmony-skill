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

@Entry
@Component
struct Index {
  private controller: webview.WebviewController = new webview.WebviewController();
  @State status: string = 'idle';
  @State lastLine: string = '';
  @State pageReady: boolean = false;
  @State loadMs: number = -1;
  private appStart: number = 0;
  private loadStart: number = 0;
  private firstCallDone: boolean = false;
  private busy: boolean = false;

  aboutToAppear(): void {
    this.appStart = Date.now();
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
    const bridge: number = biz >= 0 ? (t1 - t0) - biz : -1;
    const s: Sample = {
      group: 'D1', mode: isCold ? 'coldcall' : mode, seq: seq, total: total, biz: biz,
      bridge: bridge, load: isCold ? this.loadMs : 0, checksum: checksum, ok: ok
    };
    this.firstCallDone = true;
    this.emit(s);
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

      Text(this.status).fontSize(12)
      Text(this.lastLine).fontSize(10).maxLines(4)

      Web({ src: $rawfile('bench.html'), controller: this.controller })
        .onPageBegin(() => {
          this.loadStart = Date.now();
        })
        .onPageEnd(() => {
          this.loadMs = Date.now() - this.loadStart;
          this.pageReady = true;
          this.status = 'page loaded';
          logLine('LOAD|D1|load=' + this.loadMs + '|fromStart=' + (Date.now() - this.appStart));
        })
        .width('100%')
        .layoutWeight(1)
    }
    .padding(12)
    .width('100%')
    .height('100%')
  }
}
