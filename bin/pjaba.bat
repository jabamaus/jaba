@echo off
ruby --disable=rubyopt,did_you_mean -w %~dp0../src/jaba.rb --profile %*
