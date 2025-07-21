# frozen_string_literal: true

require 'test_helper'

describe Solace::Programs::Base do
  let(:klass) { Solace::Programs::Base }
  
  let(:connection) { Solace::Connection.new }
  let(:program_id) { '11111111111111111111111111111111' }
  
  describe '#initialize' do
    subject { klass.new(connection: connection, program_id: program_id) }
    
    it 'assigns connection' do
      assert_equal subject.connection, connection
    end

    it 'assigns program_id' do
      assert_equal subject.program_id, program_id
    end
  end
end
