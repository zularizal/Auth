class Auth::Workflow::Sop
  	include Mongoid::Document
  	include Auth::Concerns::OwnerConcern
  	embeds_many :steps, :class_name => Auth.configuration.step_class
  	embeds_many :orders, :class_name => Auth.configuration.order_class
  	embedded_in :stage, :class_name => Auth.configuration.stage_class
  	field :name, type: String
  	field :description, type: String
  	field :applicable_to_product_ids, type: Array

  	attr_accessor :assembly_id
	attr_accessor :assembly_doc_version
	attr_accessor :stage_index
	attr_accessor :stage_doc_version
	attr_accessor :stage_id
	attr_accessor :sop_index


	#########################################################
	##
	##
	##
	## CLASS METHODS
	## 
	##
	##
	#########################################################

  	
  	def self.find_self(id,signed_in_resource,options={})
  		#puts "the id is: #{id}"
		return nil unless collection =  Auth.configuration.assembly_class.constantize.where("stages.sops._id" => BSON::ObjectId(id)
		)

		collection.first

	end

	def self.permitted_params
		[{:sop => [:name,:description,:assembly_id,:assembly_doc_version,:stage_id,:stage_doc_version,:stage_index,:doc_version, :sop_index, {:applicable_to_product_ids => []}]},:id]
	end

	## @return[Array] array of hashes, each with the following structure:

	## it basically returns the stage_index as well as the sop_index alongwith their respective ids.
	## the matches array contains the product ids to which that sop is applicable, out of the product ids supplied.
	def self.find_applicable_sops(options={})
		product_ids = options[:product_ids]
		assembly_id = options[:assembly_id]

		

		res = Auth.configuration.assembly_class.constantize.collection.aggregate([
			{
				"$match" => {
					"_id" => BSON::ObjectId(assembly_id) 
				}
			},
			{
				"$unwind" => {
					"path" => "$stages",
					"includeArrayIndex" => "stage_index"
				}
			},
			{
				"$unwind" => {
					"path" => "$stages.sops",
					"includeArrayIndex" => "sop_index"
				}
			},
			{
				"$project" => {
					"common_products" => {
						"$setIntersection" => ["$stages.sops.applicable_to_product_ids",product_ids]
					},
					"stages" => 1,
					"sops" => 1,
					"sop_index" => 1,
					"stage_index" => 1
				}
			},
			{
			    "$addFields" => {
			      "stages.sops.sop_index" => "$sop_index",
			      "stages.sops.stage_index" => "$stage_index"
			    }
			},
			{
				"$project" => {
					"stages" => {
						"$cond" => {
							"if" => {
								"$gt" => [
									{"$size" => "$common_products"},
									0
								]
							},
							"then" => "$stages",
							"else" => "$$REMOVE"
						}
					},
					"sop_index" => 1,
					"stage_index" => 1	
				}
			},
			{
				"$group" => {
					"_id" => nil,
					"sops" => { "$push" => "$stages.sops" } 
				}
			}
		])


		## so we want to return an array of SOP objects.



		#res.each do |result|
		#	puts JSON.pretty_generate(result)
		#end

		puts "res is :#{res}"

		begin
			return [] unless res
			return [] unless res.count > 0

			res.first["sops"].map{|sop_hash|

				Mongoid::Factory.from_db(Auth.configuration.sop_class.constantize,sop_hash)
			}
		rescue
			return []
		end

	end

	#########################################################
	##
	##
	##
	## INSTANCE METHODS
	## 
	##
	##
	#########################################################	


	def create_with_conditions(params,permitted_params,model)
		## in this case the model is a stage model.

		return false unless model.valid?
		

		assembly_updated = Auth.configuration.assembly_class.constantize.where({
			"$and" => [
				{
					"stages.#{model.stage_index}._id" => BSON::ObjectId(model.stage_id)
				},
				{
					"stages.#{model.stage_index}.doc_version" => model.stage_doc_version
				},
				{
					"_id" => BSON::ObjectId(model.assembly_id)
				},
				{
					"doc_version" => model.assembly_doc_version
				}
			]
		})
		.find_one_and_update(
			{
				"$push" => 
				{
					"stages.#{stage_index}.sops" => model.attributes
				}
			},
			{
				:return_document => :after
			}
		)

		#puts "assembly updated is: #{assembly_updated}"

		return false unless assembly_updated

		return model
		
	end


	## so it will look first if those orders are processed or processing or whatever.
	## first we are just checking if previous order is processing.

	def can_process_order(order)

		## FIRST CHECK IF ANY OF THE PREVIOUS ORDERS REQUIREMENTS ARE BEING CHECKED OR IT IS BEING SCHEDULED OR IT COULD NOT BE SCHEDULED

		non_viable_orders = self.orders.select{|c| 
			true if (c.order_pending || c.failed_to_schedule)
		}

		order.errors.add(:status, "another order is being processed, check back later") if non_viable_orders.size > 0


		self.steps.each do |step|
			## now here we will call a method on step.
			
		end

	end

	## called from #index in authenticated_controller.
	def get_many
		self.class.find_applicable_sops({:product_ids => self.applicable_to_product_ids, :assembly_id => self.assembly_id})
	end

	## return[Boolean] true if the sop already has some order with any of the cart_items in this order.
	def has_order_with_cart_items(order)
		results =Auth.configuration.assembly_class.constantize.where({
			"$and" => [
				{
					"_id" => BSON::ObjectId
				},
				{
					"stages.#{order.stage_index}.sops.#{order.sop_index}.orders.cart_item_ids" => {
						"$in" => order.cart_item_ids
					}
				}
			]
		})

		return results && results.size == 1
	end

	## @return[Integer] the index in the sop's orders of the given order.
	def get_order_index(order)
		## unwind, and match.
		order_els = Auth.configuration.assembly_class.constantize.collection.aggregate([
				{
				"$match" => {
					"_id" => BSON::ObjectId(assembly_id) 
				}
				},
				{
					"$unwind" => {
						"path" => "$stages",
						"includeArrayIndex" => "stage_index"
					}
				},
				{
					"$unwind" => {
						"path" => "$stages.sops",
						"includeArrayIndex" => "sop_index"
					}
				},
				{
					"$unwind" => {
						"path" => "$stages.sops.orders",
						"includeArrayIndex" => "order_index"
					}
				},
				{
					"$match" => {
						"_id" => BSON::ObjectId(order.id.to_s)
					}
				}
			])

		raise "did'nt find the order" unless order_els

		return order_els.first["order_index"]


	end	



	##########################################################
	##
	##
	##
	## defs for events
	##
	##
	##
	##########################################################

	def create_order(arguments={})
		## so make an order
		## suppose there are no arguments,
		## it should register a failure.
		return nil if 
		
		return nil if (arguments[:assembly_id].blank? || arguments[:stage_id].blank? || arguments[:stage_index].blank? || arguments[:sop_index].blank? || arguments[:cart_item_ids].blank? || arguments[:assembly_doc_version].blank? || arguments[:stage_doc_version].blank? || arguments[:sop_doc_version].blank?)

		order = Auth.configuration.order_class.constantize.new(arguments)

		if order_created = order.create_with_conditions(nil,nil,order)
			return after_create_order(order_created)
		else
			return nil unless has_order_with_cart_items(order.cart_item_ids)
			return after_create_order(order)
		end

	end


	def after_create_order(order)
		if get_order_index(order) == 0
			## we want to return an array of events.
			get_sop_requirements.map{|requirement|
				e = Auth::Transaction::Event.new
				e.arguments = {}
				e.arguments[:requirement] = requirement.attributes
				e.method_to_call = "mark_requirement"
				requirement = e
			}
		else 
			## do nothing.
		end
	end

	## @return[Array] array of Auth::Workflow::Requirement objects. 
	def get_sop_requirements
		## so build_requirement/calculate requirement is on step.
		## then check is also on step.
		## then return requirements is also on step.
		
		## iterate each step -> 
		## build requirements ->
		## bypass step where we check if we have those requirements.
		## return consumables needed ->
		## and push an event, that will mark those products as being required.
	end

end


