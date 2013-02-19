require 'pony'
require 'celluloid'

class SendEmail
  include Celluloid

  #@queue = :email
  def initialize(obj)
    @to = obj[:to]
    @token = obj[:token]
    @reason = obj[:reason]
  end
  def perform
  		puts "sending email to #{@to} with token #{@token} with reason #{@reason}"  
      if @reason == 'register'     
        body = 'Please click  http://10.1.0.195:3000/account/activate/' + @token+' to confirm registration.'
      else
        body = "Your email:#{@to}, Your password: #{@token}"
      end

      Pony.mail :to => @to,
                :from => 'hoangdung1987@gmail.com',
                :subject => 'Registration confirmation',
                :body=>  body,
                :via_options => {
                :address => 'smtp.gmail.com',
                :port => '587',
                :enable_starttls_auto => true,
                :user_name => 'hoangdung1987@gmail.com',
                :password => 'revskill123',
                :authentication => :plain,
                :domain => "localhost:3002"
                }

  #   Tire.index 'emaillog' do      
   #   create
    #  store :email_to => to,   :time => Time.now, :token => token, :reason => reason
     # refresh
    #end
	
  end
end