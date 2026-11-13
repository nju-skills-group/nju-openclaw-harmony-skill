# Weather HarmonyOS port

Formal application: `io.github.uefn.weatherport`; module: `entry`; Ability: `EntryAbility`; Skill: `harmonyos-weather`; method: `query`.

Ports OpenClaw weather at commit `d79ab6195d8d0566b285008bcc30c01a6ce368e2` to HarmonyOS API 26. Uses NetworkKit HTTPS to query wttr.in, with wttr.is as fallback, and returns structured current conditions and daily high/low forecasts.

## Current status (2026-11-13)

| Item | Status and evidence |
| --- | --- |
| Formal HAP build/signature | Passed; `evidence/signing-new-identity.txt` and `evidence/current-status.json` |
| Formal package installation/start | User reported success after running supplied hdc commands; raw device output not captured |
| Formal package live weather | Pending fresh evidence |
| Earlier host live weather/empty city | Passed on old bundle `org.example.echosmoke`; historical evidence only |
| Xiaoyi dispatch and callback | Not verified; test shortcut absent; Work ZIP installation reported missing bundleName |
| Fallback domain/network error on device | Implemented, not exercised |

Do not describe this state as completed end-to-end Skill integration. `evidence/runtime-summary.json` and `build-summary.json` belong to the earlier host, not the formal identity. See `evidence/README.md` for provenance.

## Build and run

Use DevEco Studio 26.0.0.865 with the HarmonyOS API 26 SDK. Copy `build-profile.example.json5` to `build-profile.json5`, open this project, and configure your own development signing for the formal bundle and test device. The example contains no usable private signing configuration. Run `./build.ps1` after signing is configured. The script defaults to `D:/software/DevEco-Studio`; use `-DevEcoRoot` if needed.

Signed output: `entry/build/default/outputs/default/entry-default-signed.hap`. Private signing files, local SDK paths, dependencies, build outputs and device logs are excluded from publication.

On a connected, unlocked test device, install the signed HAP and start `EntryAbility` in the formal bundle. In the UI query `Shanghai`, retain resolved location, real values, source and timestamp. This verifies app business behavior, not Xiaoyi dispatch.

## Scope

Supports current temperature, feels-like temperature, humidity, wind, precipitation, condition, resolved location and provider-supplied daily date/high/low. No automatic geolocation, historical data, alerting, hourly details or original terminal art/text formats. Do not infer a timezone for the provider's raw observation time.

The platform-edited SKILL.md and module.json reported in chat have not been downloaded and independently matched to the local HAP. The local embedded instruction still uses the original exec-cli example. Platform import, host command spelling, Skill installation and full callback behavior remain integration work; do not claim the exported ZIP is a verified replacement for the installed HAP.

## Final acceptance and client correction (2026-11-13)

End-to-end Skill acceptance was not passed. The user has ended integration attempts and requested delivery as a failure case with partial application-side results. The user clarified that installation attempts used the client they call "小艺工作", not the paid target "小艺 Work", which is unavailable for this run. Earlier references to Work errors do not establish the target product's capabilities. Formal live-query evidence remains absent. No discovery/dispatch/callback success is claimed.

Executor: ue-fn (E2). File/function-level Harness source analysis remains incomplete; see the delivery summary for the explicit limitation.
