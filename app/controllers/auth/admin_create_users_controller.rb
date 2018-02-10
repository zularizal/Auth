class Auth::AdminCreateUsersController < ApplicationController
  ## only these actions need an authenticated user to be present for them to be executed.
  CONDITIONS_FOR_TOKEN_AUTH = [:create,:update,:destroy,:edit,:new,:index,:show]
  TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}
  include Auth::Concerns::DeviseConcern
  include Auth::Concerns::TokenConcern
  before_filter :do_before_request , TCONDITIONS
  before_filter :initialize_vars , TCONDITIONS
  ## ensures that only admin users.
  before_filter :is_admin_user , TCONDITIONS


  ## called before all the actions.
  def initialize_vars
    
    @auth_user_class = Auth.configuration.user_class.constantize

    @auth_user_params = permitted_params.fetch(:user,{}) 

    @auth_user = params[:id] ? @auth_user_class.find_self(params[:id],current_signed_in_resource) : @auth_user_class.new(@auth_user_params)
    
  end

  # GET /auth/admin_create_users
  def index
    #@auth_admin_create_users = Auth::AdminCreateUser.all
  end

  # GET /auth/admin_create_users/1
  def show
  end

  # GET /auth/admin_create_users/new
  def new
    # what kind of form should be presented to the admin.

    #@auth_admin_create_user = Auth::AdminCreateUser.new
    ## just render a form with the user model.
  end

  # GET /auth/admin_create_users/1/edit
  def edit
  end

  # POST /auth/admin_create_users
  def create
    @auth_user.password = @auth_user.password_confirmation =SecureRandom.hex(24)
    @auth_user.created_by_admin = true
    ## no this will not happen here.
    ## here we will only create.
    if @auth_user.save
      if @auth_user.additional_login_param
        render "auth/confirmations/enter_otp.html.erb"
      else
      ## render some partail to show him that he has to confirm the accoutn by the email.
      end
    else
      
      render "new.html.erb"

    end
  end

  # PATCH/PUT /auth/admin_create_users/1
  def update
    ## should also allow stuff like
    ## resend sms otp
    ## resend confirmation email
  end

  # DELETE /auth/admin_create_users/1
  def destroy
    @auth_admin_create_user.destroy
    redirect_to auth_admin_create_users_url, notice: 'Admin create user was successfully destroyed.'
  end

  def permitted_params
    params.permit({user: [:email,:additional_login_param, :password, :password_confirmation, :request_resend_sms_otp, :request_resend_email_confirmation]},:id)    
  end

end