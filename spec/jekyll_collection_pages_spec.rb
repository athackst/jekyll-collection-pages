# frozen_string_literal: true

require 'spec_helper'

describe Jekyll::CollectionPages::TagPagination do
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
      expect(site.pages.first).to be_a(Jekyll::TagIndexPage)
      collection_data = site.data['collection_pages']
      expect(collection_data).to include('docs')
      field_info = collection_data['docs']['category']
      field_map = field_info['pages']
      expect(field_map.keys).to include('Getting Started', 'Reference', 'Usage')
      field_map.each_value do |documents|
        expect(documents).not_to be_empty
        expect(documents.all? { |doc| doc.is_a?(Jekyll::Document) }).to be true
      end
      expect(field_info['field']).to eq('category')
      expect(field_info['path']).to eq('docs/category')
      expect(field_info['permalink']).to eq('docs/category/:category')
      labels = field_info['labels']
      expect(labels.keys).to include('Getting Started', 'Reference', 'Usage')
      labels.each_value do |entry|
        expect(entry['pages']).not_to be_empty
        expect(entry['page']).to be_a(Jekyll::TagIndexPage)
        expect(entry['path']).not_to be_empty
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
      expect(site.pages.all? { |page| page.is_a?(Jekyll::TagIndexPage) }).to be true
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

      expect(docs_info['field']).to eq('category')
      expect(docs_info['path']).to eq('docs/category')
      expect(docs_info['permalink']).to eq('docs/category/:category')
      expect(articles_info['field']).to eq('tags')
      expect(articles_info['path']).to eq('articles/tags')
      expect(articles_info['permalink']).to eq('articles/tags/:tags')

      expect(docs_info['labels'].values.flat_map { |entry| entry['pages'] }).not_to be_empty
      expect(articles_info['labels'].values.flat_map { |entry| entry['pages'] }).not_to be_empty
    end
  end
end

describe Jekyll::TagIndexPage do
  let(:site) { make_site }
  let(:layout) { '_layouts/tags.html' }
  let(:posts) { [] }
  let(:attributes) do
    {
      dir: 'tag_dir',
      page_number: 1,
      tag: 'test_tag',
      layout: layout,
      posts: posts
    }
  end

  context 'without pagination' do
    subject { described_class.new(site, attributes) }

    it 'initializes correctly' do
      expect(subject.data['tag']).to eq(attributes[:tag])
      expect(subject.data['layout']).to eq(File.basename(layout, '.*'))
      expect(subject.data['posts']).to eq(posts)
      expect(subject.data['paginator']).to be_nil
    end
  end

  context 'with pagination' do
    let(:paginator) { Jekyll::TagPager.new(1, 1, posts) }
    subject { described_class.new(site, attributes.merge(paginator: paginator)) }

    it 'initializes with paginator' do
      expect(subject.data['paginator']).to be_a(Jekyll::TagPager)
      expect(subject.data['paginator']).to eq(paginator)
    end
  end

  context 'with invalid attributes' do
    it 'raises when required keys are missing' do
      expect { described_class.new(site, attributes.except(:dir)) }
        .to raise_error(ArgumentError, /Missing TagIndexPage attributes: dir/)
    end

    it 'raises when layout is blank' do
      expect { described_class.new(site, attributes.merge(layout: '')) }
        .to raise_error(ArgumentError, /layout must be a non-empty string/)
    end

    it 'raises when page number is not positive' do
      expect { described_class.new(site, attributes.merge(page_number: 0)) }
        .to raise_error(ArgumentError, /page_number must be a positive integer/)
    end
  end
end

describe Jekyll::TagPager do
  describe '.calculate_pages' do
    let(:posts) { Array.new(10) }

    it 'returns total page count for a positive per_page' do
      expect(described_class.calculate_pages(posts, 4)).to eq(3)
    end

    it 'returns zero when per_page is zero or less' do
      expect(described_class.calculate_pages(posts, 0)).to eq(0)
      expect(described_class.calculate_pages(posts, -2)).to eq(0)
    end
  end

  describe '#initialize' do
    let(:posts) { (1..20).map { |i| double("Post#{i}") } }
    let(:per_page) { 6 }
    subject(:pager) { described_class.new(2, per_page, posts) }

    it 'normalizes per_page and computes totals' do
      expect(pager.page).to eq(2)
      expect(pager.per_page).to eq(per_page)
      expect(pager.total_posts).to eq(posts.size)
      expect(pager.total_pages).to eq(4)
    end

    it 'slices the posts for the current page' do
      expect(pager.posts).to eq(posts.slice(6, per_page))
    end
  end

  describe '#update_navigation' do
    let(:posts) { (1..20).map { |i| double("Post#{i}") } }
    let(:per_page) { 6 }

    it 'defaults to the calculated total pages' do
      pager = described_class.new(1, per_page, posts)
      pager.update_navigation

      expect(pager.previous_page).to be_nil
      expect(pager.previous_page_path).to be_nil
      expect(pager.next_page).to eq(2)
      expect(pager.next_page_path).to eq('page2.html')
    end

    it 'allows overriding total pages' do
      pager = described_class.new(3, per_page, posts)
      pager.update_navigation(10)

      expect(pager.previous_page).to eq(2)
      expect(pager.previous_page_path).to eq('page2.html')
      expect(pager.next_page).to eq(4)
      expect(pager.next_page_path).to eq('page4.html')
    end
  end

  describe '#to_liquid' do
    let(:posts) { (1..20).map { |i| double("Post#{i}") } }
    let(:per_page) { 6 }

    it 'exposes the paginator attributes as a hash' do
      pager = described_class.new(1, per_page, posts)
      pager.update_navigation

      expect(pager.to_liquid).to include(
        'page' => 1,
        'per_page' => per_page,
        'total_posts' => posts.size,
        'total_pages' => 4,
        'next_page' => 2,
        'next_page_path' => 'page2.html'
      )
    end
  end
end
