---
name: weather-current
description: Query current weather by city. Ask for a city when it is missing.
tool: get_current_weather
trigger-suffixes: 当前天气,现在下雨吗
---

For an explicit current-weather query, pass the city to get_current_weather.
Return the matched location, Celsius temperature, condition and observation time.
Ask for a city when it is missing and report failures from the tool.
