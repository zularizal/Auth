require 'rails_helper'


RSpec.describe Auth::System::Wrapper, type: :model, :wrapper_model => true do
  	

	context " -- basic functions -- " do 
		
		before(:all) do 

			User.delete_all

			## create one non admin user
			@u = User.new(attributes_for(:user_confirmed))
	        @u.save
	        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
	        @c.redirect_urls = ["http://www.google.com"]
	        @c.versioned_create
	        @u.client_authentication["testappid"] = "testestoken"
	        @u.save
	        @ap_key = @c.api_key
	        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["testappid"], "X-User-Aid" => "testappid"}

			## create one admin user.
			@admin = User.new(attributes_for(:admin_confirmed))
	        @admin.admin = true
	        @admin.client_authentication["testappid"] = "testestoken2"
	        @admin.save
	        @admin_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @admin.authentication_token, "X-User-Es" => @admin.client_authentication["testappid"], "X-User-Aid" => "testappid"}
			
		end

		before(:example) do 
			Auth::System::Wrapper.delete_all
			Auth.configuration.product_class.constantize.delete_all
			Auth.configuration.cart_item_class.constantize.delete_all
		end


		context " -- load from json -- " do 

			it " -- loads wrapper from json file -- " do 

				response = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/1.json")
				wrapper = response[:wrapper]
				expect(wrapper.address).to be_nil
				wrapper.levels.each_with_index {|l,lindex|
					expect(l.address).to eq("l#{lindex}")
					l.branches.each_with_index{|b,bindex|
						expect(b.address).to eq(l.address + ":b#{bindex}")
						b.definitions.each_with_index{|d,dindex|
							expect(d.address).to eq(b.address + ":d#{dindex}")
							d.units.each_with_index{|u,uindex|
								expect(u.address).to eq(d.address + ":u#{uindex}")
							}
						}
					}
				}
				
			end



		end

		context " -- adding of cart items -- " do 

			context " -- locates brance, defintion and creation -- " do 

				context " -- address provided -- " do 

				end

				context " -- address not provided -- " do 

					it  " -- wrapper adds cart_items to applicable branches. -- " do 

						response = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/2.json")
						wrapper = response[:wrapper]
						cart_items = response[:cart_items]
						products = response[:products]
						wrapper.add_cart_items(cart_items.map{|c| c = c.id.to_s})
						expect(wrapper.levels[0].branches[0].input_object_ids.size).to eq(2)
						
					end


					it " -- wrapper raises branch not found error, if a branch could not be found for a cart item -- " do 

												
					end
					
					it " -- branch input objects are added to definitions based on group key -- " do 

						response = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/3.json")
						wrapper = response[:wrapper]
						cart_items = response[:cart_items]
						products = response[:products]
						wrapper.add_cart_items(cart_items.map{|c| c = c.id.to_s})
						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.add_cart_items
							end
						end
						expect(wrapper.levels[0].branches[0].definitions[0].input_object_ids.size).to eq(2)
					end

					it " -- raises no definition satisfied if no definition can be found for all the cart items -- " do 


					end


				end

			end

		end

		context " -- schedule -- " do 

			context " -- multiple units in individual input object id elements -- " do 

				context " -- no previous query results -- " do 
					
					it " -- adds a wildcard entry into the intersection results. -- ", :wildcard => true do 	

						response = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/3.json")
						
						wrapper = response[:wrapper]
						
						cart_items = response[:cart_items]
						
						products = response[:products]
						
						wrapper.add_cart_items(cart_items.map{|c| c = c.id.to_s})

						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.add_cart_items
							end
						end
						
						expect(wrapper.levels[0].branches[0].definitions[0].input_object_ids.size).to eq(2)

						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.do_schedule_queries
							end
						end

						expect(wrapper.levels[0].branches[0].definitions[0].intersection_results[0]).to eq([{:minute=>"*", :locations=>["*"]}])

					end


					it " -- checks time specified in the cart_item for congruence with time specifications, and sets a common time specification for the query -- " do 

						## so each cart item will have a certain start time mentioned on it.
						## so this becomes the fallback for the set_time_specifications function.

					end

					it " -- checks location specified in the cart_item for congruence with locations specifications, and sets a common location specification for the query -- " do 


					end

				end

			end

		end

	end

end