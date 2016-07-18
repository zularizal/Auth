require_dependency "auth/application_controller"
module Auth
  class ClientsController < ApplicationController
    
    ##had to add html here, because just adding json does not work.
    ##the before action, will weed out html requests, so no need to worry about that.
   
    respond_to :html,:json
    before_action :ensure_json_request  
    include Auth::Concerns::TokenConcern
    before_action :set_client, only: [:show, :edit, :destroy,:update]

    ##need to check permissions of 

    # GET /clients
    def index
      @clients = Client.all
      respond_with @clients
    end

    # GET /clients/1
    def show
    end

    # GET /clients/new
    def new
      @client = Client.new
    end

    # GET /clients/1/edit
    def edit
    end

    # POST /clients
    def create
      @client = Client.new(client_params)
      @client.versioned_create(:user_id => @client.user_id)
      if @client.op_success?
        redirect_to @client, notice: 'Client was successfully created.'
      else
        render :new
      end
    end

    # PATCH/PUT /clients/1
    def update
      ##this line ensures that only the redirect urls can be updated, it only considers the redirect_urls as dirty_fields.
      ##puts params.to_s
      @client.redirect_urls = client_params[:redirect_urls]
      @client.versioned_update({"redirect_urls" => nil})
      if @client.op_success?
        redirect_to @client, notice: 'Client was successfully updated.'
      else
        render :edit
      end
    end

    # DELETE /clients/1
    def destroy
      @client.destroy
      redirect_to clients_url, notice: 'Client was successfully destroyed.'
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      # the find method is overriden in the model, where it uses the :id (which is actually the user_id, because we have overridden the to_param method to use user_id). 
      def set_client
        @client = Client.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def client_params
        params.require(:client).permit({:redirect_urls => []},:user_id)
      end

      def ensure_json_request  
        return if request.format == :json
        render :nothing => true, :status => 406  
      end 

  end
end
