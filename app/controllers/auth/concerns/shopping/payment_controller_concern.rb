module Auth::Concerns::Shopping::PaymentControllerConcern

  extend ActiveSupport::Concern

  included do
    

    include Auth::Concerns::DeviseConcern
    include Auth::Concerns::TokenConcern

   before_filter :do_before_request  , :only => [:create,:update,:destroy,:show,:index, :new]
   before_filter :initialize_vars, :only => [:create,:update,:destroy,:show,:index, :new]
    
  end

  def initialize_vars
    @payment_class = Auth.configuration.payment_class.constantize
  end

  def show
    @payment = @payment_class.find(params[:id])
    @payment.verify_payment 
  end

  def index

  end

  def new
    @payment = @payment_class.new(permitted_params[:payment])
  end

  def create
    @payment = @payment_class.new(permitted_params[:payment])
    @payment.resource_id = lookup_resource.id.to_s
    @payment.cash_callback(permitted_params[:payment]) if @payment.is_cash?
    @payment.cheque_callback(permitted_params[:payment]) if @payment.is_cheque?
    @payment.card_callback(permitted_params[:payment]) if @payment.is_card?
    a = @payment.save
    puts "save errors:"
    puts @payment.errors.full_messages.to_s
    respond_with @payment
  end

  ##in the normal process of making a cash payment
  ##we render a cash form, then we create a payment and then we should in the show screen,to confirm and commit the payment which finally brings it here.
  ##validations in the create call should look into whether there is a picture/cash/cheque whatever requirements are there.
  def update
    @payment = @payment_class.find(params[:id])
    ##note that params and not permitted_params is called, here because the gateway sends back all the params as a naked hash, and that is used directly to verify the authenticity, in the gateway functions.
    @payment.gateway_callback(params) if @payment.is_gateway?
    @payment.save
    respond_with @payment
  end

  def destroy
    
  end



  def permitted_params
    params.permit({payment: [:payment_type, :amount, :cart_id,:payment_ack_proof]},:id)
  end

end