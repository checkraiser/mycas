require 'data_mapper'

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'postgres://casuser:123456@10.1.0.195:5433/casauth2')

class User
	include DataMapper::Resource

	#attr_accessor :password, :password_confirmation

	property :id, Serial
	property :email, String,     :required => true, :unique => true
	
	property :created_at, DateTime 
	property :status, Integer	
	property :password, Text
	#property :password_hash,  Text  
   # property :password_salt,  Text    
   # validates_presence_of         :password
   # validates_confirmation_of     :password
   # validates_length_of           :password, :min => 6

    belongs_to :role	    
    has n, :activations
end
class Activation
	include DataMapper::Resource
	property :id, Serial
	property :token, String
	property :created_at, DateTime	
	property :description, Text
	property :status, Integer

	belongs_to :user 
end
class Profile
	include DataMapper::Resource
	property :id, Serial
	property :hovaten, String
	property :gioitinh, String
	property :ngaysinh, Date
	property :diachi, Text
	property :noicongtac, String	
	property :chucvu, String
	property :diachicongtac, Text
	property :email, String
	property :dienthoai, String
	belongs_to :user, :required => false
end
class Student
	include DataMapper::Resource
	property :id, Serial
	property :masinhvien, String
	property :lop, String
	property :hovaten, String
	property :gioitinh, String
	property :ngaysinh, Date
	property :tenkhoahoc, String
	property :tenhedaotao, String
	property :manganh, String
	property :tennganh, String
	property :trangthai, Integer
	property :email, String
	belongs_to :user, :required => false
end
class Teacher
	include DataMapper::Resource
	property :id, Serial
	property :magiaovien, String
	property :email, String	
	belongs_to :user, :required => false
end


class Role
	include DataMapper::Resource
	property :id, Serial
	property :name, String	
	property :description, Text

	has n, :users
	has n, :services, :through => Resource
end

class Service
	include DataMapper::Resource
	property :id, Serial
	property :name, String
	property :url, String
	property :description, Text

	has n, :roles, :through => Resource	
end
DataMapper.finalize
DataMapper::Model.raise_on_save_failure = true 

#DataMapper.auto_migrate!
