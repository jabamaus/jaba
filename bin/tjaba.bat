@echo off
ruby --disable=did_you_mean --enable=frozen-string-literal -w %~dp0../test/test_jaba.rb %*
rem To run a specific match:
rem eg tjaba -n /TopLevelDefinition/
rem eg tjaba -n "/supports inspect for debugging/"
