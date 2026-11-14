import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(stage: window.WindowStage): void {
    stage.loadContent('pages/Index', (error) => {
      if (error.code) {
        hilog.error(0xC202, 'C2OwnReceipt', 'event=app_load_failed code=%{public}d', error.code);
        return;
      }
      hilog.info(0xC202, 'C2OwnReceipt', 'event=app_ready');
    });
  }
}
