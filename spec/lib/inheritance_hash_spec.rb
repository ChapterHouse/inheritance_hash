require 'spec_helper'


describe InheritanceHash do

  let(:parent) { InheritanceHash[:a, 1, :b, 2, :c, 3, :z, 10] }
  let(:child)  { InheritanceHash[:d, 4, :e, 5, :f, 6, :z, 11].tap { |x| x.inherit_from(parent)} }
  let(:child2) { InheritanceHash[:g, 7, :h, 8, :i, 9, :z, 12].tap { |x| x.inherit_from(parent)} }

  context '.[]' do

    it 'accepts a list of key value pairs' do
      expect(InheritanceHash[:a, 1, :b, 2]).to eql(Hash[:a, 1, :b, 2])
    end

    it 'accepts an object convertible to a hash' do
      hash = {:a => 1, :b => 2}
      expect(InheritanceHash[hash]).to eql(Hash[hash])
    end

    it 'accepts an array of key value pairs' do
      array = [[:a, 1], [:b, 2]]
      expect(InheritanceHash[array]).to eql(Hash[array])
    end

    it 'throws an error if given a list with an odd number of arguments' do
      expect { InheritanceHash[1, 2, 3] }.to raise_error(ArgumentError)
    end

  end

  context '[]'  do

    it 'acts like a Hash but returns values from within itself or the parent' do
      expect(parent[:a]).to equal(1)
      expect(child[:a]).to equal(1)
      expect(child2[:a]).to equal(1)
    end

    it 'returns its own values over that of the parent\'s' do
      expect(child[:z]).to equal(11)
      expect(child2[:z]).to equal(12)
    end

    it 'does not return values from siblings' do
      expect(child[:d]).to_not be_nil
      expect(child2[:d]).to be_nil
    end


  end

  context '[]=' do

    it 'propagates the values to children' do
      parent[:Q] = 101
      expect(child[:Q]).to equal(101)
    end

    it 'does not propagate the values to parents or siblings' do
      child[:Q] = 101
      expect(parent[:Q]).to be_nil
      expect(child2[:Q]).to be_nil
    end

    it 'does not change existing child values' do
      parent[:d] = 101
      expect(child[:d]).to equal(4)
    end

  end

  context 'delete' do

    it 'deletes values from children if they are being inherited' do
      parent.delete(:a)
      expect(parent[:a]).to be_nil
      expect(child[:a]).to be_nil
    end

    it 'does not delete values from parents' do
      child.delete(:a)
      expect(child[:a]).to be_nil
      expect(parent[:a]).to equal(1)
    end

    it 'does not delete values from children if they have a local value of the same key' do
      child[:a] = 101
      parent.delete(:a)
      expect(parent[:a]).to be_nil
      expect(child[:a]).to equal(101)
    end

    it 'falls back to the inherited value if local value is deleted' do
      child[:a] = 101
      child.delete(:a)
      expect(child[:a]).to equal(parent[:a])
    end

  end

  context 'dont_inherit' do

    it 'prevents a value from being inherited from a parent' do
      expect(child[:a]).to_not be_nil
      child.dont_inherit(:a)
      expect(child[:a]).to be_nil
      expect(parent[:a]).to_not be_nil
      parent[:a] = 101
      expect(child[:a]).to be_nil
    end

  end


  context 'fetch'  do

    it 'acts like a Hash but returns values from within itself or the parent' do
      expect(parent.fetch(:a)).to equal(1)
      expect(child.fetch(:a)).to equal(1)
      expect(child2.fetch(:a)).to equal(1)
    end

    it 'returns its own values over that of the parent\'s' do
      expect(child.fetch(:z)).to equal(11)
      expect(child2.fetch(:z)).to equal(12)
    end

    it 'does not return values from siblings' do
      expect(child.fetch(:d)).to_not be_nil
      expect { child2.fetch(:d) }.to raise_error(KeyError)
    end


  end

  context 'inherit' do

    it 'reinherits a value that previously was disinherited' do
      child.dont_inherit(:a)
      expect(child[:a]).to be_nil
      child.inherit(:a)
      expect(child[:a]).to equal(parent[:a])
    end

  end

end







