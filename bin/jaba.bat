@echo off
jabaruby --enable=frozen-string-literal -w %~dp0../src/jaba.rb %*
