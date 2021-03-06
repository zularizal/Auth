class Auth::Transaction::EventHolder
	include Mongoid::Document

	attr_accessor :abort_function

	attr_accessor :events_ignored_since_already_completed

	## it will have an array of embedded event objects.
	## these objects will convey the last event that took place.
	## each event object will have its own attributes and data.
	embeds_many :events, :class_name => "Auth::Transaction::Event"


	## status, can be 0 -> processing/to_be_processed, or 1 -> completed.
	field :status, type: Integer
	validates :status, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, :allow_nil => true


	field :process_count, type: Integer, default: 0
	validates :process_count, numericality: {only_integer: true}

	## take each event
	## if its complete , move forward
	## if its failed , return out of the function.
	## if its processing, return out of the function.
	## otherwise process the event
	## if the result is nil, 
	## if the result is not nil, commit and mark as complete the given event.
	## proceed, till end,now finally check event count, if not_equal, to start_count, means that many events, were added. exit out of function, without changing the status.
	## otherwise, set status as 1, where the status was not 1.
	def process
			
		## increment the process count when?
		## everytime?
		## only when the result is abort, due to processing?
		## that also for a particular event?
=begin
		return unless doc_after_process_count_increment =  Auth::Transaction::EventHolder.where(
			{
				"_id" => BSON::ObjectId(self.id.to_s)
			}
		).find_one_and_update({
			"$inc" => {
				"process_count" => 1
			}
		},{
			:return_document => :after
		})
=end
		
		## where the status of the last event is not completed, update as failed, if the count in the returned document is greater than permitted count
		## use the returned doc for that.

		#####################################################
		##
		##
		##
		## ATTRIBUTE ACCESSORS INITIALIZED.
		##
		##
		####################################################

		self.abort_function = false

		self.events_ignored_since_already_completed  = []

		####################################################
		##
		##
		## end
		##
		####################################################


		return if status == 1

		events = get_events

		puts "events size is: #{events.size.to_s}"

		events.each_with_index {|ev,key|

			puts "processing event is :#{ev.id.to_s}"

			puts "event is:"
			puts ev.attributes.to_s

			ev.event_index = key

			if (ev._processing? || ev._failed?)
				#puts "processing or failed."
				self.abort_function = ev._processing? ? "processing:#{ev.id.to_s}" : "failed:#{ev.id.to_s}"  
				break
			end

			unless ev._completed?

				unless ev_updated = mark_event_as_processing(ev)
					self.abort_function = "could_not_mark_as_processing:#{ev.id.to_s}"
					break
				end
				
				ev_updated.event_index = key

				if events_to_commit = ev_updated.process

					unless ev_updated_after_commit = commit_new_events_and_mark_existing_event_as_complete(events_to_commit,ev_updated)
						self.abort_function = "could not commit new events or mark event as completed:#{ev_updated.id.to_s}"
						break
					end
				else
					self.abort_function = "event_processing_returned_nil:#{ev_updated.id.to_s}"
					break
				end

			else

				self.events_ignored_since_already_completed << ev

			end
		}

		return self if self.abort_function

		self.status = 1
		
		## as long as the number of events, has not changed, update the event_holder as completed for processing.

		Auth::Transaction::EventHolder.where({
			"$and" => [
				{
					"_id" => BSON::ObjectId(self.id.to_s)
				},
				{
					"status" => self.status_was
				},
				{
					"events.#{events.count}" => {
						"$exists" => false
					}
				}
			]
		}).find_one_and_update(
			{
				"$set" => {
					"status" => self.status
				}
			},
			{
				:return_document => :after
			}
		)

	end


	def before_commit_new_events(latest_event_holder,events,ev)



	end



	## @logic
	## will commit the new events generated by this event, only if the present event is the last event in the events array.
	## to ensure that it is the last event, we first check if this is the event at events.size - 1, and that the index events.size does not exist.
	## if these conditions are satisfied, then push all the new events.
	## @return [Auth::Transaction::EventHolder] event_holder object after the update.
	def commit_new_events(latest_event_holder,events,ev)

		before_commit_new_events(latest_event_holder,events,ev)

		return latest_event_holder if events.empty?

		puts "came to commit new events."

		events_size = latest_event_holder.events.size

		puts "events size is: #{events_size}"

		qr = {
			"$and" => [
				{
					"_id" => BSON::ObjectId(self.id.to_s)
				},
				{
					"events.#{events_size - 1}._id" => BSON::ObjectId(ev.id.to_s)
				},
				{
					"events.#{events_size}" => {
						"$exists" => false
					}
				}
			]
		}	

		puts "query results is:"

		puts Auth::Transaction::EventHolder.where(qr).count

		## if the last event is this event -> go and push all the new events, where the last event id is this.
		doc_after_update = Auth::Transaction::EventHolder.where(qr).find_one_and_update(
			{
				## add to set all the events.
				## set the event status as completed.
				"$push" => {
					"events" => {
						"$each" => events.map{|c| c = c.attributes}
					}
				}
			},
			{
				:return_document => :after
			}
		)

		return doc_after_update

=begin
		if doc_after_update
			puts "Returning doc after update."
			return doc_after_update
		else
			puts "no doc after update."
			## only in case someone else did not update it, we need to call an error and abort.
			## so suppose someone else updated it?
			latest_event_holder = Auth::Transaction::EventHolder.find(self.id)
			return new_events_already_committed(latest_event_holder,ev)
		end
