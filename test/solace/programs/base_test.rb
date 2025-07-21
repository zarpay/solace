# frozen_string_literal: true

require 'test_helper'

describe Solace::Programs::Base do
  subject { described_class.new(connection: connection, program_id: program_id) }

  let(:connection) { Solace::Connection.new }
  let(:program_id) { '11111111111111111111111111111111' }

  describe '#initialize' do
    it 'assigns connection' do
      expect(subject.connection).to eq(connection)
    end

    it 'assigns program_id' do
      expect(subject.program_id).to eq(program_id)
    end
  end
end
