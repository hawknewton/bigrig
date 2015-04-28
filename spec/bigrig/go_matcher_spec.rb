module Bigrig
  describe GoMatcher do
    it 'treats leading slash as optional' do
      expect(GoMatcher.new('/test').matches? 'test').to be true
      expect(GoMatcher.new('test').matches? 'test').to be true
    end

    it 'ignores unmatched trailing portion of the path' do
      expect(GoMatcher.new('test').matches? 'test/123').to be true
      expect(GoMatcher.new('test').matches? 'test123/123').to be false
    end

    it 'matches subdirectories' do
      expect(GoMatcher.new('test/123').matches? 'test/123').to be true
    end

    it 'escapes regex characters' do
      expect(GoMatcher.new('...').matches? '...').to be true
      expect(GoMatcher.new('...').matches? 'abc').to be false
      expect(GoMatcher.new('(').matches? '(').to be true
      expect(GoMatcher.new(')').matches? ')').to be true
      expect(GoMatcher.new('+').matches? '+').to be true
      expect(GoMatcher.new('{').matches? '{').to be true
      expect(GoMatcher.new('}').matches? '}').to be true
    end

    describe '*' do
      it 'matches any sequence of non-Separator characters' do
        expect(GoMatcher.new('test/*/123').matches? 'test/321/123').to be true
        expect(GoMatcher.new('*/*/123').matches? 'test/321/123').to be true
        expect(GoMatcher.new('*/*/*').matches? 'test/321/123').to be true

        expect(GoMatcher.new('*/123').matches? 'test/321/123').to be false
      end
    end

    describe '?' do
      it 'matches any single non-Separator character' do
        expect(GoMatcher.new('/?est').matches? 'test').to be true
      end
    end

    describe '[]' do
      it 'matches a range of characters' do
        expect(GoMatcher.new('[t]est').matches? 'test').to be true
        expect(GoMatcher.new('[123t]est').matches? 'test').to be true
        expect(GoMatcher.new('[a-z]est').matches? 'test').to be true
        expect(GoMatcher.new('[b]est').matches? 'test').to be false
      end
    end

    describe '[^]' do
      it 'negates a range of characters' do
        expect(GoMatcher.new('[^t]est').matches? 'test').to be false
      end
    end

    describe 'c' do
      it %{matches character c (c != '\\', '-', ']')} do
        expect(GoMatcher.new('t').matches? 't').to be true
        expect(GoMatcher.new('t').matches? 'test').to be false
      end
    end

    describe '\\\\c' do
      it 'matches character c' do
        expect(GoMatcher.new('\\[').matches? '[').to be true
        expect(GoMatcher.new('\\-').matches? '-').to be true
      end

      it 'matches \\' do
        expect(GoMatcher.new('\\\\').matches? '\\').to be true
      end
    end
  end
end
