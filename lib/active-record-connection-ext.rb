require 'active_record'

module Kernel
  def active_record_connection_ext_debug(msg)
    return unless ActiveRecordConnectionExt.debug?

    puts "[\033[0;34mActiveRecordConnectionExt\033[0;0m] - #{msg}"
  end
end

module ActiveRecordConnectionExt
  class << self
    def define_error_handler(handler)
      @error_handler = handler
    end

    def run_error_handler(e)
      return unless @error_handler

      @error_handler.call(e)
    end

    def define_thread_kill_handler(handler)
      @thread_kill_handler = handler
    end

    def run_thread_kill_handler
      # Default to true, so by default we will kill the database connection
      # for this thread. I think this is the safest option.
      return true unless @thread_kill_handler

      @thread_kill_handler.call(Thread.current)
    end

    def debug!
      @debug = true
    end

    def debug?
      @debug
    end
  end
end

class ActiveRecord::Base
  class << self
    def with_connection(&block)
      active_record_connection_ext_debug("#{'-'*20}#{__method__}#{'-'*20}")

      # Save the return value of the block so we can return it ourselves in
      # this method.
      result = nil

      active_record_connection_ext_debug("result = #{result}")

      # A reference to the datebase connection for the current thread.
      my_connection = nil

      active_record_connection_ext_debug("my_connection = #{my_connection}")

      # Assume that we already have a connection until proved otherwise.
      connection_already_exists = true

      active_record_connection_ext_debug("connection_already_exists = #{connection_already_exists}")

      # Figure out of if this thread already has a connection.
      connection_already_exists = connection_pool.active_connection?

      active_record_connection_ext_debug("connection_already_exists = #{connection_already_exists}")

      # If we don't have a connection, then we need to retrieve one.
      unless connection_already_exists
        active_record_connection_ext_debug("connection does not exist. retrieving connection.")

        my_connection = retrieve_connection

        active_record_connection_ext_debug("my_connection = #{my_connection}")
      end

      # Now that we should have a database connection, we can call the block.
      result = block.call().tap {|x| active_record_connection_ext_debug("result of block call = #{x}")}
    rescue => e
      active_record_connection_ext_debug("exception raise. calling error handler.")

      # Run the defined error handler.
      ActiveRecordConnectionExt.run_error_handler(e)
    ensure
      if my_connection && ActiveRecordConnectionExt.run_thread_kill_handler.tap {|x| active_record_connection_ext_debug("thread_killer_handler result = #{x}")}
        active_record_connection_ext_debug("checking in connection.")
        connection_pool.checkin(my_connection)
      end

      return result.tap {|x| active_record_connection_ext_debug("returning #{x}")}
    end

    def reap_all_connections
      connection_pool.reap
    end
  end
end

=begin
module ActiveRecord
  module ConnectionAdapters
    class ConnectionPool
      def get_current_connection_id
        current_connection_id
      end

      def get_reserved_connections
        @reserved_connections
      end
    end
  end
end
=end
