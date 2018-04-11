module Auth::Concerns::WorkflowConcern

	extend ActiveSupport::Concern

	included do

		include Mongoid::Document
  	include Auth::Concerns::OwnerConcern


    field :resolve, type: Boolean, default: false


    ## must have a start_time and an end_time
    ## or these will have to be calculated.
    ## start_time is the 
    ## dont specify these in the time information, if you want it to just continue relative to the first step.
    ## this should be added to the requirement during the resolve phse.
    field :time_information, type: Hash, default: {}

    field :location_information, type: Hash, default: {}

    field :resolved_location_id, type: String

    field :resolved_time, type: Integer

    field :calculated_duration, type: Integer

    field :duration, type: Integer

    ## we need to provide a duration calculation function here.
    field :duration_calculation_function, type: String, default: ""

    field :category, type: Array, default: []

    field :resolved_id, type: String

    def generate_location_query

      query_clause = {}

      if resolved_location_id
        
        query_clause = {
          "location_id" => resolved_location_id
        }
      
      elsif self.location_information[:location_point_coordinates] && self.location_information[:within_radius]
      
        query_clause = {
          "location" => {
            "$nearSphere" => {
              "$geometry" => {
                "type" => "Point",
                "coordinates" => self.location_information[:location_point_coordinates]
              },
              "$maxDistance" => self.location_information[:within_radius] * 1609.34
             }
          }
      }

      end

      return query_clause

    end


    def generate_time_query

      query_clause = {}

      if self.resolved_time
        query_clause =  {
          "time" => self.resolved_time
        }
      elsif self.time_information[:start_time] && self.time_information[:end_time]
        query_clause =  {
          "time" => {
            "$gte" => self.time_information[:start_time],
            "$lte" => self.time_information[:end_time]
          }
        }
      end


      return query_clause

    end


    ### @param[Hash] location_information : the location information of the present step.
    ## @param[Hash] time_information : the time information of the present step.
    ## @param[String] resolved_location_id : the resolved_location_id of the present step.
    ## @param[Integer] resolved_time : the resolved_time of the present_step
    ## will first check if a location_id is already present in the current location_information.
    ## if yes, will do nothing.
    ## if no, will assign the location_id from the provided location_information hash.
    ## next will check if within_radius and location_point_coordinates are already present in the location_information otherwise will try to assing from the provided location_information hash.
    ## at this point, will look whether this location needs to be resolved or not, and if not then will return.
    ## if it needs to be resolved, it will call the generate_location_query, using the location information now assigned, and will assign a location id based on the results of that query.
    ## the time_information and resolved_time params are not used.!
    def resolve_location(location_information={},time_information={},resolved_location_id=nil,resolved_time=nil)

      ## merge in the location information in case we don't have any location information.

      unless self.location_information[:location_id]

        self.location_information[:location_id] = location_information[:location_id] if location_information[:location_id]
      
      end

      unless (self.location_information[:within_radius] || self.location_information[:location_point_coordinates])

        if (location_information[:within_radius] && location_information[:location_point_coordinates])

            self.location_information[:within_radius] = location_information[:within_radius]

            self.location_information[:location_point_coordinates] = location_information[:location_point_coordinates]

        end

      end

      return unless self.resolve
  
      location_query = generate_location_query

      if results = Auth.configuration.location_class.constantize.where(location_query)

        self.resolved_location_id = results.first.id.to_s

      end

    end

    ### @param[Hash] location_information : provided location_information to merge in case the present location information is deemed to be insufficient.
    ## @param[Hash] time_information : provided time_information to merge in case the present time information is deemed to be insufficient.
    ## @param[String] resolved_location_id : the resolved_location_id of the present step.
    ## @param[Integer] resolved_time : the resolved_time of the present_step
    ## will merge the time information for start time and end time from the previous step in case these are not defined on the present step.
    ## will then set the resolved_time as the one that was provided in the incoming time information.
    def resolve_time(location_information={},time_information={},resolved_location_id=nil,resolved_time=nil)

      self.time_information.merge(time_information) if ((self.time_information[:start_time].blank? || self.time_information[:end_time].blank?) && self.resolved_time.blank?) 


      return unless self.resolve
      
      ## resolved time is basically just set if it is passed into the time information.
      self.resolved_time = self.time_information[:resolved_time] if self.time_information[:resolved_time]

    end


    def calculate_duration
      return if self.duration
      ##to do this, you will need to tell the function how to process. this.
      eval(self.duration_calculation_function)
    end

    ## @param [Hash] permitted_param : the permitted params passed in to the #update_with_conditions def.
    ## @param[Array] locked_fields : an array of field names as strings, denoting which fields cannot be changed in case an order has already been added to the 
    ## @return[Boolean] true/false : whether the permitted params contain any of the locked fields, and if yes, then the query has to be modified to include that there should be no orders in any sop. 
    def self.permitted_params_contain_locked_fields(permitted_params)
      
      locked_fields = self::FIELDS_LOCKED_AFTER_ORDER_ADDED
      result = false
      permitted_params.keys.each do |attr|
        if locked_fields.include? attr.to_s
          result = true
          break
        end
      end
      result
    end

	end

end