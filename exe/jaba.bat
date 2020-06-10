@echo off
ruby --disable=rubyopt,did_you_mean -w -I%~dp0\..\lib %~dp0jaba.rb --dump-input %*

