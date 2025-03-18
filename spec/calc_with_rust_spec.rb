# frozen_string_literal: true

RSpec.describe CalcWithRust do
  it 'has a version number' do
    expect(CalcWithRust::VERSION).not_to be nil
  end

  describe 'primes' do
    context 'rubyコードを使うとき' do
      it '素数が取得できる' do
        expect(CalcWithRust::Ruby.primes(10)).to eq [2, 3, 5, 7]
      end
    end
  end
end
