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

  @State pageReady: boolean = false;
  @State testStatus: string = '等待 ArkWeb 页面加载';
  @State testDetails: string = '';
  @State allPassed: boolean = false;

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
          .onPageBegin(() => {
            this.pageReady = false;
            jsonToolkitWebRuntime.markNotReady();
          })
          .onPageEnd(() => {
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
      }
      .width('100%')
      .padding(24)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
  }
}
