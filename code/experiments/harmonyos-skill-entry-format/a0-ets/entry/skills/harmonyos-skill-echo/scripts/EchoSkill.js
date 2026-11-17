// Isolated experiment only: test whether a plain JavaScript file can be
// declared as a Skill entry by module.json5. This does not claim runtime support.
export default class EchoSkill {
  async echo(info, ...argv) {
    return {
      code: 0,
      result: {
        type: 'result',
        status: 'success',
        data: { message: argv[0] ?? 'Hello from JavaScript' }
      }
    };
  }
}
