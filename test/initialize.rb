module Warning
  def warn(msg)
    # NoOp
  end
end

require './lib/active-record-connection-ext.rb'

ActiveRecord::Base.configurations = {
  'test' => {
    'adapter'  => 'mysql2',
    'host'     => 'localhost',
    'database' => 'active_record_connection_ext_test',
    'username' => 'arce_tester',
    'password' => 'giGant0*m@xIa',
    'pool'     => 2
  }
}
ActiveRecord::Base.establish_connection(:test)

require 'minitest/pride'
require 'minitest/autorun'

module ActiveRecordConnectionExt
  module Testing
    class Test < Minitest::Test
      def setup
        ActiveRecord::Base.reap_all_connections
      end

      def teardown
      end
    end
  end
end

# ActiveRecordConnectionExt.debug!