=end
	end

	def before_mark_existing_event_as_complete(latest_event_holder,events,ev)



	end

	## @logic
	## will first check if the event is already marked as completed?
	## if yes, then returns the latest_event_holder passed in.
	## if no,
	## will check that the last status of the event at the event_index is 'processing' , and that the next index does not exist.
	## @return[Auth::Transaction::EventHolder] returns the doc after update.
	def mark_existing_event_as_complete(latest_event_holder,events,ev)


		
			before_mark_existing_event_as_complete(latest_event_holder,events,ev)

			puts "came to mark existing event as complete."

			## otherwise mark the event at the event index as completed, where it is not completed.

			qr = {
				"$and" => [
					{
						"_id" => BSON::ObjectId(self.id.to_s)
					},
					{
						"events.#{ev.event_index}._id" => BSON::ObjectId(ev.id.to_s)
					},
					{
						"events.#{ev.event_index}.statuses.#{ev.statuses.size - 1}.condition" => "PROCESSING"
					},
					{
						"events.#{ev.event_index}.statuses.#{ev.statuses.size}" => {
							"$exists" => false
						}
					}
				]
			}					

			puts "query result is:"
			puts Auth::Transaction::EventHolder.where(qr).count

			doc_after_update = Auth::Transaction::EventHolder.where(qr).find_one_and_update(
				{
					## add to set all the events.
					## set the event status as completed.
					"$push" => {
						"events.#{ev.event_index}.statuses" => Auth::Transaction::Status.new(:condition => "COMPLETED", :created_at => Time.now, :updated_at => Time.now).attributes
					}
				},
				{
					:return_document => :after
				}
			)

			puts "doc after update is:"
			puts doc_after_update.to_s

			return doc_after_update

		

	end

	## @return[Auth::Transaction::EventHolder] returns the event holder if the given event is not the last event in the events_array.
	## otherwise returns nil.
	def new_events_already_committed(latest_event_holder,ev)
		puts "came to new events already commited."
		return latest_event_holder if (latest_event_holder.events.last.id.to_s != ev.id.to_s)
		puts "returning nil."
		return nil
	end

	## @return[Auth::Transaction::EventHolder] event_holder if all operations succeed.
	## nil : if there is any failure.
	def commit_new_events_and_mark_existing_event_as_complete(events,ev)

		puts "came to commit new events and mark existing event as complete."

		## get the latest event_holder
		latest_event_holder = Auth::Transaction::EventHolder.find(self.id)

		puts "latest event holder"

		puts latest_event_holder

		if new_events_already_committed(latest_event_holder,ev)
			return mark_existing_event_as_complete(latest_event_holder,events,ev)
		else
			puts "new events not already committed."
			if latest_event_holder = commit_new_events(latest_event_holder,events,ev)
				return mark_existing_event_as_complete(latest_event_holder,events,ev)
			else
				return nil
			end
		end
	
	end

	def event_marked_complete_by_other_process?(ev)
		## find a transaction event_holder with this id, where the event id is this events id, and the status of that event is completed.
		results = Auth::Transaction::EventHolder.collection.aggregate([
			{
				"$match" => {
					"_id" => BSON::ObjectId(self.id.to_s)
				}
			},
			{
				"$unwind" => {
					"path" => "$events"
				}
			},
			{
				"$unwind" => {
					"path" => "$events.statuses"
				}
			},
			{
				"$match" => {
					"$and" => [
						{
							"events.statuses._id" => BSON::ObjectId(ev.id.to_s)
						},
						{
							"events.statuses.condition" => "COMPLETED"
						}
					]
				}
			}
		])

		return true if results.count == 1

	end

	def before_mark_event_as_processing(ev)

		## self is available 

	end


	## @param[Auth::Transaction::Event] 
	## @return[Auth::Transaction:Event], the updated event.
	def mark_event_as_processing(ev)
				
		## this is currently used only while testing.
		before_mark_event_as_processing(ev)

		puts "came to mark event as processing."
		

		statuses_query = 
		[{
		"events.#{ev.event_index}.statuses.0" => 
			{
			"$exists" => false
			}
		}]
					

		if ev.statuses.size > 0
			puts "events statuses size was more than 0."
			## want to make sure that the size  is nil.
			## and the size - 1 is processing.
			## that way you can get the last one.
			## otherwise you fail.
			## and its no longer an or query.

			statuses_query =
			[
				{
					"events.#{ev.event_index}.statuses.#{ev.statuses.size - 1}.condition" => "PROCESSING"
				},
				{
					"events.#{ev.event_index}.statuses.#{ev.statuses.size}" => {
						"$exists" => false
					}
				}
			]
		end

		
		qr = {
			"$and" => [
				{
					"_id" => BSON::ObjectId(self.id.to_s)
				},
				{
					"events.#{ev.event_index}._id" => BSON::ObjectId(ev.id.to_s)
				}
			]
		}

		qr["$and"] << statuses_query
		qr["$and"].flatten!

		puts "the query is:"
		puts qr.to_s

		query_result = Auth::Transaction::EventHolder.where(qr)

		puts "the count of the query result is:"
		puts query_result.count

		
		doc_after_update = Auth::Transaction::EventHolder.where(qr).find_one_and_update(
			{
					"$push" => {
						"events.#{ev.event_index}.statuses" => Auth::Transaction::Status.new(:condition => "PROCESSING", :created_at => Time.now, :updated_at => Time.now).attributes
					}
			},
			{
					:return_document => :after
			}
		)

		return nil unless doc_after_update
		
		puts "returning doc after update , marked it as processing."

		return doc_after_update.events[ev.event_index]
	
	end

	def get_events
		Auth::Transaction::EventHolder.find(self.id).events
	end

end