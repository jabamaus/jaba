@echo off
pushd %~dp0\examples
ruby --disable=gems,rubyopt,did_you_mean -w %~dp0lib\jaba\jaba.rb --dump-input %*
popd
