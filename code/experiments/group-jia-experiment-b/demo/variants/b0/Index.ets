import JsonToolkitService, {
  JsonToolkitError,
  JsonToolkitResult
} from '../../../../skills/json-toolkit/scripts/JsonToolkitService';

@Entry
@Component
struct Index {
  private jsonService: JsonToolkitService =
    new JsonToolkitService();

  @State testStatus: string = '尚未执行';
  @State testDetails: string = '点击按钮运行 6 项测试';
  @State allPassed: boolean = false;

  private recordResult(
    lines: string[],
    name: string,
    passed: boolean
  ): number {
    lines.push(`${passed ? 'PASS' : 'FAIL'} - ${name}`);
    return passed ? 1 : 0;
  }

  private runSelfTest(): void {
    const lines: string[] = [];
    let passed: number = 0;

    try {
      const formatResult: JsonToolkitResult =
        this.jsonService.execute(
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
        this.jsonService.execute(
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
        this.jsonService.execute(
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
        this.jsonService.execute(
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
        this.jsonService.execute(
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
        this.jsonService.execute(
          'validate',
          '{"a":}'
        );
      } catch (error) {
        if (
          error instanceof JsonToolkitError &&
            error.errorCode === 'ERR_INVALID_JSON'
        ) {
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

        Text('HarmonyOS simulator self-test')
          .fontSize(16)
          .fontColor('#5F6368')
          .width('100%')

        Button('Run self-test')
          .width('100%')
          .height(48)
          .onClick(() => {
            this.runSelfTest();
          })

        Text(this.testStatus)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(
            this.allPassed ? '#147A42' : '#B54708'
          )
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
