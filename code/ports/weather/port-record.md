# Weather port record

## Source and baseline

Original: OpenClaw bundled weather, commit `d79ab6195d8d0566b285008bcc30c01a6ce368e2`; source and license preserved in `source/weather/`.
Team template snapshot: `8b83dbb465467329dc735b304cce01775fa41260`.
Baseline: `docs/04-methodology/group-b/skill-baselines/e2/weather-baseline.md` in the team repository (2026-10-30). Original baseline was not rerun in this session.

## Dependency mapping

| Original dependency/behavior | Port |
| --- | --- |
| web_fetch, fallback curl | NetworkKit HTTP; no device Python, Node or curl required |
| wttr.in with alternate wttr.is | Same HTTPS providers; connect/read timeouts and request cleanup |
| Model extracts JSON fields | Typed application-side parsing and structured return |
| OpenClaw result delivery | WeatherSkill.query and completeArkTSScriptInApp; system dispatch not yet verified |
| Network access | Application permission ohos.permission.INTERNET; no weather API key or location permission |

UI exposes the same queryWeather service as the Skill entry. Successful UI querying cannot prove Skill invocation or callback delivery.

## Baseline comparison

| Case | Original baseline | Port evidence | Acceptance |
| --- | --- | --- | --- |
| Shanghai current conditions | Real provider response, requested fields matched | Old host real query passed; formal identity query pending | Compare field presence, units, resolved location and provenance, not values across different dates |
| Primary tool unavailable | curl fallback succeeded | Host tool replaced by native HTTP | Architectural adaptation; not identical tool fallback |
| Alternate domain | Not exercised in original baseline | Implemented, device execution unverified | Record separately; no pass claim |
| Controlled timeout | curl code 28 and explicit failure | Timeouts/error returns implemented, not exercised on device | Pending |
| Empty input | Not a recorded original case | Old host UI prompt passed | Does not verify Skill ERR_INVALID_PARAMS callback |
| System host dispatch | OpenClaw target Skill read/tool trace confirmed | Xiaoyi/Work dispatch and callback unverified | Pending |

Original observation and HarmonyOS observation were collected at different times and locations resolved by the provider; numeric equality is not an acceptance requirement. Full upstream feature parity is not claimed.

## Identity and verification

Formal bundle `io.github.uefn.weatherport`, Skill `harmonyos-weather`, EntryAbility, module entry. Earlier evidence used `org.example.echosmoke`. Formal signed HAP metadata was inspected; user reported formal installation/start success, without captured raw command output. Fresh formal-identity service evidence is still required.

Platform-only edits reported by the user added module.json and changed the command example to exec/ohos-arktsScript. These exported bytes have not been independently inspected or synchronized with the installed signed HAP. Retain this version boundary when troubleshooting.

## Integration blocker

The user verified the test account and restarted Xiaoyi; the Skill test shortcut remained absent. Work attempted ZIP installation and reported missing bundleName despite a supplied bundleName. This is user-relayed evidence, not an agent-captured tool trace. A missing tool Schema is an unproven explanation. Do not bypass read-only directories, invent tool definitions or treat safety scan success as installation success.

## Remaining acceptance work

1. Capture a real Shanghai query on the formal identity with timestamp, resolved location and source.
2. Inspect the actual platform ZIP and reconcile it with the signed application's Skill entry.
3. Verify host installation/discovery, actual query dispatch and completion result; retain the raw failure if blocked.
4. Exercise controlled network failure and alternate-domain handling if claiming those paths passed.
5. Review and submit source under code/ports/weather and call-chain documentation under docs/04-methodology/group-b/harness.

## Final acceptance and client correction (2026-11-13)

End-to-end Skill acceptance was not passed. The user has ended integration attempts and requested delivery as a failure case with partial application-side results. The user clarified that installation attempts used the client they call "小艺工作", not the paid target "小艺 Work", which is unavailable for this run. Earlier references to Work errors do not establish the target product's capabilities. Formal live-query evidence remains absent. No discovery/dispatch/callback success is claimed.

Executor: ue-fn (E2). File/function-level Harness source analysis remains incomplete; see the delivery summary for the explicit limitation.
