require './test/initialize.rb'

module ActiveRecordConnectionExt
  module Testing
    class ActiveRecordConnectionExtTest < ActiveRecordConnectionExt::Testing::Test
      def test_reproduce_connection_timeout
        sleep_time = 5
        connection_timeout_error_occurred = false

        ActiveRecordConnectionExt.define_error_handler ->(e) {
          if e.is_a?(ActiveRecord::ConnectionTimeoutError)
            connection_timeout_error_occurred = true
          else
            assert(false)
          end
        }
        ActiveRecordConnectionExt.define_thread_kill_handler ->(t) { false }

        thread1 = Thread.start {
          ActiveRecord::Base.with_connection {
            ActiveRecord::Base.connection.execute('SHOW TABLES')
            sleep sleep_time
          }
        }

        thread2 = Thread.start {
          ActiveRecord::Base.with_connection {
            ActiveRecord::Base.connection.execute('SHOW TABLES')
            sleep sleep_time
          }
        }

        thread3 = Thread.start {
          ActiveRecord::Base.with_connection {
            ActiveRecord::Base.connection.execute('SHOW TABLES')
            sleep sleep_time
          }
        }

        thread1.join
        thread2.join
        thread3.join

        assert(connection_timeout_error_occurred)
      end

      def test_cannot_reproduce_connection_timeout_by_checking_in_connection_when_done
        sleep_time = 5
        connection_timeout_error_occurred = false

        ActiveRecordConnectionExt.define_error_handler ->(e) {
          if e.is_a?(ActiveRecord::ConnectionTimeoutError)
            connection_timeout_error_occurred = true
          else
            assert(false)
          end
        }
        ActiveRecordConnectionExt.define_thread_kill_handler ->(t) { true }

        thread1 = Thread.start {
          ActiveRecord::Base.with_connection {
            ActiveRecord::Base.connection.execute('SHOW TABLES')
            sleep sleep_time
          }
        }

        thread2 = Thread.start {
          ActiveRecord::Base.with_connection {
            ActiveRecord::Base.connection.execute('SHOW TABLES')
            sleep sleep_time
          }
        }

        thread3 = Thread.start {
          ActiveRecord::Base.with_connection {
            ActiveRecord::Base.connection.execute('SHOW TABLES')
            sleep sleep_time
          }
        }

        thread1.join
        thread2.join
        thread3.join

        refute(connection_timeout_error_occurred)
      end
    end
  end
end
