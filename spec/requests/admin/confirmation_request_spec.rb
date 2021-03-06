require "rails_helper"

RSpec.describe "confirmation request spec",:admin_confirmation => true, :type => :request do 

	before(:example) do 
		ActionController::Base.allow_forgery_protection = false
      	Admin.delete_all
      	Auth::Client.delete_all
      	@u = Admin.new(attributes_for(:admin))
      	@u.save
      	##HERE THE USER IS NOT CONFIRMED, SO THE CLIENT IS NOT CREATED IN THE AFTER_sAVE BLOCK.
      	##AS A RESULT WE MANUALLY CREATE A CLIENT.
      	##WE USE THIS SAME CLIENT FOR THE API_KEY AND REDIRECT_URL.
      	##NORMALLY THIS WOULD BE A CLIENT OF ANOTHER USER, ENTIRELY.
      	@c = Auth::Client.new(:resource_id => @u.id)
        @c.api_key = "test"
      	@c.redirect_urls = ["http://www.google.com"]
      	@c.app_ids << "test_app_id"
      	@c.versioned_create
      	@ap_key = @c.api_key	
    end

	after(:example) do 
		Admin.delete_all
      	Auth::Client.delete_all
	end

	context "-- web app requests" do 

		before(:example) do 

			ActionController::Base.allow_forgery_protection = false

		end

		context "-- no api key" do 

			it "-- get request is successfull" do 
				
				get new_admin_confirmation_path,{}
				expect(response.code).to eq("200")		
			end

			it "-- create request is successfull" do				
				prev_msg_count = ActionMailer::Base.deliveries.size
				post admin_confirmation_path,{admin:{email: @u.email}}
				expect(response.code).to eq("302")
				message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("confirmation_token")+"confirmation_token".length+1
    			confirmation_token = message[rpt_index...message.index("\"", rpt_index)]
    			new_msg_count = ActionMailer::Base.deliveries.size
    			expect(confirmation_token).not_to be(nil)
    			expect(new_msg_count - prev_msg_count).to eq(1)
			end

			it "-- show request is successfull" do 
				##should return redirect.
				message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("confirmation_token")+"confirmation_token".length+1
    			confirmation_token = message[rpt_index...message.index("\"", rpt_index)]
    			get admin_confirmation_path,{confirmation_token: confirmation_token}
    			@u.reload
    			expect(@u.confirmed_at).not_to be(nil)
    			
			end

		end

		context "-- valid api key + redirect url" do 
			

			it "-- get request, client created, but no redirection" do 
				get new_admin_confirmation_path, {redirect_url: "http://www.google.com", api_key: @ap_key, current_app_id: @c.app_ids[0]}
				expect(response.code).to eq("200")	

			end

			it "-- create request, client created, but no redirection" do 
				prev_msg_count = ActionMailer::Base.deliveries.size
				post admin_confirmation_path,{admin:{email: @u.email},redirect_url: "http://www.google.com", api_key: @ap_key, current_app_id: @c.app_ids[0]}
				
				expect(session[:client]).not_to be_nil
				expect(session[:redirect_url]).not_to be_nil
				expect(response.location=~/google/).to be_nil
				expect(response.code).to eq("302")
				message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("confirmation_token")+"confirmation_token".length+1
    			confirmation_token = message[rpt_index...message.index("\"", rpt_index)]
    			new_msg_count = ActionMailer::Base.deliveries.size
    			expect(confirmation_token).not_to be(nil)
    			expect(new_msg_count - prev_msg_count).to eq(1)
    			expect(response).not_to redirect_to("http://www.google.com?authentication_token=#{@u.authentication_token}&es=#{@u.client_authentication[@c.app_ids[0]]}")
			end

			##redirection on show action is tested in the feature specs.
			##what that does is first visits the sign in page with a redirect url and api key, then goes to sign up, then signs up, then visits the confirmation_url page and is successfully redirected to the redirect url with the correct authentication_token and es.

		end

	end

	context "-- json requests " do 
		before(:all) do 
			@headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
		end
		context "-- no api key" do 

			it "-- get request returns 406" do 
				get new_admin_confirmation_path,nil,@headers
        		expect(response.code).to eq("406")
			end

			it "-- create request returns not authenticated" do 
				post admin_confirmation_path,{admin:{email: @u.email}}.to_json,@headers
				expect(response.code).to eq("401")
			end

			it "-- show request returns not authenticated" do 
				get admin_confirmation_path,{confirmation_token: "dog"}.to_json,@headers
				expect(response.code).to eq("401")
			end

		end


		context "-- valid api key" do 


			it "-- get request returns 406" do 
				get new_admin_confirmation_path,{api_key: @ap_key,:current_app_id => "test_app_id"}.to_json,@headers
        		expect(response.code).to eq("406")
			end

			it "-- create request works" do 
				prev_msg_count = ActionMailer::Base.deliveries.size
				

				post admin_confirmation_path,{admin:{email: @u.email}, api_key: @ap_key,:current_app_id => "test_app_id"}.to_json,@headers
				
				message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("confirmation_token")+"confirmation_token".length+1
    			confirmation_token = message[rpt_index...message.index("\"", rpt_index)]
    			new_msg_count = ActionMailer::Base.deliveries.size
    			expect(confirmation_token).not_to be(nil)
    			expect(new_msg_count - prev_msg_count).to eq(1)
    			expect(response.code).to eq("201")

			end

			it "-- show request works --" do 
				message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("confirmation_token")+"confirmation_token".length+1
    			confirmation_token = message[rpt_index...message.index("\"", rpt_index)]
    			get admin_confirmation_path,{confirmation_token: confirmation_token, api_key: @ap_key, :current_app_id => "test_app_id"}, @headers
    			@u.reload
    			expect(@u.confirmed_at).not_to be(nil)
    			expect(response.code).to eq("201")
			end

		end

	end

end
