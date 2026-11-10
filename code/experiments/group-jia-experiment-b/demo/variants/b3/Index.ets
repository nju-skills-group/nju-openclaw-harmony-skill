import { webview } from '@kit.ArkWeb';
import {
  JsonToolkitError,
  JsonToolkitResult,
  jsonToolkitWebRuntime
} from '../../../../skills/json-toolkit/scripts/JsonToolkitWebRuntime';

@Entry
@Component
struct Index {
  private controller: webview.WebviewController =
    new webview.WebviewController();
  private pageLoadStartedAt: number = 0;

  @State pageReady: boolean = false;
  @State testStatus: string = '等待 ArkWeb 页面加载';
  @State testDetails: string = '';
  @State allPassed: boolean = false;
  @State pageLoadMs: number = 0;
  @State timingDetails: string = '等待测试数据';
  @State diagnosticStatus: string = '尚未执行异常路径测试';
  @State diagnosticDetails: string = '';

  private recordResult(
    lines: string[],
    name: string,
    passed: boolean
  ): number {
    lines.push(`${passed ? 'PASS' : 'FAIL'} - ${name}`);
    return passed ? 1 : 0;
  }

  private async runSelfTest(): Promise<void> {
    const lines: string[] = [];
    let passed: number = 0;
    jsonToolkitWebRuntime.resetMetrics();

    try {
      const formatResult: JsonToolkitResult =
        await jsonToolkitWebRuntime.execute(
          'format',
          '{"b":2,"a":1}',
          '',
          2,
          false
        );
      passed += this.recordResult(
        lines,
        'format',
        formatResult.result === '{\n  "b": 2,\n  "a": 1\n}'
      );

      const minifyResult: JsonToolkitResult =
        await jsonToolkitWebRuntime.execute(
          'minify',
          '{"b": 2, "a": 1}',
          '',
          2,
          true
        );
      passed += this.recordResult(
        lines,
        'minify + sortKeys',
        minifyResult.result === '{"a":1,"b":2}'
      );

      const validateInput: string = '{"name":"张三"}';
      const validateResult: JsonToolkitResult =
        await jsonToolkitWebRuntime.execute(
          'validate',
          validateInput
        );
      passed += this.recordResult(
        lines,
        'validate + UTF-8 size',
        validateResult.valid &&
          validateResult.jsonType === 'object' &&
          validateResult.itemCount === 1 &&
          validateResult.size !== undefined &&
          validateResult.size > validateInput.length
      );

      const queryResult: JsonToolkitResult =
        await jsonToolkitWebRuntime.execute(
          'query',
          '{"data":{"users":[{"name":"Alice"}]}}',
          'data.users.0.name'
        );
      passed += this.recordResult(
        lines,
        'query',
        queryResult.result === '"Alice"'
      );

      const sortResult: JsonToolkitResult =
        await jsonToolkitWebRuntime.execute(
          'sort',
          '{"z":2,"a":1}',
          '',
          2
        );
      passed += this.recordResult(
        lines,
        'sort',
        sortResult.result === '{\n  "a": 1,\n  "z": 2\n}'
      );

      let invalidJsonHandled: boolean = false;
      try {
        await jsonToolkitWebRuntime.execute(
          'validate',
          '{"a":}'
        );
      } catch (error) {
        if (error instanceof JsonToolkitError &&
          error.errorCode === 'ERR_INVALID_JSON') {
          invalidJsonHandled = true;
        }
      }
      passed += this.recordResult(
        lines,
        'invalid JSON',
        invalidJsonHandled
      );
    } catch (error) {
      const runtimeError: Error = error as Error;
      lines.push(`ERROR - ${runtimeError.message}`);
    }

    this.allPassed = passed === 6;
    this.testStatus = `${passed}/6 tests passed`;
    this.testDetails = lines.join('\n');
    this.timingDetails =
      `页面加载: ${this.pageLoadMs} ms\n` +
      `桥接调用: ${jsonToolkitWebRuntime.getBridgeCount()} 次\n` +
      `平均桥接: ${jsonToolkitWebRuntime.getAverageBridgeMs().toFixed(2)} ms\n` +
      `最后一次桥接: ${jsonToolkitWebRuntime.getLastBridgeMs()} ms`;
  }

  private diagnosticLine(
    lines: string[],
    name: string,
    passed: boolean,
    detail: string
  ): number {
    lines.push(
      `${passed ? 'PASS' : 'FAIL'} - ${name}: ${detail}`
    );
    return passed ? 1 : 0;
  }

