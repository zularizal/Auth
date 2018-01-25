module Auth::Concerns::Shopping::PaymentControllerConcern

  extend ActiveSupport::Concern

  included do
    
  end

  def initialize_vars
    instantiate_shopping_classes
    @payment_params = permitted_params.fetch(:payment,{})
    @payment = params[:id] ? @payment_class.find_self(params[:id],current_signed_in_resource) : @payment_class.new(@payment_params)
  end

  def show
    @payment = add_signed_in_resource(@payment)
    @payment.set_payment_receipt
    respond_with @payment
  end

  def index

  end

  def new
    @payment = add_owner_and_signed_in_resource(@payment)
  end

  def edit

  end

  def create
   
    check_for_create(@payment)
   
    @payment.payment_params = params
    
    @payment = add_owner_and_signed_in_resource(@payment)
   
    @payment.save
    respond_with @payment
  end

  ##in the normal process of making a cash payment
  ##we render a cash form, then we create a payment and then we should in the show screen,to confirm and commit the payment which finally brings it here.
  ##validations in the create call should look into whether there is a picture/cash/cheque whatever requirements are there.
  def update
    check_for_update(@payment)
    @payment.assign_attributes(permitted_params[:payment])
    @payment = add_owner_and_signed_in_resource(@payment)
    ##note that params and not permitted_params is called, here because the gateway sends back all the params as a naked hash, and that is used directly to verify the authenticity, in the gateway functions.
    @payment.payment_params = params
    @payment.save
    respond_with @payment
  end

  def destroy
     @payment = add_signed_in_resource(@payment)
     if @payment.signed_in_resource.is_admin?
        @payment.delete
     end
     respond_with @payment
  end


  def permitted_params
    payment_params = [:payment_type, :amount, :cart_id,:payment_ack_proof, :refund, :payment_status]

    if !current_signed_in_resource.is_admin?
      payment_params.delete(:payment_status)
      if action_name.to_s == "update"
        payment_params = []
      end
    end
    params.permit({payment: payment_params},:id)
    
  end

end