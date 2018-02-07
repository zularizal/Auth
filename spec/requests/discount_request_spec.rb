require "rails_helper"

RSpec.describe "discount request spec",:discount => true,:shopping => true, :type => :request do 

	before(:all) do 
        ActionController::Base.allow_forgery_protection = false
        User.delete_all
        Auth::Client.delete_all
        
        Shopping::CartItem.delete_all
        Shopping::Product.delete_all
        
        @u = User.new(attributes_for(:user_confirmed))
        @u.save

        @u2 = User.new(attributes_for(:user_confirmed))
        @u.save

        ## THIS PRODUCT IS USED IN THE CART_ITEM FACTORY, TO PROVIDE AND ID.
        @product = Shopping::Product.new(:name => "test product", :price => 10.00)
       
        @product.save


        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["test_app_id"])
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @u.client_authentication["test_app_id"] = "test_es_token"
        @u.save
        @u2.client_authentication["test_app_id"] = "test_es_token2"
        @u2.save
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
        

        @u2_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u2.authentication_token, "X-User-Es" => @u2.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
        
        ### CREATE ONE ADMIN USER

        ### It will use the same client as the user.
        @admin = Admin.new(attributes_for(:admin_confirmed))
        @admin.client_authentication["test_app_id"] = "test_es_token"
        @admin.save
        @admin_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-Admin-Token" => @admin.authentication_token, "X-Admin-Es" => @admin.client_authentication["test_app_id"], "X-Admin-Aid" => "test_app_id"}
        
    end

	context " -- json requests -- " do 
		before(:example) do 
			Shopping::CartItem.delete_all
			Shopping::Cart.delete_all
			Shopping::Payment.delete_all
			Shopping::Discount.delete_all
		end
		context " -- with proxy -- " do 

			context " -- normal flow -- " do 

				it " -- user creates a discount coupon, after successfull payment -- " do 

					cart_items = create_cart_items(@u)
					
					cart = create_cart(@u)
					
					add_cart_items_to_cart(cart_items,cart,@u)
					
					payment = create_payment(cart,50,@u)
					
					authorize_payment_as_admin(payment,@admin)

					discount = build_discount_for_request(cart)
					
					post shopping_discounts_path,{discount: discount,:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers

					expect(response.code).to eq("201")
					expect(Shopping::Discount.count).to eq(1)

				end

				it " -- signed out user can view the discount coupon -- ", :view_discount => true do 

					cart_items = create_cart_items(@u)
					
					cart = create_cart(@u)
					
					add_cart_items_to_cart(cart_items,cart,@u)
					
					payment = create_payment(cart,50,@u)
					
					authorize_payment_as_admin(payment,@admin)					
					discount = create_discount(cart,@u)

					get shopping_discount_path({:id => discount.id.to_s}),{:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}					

					discount_obj = JSON.parse(response.body)

					expect(discount_obj["discount_amount"]).to eq(discount.discount_amount)

				end

				it " -- signed in user can create cart items from the coupon -- " do 

					cart_items = create_cart_items(@u)
					
					cart = create_cart(@u)
					
					add_cart_items_to_cart(cart_items,cart,@u)
					
					payment = create_payment(cart,50,@u)
					
					authorize_payment_as_admin(payment,@admin)					
					discount = create_discount(cart,@u)

					post create_multiple_shopping_cart_items_path, {:id => discount.id.to_s, discount: { :product_ids => discount.product_ids},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @u2_headers

					expect(response.code).to eq("200")
					expect(Shopping::CartItem.count).to eq(10)

				end

				it " -- signed in user can create a cart from those cart items -- " do 

=begin
					cart_items = create_cart_items(@u)
					
					cart = create_cart(@u)
					
					add_cart_items_to_cart(cart_items,cart,@u)
					
					payment = create_payment(cart,50,@u)
					
					authorize_payment_as_admin(payment,@admin)					
					discount = create_discount(cart,@u)

					multiple_created_cart_items = create_multiple_cart_items(discount,@u2)

					post shopping_carts_path,{cart: {add_cart_item_ids: multiple_created_cart_items.map{|c| c = c.id.to_s}},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @u2_headers

					expect(response.code).to eq("201")
=end

				end


				it " -- signed in user, is shown option to pay for cart with coupon -- " do 

				end

				it " -- he gets a notification that his request is pending -- " do 

				end

				it " -- coupon creator an verify the payment -- " do 

				end

				it " -- payment creator gets a notification that his payment has been sent for verification -- " do 

				end

				it " -- payment creator can verify and view the that his payment is now verified -- " do 

				end

			end

=begin
			context " -- discount creation not permitted if -- " do 

				it " -- cannot create discount unless minimum payable amount is satsifeid for cart -- " do 

				end

				it " -- cannot create discount if payment is unsuccessfull/pending, using that payment -- " do 

				end

			end
=end
=begin
			context " -- when base payment becomes unsuccessfull"

				it " -- cancels all related discounts -- " do 

				end

			end
=end
=begin
			context " -- delete -- " do 
				it " -- discount once created cannot be deleted -- " do 

				end
			end
=end
=begin
			context " -- discount and refund -- " do 
				it " -- refund amount does not include discount payments -- " do 

				end
			end
=end
		end	

	end


end