##need a seperate model that implements it
module Auth::Concerns::Shopping::ProductConcern

	extend ActiveSupport::Concern
	include Auth::Concerns::ChiefModelConcern
	include Auth::Concerns::OwnerConcern
	include Auth::Concerns::EsConcern
	


	included do 
	
		#embeds_many :specifications, :class_name => Auth.configuration.specification_class

		embeds_many :cycles, :class_name => "Auth::Work::Cycle", :as => :product_cycles

		
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

	module ClassMethods

		## so we have completed the rolling n minutes.
		def add_to_previous_rolling_n_minutes(minutes,origin_epoch,cycle_to_add)

			## get all the minutes less than that.
			rolling_n_minutes_less_than_that = minutes.keys.select{|c| c < origin_epoch}			

			end_min = rolling_n_minutes_less_than_that.size < Auth.configuration.rolling_minutes ? rolling_n_minutes_less_than_that.size : Auth.configuration.rolling_minutes

			end_min = end_min - 1

			end_min = end_min > 0 ? end_min : 0
			rolling_n_minutes_less_than_that[0..end_min].each do |epoch|
				minutes[epoch].cycles << cycle_to_add
			end

		end

		## minutes : {epoch => minute object}
		def schedule_cycles(minutes,location_id,conditions = {})

			products = Auth.configuration.product_class.constantize.all if conditions.blank?

			products = Auth.configuration.product_class.constantize.where(conditions) if !conditions.blank?

			minutes.keys.each do |epoch|
				
				products.each do |product|
				
					all_cycles_valid = true
					product.cycles.each do |cycle|
				
						all_cycles_valid = cycle.requirements_satisfied(epoch + cycle.time_since_prev_cycle.minutes*60,location_id)
								
					end

					## just because the cycles are valid, it means we have workers, but how many?
					## that also has to be returned by the cycle validity statements

					if all_cycles_valid == true
						cycle_chain = []
						product.cycles.each do |cycle|
							epoch_at_which_to_add = epoch + cycle.time_since_prev_cycle.minutes*60
							cycle_to_add = cycle.dup
							cycle_to_add.start_time = epoch_at_which_to_add
							cycle_to_add.end_time = cycle_to_add.start_time + cycle_to_add.duration
							cycle_to_add.cycle_chain = cycle_chain
							if minutes[epoch_at_which_to_add]
								
								add_to_previous_rolling_n_minutes(minutes,epoch_at_which_to_add,cycle_to_add)


								minutes[epoch_at_which_to_add].cycles << cycle_to_add

								cycle_chain << cycle_to_add.id.to_s
							else
								#raise "necessary minute not in range."
							end
						end
					end
				end
			end
			minutes
		end
	end
end
