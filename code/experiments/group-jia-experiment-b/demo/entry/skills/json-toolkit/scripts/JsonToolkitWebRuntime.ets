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
  private lastBridgeMs: number = 0;
  private totalBridgeMs: number = 0;
  private bridgeCount: number = 0;

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

  public resetMetrics(): void {
    this.lastBridgeMs = 0;
    this.totalBridgeMs = 0;
    this.bridgeCount = 0;
  }

  public getLastBridgeMs(): number {
    return this.lastBridgeMs;
  }

  public getAverageBridgeMs(): number {
    if (this.bridgeCount === 0) {
      return 0;
    }

    return this.totalBridgeMs / this.bridgeCount;
  }

  public getBridgeCount(): number {
    return this.bridgeCount;
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
    const rawResult: string = await this.runExpression(
      expression,
      5000,
      true
    );
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

  public async probeUnboundController(): Promise<void> {
    const emptyController: webview.WebviewController =
      new webview.WebviewController();

    try {
      await emptyController.runJavaScript('1+1');
    } catch (error) {
      const message: string = this.getErrorMessage(
        error,
        'Unbound ArkWeb controller rejected'
      );
      throw new JsonToolkitError(
        'ERR_WEB_BRIDGE',
        message,
        'WebviewController 必须先绑定到 Web 组件'
      );
    }

    throw new JsonToolkitError(
      'ERR_WEB_BRIDGE_UNEXPECTED',
      'Unbound ArkWeb controller unexpectedly resolved',
      '请检查当前 SDK 的 ArkWeb 控制器行为'
    );
  }

  public async runProbe(
    mode: string,
    timeoutMs: number = 2000
  ): Promise<void> {
    if (!this.isReady()) {
      throw new JsonToolkitError(
        'ERR_WEB_NOT_READY',
        'ArkWeb runtime is not ready',
        '请先等待本地 ArkWeb 页面加载完成'
      );
    }

    try {
      const expression: string =
        `window.JsonToolkit.probe(${JSON.stringify(mode)})`;
      const rawResult: string = await this.runExpression(
        expression,
        timeoutMs,
        false
      );
      const envelope: JsonToolkitEnvelope =
        this.parseEnvelope(rawResult);

      if (!envelope.ok) {
        throw new JsonToolkitError(
          envelope.errorCode || 'ERR_WEB_EXECUTION',
          envelope.message || 'ArkWeb probe failed',
          envelope.suggestion || 'Check the page JavaScript logs'
        );
      }
    } catch (error) {
      if (error instanceof JsonToolkitError) {
        throw error;
      }

      throw new JsonToolkitError(
        'ERR_WEB_BRIDGE',
        this.getErrorMessage(
          error,
          'ArkWeb JavaScript probe rejected without an error object'
        ),
        'Normalize page JavaScript errors at the ArkTS bridge boundary'
      );
    }
  }

  private async runExpression(
    expression: string,
    timeoutMs: number,
    recordMetrics: boolean
  ): Promise<string> {
    if (this.controller === undefined) {
      throw new JsonToolkitError(
        'ERR_WEB_NOT_READY',
        'ArkWeb controller is not bound',
        '请先等待本地 ArkWeb 页面加载完成'
      );
    }

    const startedAt: number = Date.now();
    let execution: Promise<string>;

    try {
      execution = this.controller.runJavaScript(expression);
    } catch (error) {
      const message: string = this.getErrorMessage(
        error,
        'ArkWeb bridge setup failed'
      );
      throw new JsonToolkitError(
        'ERR_WEB_BRIDGE',
        message,
        '请确认 WebviewController 已绑定并且页面允许执行 JavaScript'
      );
    }

    const timeout: Promise<string> = new Promise<string>(
      (resolve, reject) => {
        setTimeout(() => {
          reject(new JsonToolkitError(
            'ERR_WEB_TIMEOUT',
            `ArkWeb execution timed out after ${timeoutMs} ms`,
            '请限制页面脚本执行时间并为桥接调用设置超时'
          ));
        }, timeoutMs);
      }
    );

    try {
      const rawResult: string = await Promise.race([
        execution,
        timeout
      ]);
      const elapsed: number = Date.now() - startedAt;

      if (recordMetrics) {
        this.lastBridgeMs = elapsed;
        this.totalBridgeMs += elapsed;
        this.bridgeCount += 1;
      }

      return rawResult;
    } catch (error) {
      if (error instanceof JsonToolkitError) {
        throw error;
      }

      const message: string = this.getErrorMessage(
        error,
        'ArkWeb bridge execution failed'
      );
      throw new JsonToolkitError(
        'ERR_WEB_BRIDGE',
        message,
        '请确认本地 ArkWeb 页面已加载并且 JavaScript 执行已启用'
      );
    }
  }

  private getErrorMessage(error: Object, fallback: string): string {
    if (error instanceof Error && error.message.length > 0) {
      return error.message;
    }

    if (error !== undefined && error !== null) {
      const text: string = String(error);
      if (text.length > 0) {
        return text;
      }
    }

    return fallback;
  }

  private parseEnvelope(rawResult: string): JsonToolkitEnvelope {
    try {
      const firstValue: Object = JSON.parse(rawResult) as Object;

      if (typeof firstValue === 'string') {
        return JSON.parse(firstValue as string) as JsonToolkitEnvelope;
      }

      return firstValue as JsonToolkitEnvelope;
    } catch (error) {
      throw new JsonToolkitError(
        'ERR_WEB_RESPONSE',
        'ArkWeb returned a malformed response',
        '桥接层必须校验页面 JavaScript 的返回值格式'
      );
    }
  }
}

export const jsonToolkitWebRuntime: JsonToolkitWebRuntime =
  new JsonToolkitWebRuntime();
