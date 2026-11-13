import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

export interface OntologyEntity {
  id: string;
  type: string;
  properties: Record<string, Object>;
  created: string;
  updated: string;
}

export interface StoreResult {
  ok: boolean;
  data?: Object;
  errCode?: string;
  errMsg?: string;
  suggestion?: string;
}

class EntityResultData {
  entity: OntologyEntity;

  constructor(entity: OntologyEntity) {
    this.entity = entity;
  }
}

class EntityListResultData {
  entities: OntologyEntity[];
  count: number;

  constructor(entities: OntologyEntity[]) {
    this.entities = entities;
    this.count = entities.length;
  }
}

const STORE_NAME: string = 'e3_ontology_store';
const ENTITIES_KEY: string = 'entities_json';
const MAX_ENTITIES: number = 500;
const MAX_PROPERTIES_CHARS: number = 16 * 1024;
const ID_PATTERN: RegExp = /^[A-Za-z0-9_-]{1,64}$/;
const ALLOWED_TYPES: string[] = [
  'Person', 'Project', 'Task', 'Goal', 'Event', 'Document',
  'Message', 'Thread', 'Note', 'Action', 'Policy'
];

export class OntologyStore {
  private context: common.Context;

  constructor(context: common.Context) {
    this.context = context;
  }

  public async createEntity(id: string, type: string, propertiesJson: string): Promise<StoreResult> {
    if (!ID_PATTERN.test(id) || ALLOWED_TYPES.indexOf(type) < 0 || propertiesJson.length === 0) {
      return this.failure('ERR_INVALID_PARAMS', 'id, type or properties is invalid',
        '请使用合法 ID、受支持类型和非空 JSON 对象。');
    }
    if (propertiesJson.length > MAX_PROPERTIES_CHARS) {
      return this.failure('ERR_LIMIT', 'properties exceeds 16 KiB', '请缩小实体属性。');
    }

    let propertiesObject: Record<string, Object>;
    try {
      const parsed: Object = JSON.parse(propertiesJson) as Object;
      if (Array.isArray(parsed) || parsed === null || typeof parsed !== 'object') {
        return this.failure('ERR_INVALID_JSON', 'properties must be a JSON object', '请传入 JSON 对象。');
      }
      propertiesObject = parsed as Record<string, Object>;
    } catch (error) {
      return this.failure('ERR_INVALID_JSON', String(error), '请检查 properties JSON 格式。');
    }

    const missing: string = this.missingRequiredProperty(type, propertiesObject);
    if (missing.length > 0) {
      return this.failure('ERR_REQUIRED_PROPERTY', `${type}.${missing} is required`, `请补充 ${missing}。`);
    }
    const forbidden: string = this.forbiddenProperty(propertiesObject);
    if (forbidden.length > 0) {
      return this.failure('ERR_FORBIDDEN_PROPERTY', `${forbidden} must not be stored`,
        '请移除密码、令牌或秘密字段，仅保存非敏感引用。');
    }

    try {
      const entities: OntologyEntity[] = await this.loadEntities();
      if (entities.some((entity: OntologyEntity) => entity.id === id)) {
        return this.failure('ERR_CONFLICT', `entity ${id} already exists`, '请更换 ID 或先查询现有实体。');
      }
      if (entities.length >= MAX_ENTITIES) {
        return this.failure('ERR_LIMIT', 'entity limit reached', '请清理应用数据或缩小测试规模。');
      }

      const now: string = new Date().toISOString();
      const entity: OntologyEntity = {
        id: id,
        type: type,
        properties: propertiesObject,
        created: now,
        updated: now
      };
      entities.push(entity);
      await this.saveEntities(entities);
      return { ok: true, data: new EntityResultData(entity) };
    } catch (error) {
      return this.failure('ERR_INTERNAL', String(error), '本地存储失败，请稍后重试。');
    }
  }

  public async getEntity(id: string): Promise<StoreResult> {
    if (!ID_PATTERN.test(id)) {
      return this.failure('ERR_INVALID_PARAMS', 'id is invalid', '请提供合法实体 ID。');
    }
    try {
      const entities: OntologyEntity[] = await this.loadEntities();
      const entity: OntologyEntity | undefined = entities.find((item: OntologyEntity) => item.id === id);
      if (entity === undefined) {
        return this.failure('ERR_NOT_FOUND', `entity ${id} was not found`, '请确认 ID，或先创建实体。');
      }
      return { ok: true, data: new EntityResultData(entity) };
    } catch (error) {
      return this.failure('ERR_INTERNAL', String(error), '本地读取失败，请稍后重试。');
    }
  }

  public async listEntities(type: string): Promise<StoreResult> {
    if (ALLOWED_TYPES.indexOf(type) < 0) {
      return this.failure('ERR_INVALID_PARAMS', 'type is unsupported', '请使用受支持的实体类型。');
    }
    try {
      const entities: OntologyEntity[] = await this.loadEntities();
      const matches: OntologyEntity[] = entities.filter((entity: OntologyEntity) => entity.type === type);
      return { ok: true, data: new EntityListResultData(matches) };
    } catch (error) {
      return this.failure('ERR_INTERNAL', String(error), '本地读取失败，请稍后重试。');
    }
  }

  private async loadEntities(): Promise<OntologyEntity[]> {
    const store: preferences.Preferences = await preferences.getPreferences(this.context, { name: STORE_NAME });
    const rawValue: preferences.ValueType = await store.get(ENTITIES_KEY, '[]');
    const raw: string = String(rawValue);
    const parsed: Object = JSON.parse(raw) as Object;
    return Array.isArray(parsed) ? parsed as OntologyEntity[] : [];
  }

  private async saveEntities(entities: OntologyEntity[]): Promise<void> {
    const store: preferences.Preferences = await preferences.getPreferences(this.context, { name: STORE_NAME });
    await store.put(ENTITIES_KEY, JSON.stringify(entities));
    await store.flush();
  }

  private missingRequiredProperty(type: string, props: Record<string, Object>): string {
    if (type === 'Note' && !this.hasText(props, 'content')) return 'content';
    if (type === 'Project' && !this.hasText(props, 'name')) return 'name';
    if (type === 'Project' && !this.hasText(props, 'status')) return 'status';
    if (type === 'Task' && !this.hasText(props, 'title')) return 'title';
    if (type === 'Task' && !this.hasText(props, 'status')) return 'status';
    if (type === 'Person' && !this.hasText(props, 'name')) return 'name';
    return '';
  }

  private hasText(props: Record<string, Object>, key: string): boolean {
    const value: Object | undefined = props[key];
    return value !== undefined && typeof value === 'string' && String(value).trim().length > 0;
  }

  private forbiddenProperty(props: Record<string, Object>): string {
    if (props['password'] !== undefined) return 'password';
    if (props['secret'] !== undefined) return 'secret';
    if (props['token'] !== undefined) return 'token';
    return '';
  }

  private failure(errCode: string, errMsg: string, suggestion: string): StoreResult {
    return { ok: false, errCode: errCode, errMsg: errMsg, suggestion: suggestion };
  }
}
