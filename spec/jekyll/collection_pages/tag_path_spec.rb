# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jekyll::CollectionPages::TagPath do
  let(:template) { '/docs/category/:field/page:num/index.html' }
  let(:tag_path) { described_class.new(template, field_value) }
  let(:field_value) { 'Alpha Tag' }

  describe '#tag' do
    it 'slugifies the field value' do
      expect(tag_path.tag).to eq('alpha-tag')
    end
  end

  describe '#dir_for' do
    it 'returns the base directory for the first page' do
      expect(tag_path.dir_for(1)).to eq('docs/category/alpha-tag')
    end

    it 'includes the page segment for subsequent pages' do
      expect(tag_path.dir_for(3)).to eq('docs/category/alpha-tag/page3')
    end
  end

  describe '#filename_for' do
    it 'returns index file for the first page' do
      expect(tag_path.filename_for(1)).to eq(Jekyll::CollectionPages::INDEXFILE)
    end

    it 'returns the template filename for later pages' do
      expect(tag_path.filename_for(2)).to eq('index.html')
    end
  end

  describe '#url_for' do
    it 'returns a trailing slash url for the first page' do
      expect(tag_path.url_for(1)).to eq('/docs/category/alpha-tag/')
    end

    it 'appends the page segment for later pages' do
      expect(tag_path.url_for(2)).to eq('/docs/category/alpha-tag/page2/')
    end
  end

  context 'with a file-style template' do
    let(:template) { '/docs/category/:field.html' }

    describe '#dir_for' do
      it 'returns the containing directory' do
        expect(tag_path.dir_for(1)).to eq('docs/category')
      end
    end

    describe '#filename_for' do
      it 'returns the substituted filename for the first page' do
        expect(tag_path.filename_for(1)).to eq('alpha-tag.html')
      end
    end

    describe '#url_for' do
      it 'returns the file permalink for the first page' do
        expect(tag_path.url_for(1)).to eq('/docs/category/alpha-tag.html')
      end
    end
  end
end
