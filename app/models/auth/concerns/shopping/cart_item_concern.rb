##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::CartItemConcern

	extend ActiveSupport::Concern
	
	
	include Auth::Concerns::Shopping::ProductConcern

	included do 

		validate :resource_id_not_changed

		##the id of the product to which this cart item refers.
		##permitted
		field :product_id, type: String

		##the user id who is buying this product.
		##not permitted
		field :resource_id, type: String
			
		##the number of this product that are being added to the cart
		##permitted
		field :quantity, type: Integer, default: 1

		##when it is paid for, a transaction should get generated.
		##not permitted
		field :parent_id, type: String

		##name of transaction
		field :parent_name, type: String

		##notes on transaction
		field :parent_notes, type: String

		##is it being discounted, can be from 0 -> 100 percent discount
		##not permitted
		field :discount, type: Float

		##discount code to offer discounts
		##permitted
		field :discount_code, type: String
	end

	private
	def resource_id_not_changed
	  ##this method will give you access to be able to reset the resource_id in case the admin is modifying the resource.
	  ##need to check if that can be done?

	  if resource_id_changed? && resource_id_was
	      errors.add(:resource_id, "You cannot change or view this cart item")
	  end
	end

	module ClassMethods
		##used in cart controller concern.
		##you can modify this to allow admin to also view/update/etc the cart items.
		def find_cart_item(params_cart_item_id,resource)
			self.where(:_id =>params_cart_item_id, :resource_id => resource.id.to_s).first
		end

		##used in transactions controller concern.
		##and in cart item controller concern#index
		def find_cart_items(resource,parent_id=nil)
			conditions = {:resource_id => resource.id.to_s}
			if parent_id
				self.where(conditions.merge({:parent_id => parent_id}))
			else
				self.where(conditions)
			end
		end
	end
	
end