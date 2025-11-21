# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jekyll::CollectionPages::PathTemplate do
  def build(raw, field: 'category', collection: 'docs', require_num: true)
    described_class.new(raw_template: raw, tag_field: field, collection_name: collection, require_num: require_num)
  end

  describe 'defaults & sanitization' do
    it 'defaults to /<collection>/:field/page:num when path is nil' do
      tpl = build(nil)
      expect(tpl.instance_variable_get(:@template)).to eq('docs/:field/page:num/index.html')
    end

    it 'defaults to /<collection>/:field/page:num when path is empty' do
      tpl = build('')
      expect(tpl.instance_variable_get(:@template)).to eq('docs/:field/page:num/index.html')
    end

    it 'sanitizes trailing slashes' do
      tpl = build('/docs/:field/page:num/')
      expect(tpl.instance_variable_get(:@template)).to eq('docs/:field/page:num/index.html')
    end
  end

  describe 'placeholder validation' do
    it 'accepts paths that include :field' do
      tpl = build('docs/:field/page:num')
      expect(tpl.instance_variable_get(:@template)).to include(':field')
    end

    it 'accepts paths that include :num' do
      tpl = build('docs/:field/page:num')
      expect(tpl.instance_variable_get(:@template)).to include(':num')
    end

    it 'adds placeholders when path has no placeholders' do
      tpl = build('/docs/reference')
      expect(tpl.instance_variable_get(:@template)).to eq('docs/reference/:field/page:num/index.html')
    end

    it 'raises error when :field is missing and path ends with .html' do
      expect do
        build('/docs/page:num.html')
      end.to raise_error(ArgumentError, /must include a ':field' placeholder/)
    end

    it 'raises error when :num is missing and path ends with .html' do
      expect do
        build('/docs/:field/index.html')
      end.to raise_error(ArgumentError, /must include a ':num' placeholder/)
    end

    it 'adds :num when missing' do
      tpl = build('/docs/:field')
      expect(tpl.instance_variable_get(:@template)).to eq('docs/:field/page:num/index.html')
    end

    it 'raises an error when :field is missing but :num is present' do
      expect do
        build('/docs/:num')
      end.to raise_error(ArgumentError, /':field' must come before ':num'/)
    end

    it 'raises an error when :num comes before :field' do
      expect do
        build('/docs/:num/:field')
      end.to raise_error(ArgumentError, /':field' must come before ':num'/)
    end

    it 'raises an error when multiple :field placeholders are present' do
      expect do
        build('/docs/:field/:num/:field')
      end.to raise_error(ArgumentError, /must include exactly one ':field' placeholder/)
    end

    it 'raises an error when multiple :num placeholders are present' do
      expect do
        build('/docs/:field/:num/:num')
      end.to raise_error(ArgumentError, /must include exactly one ':num' placeholder/)
    end

    it 'raises an error when :field and :num are in the same file segment' do
      expect do
        build('/docs/:field:num/index.html')
      end.to raise_error(ArgumentError, /':field' and ':num' cannot be in the same file segment/)
    end

    context 'when :num is optional' do
      it 'allows html templates without :num' do
        tpl = build('docs/:field.html', require_num: false)
        expect(tpl.instance_variable_get(:@template)).to eq('docs/:field.html')
      end

      it 'does not append pagination segments' do
        tpl = build('docs/category', require_num: false)
        expect(tpl.instance_variable_get(:@template)).to eq('docs/category/:field/index.html')
      end
    end
  end
end
