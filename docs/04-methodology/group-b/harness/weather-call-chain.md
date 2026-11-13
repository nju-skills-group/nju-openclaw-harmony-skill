# Weather call chain and Harness boundary

Status date: 2026-11-13. This is a design and evidence map, not a successful end-to-end trace.

## Intended system chain

User city request -> Xiaoyi/Work loads harmonyos-weather instructions -> host resolves the installed application's Skill -> host ArkTS execution command -> WeatherSkill.query(info, ...argv) -> queryWeather(city) -> NetworkKit HTTPS primary wttr.in -> fallback wttr.is on failure -> validate/parse provider JSON -> structured success/failure -> completeArkTSScriptInApp -> host presents actual result.

## Observed application chain

Application UI -> queryWeather -> real provider result -> displayed fields passed on the historical org.example.echosmoke host. The formal io.github.uefn.weatherport signed HAP was built and inspected; installation/start was confirmed by the user. Formal live query and the host-specific chain still need evidence.

## Harness responsibilities

| Layer | Responsibility | Evidence boundary |
| --- | --- | --- |
| Original OpenClaw host | Discover/read Skill, expose web_fetch/exec, deliver tool result | E2 baseline has read and tool traces |
| HarmonyOS host | Discover Skill, associate application, expose command, dispatch and receive callback | Not verified; shortcut absent and Work installation failed |
| Signed application | Skill entry, validation, HTTP requests, parsing and completion API | Built; historical UI tests do not enter the Skill entry |
| Provider | Supply current observations and daily forecasts | Historical response recorded; no independent meteorological freshness validation |

The Harness is not just SKILL.md. It includes discovery, tool exposure, application binding, permissions, execution context and result delivery. A ZIP passing static validation or safety scan does not prove these runtime responsibilities work.

## Required end-to-end evidence

Record user input, host Skill discovery/load, actual command and parameters, installed bundle/Skill identity, Skill entry marker, provider response or error, callback result and final answer. Verify fields against the same captured response. Never substitute model-generated weather. Report failures at the earliest evidenced layer; missing Schema is not established by a missing-parameter error alone.

Related source: ../../../../code/ports/weather/port-record.md

## Final outcome

End-to-end acceptance not passed; user ended attempts. Earlier Work references were based on an incorrect client assumption: the attempted entry was user-described 小艺工作, not the unavailable paid 小艺 Work. Its reported tool list is not evidence of the target host capability. No runtime route is certified by this document.

## Source-analysis limitation

This handoff maps host responsibilities and available baseline traces. A file/function-level OpenClaw source walkthrough has not been completed for this run; the full Harness source-study requirement remains unmet. Original baseline environment: OpenClaw 2026.10.3 (59cb447), embedded local agent execution, no Gateway RPC, as recorded in the referenced E2 baseline.
