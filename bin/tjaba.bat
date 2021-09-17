@echo off
ruby --disable=did_you_mean --enable=frozen-string-literal -w %~dp0../test/test_jaba.rb %*

