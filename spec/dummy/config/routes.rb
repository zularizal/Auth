Rails.application.routes.default_url_options[:host] = 'localhost:3000'
Rails.application.routes.draw do

  resources :worms
  resources :tests
  resources :topics
  
  
  get 'get_activities' , :action => "get_activities", :controller => "activity"

  get 'send_notification', :action => "send_notification", :controller => "home", :as => "send_notification"

  

  root "home#index"
  
  mount_routes Auth.configuration.auth_resources
    

  ##PAYUMONEY CALLBACK ROUTE
  post 'shopping/payments/:id', to: 'shopping/payments#update', as: "payumoney_payment_gateway_callback_path"  

  post 'sms_webhook', to: 'webhooks#sms_webhook'

  post 'email_webhook', to: 'webhooks#email_webhook'

  ##app-specific routes 
  namespace :api do 

    namespace :v1 do 

      post "user_info" => 'token_auth#index'

    end

  end

 
end