import { JSON } from '@kit.ArkTS';
import { webview } from '@kit.ArkWeb';

export class JsonToolkitError extends Error {
  public errorCode: string;
  public suggestion: string;

  constructor(errorCode: string, message: string, suggestion: string) {
    super(message);
    this.errorCode = errorCode;
    this.suggestion = suggestion;
  }
}

export class JsonToolkitResult {
  public operation: string = '';
  public valid: boolean = true;
  public result?: string;
  public jsonType?: string;
  public itemCount?: number;
  public size?: number;
}

class JsonToolkitRequest {
  public operation: string;
  public content: string;
  public path: string;
  public indent: number;
  public sortKeys: boolean;

  constructor(
    operation: string,
    content: string,
    path: string,
    indent: number,
    sortKeys: boolean
  ) {
    this.operation = operation;
    this.content = content;
    this.path = path;
    this.indent = indent;
    this.sortKeys = sortKeys;
  }
}

class JsonToolkitEnvelope {
  public ok: boolean = false;
  public data?: JsonToolkitResult;
  public errorCode?: string;
  public message?: string;
  public suggestion?: string;
}

class JsonToolkitWebRuntime {
  private controller?: webview.WebviewController;
  private ready: boolean = false;

  public bind(controller: webview.WebviewController): void {
    this.controller = controller;
    this.ready = true;
  }

  public markNotReady(): void {
    this.ready = false;
  }

  public isReady(): boolean {
    return this.ready && this.controller !== undefined;
  }

  public async execute(
    operation: string,
    content: string,
    path: string = '',
    indent: number = 2,
    sortKeys: boolean = false
  ): Promise<JsonToolkitResult> {
    if (!this.isReady() || this.controller === undefined) {
      throw new JsonToolkitError(
        'ERR_WEB_NOT_READY',
        'ArkWeb runtime is not ready',
        '请先打开应用页面并等待本地 ArkWeb 页面加载完成'
      );
    }

    const request: JsonToolkitRequest = new JsonToolkitRequest(
      operation,
      content,
      path,
      indent,
      sortKeys
    );
    const requestText: string = JSON.stringify(request);
    const expression: string =
      `window.JsonToolkit.execute(${JSON.stringify(requestText)})`;
    let rawResult: string;

    try {
      rawResult = await this.controller.runJavaScript(expression);
    } catch (error) {
      const runtimeError: Error = error as Error;
      throw new JsonToolkitError(
        'ERR_WEB_BRIDGE',
        runtimeError.message || 'ArkWeb bridge execution failed',
        '请确认本地 ArkWeb 页面已加载并且 JavaScript 执行已启用'
      );
    }
    const envelope: JsonToolkitEnvelope =
      this.parseEnvelope(rawResult);

    if (!envelope.ok || envelope.data === undefined) {
      throw new JsonToolkitError(
        envelope.errorCode || 'ERR_WEB_EXECUTION',
        envelope.message || 'ArkWeb JavaScript execution failed',
        envelope.suggestion || '请检查 ArkWeb 页面和 JavaScript 控制台日志'
      );
    }

    return envelope.data;
  }

  private parseEnvelope(rawResult: string): JsonToolkitEnvelope {
    const firstValue: Object = JSON.parse(rawResult) as Object;

    if (typeof firstValue === 'string') {
      return JSON.parse(firstValue as string) as JsonToolkitEnvelope;
    }

    return firstValue as JsonToolkitEnvelope;
  }
}

export const jsonToolkitWebRuntime: JsonToolkitWebRuntime =
  new JsonToolkitWebRuntime();
