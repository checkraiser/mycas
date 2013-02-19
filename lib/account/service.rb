require 'data_mapper'
require 'sinatra'
require 'securerandom'
require 'date'
require 'time'
require 'digest/md5'
#require 'resque'
 require 'dm-validations'
require 'rack-flash'
#require 'celluloid'

#Resque.redis = 'localhost:6379'

require './models'



@host_name = '10.1.0.195:3000/'
	module AccountModule
	  class Account < CASServer::Base

		use Rack::Flash
		set :environment, :production
		#set :erb, :layout => false
		set :root, File.dirname(__FILE__)
		set :views, Proc.new { File.join(root, "views") }
		set :public_folder, Proc.new { File.join(root, "static") }
		register do
		    def check (name)
		      condition do
		        error 401 unless send(name) == true
		      end
		    end
		  end		

		get "/api/users", :check => :valid_key? do
			[1,2,3].to_json
		end


		# ngayketthuc = DateTime.strptime(item[:ngay_ket_thuc].strip,"%d/%m/%Y");
		# profile view
		get "/" do
			#@message = {:msg => 'Please register or login'}	 if session[:user] == nil
			if session[:user]			
				erb :index
			else
				redirect @host_name
			end
		end

		# update profile or reactivate
		post "/" do
			if session[:user]
				email = params[:user][:email].gsub(/\s+/, "")
				password = params[:user][:password].gsub(/\s+/, "")
				password2 = params[:user][:password2].gsub(/\s+/, "")
				if password == password2
					if user = User.first(:email => session[:user]) then
						user.email = email
						user.password = Digest::MD5.hexdigest(password)
						if user.save
							flash[:notice] = 'Update profile successfully'
							redirect '/'
						else
							user.errors.each do |e|
								puts e
							end
							#@message = {:msg => 'Error saving user' }
							flash[:error] = 'Error saving user'
							redirect @host_name
						end
					end
				else
					flash[:error] =  'Passwords are not the same'
					redirect '/'
				end
			else
				flash[:notice] = 'Please login'
				redirect @host_name
			end
		end

		#reactivate account after expire
		post "/reactivate" do
			if session[:user]	
				if current_user.status == 0 then
					if current_user.activations
						current_user.activations.each do |ac|
							ac.status = 1	if ac		
						end
					end
					register_confirm = Activation.new({:token => SecureRandom.hex, :created_at => Time.now, 
		  	:description => 'Register confirmation', :status => 0})
					current_user.activations << register_confirm
					if current_user.save and register_confirm.save
						flash[:notice] = 'An email has been sent to #{email}'
		  				#sendmail(user.email, register_confirm.token, :registermail)
		  				#Resque.enqueue(SendEmail, current_user.email, register_confirm.token, 'register')
		  				sm = SendEmail.new({:to => email, :token => register_confirm.token, :reason => 'register'})
		  				sm.async.perform
		  				redirect @host_name
					else
						flash[:error] = 'Error reactivate'
						redirect '/'
					end
				end
			else
				flash[:notice] = 'Please login'
				redirect @host_name
			end
		end

		get "/signup" do
			if session[:user]
		  		redirect "/"
		  	else 
		  		erb :signup
		  	end
		end
		post "/signup" do
		  email = params[:user][:email].gsub(/\s+/, "")
		  password = params[:user][:password] 
		  password2 = params[:user][:password2] 
		  puts "email #{email}, password #{Digest::MD5.hexdigest(password)}"
		  if email.empty? or password.empty? or password2.empty?
		  	flash[:error] = 'Email or password cannot be blank'  	
		  	redirect '/account/signup'
		  end

		  if user = User.first(:email => email)
		  	flash[:error] = 'Exist email'
		  	redirect '/account/signup'
		  end
		  if params[:user][:password] != params[:user][:password2] 
		  	flash[:error] = 'Passwords are not the same'
		  	redirect '/account/signup'
		  end
		  pass_hash = Digest::MD5.hexdigest(password)
		 
		  role = Role.first_or_create(:name => 'Guest')
		  user = User.new(:email => email, :password => pass_hash, :status => 0,  :created_at => Time.now)
		  user.role = role
		  register_confirm = Activation.new(:token => SecureRandom.hex, :created_at => Time.now, :description => 'Register confirmation', :status => 0)
		  puts "user created: #{user.email}"
		  register_confirm.user = user
		  
		  if user.save and register_confirm.save and role.save
		  	flash[:notice] = 'An email has been sent to #{email}'
		  	#Resque.enqueue(SendEmail, email, register_confirm.token, 'register')
		  	sm = SendEmail.new({:to => email, :token => register_confirm.token, :reason => 'register'})
		  	sm.async.perform
		  	#sendmail(user.email, register_confirm.token, :registermail)
		    #session[:user] = user.email
		    redirect "/" 
		  else
		  	user.errors.each do |e|
				puts e
			end
			register_confirm.each do |e|
				puts e
			end
		  	puts "Error save user"
		  	flash[:error] = 'Error save user'
		    redirect "/signup"
		  end
		end

		# activation for registering
		# in case token expired, what to do , the client need to relogin and activate again
		get "/activate/:token" do |token|
			if activate_token = Activation.first(:token => token.strip) then 
				user = activate_token.user
				if user.status == 0 and (activate_token.created_at - 3 <= DateTime.parse(Time.now.to_s)) then 
					user.status = 1 
					activate_token.token = Time.now.to_s
					activate_token.status = 1
				else
					flash[:error] = 'Activation expired, please reactive'
					redirect '/'			
				end
				if user.save and activate_token.save then 
					flash[:notice] = 'Your acount was activated'
					#session[:user] = user.email
					redirect "/"				
				else
					redirect "/signup"
				end
			else
				flash[:error] = 'Invalid token'
				redirect @host_name
			end
		end

		get "/reset" do
			erb :reset
		end
		post "/reset" do
			email = params[:user][:email].gsub(/\s+/, "")
			if email.empty?
			  	flash[:error] = 'Email cannot be blank'
			  	redirect '/reset'
			 end			
			if user = User.first(:email => email) then				
				newpass = generate_password(8)
				user.password = hash_pass(newpass)
				if  user.save
					#Resque.enqueue(SendEmail, email, newpass, 'reset')
					sm = SendEmail.new({:to => email, :token => newpass, :reason => 'reset'})
		  			sm.async.perform
					#sendmail(user.email, register_confirm.token, :resetmail)
					flash[:notice] = 'Email sent'
					redirect '/'
				else
					flash[:error] = 'Reset pasword error'
					redirect '/'
				end
			else
				flash[:error] = 'Not exist email, please register'
				redirect '/'
			end
		end
		
		
	

		helpers do       
		    def current_user
		      @current_user ||= User.first(:email => session[:user]) if session[:user]
		    end
		    def h(text)
			    Rack::Utils.escape_html(text)
			end
			def generate_password(size = 6)
			  charset = %w{ 2 3 4 6 7 9 A C D E F G H J K M N P Q R T V W X Y Z}
			  (0...size).map{ charset.to_a[rand(charset.size)] }.join
			end
			def hash_pass(password)
				return Digest::MD5.hexdigest(password)
			end
			def current_message
				if flash.has?(:notice) then return flash[:notice]
				elsif flash.has?(:error) then return flash[:error] end
			end
			def valid_key?
		      params[:key] == 'cashpu'
		    end
		end
	end
end