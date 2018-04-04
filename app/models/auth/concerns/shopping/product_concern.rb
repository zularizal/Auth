##need a seperate model that implements it
module Auth::Concerns::Shopping::ProductConcern

	extend ActiveSupport::Concern
	include Auth::Concerns::ChiefModelConcern
	include Auth::Concerns::OwnerConcern
	include Auth::Concerns::EsConcern

	included do 
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
				          "auth/shopping/product" => {
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
		field :stock, type: Float, default: 0.0

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

=begin
	## @param[Hash] options : an optional hash of options that can be used to modify the query for the product.
	## @return[Boolean] true if there is enough stock.
	def in_stock?(options={})
		required_stock = options[:required_stock] || 0.0
		self.stock >= required_stock
	end	

	## @param[Auth::Workflow::Requirement] options : an optional hash of options that can be used to modify the query for the product.
	## @return[Mongoid::Document] : atomically decrements the stock of the product, provided that enough stock exists.
	def use_stock(requirement)
		product_document = Auth.configuration.product_class.where({
				"$and" => [
					"stock" => {
						"$gte" => options[:required_stock]
					},
					"_id" => {
						"$eq" => BSON::ObjectId(self.id.to_s)
					}
				]
			}).find_one_and_update(
				{
					"$inc" => {
						:stock => options[:required_stock]*-1
					}
				},
				{
					:return_document => :after	
				}
			)
		return product_document
	end
=end
end