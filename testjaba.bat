@echo off
pushd %~dp0test
ruby -w test_jaba.rb %*
popd
