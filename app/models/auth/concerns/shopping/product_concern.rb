##need a seperate model that implements it
module Auth::Concerns::Shopping::ProductConcern

	extend ActiveSupport::Concern
	include Auth::Concerns::ChiefModelConcern
	include Auth::Concerns::OwnerConcern
	include Auth::Concerns::EsConcern
	


	included do 
	
		embeds_many :specifications, :class_name => Auth.configuration.specification_class

		embeds_many :cycles, :clsass_name => "Auth::Work::Cycle", :as => :product_cycles

		
		INDEX_DEFINITION = {
				index_options:  {
				    settings:  {
				    		index: {
						        analysis:  {
						            filter:  {
						                nGram_filter:  {
						                    type: "nGram",
						                    min_gram: 2,
						                    max_gram: 20,
						                   	token_chars: [
						                       "letter",
						                       "digit",
						                       "punctuation",
						                       "symbol"
						                    ]
						                }
						            },
						            analyzer:  {
						                nGram_analyzer:  {
						                    type: "custom",
						                    tokenizer:  "whitespace",
						                    filter: [
						                        "lowercase",
						                        "asciifolding",
						                        "nGram_filter"
						                    ]
						                },
						                whitespace_analyzer: {
						                    type: "custom",
						                    tokenizer: "whitespace",
						                    filter: [
						                        "lowercase",
						                        "asciifolding"
						                    ]
						                }
						            }
						        }
					    	}
					    },
				        mappings: {
				          Auth::OmniAuth::Path.pathify(Auth.configuration.product_class) => {
				            properties: {
				            	_all_fields: {
				            		type: "text",
				            		analyzer: "nGram_analyzer",
					            	search_analyzer: "whitespace_analyzer"
				            	},
				                name: {
				                	type: "keyword",
				                	copy_to: "_all_fields"
				                },
				                price: {
				                	type: "double",
				                	copy_to: "_all_fields"
				                },
				                public: {
				                	type: "keyword"
				                },
				                resource_id: {
				                	type: "keyword",
				                	copy_to: "_all_fields"
				                }
				            }
				        }
				    }
				}
			}
		#include MongoidVersionedAtomic::VAtomic	
		field :price, type: BigDecimal
		field :name, type: String
		## a product can only belong to one bunch.
		field :bunch, type: String
		##PERMITTED
		##the number of this product that are being added to the cart
		##permitted
		field :quantity, type: Float, default: 1
		## for WORKFLOW
		#field :location_information, type: Hash, default: {}
		#field :time_information, type: Hash, default: {}
		field :miscellaneous_attributes, type: Hash, default: {}


		## all products are public to be searched.
		before_save do |document|
			self.public = "yes"
		end

	end


	def as_indexed_json(options={})
	 {
	 	name: name,
	    price: price,
	    resource_id: resource_id,
	    public: public
	 }
	end 

	def self.schedule_cycles(minutes,location_id,conditions = {})

		products = Auth.configuration.product_class.constantize.all if conditions.blank?

		products = Auth.configuration.product_class.constantize.where(conditions) if !conditions.blank?

		## this will add the cycles to the minutes.
		## that's all folks.

		minutes.keys.each do |minute|
			## what should be added here ?
			## we will also have to add at those additional minutes.
			products.each do |product|
				all_cycles_valid = true
				product.cycles.each do |cycle|
					all_cycles_valid = cycle.requirements_satisfied(minute + time_since_prev_cycle,location_id)				
				end
				if all_cycles_valid == true
					product.cycles.each do |cycle|
						minute_at_which_to_add = minute + time_since_prev_cycle
						if minutes[minute_at_which_to_add]
							minutes[minute_at_which_to_add].cycles << cycle
						else
							raise "necessary minute not in range."
						end
					end
				end
			end
		end


	end

end

