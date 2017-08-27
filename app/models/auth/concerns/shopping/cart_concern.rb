##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::CartConcern

	extend ActiveSupport::Concern
	
	include Auth::Concerns::ChiefModelConcern	

	included do 
		field :name, type: String
		field :notes, type: String
	end

	def find_cart_items(resource)
		conditions = {:resource_id => resource.id.to_s, :parent_id => self.id.to_s}
		Auth.configuration.cart_item_class.constantize.where(conditions)
	end


end
