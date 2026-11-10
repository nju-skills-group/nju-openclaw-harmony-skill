export class JsonToolkitError extends Error {
  public readonly errorCode: string;
  public readonly suggestion: string;

  constructor(errorCode: string, message: string, suggestion: string);
}

export class JsonToolkitResult {
  public operation: string;
  public valid: boolean;
  public result?: string;
  public jsonType?: string;
  public itemCount?: number;
  public size?: number;
}

export default class JsonToolkitService {
  public execute(
    operation: string,
    content: string,
    path?: string,
    indent?: number,
    sortKeys?: boolean
  ): JsonToolkitResult;
}
