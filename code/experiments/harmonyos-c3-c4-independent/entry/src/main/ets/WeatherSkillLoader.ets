import { util } from '@kit.ArkTS';
import { resourceManager } from '@kit.LocalizationKit';
import { trace } from './Receipt';
import { getCurrentWeather, WeatherResult } from './WeatherService';

const SKILL_FILE = 'skills/weather-current/SKILL.md';

export async function runWeatherSkill(resources: resourceManager.ResourceManager, input: string,
  enabled: boolean, id: string, timeoutMs: number): Promise<WeatherResult> {
  if (!enabled) {
    trace('weather_skill_disabled', id);
    return { status: 'disabled', reason: '天气 Skill 已禁用。' };
  }
  const bytes = await resources.getRawFileContent(SKILL_FILE);
  const text = util.TextDecoder.create('utf-8').decodeToString(bytes);
  const header = /^---\r?\n([\s\S]*?)\r?\n---\r?\n/.exec(text)?.[1] ?? '';
  const name = /^name: ([a-z0-9-]+)$/m.exec(header)?.[1];
  const description = /^description: (.+)$/m.exec(header)?.[1];
  const tool = /^tool: ([a-z_]+)$/m.exec(header)?.[1];
  const triggers = /^trigger-suffixes: (.+)$/m.exec(header)?.[1];
  if (name !== 'weather-current' || !description || tool !== 'get_current_weather' || !triggers) {
    throw new Error('天气 Skill 缺少有效名称、描述、触发规则或工具绑定');
  }
  trace('weather_skill_loaded', id, name);
  const request = input.trim().replace(/[？?。]$/, '').replace(/^(?:查询|查)\s*/, '');
  const trigger = triggers.split(',').map(value => value.trim()).find(value => value && request.endsWith(value));
  if (!trigger) {
    trace('weather_skill_no_match', id);
    return { status: 'no_match', reason: '请输入要查询的当前天气，例如「南京当前天气」。' };
  }
  const city = request.slice(0, -trigger.length).trim();
  trace('weather_skill_matched', id, tool);
  if (!city) {
    return { status: 'clarification', reason: '请提供要查询的城市。' };
  }
  return getCurrentWeather(city, id, timeoutMs);
}
