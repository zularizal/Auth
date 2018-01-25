module Auth::Shopping::Payments::PaymentsHelper

	## get /new
	def new_payment_path
      main_app.send(Auth::OmniAuth::Path.new_path(Auth.configuration.payment_class))
    end

    ## (PUT/PATCH/GET) - individual payment
    def payment_path(payment)
    	
    	main_app.send(Auth::OmniAuth::Path.show_or_update_or_delete_path(Auth.configuration.payment_class),payment)
    end

	
	##/payments (GET - all payments /CREATE - individual payment) 
	def payments_path
    	main_app.send(Auth::OmniAuth::Path.create_or_index_path(Auth.configuration.payment_class))
    end

    ##/shopping/payments/:id/edit
    def edit_payment_path(payment)
    	main_app.send(Auth::OmniAuth::Path.edit_path(Auth.configuration.payment_class),payment)
    end

end