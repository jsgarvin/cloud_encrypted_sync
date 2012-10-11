module CloudEncryptedSync
  class ProgressMeter
    attr_accessor :completed_index
    attr_reader   :max_index, :start_time, :label

    def initialize(max_index,options = {})
      @max_index = max_index.to_f
      @label = options[:label] || ''
      @completed_index = 0.0
      @start_time = Time.now
    end

    def percent_completed
      (completed_index/max_index)*100
    end

    def time_elapsed
      Time.now - start_time
    end

    def estimated_finish_time
      if percent_completed > 0
        start_time + ((100/percent_completed)*time_elapsed)
      else
        start_time + 3600
      end
    end

    def time_remaining
      Time.at(estimated_finish_time - Time.now)
    end

    def update(completed_index)
      self.completed_index = completed_index
      return progress_string
    end

    def progress_string
      sprintf("\r#{label}%0.1f%% Complete. Time Remaining %s", percent_completed, time_remaining.strftime('%M:%S'))
    end
  end
end