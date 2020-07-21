@echo off
ruby --disable=rubyopt,did_you_mean -w %~dp0jaba.rb --profile %*
