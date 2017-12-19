require "rails_helper"

RSpec.describe "payment request spec",:payment => true, :shopping => true, :type => :request do 

	before(:all) do 
        ActionController::Base.allow_forgery_protection = false
        User.delete_all
        Auth::Client.delete_all
        @u = User.new(attributes_for(:user_confirmed))
        @u.save

        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["test_app_id"])
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @u.client_authentication["test_app_id"] = "test_es_token"
        @u.save
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
        
        
        ### CREATE ONE ADMIN USER

        ### It will use the same client as the user.
        @admin = Admin.new(attributes_for(:admin_confirmed))
        @admin.client_authentication["test_app_id"] = "test_es_token"
        @admin.save
        @admin_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-Admin-Token" => @admin.authentication_token, "X-Admin-Es" => @admin.client_authentication["test_app_id"], "X-Admin-Aid" => "test_app_id"}

    end


    context " -- cash, card, cheque payment -- " do 

        before(:example) do 
            Shopping::CartItem.delete_all
            Shopping::Cart.delete_all
            Shopping::Payment.delete_all
            @created_cart_item_ids = []
            @cart = Shopping::Cart.new
            @cart.resource_id = @u.id.to_s
            @cart.resource_class = @u.class.name
            @cart.save

            5.times do 
                cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
                cart_item.resource_id = @u.id.to_s
                cart_item.resource_class = @u.class.name
                cart_item.parent_id = @cart.id
                cart_item.price = 10.00
                cart_item.save
                @created_cart_item_ids << cart_item.id.to_s
            end
           
        end

        after(:example) do 
            Shopping::CartItem.delete_all
            Shopping::Cart.delete_all
            Shopping::Payment.delete_all
        end


        it " -- creates a payment to the cart-- " do 
            
            post shopping_payments_path, {cart_id: @cart.id.to_s,payment_type: "cash", amount: 10, :api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
                    
            expect(Shopping::Payment.count).to eq(1)
        
        end

        it " -- sets all cart items as accepted, if payment amount is sufficient for all the cart items. " do 
            post shopping_payments_path, {cart_id: @cart.id.to_s,payment_type: "cash", amount: 50.00, :api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
                    
            expect(Shopping::Payment.count).to eq(1)
            
            @created_cart_item_ids.each do |id|
                cart_item = Shopping::CartItem.find(id)
                expect(cart_item.accepted).to be_truthy
            end


        end


        ## payment goes from success to failure.
        ## in that case cart items should become unpaid.
        it " -- if payment status is set as false, cart item statuses are also updated -- " do 
            

        end

        it " -- mix and play : payments made, then cart item removed, then refund request made, then earlier payment fails, now what happens to the other cart items -- " do 

        end

    end


    context " -- gateway payment -- " do 

    end


    context " -- payment made to empty cart -- " do 

    end

    ## note also need to check this in case of cart controller, when we add or remove cart items.
    ## set cart item accepted specs.
    context " -- transactional issues in multiple cart items being marked as accepted -- " do 

        before(:example) do 

            Shopping::CartItem.delete_all
            Shopping::Cart.delete_all
            Shopping::Payment.delete_all
            @created_cart_item_ids = []
            @cart = Shopping::Cart.new
            @cart.resource_id = @u.id.to_s
            @cart.resource_class = @u.class.name
            @cart.save

            5.times do 
                cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
                cart_item.resource_id = @u.id.to_s
                cart_item.resource_class = @u.class.name
                cart_item.parent_id = @cart.id
                cart_item.price = 10.00
                cart_item.save
                @created_cart_item_ids << cart_item.id.to_s
            end

           
            allow_any_instance_of(Shopping::CartItem).to receive(:set_accepted).and_return(false)
  

        end

        after(:example) do 
            Shopping::CartItem.delete_all
            Shopping::Cart.delete_all
            Shopping::Payment.delete_all

            
                        
        end

        it " -- shows a validation error if, all cart items cannot be successfully updated ", :cart_item_update_payment_failure do 

            ## so how to simulate this?
            ## override set_accepted method in payment_concern to return false.
            

            post shopping_payments_path, {cart_id: @cart.id.to_s,payment_type: "cash", amount: 50, :api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers

            payment = assigns(:payment)
            expect(payment.errors.full_messages).not_to be_empty
        end

    end
 
    context " -- payment receipt -- " do 
        it " -- generates receipt after payment is saved -- " do 

            ## proposed plan for successfull payment.
            ## cart should prepare cart
            ## it should also show the receipt of the latest payment.
            ## so basically a hash with two keys should be generated
            ## cart => {with all its attributes}
            ## curr_payment => {with cart item ids, that it has paid for.}

        end
    end

    context " -- refund -- ", :refund => true do 
        
        before(:example) do 

        	Shopping::CartItem.delete_all
            Shopping::Cart.delete_all
            Shopping::Payment.delete_all

            ## create a cart
            @cart = Shopping::Cart.new
            @cart.resource_id = @u.id.to_s
            @cart.resource_class = @u.class.name
            @cart.save


            ## create five cart items and add them to the cart.
            @created_cart_item_ids = []
            5.times do 
                cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
                cart_item.resource_id = @u.id.to_s
                cart_item.resource_class = @u.class.name
                cart_item.parent_id = @cart.id
                cart_item.price = 10.00
                cart_item.save
                @created_cart_item_ids << cart_item.id.to_s
            end

            ## create a payment to the cart
            payment = Shopping::Payment.new
            payment.payment_type = "cash"
            payment.amount = 50.00
            payment.resource_id = @u.id.to_s
            payment.resource_class = @u.class.name.to_s
            payment.cart_id = @cart.id.to_s
            ps = payment.save
            @cart.prepare_cart

        end

        after(:example) do 
            Shopping::CartItem.delete_all
            Shopping::Cart.delete_all
            Shopping::Payment.delete_all
        end


        it " -- creates a refund request if the cart pending balance is negative. -- " do 

            
            expect(@cart.cart_pending_balance).to eq(0.00)


            ## now basically remove a cart item from the cart.
            last_cart_item = Shopping::CartItem.find(@created_cart_item_ids.last.to_s)
            last_cart_item.unset_cart

            ## now the pending balance should be -ve
            @cart.prepare_cart
            expect(@cart.cart_pending_balance).to eq(-10.00)


            ## so basically here we are just creating a refund request.
            ## basically here it doesn't matter what payment type and amount is used.
            post shopping_payments_path, {cart_id: @cart.id.to_s,payment_type: "cash", refund: true, amount: 10, :api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers        
            puts response.body.to_s
            expect(response.code).to eq("201")
            
            ## now basically the idea is that when the refund is set as approved, it has to check 

        end

        it " -- does not create a refund request if the cart pending balance is positive or zero -- " do 

            ## add an item to the cart.
            cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
            cart_item.resource_id = @u.id.to_s
            cart_item.resource_class = @u.class.name
            cart_item.parent_id = @cart.id
            cart_item.price = 10.00
            cart_item.save            

            ## prepare the cart again.
            @cart.prepare_cart
            expect(@cart.cart_pending_balance).to eq(10.00)

            ## now try to create a refund request, and it should fail

            post shopping_payments_path, {cart_id: @cart.id.to_s,payment_type: "cash", refund: true, amount: 10, :api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers        
            
            expect(response.code).to eq("422")


        end


        it " -- accepts a valid refund if the user is an administrator -- " do 

        	last_cart_item = Shopping::CartItem.find(@created_cart_item_ids.last.to_s)
            last_cart_item.unset_cart

            ## create a new refund request and set it as pending.
            payment = Shopping::Payment.new
            
            ## this doesn't matter while creating refunds.
            payment.payment_type = "cheque"
            
            ## this also doesnt matter while creating refunds.
            payment.amount = 50.00
            payment.refund = true
            payment.resource_id = @u.id.to_s
            payment.resource_class = @u.class.name.to_s
            payment.cart_id = @cart.id.to_s
            
            ## need to assign this because we are bypassing the controller.
            payment.signed_in_resource = @u
            ps = payment.save
            
            ##now first assert that a refund exists whose refund status is null.
            payment = Shopping::Payment.find(payment.id.to_s)
            expect(payment.payment_status).to eq(nil)

            ## now use the admin user to create a put request to the above payment.

            ## it should set the status of the payment as accepted.

            put shopping_payment_path({:id => payment.id}), {payment: {payment_status: 1},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @admin_headers
          
            
            payment = Shopping::Payment.find(payment.id)

            expect(payment.payment_status).to eq(1)

        end
	

        it " -- before accepting a refund as an administrator it checks that there is negative pending balance -- ", :problematic => true do 

            ## remove an item from the cart.
            last_cart_item = Shopping::CartItem.find(@created_cart_item_ids.last.to_s)
            last_cart_item.unset_cart

            ## create a new refund request and set it as pending.
            payment = Shopping::Payment.new
            
            ## this doesn't matter while creating refunds.
            payment.payment_type = "cheque"
            
            ## this also doesnt matter while creating refunds.
            payment.amount = 50.00
            payment.refund = true
            payment.resource_id = @u.id.to_s
            payment.resource_class = @u.class.name.to_s
            payment.cart_id = @cart.id.to_s
            
            ## need to assign this because we are bypassing the controller.
            payment.signed_in_resource = @u
            ps = payment.save
            
            ##now first assert that a refund exists whose refund status is null.
            payment = Shopping::Payment.find(payment.id.to_s)
            expect(payment.payment_status).to eq(nil)

            ## at this stage, check the cart and expect it to have a negative balance : i.e the user deserves a refund.
            @cart = Shopping::Cart.find(@cart.id)
            @cart.prepare_cart
            expect(@cart.cart_pending_balance < 0).to be(true)


            ## now again add another item to the cart so that the balance is no longer negative.
            cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
            cart_item.resource_id = @u.id.to_s
            cart_item.resource_class = @u.class.name
            cart_item.parent_id = @cart.id
            cart_item.price = 10.00
            cart_item.save            


            ## now use the admin user to create a put request to the above payment.

            ## it should set the payment status as 0 or failed, because balance is now negative.

            put shopping_payment_path({:id => payment.id}), {payment: {payment_status: 1},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @admin_headers
          
            
            payment = Shopping::Payment.find(payment.id)

            expect(payment.payment_status).to eq(0)


        end


        it " -- after accepting a refund as an administrator, will update all pending refunds as failed" do 


            ## remove an item from the cart.
            last_cart_item = Shopping::CartItem.find(@created_cart_item_ids.last.to_s)
            last_cart_item.unset_cart


            ## now we create three refunds
            refunds_expected_to_have_failed = []
            3.times do 
                payment = Shopping::Payment.new
                payment.payment_type = "cheque"
                payment.amount = 50.00
                payment.refund = true
                payment.resource_id = @u.id.to_s
                payment.resource_class = @u.class.name.to_s
                payment.cart_id = @cart.id.to_s
                payment.signed_in_resource = @u
                ps = payment.save
                refunds_expected_to_have_failed << payment
            end


            ## then we accept the last one, by sending in a put request as the admin.
            put shopping_payment_path({:id => refunds_expected_to_have_failed.last.id}), {payment: {payment_status: 1},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @admin_headers


            ## we only keep the first two because the last one will not be deleted, we are going to be accepting the last one. 
            refunds_expected_to_have_failed.map!{|c| c = c.id.to_s}
            refunds_expected_to_have_failed.pop
            ## all previous payments should be marked as successfull.
            ## for this an after update callback can be added?
            ## but then that will be 
            refunds_expected_to_have_failed.each do |ref_id|
                expect(Shopping::Payment.find(ref_id).payment_status).to eq(0)
            end

        end

            
        it " -- attempting to 'show' a refund, if a subsequent refund was accepted, then will redirect to update this refund as failed -- ", :only_failure => true do 

            ## remove an item from the cart.
            last_cart_item = Shopping::CartItem.find(@created_cart_item_ids.last.to_s)
            last_cart_item.unset_cart


            ## now we create three refunds
            refunds_expected_to_have_failed = []
            3.times do 
                payment = Shopping::Payment.new
                payment.payment_type = "cheque"
                payment.amount = 50.00
                payment.refund = true
                payment.resource_id = @u.id.to_s
                payment.resource_class = @u.class.name.to_s
                payment.cart_id = @cart.id.to_s
                payment.signed_in_resource = @u
                ps = payment.save
                refunds_expected_to_have_failed << payment
            end

            ## sleep so that there is some time lag between creating the refunds and updating the last one as a success.
            sleep(2)
            

            ## update the last refund as successfull. 
            successfull_refund = refunds_expected_to_have_failed.pop 
            
            successfull_refund.refund_success
          
            res1 = successfull_refund.save
          
           

            ## convert the remaining two refunds into their ids.
            refunds_expected_to_have_failed.map!{|c| c = c.id.to_s}
            
            ## now update the last one as nil, i.e we simulate that somehow it didnt get converted to a failure payment status when the successfull refund was accepted.
            last_refund = Shopping::Payment.find(refunds_expected_to_have_failed.last)
            last_refund.payment_status = nil
            last_refund.skip_callbacks = {:before_save => true, :after_save => true}
            res = last_refund.save
          
            ## now do update on this last refund, so that it will call refund_refresh, and we now expect it to have a 0 payment status.
            put shopping_payment_path({:id => last_refund.id}), {:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers

            last_refund = Shopping::Payment.find(last_refund.id.to_s)

            expect(last_refund.payment_status).to eq(0)

        end
        
        ## expected behavior should play out as follows:
        ## so on removing a cart item, will the cart item states for the rest of the stuff be affected?
        ## no -> because that is affected only if the payment status of a payment changes.
        ## since at that stage
        it " -- how does refund affect cart_item_accepted -- " do 

        end


    end

    context " --- update, delete, payment and refund by user -- " do 

        before(:example) do 
            Shopping::CartItem.delete_all
            Shopping::Cart.delete_all
            Shopping::Payment.delete_all

            ## create a cart
            @cart = Shopping::Cart.new
            @cart.resource_id = @u.id.to_s
            @cart.resource_class = @u.class.name
            @cart.save


            ## create five cart items and add them to the cart.
            @created_cart_item_ids = []
            5.times do 
                cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
                cart_item.resource_id = @u.id.to_s
                cart_item.resource_class = @u.class.name
                cart_item.parent_id = @cart.id
                cart_item.price = 10.00
                cart_item.save
                @created_cart_item_ids << cart_item.id.to_s
            end
        end



        it " -- user cannot update a payment once made -- ", :update_payment => true do 

            ## create a payment.
            payment = Shopping::Payment.new
            payment.payment_type = "cash"
            payment.amount = 50.00
            payment.resource_id = @u.id.to_s
            payment.resource_class = @u.class.name.to_s
            payment.cart_id = @cart.id.to_s
            ps = payment.save


            ## now try to update it.
            put shopping_payment_path({:id => payment.id}), {payment: {amount: 10.00},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers

            payment = Shopping::Payment.find(payment.id.to_s)
            expect(payment.amount).to eq(50.00)



        end 

        it " -- user cannot update a refund once created -- ", :update_refund => true do 

            ## create a payment.
            payment = Shopping::Payment.new
            payment.payment_type = "cash"
            payment.amount = 50.00
            payment.resource_id = @u.id.to_s
            payment.resource_class = @u.class.name.to_s
            payment.cart_id = @cart.id.to_s
            ps = payment.save
            expect(ps).to be_truthy

            ## remove an item from the cart
            last_cart_item = Shopping::CartItem.find(@created_cart_item_ids.last.to_s)
            last_cart_item.unset_cart


            ## create a refund
            ref = Shopping::Payment.new
            ref.payment_type = "cash"
            ref.amount = 50.00
            ref.refund = true
            ref.resource_id = @u.id.to_s
            ref.resource_class = @u.class.name.to_s
            ref.signed_in_resource = @u
            ref.cart_id = @cart.id.to_s
            rs = ref.save
            expect(rs).to be_truthy

            ## now try to update it.
            put shopping_payment_path({:id => ref.id}), {payment: {refund: false},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers

            ref = Shopping::Payment.find(ref.id.to_s)
            expect(ref.refund).to be_truthy

        end

        it " -- user cannot delete a payment once made -- ", :delete_payment do 

            ## create a payment.
            payment = Shopping::Payment.new
            payment.payment_type = "cash"
            payment.amount = 50.00
            payment.resource_id = @u.id.to_s
            payment.resource_class = @u.class.name.to_s
            payment.cart_id = @cart.id.to_s
            ps = payment.save
            expect(ps).to be_truthy

            ## now try to update it.
            delete shopping_payment_path({:id => payment.id}),{:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers

            expect(Shopping::Payment.count).to eq(1)

        end

    end

end


=begin

-so basically it boils down to this->

-1. 
    before_remove - check if status is accepted, if yes, then 
    it cannot be removed, provide a hook to override this method as per the needs.

    - here only there is fork - that if removal fails, then provide:
    on_cannot_remove_item_hook

-2. 
    after_remove - this is not done automatically. He has to request a refund, by creating a refund request.

-3. provide a method to cancel all the tests in the cart, this is done by calling destroy cart - if call destroy cart, then where will we show the refund?
    - refund should also be shown in the cart.

    so you cannot destroy the cart if payments have already been made to it.
    you can only remove items from the cart, i.e all the items.
    and there you can show the refunds.

    so before destroy cart - check if payments have been made, and if yes, then don't destroy the cart.


-4. basically we have to make a payment to the user.
    thats the essence.
    so the payment should have a pay_to
    it will also have a type, this will be the same as the last payment made by the user.
    it will have to be done by the business seperately.
    notification behaviour has to be defined, for eg: 
    
    refund can be by cheque only at this stage. 
    the refund is successfull if the cheque is ready.

    After refund success, a callback has to notify the payee, that his cheque can be picked up,

    at this stage the acknowledgement proof can be picked up, saying that his payment was successfully received.
    
- 5. refund lifecycle.

    a. first the refund is created, by the user.
    b. before_creating the refund, check if the pending_balance is -ve, only then create the refund, otherwise not.
    c. refund now has a status of 0, i.e pending.
    d. before_updating refund, if the refund is being set as accepted, then it has to check if there is any negative balance and only then update it.
       while changing such a status, it has to set the amount of the refund, and also delete any other refund requests, created before now.

=end





