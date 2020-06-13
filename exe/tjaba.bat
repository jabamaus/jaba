@echo off
ruby --disable=did_you_mean -w -I%~dp0\..\lib %~dp0jaba.rb --dump-input %*

