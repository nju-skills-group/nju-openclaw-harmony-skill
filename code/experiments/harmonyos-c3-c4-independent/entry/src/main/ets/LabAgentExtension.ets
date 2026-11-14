import { AgentExtensionAbility, common, Want } from '@kit.AbilityKit';
import { createA2AServer, OnDataCallback, RequestContext, Role, Server, TaskState } from '@kit.AgentFrameworkKit';
import { util } from '@kit.ArkTS';
import { issueReceipt, matchReceipt, trace } from './Receipt';

export default class LabAgentExtension extends AgentExtensionAbility {
  private server?: Server;

  private handle: OnDataCallback = (method: string, context: RequestContext): void => {
    const taskId = context.getTaskId() ?? '';
    trace('a2a_method', taskId, method);
    if (method !== 'Execute' || !taskId) {
      return;
    }
    const text = context.getUserInput(' ').trim();
    const routedCodes = text.match(/\bC4-[A-Za-z0-9-]{3,29}\b/g);
    const code = matchReceipt(text) || (routedCodes?.length === 1 ? routedCodes[0] : '');
    const reply = code ? issueReceipt(code) : '请输入「生成回执」及一个测试码，例如「生成回执 C4-DEMO-01」。';
    if (code) {
      trace('a2a_receipt', taskId, reply);
    } else {
      trace('a2a_input_unmatched', taskId, String(text.length));
    }
    this.server?.addArtifact(taskId, {
      artifactId: util.generateRandomUUID(),
      parts: [{ mediaType: 'text/plain', text: reply }],
      lastChunk: true
    });
    this.server?.updateStatus(taskId, {
      state: TaskState.COMPLETED,
      message: {
        messageId: util.generateRandomUUID(),
        role: Role.AGENT,
        parts: [{ mediaType: 'text/plain', text: reply }]
      }
    });
  };

  onCreate(want: Want): void {
    trace('a2a_create', '');
    try {
      const card = this.context.agentCard;
      if (card) {
        this.server = createA2AServer(card, this.handle, want);
      } else {
        trace('a2a_card_missing', '');
      }
    } catch (error) {
      trace('a2a_create_failed', '', String(error));
    }
  }

  onConnect(_want: Want, _proxy: common.AgentHostProxy): void {
    trace('a2a_connected', '');
    this.server?.start();
  }

  onAuth(_proxy: common.AgentHostProxy, _handshakeData: string): void {
    trace('a2a_auth_requested', '');
  }

  onData(proxy: common.AgentHostProxy, data: string): void {
    trace('a2a_data', '', String(data.length));
    this.server?.onMessage(data, (reply: string): void => {
      try {
        proxy.sendData(reply);
        trace('a2a_sent', '', String(reply.length));
      } catch (error) {
        trace('a2a_send_failed', '', String(error));
      }
    });
  }

  onDisconnect(_want: Want, _proxy: common.AgentHostProxy): void {
    trace('a2a_disconnected', '');
    this.server?.stop();
  }

  onDestroy(): void {
    this.server?.stop();
  }
}
