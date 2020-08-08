pushd ..\..\ruby
win32\configure.bat --with-static-linked-ext --disable-install-doc  --prefix=C:\GitHub\Projects\JabaRuby --with-baseruby=C:\Ruby27-x64\bin\ruby.exe --without-ext="bigdecimal,cgi,continuation,coverage,date,dbm,etc,fcntl,fiber,fiddle,gdbm,io,monitor,nkf,objspace,openssl,pathname,psych,pty,racc,readline,ripper,rubyvm,sdbm,socket,stringio,strscan,syslog,-test-,win32,win32ole,zlib"
popd
