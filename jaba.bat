@echo off
pushd %~dp0\examples
ruby -w %~dp0lib\jaba\jaba.rb %*
popd
