# frozen_string_literal: true

module RuboCop
  module Cop
    module Solace
      # Every pair in a braced hash starts on its own line.
      #
      # A hash is read as a table: a reader scanning for one key, or diffing two
      # of them, works down the left edge. Collapsing pairs onto a shared line
      # hides a key mid-line and makes a one-key change show up as a rewritten
      # line. Length is not the test — a short hash collapses just as badly as a
      # long one, which is why the built-in layout cops are not enough: they only
      # act once a hash is already multi-line.
      #
      # Only a hash written on one line is this cop's business. Once a hash spans
      # lines, Layout/FirstHashElementLineBreak and Layout/MultilineHashKeyLineBreaks
      # already break every pair onto its own line, and a second cop inserting the
      # same break in the same correction loop leaves a blank line behind.
      #
      # Two more restrictions keep it from reaching where it does not belong. A
      # hash of one pair is left inline, since it is already the only thing on
      # its line. And only BRACED hashes are checked: a keyword argument list is
      # a hash node too, and exploding it would break up every multi-argument
      # call in the codebase.
      #
      # @example
      #   # bad
      #   page_id: { type: 'string', format: 'uuid' }
      #
      #   # good
      #   page_id: {
      #     type: 'string',
      #     format: 'uuid'
      #   }
      #
      #   # good — one pair, and a keyword argument list
      #   { user: payload[:user_id] }
      #   create(:user, name: 'Ada', email: 'ada@example.com')
      class ExplodedHash < Base
        extend AutoCorrector

        MSG = 'Each pair in a hash starts on its own line.'

        def on_hash(node)
          pairs = braced_pairs(node)
          return unless pairs

          pairs.each { |pair| flag(pair) }
        end

        private

        # Nil for anything this cop leaves alone: a hash already spanning lines,
        # a keyword argument list, which carries no braces, and a hash of a
        # single pair.
        def braced_pairs(node)
          return unless node.loc.begin
          return if node.multiline?

          pairs = node.pairs
          pairs if pairs.size >= 2
        end

        # The break replaces the space in front of the pair rather than being
        # inserted before it, or the old separator is left behind as trailing
        # whitespace. Indentation is left to Layout/FirstHashElementIndentation
        # and Layout/HashAlignment, which run in the same correction loop.
        def flag(pair)
          add_offense(pair) { |corrector| corrector.replace(leading_space(pair), "\n") }
        end

        def leading_space(pair)
          range  = pair.source_range
          source = range.source_buffer.source
          start  = range.begin_pos
          start -= 1 while start.positive? && [' ', "\t"].include?(source[start - 1])
          Parser::Source::Range.new(range.source_buffer, start, range.begin_pos)
        end
      end
    end
  end
end
