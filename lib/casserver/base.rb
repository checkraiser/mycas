require 'sinatra/base'
require 'sinatra/r18n'
require 'logger'
require 'rack-flash'
$LOG ||= Logger.new(STDOUT)

module CASServer
  class Base < Sinatra::Base
    register Sinatra::R18n
    R18n::I18n.default = 'en'
    R18n.default_places { File.join(root,'..','..','locales') }
    use Rack::Flash
    set :sessions, true
  end
end
