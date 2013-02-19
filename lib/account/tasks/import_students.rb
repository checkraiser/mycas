require 'savon'
require 'data_mapper'
require 'date'
require 'time'

require '../models'
#DataMapper.auto_migrate!
def runit()
	client = Savon::Client.new do |wsdl, http|
    wsdl.document = "http://10.1.0.238:8082/HPUWebService.asmx?wsdl"
    http.read_timeout = 7*24*3600
  end  
  

  response = client.request(:sinh_vien) ;    
  res_hash = response.body.to_hash if response and response.body;
  ls = res_hash[:sinh_vien_response][:sinh_vien_result][:diffgram][:document_element];   
  cc = 0
 # if (ls) then         
  #  ls[:sinh_vien].each do |item|      

  #  end
 # end
 	ls[:sinh_vien].each do |sv|
 		puts "processing " + sv[:ma_sinh_vien].strip
 		next if sinhvien = Student.first(:masinhvien => sv[:ma_sinh_vien].strip)
 		sinhvien = Student.new(:masinhvien => sv[:ma_sinh_vien].strip,
 			:lop => sv[:lop].kind_of?(String) ? sv[:lop].strip : '',
 			:hovaten => sv[:hodem].strip + ' ' + sv[:ten].strip,
 			:gioitinh => sv[:gioi_tinh] == true ? 1 : 0,
 			:ngaysinh => DateTime.parse(sv[:ngay_sinh].to_s),
 			:tenkhoahoc => sv[:ten_khoa_hoc].kind_of?(String) ? sv[:ten_khoa_hoc].strip : '',
 			:tenhedaotao => sv[:ten_he_dao_tao].kind_of?(String) ? sv[:ten_he_dao_tao].strip : '',
 			:manganh => sv[:ma_nganh].kind_of?(String) ? sv[:ma_nganh].strip : '',
 			:tennganh => sv[:ten_nganh].kind_of?(String) ? sv[:ten_nganh].strip : '',
 			:trangthai =>  sv[:trang_thai] )
 		if sinhvien.save 
 			puts "OK"
 		else
 			puts "error"
 		end
 	end
 	
end

runit()