  private async runFailurePathTests(): Promise<void> {
    const lines: string[] = [];
    let passed: number = 0;

    jsonToolkitWebRuntime.markNotReady();
    try {
      await jsonToolkitWebRuntime.execute('validate', '{}');
      passed += this.diagnosticLine(
        lines,
        'page not loaded',
        false,
        'unexpectedly resolved'
      );
    } catch (error) {
      const toolkitError: JsonToolkitError =
        error as JsonToolkitError;
      passed += this.diagnosticLine(
        lines,
        'page not loaded',
        toolkitError.errorCode === 'ERR_WEB_NOT_READY',
        toolkitError.errorCode
      );
    } finally {
      jsonToolkitWebRuntime.bind(this.controller);
    }

    try {
      await jsonToolkitWebRuntime.probeUnboundController();
      passed += this.diagnosticLine(
        lines,
        'bridge error',
        false,
        'unexpectedly resolved'
      );
    } catch (error) {
      const toolkitError: JsonToolkitError =
        error as JsonToolkitError;
      passed += this.diagnosticLine(
        lines,
        'bridge error',
        toolkitError.errorCode === 'ERR_WEB_BRIDGE',
        toolkitError.errorCode
      );
    }

    try {
      await jsonToolkitWebRuntime.runProbe('throw');
      passed += this.diagnosticLine(
        lines,
        'JavaScript throw',
        false,
        'unexpectedly resolved'
      );
    } catch (error) {
      const toolkitError: JsonToolkitError =
        error as JsonToolkitError;
      const handled: boolean =
        toolkitError.errorCode === 'ERR_WEB_BRIDGE' ||
          toolkitError.errorCode === 'ERR_WEB_RESPONSE';
      passed += this.diagnosticLine(
        lines,
        'JavaScript throw',
        handled,
        toolkitError.errorCode
      );
    }

    try {
      await jsonToolkitWebRuntime.runProbe('malformed');
      passed += this.diagnosticLine(
        lines,
        'malformed return',
        false,
        'unexpectedly resolved'
      );
    } catch (error) {
      const toolkitError: JsonToolkitError =
        error as JsonToolkitError;
      passed += this.diagnosticLine(
        lines,
        'malformed return',
        toolkitError.errorCode === 'ERR_WEB_RESPONSE',
        toolkitError.errorCode
      );
    }

    const timeoutStartedAt: number = Date.now();
    try {
      await jsonToolkitWebRuntime.runProbe('slow', 1000);
      passed += this.diagnosticLine(
        lines,
        'timeout',
        false,
        `${Date.now() - timeoutStartedAt} ms`
      );
    } catch (error) {
      const toolkitError: JsonToolkitError =
        error as JsonToolkitError;
      passed += this.diagnosticLine(
        lines,
        'timeout',
        toolkitError.errorCode === 'ERR_WEB_TIMEOUT',
        `${toolkitError.errorCode}, ${Date.now() - timeoutStartedAt} ms`
      );
    }

    this.diagnosticStatus = `${passed}/5 failure paths handled`;
    this.diagnosticDetails = lines.join('\n');
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('JSON Toolkit')
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        Text('ArkWeb page JavaScript experiment')
          .fontSize(16)
          .fontColor('#5F6368')
          .width('100%')

        Web({
          src: $rawfile('json_toolkit_web.html'),
          controller: this.controller
        })
          .javaScriptAccess(true)
          .onAppear(() => {
            this.pageLoadStartedAt = Date.now();
          })
          .onPageBegin(() => {
            if (this.pageLoadStartedAt === 0) {
              this.pageLoadStartedAt = Date.now();
            }
            this.pageReady = false;
            jsonToolkitWebRuntime.markNotReady();
          })
          .onPageEnd(() => {
            this.pageLoadMs = Date.now() - this.pageLoadStartedAt;
            jsonToolkitWebRuntime.bind(this.controller);
            this.pageReady = true;
            this.testStatus = 'ArkWeb runtime ready';
          })
          .height(64)
          .width('100%')

        Button('Run self-test')
          .width('100%')
          .height(48)
          .enabled(this.pageReady)
          .onClick(async () => {
            await this.runSelfTest();
          })

        Button('Run failure-path tests')
          .width('100%')
          .height(48)
          .enabled(this.pageReady)
          .onClick(async () => {
            await this.runFailurePathTests();
          })

        Text(this.testStatus)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.allPassed ? '#147A42' : '#B54708')
          .width('100%')

        Text(this.testDetails)
          .fontSize(16)
          .fontFamily('monospace')
          .lineHeight(28)
          .width('100%')
          .padding(16)
          .backgroundColor('#F4F5F7')
          .borderRadius(6)

        Text('Timing')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        Text(this.timingDetails)
          .fontSize(16)
          .fontFamily('monospace')
          .lineHeight(26)
          .width('100%')

        Text(this.diagnosticStatus)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        Text(this.diagnosticDetails)
          .fontSize(16)
          .fontFamily('monospace')
          .lineHeight(26)
          .width('100%')
          .padding(16)
          .backgroundColor('#F4F5F7')
          .borderRadius(6)
      }
      .width('100%')
      .padding(24)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }
}
