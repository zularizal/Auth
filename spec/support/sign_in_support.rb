#module for helping controller specs
module ValidUserHelper
  def signed_in_as_a_valid_user
    @user ||= FactoryGirl.create :user
    sign_in @user # method from devise:TestHelpers
  end

  def signed_in_as_a_valid_admin
    @admin ||= FactoryGirl.create :admin
    sign_in @admin
  end
end

# module for helping request specs
module ValidUserRequestHelper
  include Warden::Test::Helpers

  def self.included(base)
    base.before(:each) { Warden.test_mode! }
    base.after(:each) { Warden.test_reset! }
  end

  def sign_in(resource)
    login_as(resource, scope: warden_scope(resource))
  end

  def sign_out(resource)
    logout(warden_scope(resource))
  end

  private

  def warden_scope(resource)
    resource.class.name.underscore.to_sym
  end

  def sign_in_as_a_valid_admin
    @admin = FactoryGirl.create :admin
    cli = Auth::Client.new
    cli.current_app_id = "test_app_id"
    @admin.set_client_authentication(cli)
    @admin.save!
    post_via_redirect admin_session_path, 'admin[email]' => @admin.email, 'admin[password]' => @admin.password
  end

  def sign_in_as_a_valid_and_confirmed_admin
    @admin = Admin.new(attributes_for(:admin_confirmed))
    @admin.versioned_create
    sign_in(@admin)
  end
  
  

  def sign_in_as_a_valid_and_confirmed_user
    @user = User.new(attributes_for(:user_confirmed))
    @user.versioned_create
    sign_in(@user)
  end

end

module AdminRootPathSupport
  ##this needs to be done ,because after_sign_in_path_for has been changed for admin in the application_controller, to topics/new.
  def admin_after_sign_in_path
    app.routes.url_helpers.new_topic_url(:only_path => true)
  end
end

module DiscountSupport
  
  def create_cart_items(signed_in_res,user=nil,number=5,price=10.0)
    cart_items = []
    user ||= signed_in_res
    number.times do             
        cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
        cart_item.resource_id = user.id.to_s
        cart_item.resource_class = user.class.name
        cart_item.product_id = Shopping::Product.first.id.to_s
        cart_item.price = Shopping::Product.first.price
        cart_item.signed_in_resource = signed_in_res
        cart_items << cart_item if cart_item.save
        puts "cart item create errors."
        puts cart_item.errors.full_messages.to_s
    end
    return cart_items 
  end

  def create_cart(signed_in_res,user=nil)
    user ||= signed_in_res

    cart = Shopping::Cart.new
    cart.signed_in_resource = signed_in_res
    cart.resource_id = user.id.to_s
    cart.resource_class = user.class.name
    puts "result of creating cart."
    puts cart.save.to_s
    puts "cart create errors."
    puts cart.errors.full_messages.to_s
    return cart
  end

  def add_cart_items_to_cart(cart_items,cart,signed_in_res,user=nil)
    user ||= signed_in_res
    k = cart_items.map{|citem|
      citem.signed_in_resource = signed_in_res
      citem.parent_id = cart.id.to_s
      citem.save
    }.select{|c| c == false}.size == 0
    puts "result of adding cart items to cart"
    puts k.to_s
    k
  end

  def create_payment(cart,amount,signed_in_res,type="cash",user=nil)
    user ||= signed_in_res
    payment = Shopping::Payment.new
    payment.amount = amount
    payment.cart_id = cart.id.to_s
    payment.payment_type = type
    payment.signed_in_resource = signed_in_res
    payment.resource_id = user.id
    payment.resource_class = user.class.name
    d = payment.save
    puts "result of saving payemnt #{d.to_s}"
    puts payment.errors.full_messages.to_s
    payment
  end

  def authorize_payment_as_admin(payment,admin)
    payment.signed_in_resource = admin
    payment.payment_status = 1
    res = payment.save
    puts "Result of saving payment is: #{res}"
    puts payment.errors.full_messages.to_s
  end

  def build_discount_for_request(cart)
    cart.prepare_cart
    discount = Shopping::Discount.new
    discount.requires_verification = true
    discount.cart_id = cart.id.to_s
    discount.discount_amount = cart.cart_paid_amount
    discount.product_ids = cart.cart_items.map{|c| c = c.product_id}
    discount
  end

  def create_discount(cart,signed_in_res,user=nil)
    cart.prepare_cart
    user ||= signed_in_res
    discount = Shopping::Discount.new
    discount.requires_verification = true
    discount.cart_id = cart.id.to_s
    discount.discount_amount = cart.cart_paid_amount
    discount.resource_id = user.id.to_s
    discount.resource_class = user.class.name
    discount.signed_in_resource = signed_in_res
    discount.product_ids = cart.cart_items.map{|c| c = c.product_id}
    res = discount.save
    puts "discount save response: #{res.to_s}"
    puts "create discount errors:"
    puts discount.errors.full_messages
    discount
  end

  def create_multiple_cart_items(discount,signed_in_res,user = nil)

    user ||= signed_in_res

    created_multiple_cart_items = discount.product_ids.map{|pid|
      c = Shopping::CartItem.new
      c.product_id = pid
      c.signed_in_resource = signed_in_res
      c.resource_id = user.id.to_s
      c.resource_class = user.class.to_s
      #puts "multiple cart save response:"
      l = c.save
      #puts l.to_s
      #puts l.errors.full_messages.to_s
      c
    }

    created_multiple_cart_items

  end

  def create_payment_using_discount(discount,cart,signed_in_res,user = nil)
    
    user ||= signed_in_res
    payment = Shopping::Payment.new
    payment.signed_in_resource = signed_in_res
    payment.resource_id = user.id.to_s
    payment.resource_class = user.class.name
    payment.amount = 0.0
    payment.cart_id = cart.id.to_s
    payment.discount_id = discount.id.to_s
    payment.payment_type = "cash"
    res = payment.save
    puts "Result of saving payment"
    puts res.to_s
    puts "errors saving payment:"
    puts payment.errors.full_messages
    payment

  end

end

RSpec.configure do |config|
  config.include ValidUserHelper, :type => :controller
  config.include ValidUserRequestHelper, :type => :request
  config.include AdminRootPathSupport, :type => :request
  config.include DiscountSupport, :type => :request
end

