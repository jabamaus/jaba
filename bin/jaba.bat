@echo off
jabaruby.exe --disable=rubyopt -I%~dp0..\jabaruby\stdlib -w %~dp0jaba.rb %*

