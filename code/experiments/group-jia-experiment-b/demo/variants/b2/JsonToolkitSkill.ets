import { scriptManager } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import JsonToolkitService, {
  JsonToolkitError,
  JsonToolkitResult
} from './JsonToolkitServiceJs';

export default class JsonToolkitSkill {
  private readonly service: JsonToolkitService =
    new JsonToolkitService();

  public async run(
    info: scriptManager.ArkTSScriptInfo,
    ...argv: string[]
  ): Promise<void> {
    try {
      const operation: string = this.getArg(argv, 0).trim();
      const content: string = this.getArg(argv, 1);
      const path: string = this.getArg(argv, 2).trim();
      const indent: number = this.parseIndent(
        this.getArg(argv, 3)
      );
      const sortKeys: boolean = this.parseBoolean(
        this.getArg(argv, 4)
      );

      console.info(
        `JSON Toolkit operation: ${operation}, args count: ${argv.length}`
      );

      const serviceResult: JsonToolkitResult =
        this.service.execute(
          operation,
          content,
          path,
          indent,
          sortKeys
        );

      await this.report(info, {
        code: 0,
        result: this.createSuccessPayload(serviceResult)
      });
    } catch (error) {
      if (error instanceof JsonToolkitError) {
        await this.report(info, {
          code: -1,
          result: this.createFailurePayload(error)
        });
        return;
      }

      const businessError: BusinessError =
        error as BusinessError;

      console.error(
        `JSON Toolkit failed, code: ${businessError.code}, ` +
          `message: ${businessError.message}`
      );

      await this.report(info, {
        code: -1,
        result: {
          'type': 'result',
          'status': 'failed',
          'errCode': 'ERR_INTERNAL',
          'errMsg': businessError.message || 'Unknown internal error',
          'suggestion': '请稍后重试；如果问题持续出现，请检查运行日志'
        }
      });
    }
  }

  private getArg(argv: string[], index: number): string {
    if (index >= 0 && index < argv.length) {
      return argv[index];
    }

    return '';
  }

  private parseIndent(rawValue: string): number {
    const normalized: string = rawValue.trim();

    if (normalized.length === 0) {
      return 2;
    }

    const indent: number = Number(normalized);

    if (!Number.isInteger(indent)) {
      throw new JsonToolkitError(
        'ERR_INVALID_PARAMS',
        `Invalid indentation: ${rawValue}`,
        '缩进数必须是 0 到 8 之间的整数'
      );
    }

    return indent;
  }

  private parseBoolean(rawValue: string): boolean {
    const normalized: string = rawValue.trim().toLowerCase();

    if (normalized.length === 0 || normalized === 'false') {
      return false;
    }

    if (normalized === 'true') {
      return true;
    }

    throw new JsonToolkitError(
      'ERR_INVALID_PARAMS',
      `Invalid boolean value: ${rawValue}`,
      '排序参数只能使用 true 或 false'
    );
  }

  private createSuccessPayload(
    serviceResult: JsonToolkitResult
  ): Record<string, Object> {
    const data: Record<string, Object> = {
      'operation': serviceResult.operation,
      'valid': serviceResult.valid
    };

    if (serviceResult.result !== undefined) {
      data['result'] = serviceResult.result;
    }

    if (serviceResult.jsonType !== undefined) {
      data['jsonType'] = serviceResult.jsonType;
    }

    if (serviceResult.itemCount !== undefined) {
      data['itemCount'] = serviceResult.itemCount;
    }

    if (serviceResult.size !== undefined) {
      data['size'] = serviceResult.size;
    }

    return {
      'type': 'result',
      'status': 'success',
      'data': data
    };
  }

  private createFailurePayload(
    error: JsonToolkitError
  ): Record<string, Object> {
    return {
      'type': 'result',
      'status': 'failed',
      'errCode': error.errorCode,
      'errMsg': error.message,
      'suggestion': error.suggestion
    };
  }

  private async report(
    info: scriptManager.ArkTSScriptInfo,
    result: scriptManager.ExecuteResult
  ): Promise<void> {
    try {
      await scriptManager.completeArkTSScriptInApp(
        info.context,
        info.requestCode,
        result
      );
    } catch (error) {
      const businessError: BusinessError =
        error as BusinessError;

      console.error(
        `JSON Toolkit result report failed, ` +
          `code: ${businessError.code}, ` +
          `message: ${businessError.message}`
      );
    }
  }
}
