module Auth::Concerns::Shopping::DiscountControllerConcern

  extend ActiveSupport::Concern

  included do
   	 
  end

  def initialize_vars
  
    instantiate_shopping_classes

    @auth_shopping_discount_object_params = permitted_params.fetch(:discount_object,{})
    
    @auth_shopping_discount = @auth_shopping_discount_object_params[:id] ? @auth_shopping_discount_class.find_self(@auth_shopping_discount_object_params[:id],current_signed_in_resource) : @auth_shopping_discount_class.new(@auth_shopping_discount_object_params)
  
  end

  ##########################################################
  ##
  ##
  ## ACTIONS.
  ##
  ##
  ##########################################################
    
  ##expects the product id, resource_id is the logged in resource, and quantity 
  def create
    ##ensure that the cart item is new
   
    check_for_create(@auth_shopping_discount)
    @auth_shopping_discount = add_owner_and_signed_in_resource(@auth_shopping_discount)
     
    @auth_shopping_discount.save

    respond_with @auth_shopping_discount
  end

  ##only permits the quantity to be changed, transaction id is internally assigned and can never be changed by the external world.
  def update
    check_for_update(@auth_shopping_discount)
    @auth_shopping_discount.assign_attributes(@auth_shopping_discount_params)
    @auth_shopping_discount = add_owner_and_signed_in_resource(@auth_shopping_discount)  
    @auth_shopping_discount.save
    respond_with @auth_shopping_discount
  end

  def show
    not_found if @auth_shopping_discount.nil?
    respond_with @auth_shopping_discount 
  end

  ##should show those cart items which do not have a parent_id.
  ##since these are the pending cart items.
  ##all remaining cart items have already been assigned to carts
  def index
    @auth_shopping_discounts = @auth_shopping_discount_class.where({:resource => lookup_resource})
    respond_with @auth_shopping_discounts
  end


  ##can be removed.
  ##responds with 204, and empty response body, if all is ok.
  def destroy
    not_found if @auth_shopping_discount.nil?
    @auth_shopping_discount.destroy
    respond_with @auth_shopping_discount
  end

  

  private

  def permitted_params

    params.permit({discount: [:discount_amount,:discount_percentage,:cart_id]},:id)

  end


end