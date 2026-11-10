export class JsonToolkitError extends Error {
  constructor(errorCode, message, suggestion) {
    super(message);
    this.errorCode = errorCode;
    this.suggestion = suggestion;
  }
}

export class JsonToolkitResult {
  constructor() {
    this.operation = '';
    this.valid = true;
  }
}

export default class JsonToolkitService {
  execute(operation, content, path = '', indent = 2, sortKeys = false) {
    this.validateParameters(operation, content, path, indent);

    let parsed;
    try {
      parsed = JSON.parse(content);
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
      return this.createTextResult(
        operation,
        JSON.stringify(this.queryJson(parsed, path))
      );
    }

    if (operation === 'minify') {
      const value = sortKeys ? this.sortValue(parsed) : parsed;
      return this.createTextResult(operation, JSON.stringify(value));
    }

    if (operation === 'sort') {
      return this.createTextResult(
        operation,
        JSON.stringify(this.sortValue(parsed), null, indent)
      );
    }

    const value = sortKeys ? this.sortValue(parsed) : parsed;
    return this.createTextResult(
      operation,
      JSON.stringify(value, null, indent)
    );
  }

  validateParameters(operation, content, path, indent) {
    const operations = ['format', 'minify', 'validate', 'query', 'sort'];

    if (!operations.includes(operation)) {
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

  validateJson(value, content) {
    const result = new JsonToolkitResult();
    result.operation = 'validate';
    result.jsonType = this.getJsonType(value);
    result.size = this.getUtf8Size(content);

    const itemCount = this.getItemCount(value);
    if (itemCount !== undefined) {
      result.itemCount = itemCount;
    }

    return result;
  }

  createTextResult(operation, output) {
    const result = new JsonToolkitResult();
    result.operation = operation;
    result.result = output;
    return result;
  }

  queryJson(value, path) {
    const segments = path.split('.');
    let current = value;

    for (const segment of segments) {
      if (Array.isArray(current)) {
        const index = Number(segment);
        if (!Number.isInteger(index) || index < 0 || index >= current.length) {
          throw new JsonToolkitError(
            'ERR_QUERY_PATH',
            `Invalid array index: ${segment}`,
            '请检查数组下标是否存在'
          );
        }
        current = current[index];
        continue;
      }

      if (current !== null && typeof current === 'object' &&
        Object.prototype.hasOwnProperty.call(current, segment)) {
        current = current[segment];
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

  sortValue(value) {
    if (Array.isArray(value)) {
      return value.map((item) => this.sortValue(item));
    }

    if (value !== null && typeof value === 'object') {
      const sorted = {};
      Object.keys(value).sort().forEach((key) => {
        sorted[key] = this.sortValue(value[key]);
      });
      return sorted;
    }

    return value;
  }

  getJsonType(value) {
    if (value === null) {
      return 'null';
    }
    return Array.isArray(value) ? 'array' : typeof value;
  }

  getItemCount(value) {
    if (Array.isArray(value)) {
      return value.length;
    }
    if (value !== null && typeof value === 'object') {
      return Object.keys(value).length;
    }
    return undefined;
  }

  getUtf8Size(content) {
    let size = 0;

    for (let index = 0; index < content.length; index++) {
      const code = content.charCodeAt(index);

      if (code < 0x80) {
        size += 1;
      } else if (code < 0x800) {
        size += 2;
      } else if (code >= 0xD800 && code <= 0xDBFF &&
        index + 1 < content.length) {
        const next = content.charCodeAt(index + 1);
        if (next >= 0xDC00 && next <= 0xDFFF) {
          size += 4;
          index += 1;
        } else {
          size += 3;
        }
      } else {
        size += 3;
      }
    }

    return size;
  }
}
