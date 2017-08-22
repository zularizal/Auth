module ActionDispatch::Routing
  class Mapper

  	##@param app_route_resources[Hash] -> 
  	##key:resource[String] -> the name of the resource for which omniauth routes are to be generated.
  	##value:opts[Hash] -> the options specifying the views, controllers etc for omniauth.
  	##expected to be present in the preinitializer in the routes of the target app.
	def mount_routes(app_route_resources)
	      
	  	  resources :clients, :controller => "auth/clients"
		  resources :profiles, :controller => "auth/users/profiles" do 
		  	collection do 
		  		get 'credential_exists'
		  	end
		  end
		  
		 if Auth.configuration.otp_controller
			 get "#{Auth.configuration.mount_path}/:resource/otp_verification_result", :action => "otp_verification_result", :controller => "#{Auth.configuration.otp_controller}", :as => "otp_verification_result"
			  get "#{Auth.configuration.mount_path}/:resource/verify_otp", :action => "verify_otp", :controller => "#{Auth.configuration.otp_controller}", :as => "verify_otp"
			  get "#{Auth.configuration.mount_path}/:resource/send_sms_otp", :action => "send_sms_otp", :controller => "#{Auth.configuration.otp_controller}", :as => "send_sms_otp"
			  get "#{Auth.configuration.mount_path}/:resource/resend_sms_otp", :action => "resend_sms_otp", :controller => "#{Auth.configuration.otp_controller}", :as => "resend_sms_otp"
		  end

		 ###CART ITEM ROUTES
		 if Auth.configuration.cart_item_controller
		 	 scope_path = "/"
		 	 as_prefix = nil
		 	 cart_items_collection = nil
		 	 Auth.configuration.cart_item_class.underscore.pluralize.scan(/(?<scope_path>.+?)\/(?<cart_items_collection>[A-Za-z_]+)$/) do |match|
		 	 		if Regexp.last_match[:scope_path]
		 	 			scope_path = scope_path +  Regexp.last_match[:scope_path]
		 	 			as_prefix = Regexp.last_match[:scope_path]
		 	 		end
		 	 		cart_items_collection = Regexp.last_match[:cart_items_collection]
		 	 end
		 	 if cart_items_collection
		 	 	scope :path => scope_path, :as => as_prefix do 
			    	resources cart_items_collection.to_sym, controller: "#{Auth.configuration.cart_item_controller}"
			    end
			 end
		 end

		 if Auth.configuration.transaction_controller
		 	scope_path = "/"
		 	 as_prefix = nil
		 	 transactions_collection = nil
		 	 Auth.configuration.transaction_class.underscore.pluralize.scan(/(?<scope_path>.+?)\/(?<transactions_collection>[A-Za-z_]+)$/) do |match|
		 	 		if Regexp.last_match[:scope_path]
		 	 			scope_path = scope_path +  Regexp.last_match[:scope_path]
		 	 			as_prefix = Regexp.last_match[:scope_path]
		 	 		end
		 	 		transactions_collection = Regexp.last_match[:transactions_collection]
		 	 end
		 	 if transactions_collection
		 	 	scope :path => scope_path, :as => as_prefix do 
			    	resources transactions_collection.to_sym, controller: "#{Auth.configuration.transaction_controller}"
			    end
			 end
		 end
		  
		  app_route_resources.each do |resource,opts| 

		  	  #puts "resource is : #{resource}"
		  	  #puts "opts are: #{opts}"
			  # ensure objects exist to simplify attr checks
			  opts[:controllers] ||= {}
			  opts[:skip]        ||= []
			  

			  # check for ctrl overrides, fall back to defaults
			  sessions_ctrl          = opts[:controllers][:sessions] || "auth/sessions"
			  registrations_ctrl     = opts[:controllers][:registrations] || "auth/registrations"
			  passwords_ctrl         = opts[:controllers][:passwords] || "auth/passwords"
			  confirmations_ctrl     = opts[:controllers][:confirmations] || "auth/confirmations"
			  omniauth_ctrl          = opts[:controllers][:omniauth_callbacks] || "auth/omniauth_callbacks"
			  unlocks_ctrl 			 = opts[:controllers][:unlocks] || "auth/unlocks"

			  # define devise controller mappings
			  controllers = {:sessions           => sessions_ctrl,
			                 :registrations      => registrations_ctrl,
			                 :passwords          => passwords_ctrl,
			                 :confirmations      => confirmations_ctrl,
			             	 :unlocks  			 => unlocks_ctrl
			             	}

			  # remove any unwanted devise modules
			  opts[:skip].each{|item| controllers.delete(item)}

			  resource_as_pluralized_string = Auth::OmniAuth::Path.resource_pluralized(resource)

			  devise_for resource_as_pluralized_string.to_sym,
			    :class_name  => resource,
			    :module      => :devise,
			    :path        => "#{Auth::OmniAuth::Path.resource_path(resource)}",
			    :controllers => controllers,
			    :skip        => opts[:skip] + [:omniauth_callbacks]


			  resource_class = Object.const_get resource
			
              #################################################################
              ##
              ## OMNIAUTH PATHS
              ##
              #################################################################

			  if !(opts[:skip].include? :omniauthable)

					resource_class.omniauth_providers.each do |provider|
						
						omniauth_request_path = Auth::OmniAuth::Path.omniauth_request_path(nil,provider)

						common_callback_path = Auth::OmniAuth::Path.common_callback_path(provider)

						if !Rails.application.routes.url_helpers.method_defined?("#{provider}_omniauth_authorize_path".to_sym)
							puts "calling route for provider: #{provider}"
							match "#{omniauth_request_path}", controller: omniauth_ctrl, action: "passthru", via: [:get,:post], as: "#{provider}_omniauth_authorize"
						end

						if !Rails.application.routes.url_helpers.method_defined?("#{provider}_omniauth_callback_path".to_sym)
							match "#{common_callback_path}", controller: omniauth_ctrl, action: "omni_common", via: [:get,:post], as: "#{provider}_omniauth_callback"
						end
					end

					oauth_failure_route_path = Auth::OmniAuth::Path.omniauth_failure_route_path(nil)

					if !Rails.application.routes.url_helpers.method_defined?("omniauth_failure_path".to_sym)

						match "#{oauth_failure_route_path}", controller: omniauth_ctrl, action: "failure", via:[:get,:post], as: "omniauth_failure"
					end
			  end

			  #################################################################
			  ##
			  ## RESOURCE_PROFILE PATHS
			  ##
			  #################################################################

			  #match "#{omniauth_request_path}", controller: omniauth_ctrl, action: "passthru", via: [:get,:post], as: "#{provider}_omniauth_authorize"

		  end
	  end
  end
end

