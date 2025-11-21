# frozen_string_literal: true

require 'spec_helper'

describe Jekyll::CollectionPages::CollectionPages do
  let(:site) { make_site }
  let(:generator) { described_class.new }

  context 'with single collection configuration' do
    before do
      site.config['collection_pages'] = {
        'collection' => 'docs',
        'field' => 'category',
        'path' => 'docs/category',
        'layout' => 'category_layout.html',
        'paginate' => 6
      }
    end

    it 'generates tag pages for the specified collection' do
      generator.generate(site)
      expect(site.pages).not_to be_empty
      expect(site.pages.first).to be_a(Jekyll::CollectionPages::TagPage)
      collection_data = site.data['collection_pages']
      expect(collection_data).to include('docs')
      field_info = collection_data['docs']['category']
      field_map = field_info['pages']
      expect(field_map.keys).to include('Getting Started', 'Reference', 'Usage')
      field_map.each_value do |documents|
        expect(documents).not_to be_empty
        expect(documents.all? { |doc| doc.is_a?(Jekyll::Document) }).to be true
      end
      expect(field_info['template']).to eq('/docs/category/:field/page:num/index.html')
      expect(field_info['permalink']).to eq('/docs/category/:field/')
      labels = field_info['labels']
      expect(labels.keys).to include('Getting Started', 'Reference', 'Usage')
      labels.each_value do |entry|
        expect(entry['pages']).not_to be_empty
        expect(entry['index']).to be_a(Jekyll::CollectionPages::TagPage)
      end
    end
  end

  context 'with multiple collections configuration' do
    before do
      site.config['collection_pages'] = [
        {
          'collection' => 'docs',
          'field' => 'category',
          'path' => 'docs/category',
          'layout' => 'category_layout.html',
          'paginate' => 6
        },
        {
          'collection' => 'articles',
          'field' => 'tags',
          'path' => 'articles/tags',
          'layout' => 'tags.html',
          'paginate' => 6
        }
      ]
    end

    it 'generates tag pages for multiple collections' do
      generator.generate(site)
      expect(site.pages).not_to be_empty
      expect(site.pages.count).to be > 1
      expect(site.pages.all? { |page| page.is_a?(Jekyll::CollectionPages::TagPage) }).to be true
      collection_data = site.data['collection_pages']
      expect(collection_data.keys).to include('docs', 'articles')
      docs_info = collection_data['docs']['category']
      articles_info = collection_data['articles']['tags']
      expect(docs_info).not_to be_nil
      expect(articles_info).not_to be_nil

      docs_field_map = docs_info['pages']
      articles_field_map = articles_info['pages']
      expect(docs_field_map.values.flatten).not_to be_empty
      expect(articles_field_map.values.flatten).not_to be_empty

      expect(docs_info['template']).to eq('/docs/category/:field/page:num/index.html')
      expect(docs_info['permalink']).to eq('/docs/category/:field/')
      expect(articles_info['template']).to eq('/articles/tags/:field/page:num/index.html')
      expect(articles_info['permalink']).to eq('/articles/tags/:field/')

      expect(docs_info['labels'].values.flat_map { |entry| entry['pages'] }).not_to be_empty
      expect(articles_info['labels'].values.flat_map { |entry| entry['pages'] }).not_to be_empty
    end
  end

  context 'with path templates containing :field and :num' do
    before do
      site.config['collection_pages'] = {
        'collection' => 'docs',
        'field' => 'category',
        'path' => 'docs/:field/page:num',
        'layout' => 'category_layout.html',
        'paginate' => 1
      }
    end

    it 'creates nested directories for paginated pages' do
      generator.generate(site)
      reference_pages = site.pages.select { |page| page.data['tag'] == 'reference' }
      urls = reference_pages.map(&:url)

      expect(urls).to include('/docs/reference/')
      expect(urls).to include('/docs/reference/page2/')
    end
  end

  context 'with non-positive paginate value' do
    [0, -5].each do |non_positive|
      it "falls back to single page generation when paginate is #{non_positive}" do
        site.config['collection_pages'] = {
          'collection' => 'docs',
          'field' => 'category',
          'path' => 'docs/category',
          'layout' => 'category_layout.html',
          'paginate' => non_positive
        }

        generator.generate(site)
        field_info = site.data['collection_pages']['docs']['category']
        field_info['labels'].each_value do |entry|
          expect(entry['pages'].size).to eq(1)
          expect(entry['paginate']).to be_nil
        end
      end
    end
  end

  context 'with non-numeric paginate value' do
    it 'raises an informative error' do
      site.config['collection_pages'] = {
        'collection' => 'docs',
        'field' => 'category',
        'path' => 'docs/category',
        'layout' => 'category_layout.html',
        'paginate' => 'ten'
      }

      expect { generator.generate(site) }
        .to raise_error(ArgumentError, /paginate value .*numeric/i)
    end
  end

  context 'with invalid collection_pages configuration shape' do
    it 'logs an error and skips generation' do
      site.config['collection_pages'] = 'not-a-hash-or-array'
      allow(Jekyll.logger).to receive(:error)

      generator.generate(site)

      expect(Jekyll.logger).to have_received(:error).with('CollectionPages:', 'Invalid configuration.')
      expect(site.pages).to be_empty
      expect(site.data['collection_pages']).to be_nil
    end
  end

  context 'with an array containing invalid entries' do
    it 'logs the bad entry and raises an error' do
      valid_config = {
        'collection' => 'docs',
        'field' => 'category',
        'path' => 'docs/category',
        'layout' => 'category_layout.html',
        'paginate' => 2
      }
      site.config['collection_pages'] = [valid_config, 'oops']
      allow(Jekyll.logger).to receive(:error)

      expect { generator.generate(site) }.to raise_error(ArgumentError, /Invalid/)

      expect(Jekyll.logger).to have_received(:error).with('CollectionPages:', /Invalid collection config entry/)
    end
  end
end
