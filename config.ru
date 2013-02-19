require 'rubygems'
require 'bundler/setup'

$:.unshift "#{File.dirname(__FILE__)}/lib"
require "casserver"
use Rack::ShowExceptions
use Rack::Runtime
use Rack::CommonLogger




map ('/account') {run AccountModule::Account.new}
map ('/') {run CASServer::Server.new}