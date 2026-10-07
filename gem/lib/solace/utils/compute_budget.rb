# frozen_string_literal: true

module Solace
  module Utils
    # The compute budget a transaction composer carries as a setting
    #
    # Holds the compute unit limit and price, answers the ComputeBudget composers
    # they translate to (limit then price), and decides which directly added
    # ComputeBudget composers the setting supersedes so the budget is never
    # declared twice. Instances are immutable; {#merge} answers a new one.
    #
    # @example
    #   budget = Solace::Utils::ComputeBudget.new(units: 200_000, micro_lamports: 50_000)
    #   budget.composers # => [SetComputeUnitLimit composer, SetComputeUnitPrice composer]
    #
    # @see Solace::TransactionComposer#set_compute_budget
    # @since 0.1.9
    class ComputeBudget
      # The composer a compute unit limit translates to
      LIMIT_COMPOSER = Composers::ComputeBudgetProgramSetComputeUnitLimitComposer
      private_constant :LIMIT_COMPOSER

      # The composer a compute unit price translates to
      PRICE_COMPOSER = Composers::ComputeBudgetProgramSetComputeUnitPriceComposer
      private_constant :PRICE_COMPOSER

      # @!attribute units
      #   The compute unit limit, or nil when none is set
      attr_reader :units

      # @!attribute micro_lamports
      #   The compute unit price in micro-lamports, or nil when none is set
      attr_reader :micro_lamports

      # Initialize the compute budget
      #
      # @param units [Integer, nil] The compute unit limit
      # @param micro_lamports [Integer, nil] The compute unit price in micro-lamports
      def initialize(units: nil, micro_lamports: nil)
        @units          = units
        @micro_lamports = micro_lamports
      end

      # Whether any part of the budget is set
      #
      # @return [Boolean]
      def set?
        !(units.nil? && micro_lamports.nil?)
      end

      # The ComputeBudget composers the budget translates to, limit then price
      #
      # @return [Array<Composers::Base>] The composers, empty when nothing is set
      def composers
        [
          (LIMIT_COMPOSER.new(units: units) if units),
          (PRICE_COMPOSER.new(micro_lamports: micro_lamports) if micro_lamports)
        ].compact
      end

      # Whether a directly added composer is replaced by a setting of the same kind
      #
      # @param composer [Composers::Base] The added composer
      # @return [Boolean]
      def supersedes?(composer)
        (!units.nil? && composer.is_a?(LIMIT_COMPOSER)) || (!micro_lamports.nil? && composer.is_a?(PRICE_COMPOSER))
      end

      # A budget with the other's settings where it has them, and this one's otherwise
      #
      # @param other [ComputeBudget] The budget to fold in
      # @return [ComputeBudget] The merged budget
      def merge(other)
        self.class.new(
          units:          other.units || units,
          micro_lamports: other.micro_lamports || micro_lamports
        )
      end
    end
  end
end
