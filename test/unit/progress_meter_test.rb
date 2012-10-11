require 'test_helper'

module CloudEncryptedSync
  class ProgressMeterTest < ActiveSupport::TestCase

    def setup
      @progress_meter = ProgressMeter.new(4)
      @progress_meter.instance_variable_set(:@start_time,Time.now-42)
    end

    test 'should calculate percent completed' do
      @progress_meter.update(1)
      assert_equal(25,@progress_meter.percent_completed)
    end

    test 'should calculate time elapsed' do
      assert_in_delta(42,@progress_meter.time_elapsed,0.01)
    end

    test 'should estimate finish time' do
      @progress_meter.update(1)
      assert_in_delta(Time.now+(42*3),@progress_meter.estimated_finish_time,0.01)
    end

    test 'should estimate time remaining' do
      @progress_meter.update(1)
      assert_in_delta((42*3),@progress_meter.estimated_time_remaining.to_f,0.01)
    end

    test 'should update progress and return self' do
      assert_difference('@progress_meter.completed_index',2) do
        assert_equal(@progress_meter,@progress_meter.update(2))
      end
    end

    test 'should render string' do
      assert_match(/0\% Complete/,@progress_meter.to_s)
    end
  end
end