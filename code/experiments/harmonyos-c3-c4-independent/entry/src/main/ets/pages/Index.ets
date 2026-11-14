import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { BUNDLE, issueReceipt, matchReceipt, trace } from '../Receipt';
import { runWeatherSkill } from '../WeatherSkillLoader';

@Entry
@Component
struct Index {
  @State input: string = '';
  @State result: string = '';
  @State busy: boolean = false;
  @State weatherEnabled: boolean = true;

  async runWeather(timeoutMs: number): Promise<void> {
    const id = util.generateRandomUUID();
    this.busy = true;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const weather = await runWeatherSkill(context.resourceManager, this.input, this.weatherEnabled, id, timeoutMs);
      this.result = weather.status === 'success'
        ? `${weather.location} · ${weather.temperatureC} °C · ${weather.condition} · ${weather.observationTime ?? '时间未提供'}`
        : weather.reason ?? '天气查询失败。';
      trace('weather_agent_result', id, JSON.stringify(weather));
    } catch (error) {
      this.result = '无法加载天气 Skill。';
      trace('weather_skill_load_failed', id, String(error));
    } finally {
      this.busy = false;
    }
  }

  async run(useAbility: boolean): Promise<void> {
    const id = util.generateRandomUUID();
    const code = matchReceipt(this.input);
    trace('agent_match', id, code ? 'receipt' : 'no_match');
    if (!code) {
      this.result = '请输入「生成回执」和测试码';
      return;
    }
    this.busy = true;
    try {
      if (useAbility) {
        trace('ability_requested', id, code);
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        const response = await context.startAbilityForResult({
          bundleName: BUNDLE,
          abilityName: 'ReceiptAbility',
          parameters: { requestId: id, code }
        });
        const receipt = response.want?.parameters?.receipt;
        if (response.resultCode !== 0 || typeof receipt !== 'string') {
          throw new Error('Ability 返回无效');
        }
        this.result = receipt;
      } else {
        trace('local_handler_entered', id, code);
        this.result = issueReceipt(code);
      }
      trace('agent_result', id, this.result);
    } catch (error) {
      this.result = '调用失败';
      trace('agent_failed', id, String(error));
    } finally {
      this.busy = false;
    }
  }

  build() {
    Column({ space: 16 }) {
      Text('个人实验智能体').fontSize(24)
      TextInput({ placeholder: '生成回执 C3-DEMO-01', text: this.input })
        .id('c34_input')
        .onChange((value: string) => { this.input = value; })
      Button('调用应用内处理器').id('c34_local').enabled(!this.busy).onClick(() => { void this.run(false); })
      Button('调用回执 Ability').id('c34_ability').enabled(!this.busy).onClick(() => { void this.run(true); })
      Toggle({ type: ToggleType.Switch, isOn: this.weatherEnabled }).id('weather_enabled')
        .enabled(!this.busy).onChange((value: boolean) => { this.weatherEnabled = value; })
      Text('启用天气 Skill')
      Button('执行天气 Skill').id('weather_run').enabled(!this.busy).onClick(() => { void this.runWeather(10000); })
      Button('执行天气超时对照（1 ms）').id('weather_timeout')
        .enabled(!this.busy).onClick(() => { void this.runWeather(1); })
      Text(this.result).id('c34_result')
    }.padding(24).width('100%').height('100%').justifyContent(FlexAlign.Center)
  }
}
