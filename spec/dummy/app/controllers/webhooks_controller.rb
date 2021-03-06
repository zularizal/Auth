class WebhooksController < Auth::WebhooksController
	def sms_webhook 
		## send to a background job in the respective module.
		OtpJob.perform_later([nil,nil,"sms_webhook",JSON.generate(params)])
		render :nothing => true, :status => 200
	end

	def email_webhook
		## send to a background job in the respective module.
		OtpJob.perform_later([nil,nil,"email_webhook",JSON.generate(params)])
		render :nothing => true, :status => 200
	end
end