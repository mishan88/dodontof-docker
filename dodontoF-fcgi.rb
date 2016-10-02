#!/usr/bin/ruby
#--*-coding:utf-8-*--
Encoding.default_external='utf-8'

require 'fcgi'

load '/var/www/html/DodontoFServer.rb'
FCGI.each do |cgi|
    $stdout = cgi.out
    $stdin = cgi.in
    ENV.replace(cgi.env)
    executeDodontoServerCgi
    cgi.finish
end
