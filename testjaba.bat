@echo off
pushd %~dp0test
ruby test_jaba.rb %*
popd
