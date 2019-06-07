@echo off
pushd %~dp0\examples
ruby %~dp0lib\jaba\jaba.rb %*
popd
