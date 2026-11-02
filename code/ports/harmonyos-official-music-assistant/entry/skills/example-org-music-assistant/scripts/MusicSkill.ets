import { BusinessError } from '@kit.BasicServicesKit';
import { scriptManager } from '@kit.AbilityKit';
import { MusicPlayer, PlaybackResult, PlayResult, Track } from '../../../src/main/ets/service/MusicPlayer';

const INVALID_PARAMS: string = 'ERR_INVALID_PARAMS';
const NOT_FOUND: string = 'ERR_NOT_FOUND';
const INTERNAL: string = 'ERR_INTERNAL';

export default class MusicSkill {
  public async playMusicByName(
    info: scriptManager.ArkTSScriptInfo,
    ...argv: string[]
  ): Promise<void> {
    const songName: string = argv.length > 0 ? argv[0].trim() : '';
    const singer: string = argv.length > 1 ? argv[1].trim() : '';
    let executeResult: scriptManager.ExecuteResult;

    if (songName.length === 0 && singer.length === 0) {
      executeResult = this.failure(
        -1,
        INVALID_PARAMS,
        'songName and singer are both empty',
        '请告诉我歌名或歌手。'
      );
    } else {
      try {
        const playResult: PlayResult | null = MusicPlayer.searchAndPlay(songName, singer);
        if (playResult === null) {
          executeResult = {
            code: -2,
            result: {
              type: 'result',
              status: 'failed',
              errCode: NOT_FOUND,
              data: { searchedKeywords: [songName, singer] },
              suggestion: `没有找到${singer}${songName.length > 0 ? `的《${songName}》` : '相关歌曲'}`
            }
          };
        } else {
          const first: Track = playResult.tracks[0];
          executeResult = {
            code: 0,
            result: {
              type: 'result',
              status: 'success',
              data: {
                playingTrack: {
                  name: first.name,
                  singer: first.singer,
                  duration: first.duration
                },
                matchedCount: playResult.tracks.length,
                playback: 'playing'
              }
            }
          };
        }
      } catch (error) {
        const businessError = error as BusinessError;
        executeResult = this.failure(
          -3,
          INTERNAL,
          `${businessError.code}: ${businessError.message}`,
          '播放请求处理失败，请稍后重试。'
        );
      }
    }

    await this.report(info, executeResult);
  }

  public async controlPlayback(
    info: scriptManager.ArkTSScriptInfo,
    ...argv: string[]
  ): Promise<void> {
    const action: string = argv.length > 0 ? argv[0].trim() : '';
    const allowedActions: string[] = ['pause', 'resume', 'next', 'previous'];
    let executeResult: scriptManager.ExecuteResult;

    if (!allowedActions.includes(action)) {
      executeResult = this.failure(
        -1,
        INVALID_PARAMS,
        `Unsupported action: ${action}`,
        '可以暂停、继续、切到下一首或上一首。'
      );
    } else {
      try {
        const playback: PlaybackResult | null = MusicPlayer.controlPlayback(action);
        if (playback === null) {
          executeResult = this.failure(
            -2,
            NOT_FOUND,
            'There is no active track',
            '请先选择一首歌曲再控制播放。'
          );
        } else {
          executeResult = {
            code: 0,
            result: {
              type: 'result',
              status: 'success',
              data: {
                action: playback.action,
                status: playback.status,
                playingTrack: playback.playingTrack === undefined ? {} : {
                  name: playback.playingTrack.name,
                  singer: playback.playingTrack.singer,
                  duration: playback.playingTrack.duration
                }
              }
            }
          };
        }
      } catch (error) {
        const businessError = error as BusinessError;
        executeResult = this.failure(
          -3,
          INTERNAL,
          `${businessError.code}: ${businessError.message}`,
          '播放控制失败，请稍后重试。'
        );
      }
    }

    await this.report(info, executeResult);
  }

  private failure(
    code: number,
    errCode: string,
    errMsg: string,
    suggestion: string
  ): scriptManager.ExecuteResult {
    return {
      code: code,
      result: {
        type: 'result',
        status: 'failed',
        errCode: errCode,
        errMsg: errMsg,
        suggestion: suggestion
      }
    };
  }

  private async report(
    info: scriptManager.ArkTSScriptInfo,
    result: scriptManager.ExecuteResult
  ): Promise<void> {
    try {
      await scriptManager.completeArkTSScriptInApp(info.context, info.requestCode, result);
    } catch (error) {
      const businessError = error as BusinessError;
      console.error(
        `completeArkTSScriptInApp failed, code: ${businessError.code}, message: ${businessError.message}`
      );
    }
  }
}
