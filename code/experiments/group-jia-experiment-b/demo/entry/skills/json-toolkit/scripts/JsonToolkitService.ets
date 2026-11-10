import { JSON, util } from '@kit.ArkTS';

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

export default class JsonToolkitService {
  public execute(
    operation: string,
    content: string,
    path: string = '',
    indent: number = 2,
    sortKeys: boolean = false
  ): JsonToolkitResult {
    this.validateParameters(operation, content, path, indent);

    let parsed: Object;

    try {
      parsed = JSON.parse(content) as Object;
    } catch (error) {
      throw new JsonToolkitError(
        'ERR_INVALID_JSON',
        'JSON parse failed',
        '请检查 JSON 的引号、逗号和括号是否正确'
      );
    }

    if (operation === 'validate') {
      return this.validateJson(parsed, content);
    }

    if (operation === 'query') {
      const queryResult: Object = this.queryJson(parsed, path);
      return this.createTextResult(
        operation,
        JSON.stringify(queryResult)
      );
    }

    if (operation === 'minify') {
      const minifiedValue: Object =
        sortKeys ? this.sortValue(parsed) : parsed;

      return this.createTextResult(
        operation,
        JSON.stringify(minifiedValue)
      );
    }

    if (operation === 'sort') {
      const sortedValue: Object = this.sortValue(parsed);

      return this.createTextResult(
        operation,
        JSON.stringify(sortedValue, null, indent)
      );
    }

    const formattedValue: Object =
      sortKeys ? this.sortValue(parsed) : parsed;

    return this.createTextResult(
      operation,
      JSON.stringify(formattedValue, null, indent)
    );
  }

  private validateParameters(
    operation: string,
    content: string,
    path: string,
    indent: number
  ): void {
    const supportedOperations: string[] = [
      'format',
      'minify',
      'validate',
      'query',
      'sort'
    ];

    if (!supportedOperations.includes(operation)) {
      throw new JsonToolkitError(
        'ERR_INVALID_PARAMS',
        `Unsupported operation: ${operation}`,
        '请选择 format、minify、validate、query 或 sort'
      );
    }

    if (content.trim().length === 0) {
      throw new JsonToolkitError(
        'ERR_INVALID_PARAMS',
        'JSON content is empty',
        '请提供需要处理的 JSON 字符串'
      );
    }

    if (!Number.isInteger(indent) || indent < 0 || indent > 8) {
      throw new JsonToolkitError(
        'ERR_INVALID_PARAMS',
        `Invalid indentation: ${indent}`,
        '缩进数必须是 0 到 8 之间的整数'
      );
    }

    if (operation === 'query' && path.trim().length === 0) {
      throw new JsonToolkitError(
        'ERR_INVALID_PARAMS',
        'Query path is empty',
        'query 操作必须提供点号路径'
      );
    }
  }

  private validateJson(
    value: Object,
    content: string
  ): JsonToolkitResult {
    const result: JsonToolkitResult = new JsonToolkitResult();
    result.operation = 'validate';
    result.valid = true;
    result.jsonType = this.getJsonType(value);
    result.size = this.getUtf8Size(content);

    const itemCount: number | undefined = this.getItemCount(value);
    if (itemCount !== undefined) {
      result.itemCount = itemCount;
    }

    return result;
  }

  private createTextResult(
    operation: string,
    output: string
  ): JsonToolkitResult {
    const result: JsonToolkitResult = new JsonToolkitResult();
    result.operation = operation;
    result.valid = true;
    result.result = output;
    return result;
  }

  private queryJson(value: Object, path: string): Object {
    const segments: string[] = path.split('.');
    let current: Object = value;

    for (const segment of segments) {
      if (Array.isArray(current)) {
        const values: Object[] = current as Object[];
        const index: number = Number(segment);

        if (
          !Number.isInteger(index) ||
            index < 0 ||
            index >= values.length
        ) {
          throw new JsonToolkitError(
            'ERR_QUERY_PATH',
            `Invalid array index: ${segment}`,
            '请检查数组下标是否存在'
          );
        }

        current = values[index];
        continue;
      }

      if (
        current !== null &&
          typeof current === 'object' &&
          Reflect.has(current, segment)
      ) {
        current = Reflect.get(current, segment) as Object;
        continue;
      }

      throw new JsonToolkitError(
        'ERR_QUERY_PATH',
        `Key not found: ${segment}`,
        '请检查查询路径是否与 JSON 结构一致'
      );
    }

    return current;
  }

  private sortValue(value: Object): Object {
    if (Array.isArray(value)) {
      const source: Object[] = value as Object[];
      const sortedArray: Object[] = [];

      source.forEach((item: Object) => {
        sortedArray.push(this.sortValue(item));
      });

      return sortedArray;
    }

    if (value !== null && typeof value === 'object') {
      const sortedObject: Record<string, Object> = {};
      const keys: string[] = Object.keys(value);
      keys.sort();

      keys.forEach((key: string) => {
        const childValue: Object = Reflect.get(value, key) as Object;
        sortedObject[key] = this.sortValue(childValue);
      });

      return sortedObject;
    }

    return value;
  }

  private getJsonType(value: Object): string {
    if (value === null) {
      return 'null';
    }

    if (Array.isArray(value)) {
      return 'array';
    }

    return typeof value;
  }

  private getItemCount(value: Object): number | undefined {
    if (Array.isArray(value)) {
      return (value as Object[]).length;
    }

    if (value !== null && typeof value === 'object') {
      return Object.keys(value).length;
    }

    return undefined;
  }

  private getUtf8Size(content: string): number {
    const encoder: util.TextEncoder = new util.TextEncoder();
    return encoder.encodeInto(content).byteLength;
  }
}