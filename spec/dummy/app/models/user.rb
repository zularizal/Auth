class User
  include Mongoid::Document
  include Auth::Concerns::UserConcern
  include Auth::Concerns::SmsOtpConcern
  include Auth::TwoFactorOtp

  field :name, type: String
  field :dog, type: String

  
  ##FUNCTION OVERRIDEN FROM THE USER CONCERN TO FORMAT AND PARSE THE ADDITIONAL_LOGIN_PARAM.
  ##here we are processing it assuming it is a mobile number
  ##the regex is the same one used on the javascript side as well.
  def additional_login_param_format
  	if !additional_login_param.blank?
  		if !additional_login_param =~/^([0]\+[0-9]{1,5})?([7-9][0-9]{9})$/
  			errors.add(:additional_login_param,"please enter a valid mobile number")
  		end
  	end
  end 

  ################
  ##
  ## OVERRIDE SMS OTP METHODS
  ## auth/app/models/auth/concerns/sms_otp_concern.rb
  ## 
  ################
  def send_sms_otp
    ##The super tap just sets the additional_param_confirmed
    ##to 0 i.e unconfirmed.
      #puts "sending sms otp"
      auth_gen(self.id,self.additional_login_param)
    
  end

  def verify_sms_otp(user_provided_otp)
    
      verify(self.class,self.id,user_provided_otp)
    
  end

  ##############
  ##
  ##
  ## END OVERRIDE.
  ##
  ###############

end
