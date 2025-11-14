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
      reference_pages = site.pages.select { |page| page.data['tag'] == 'Reference' }
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
end

describe Jekyll::TagIndexPage do
  let(:site) { make_site }
  let(:layout) { '_layouts/tags.html' }
  let(:posts) { [] }
  let(:attributes) do
    {
      dir: 'tag_dir',
      name: 'index.html',
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
    subject { described_class.new(site, attributes.merge(paginator: paginator)) }
    let(:resolver) { instance_double(Jekyll::CollectionPages::PathTemplate) }
    let(:paginator) { Jekyll::TagPager.new(1, 1, posts, resolver) }

    it 'initializes with paginator' do
      expect(subject.data['paginator']).to be_a(Jekyll::TagPager)
      expect(subject.data['paginator']).to eq(paginator)
    end
  end
end

describe Jekyll::TagPager do
  let(:posts) { (1..10).map { |i| "p#{i}" } } # simple stand-in "posts" array
  let(:indexfile) { 'index.html' }
  let(:resolver) { instance_double('TagPath') }

  before do
    # The class references Jekyll::CollectionPages::INDEXFILE; stub it explicitly
    stub_const('Jekyll::CollectionPages::INDEXFILE', indexfile)
  end

  describe '.calculate_pages' do
    it 'returns 1 when per_page.to_i <= 0 (nil, 0, negative)' do
      expect(described_class.calculate_pages(posts, nil)).to eq(1) # nil.to_i => 0
      expect(described_class.calculate_pages(posts, 0)).to eq(1)
      expect(described_class.calculate_pages(posts, -5)).to eq(1)
    end

    it 'return total pages given posts' do
      expect(described_class.calculate_pages(posts, 4)).to eq(3) # 10/4 => 3
      expect(described_class.calculate_pages(posts, 5)).to eq(2)
      expect(described_class.calculate_pages(posts, 10)).to eq(1)
      expect(described_class.calculate_pages(posts, 11)).to eq(1)
    end

    it 'accepts numeric strings via to_i' do
      expect(described_class.calculate_pages(posts, '3')).to eq(4)
    end
  end

  describe '#initialize and slicing' do
    it 'stores page, per_page (to_i), totals and slices posts' do
      expect(resolver).to receive(:url_for).with(1).and_return('/tags/ruby/index.html')
      expect(resolver).to receive(:url_for).with(3).and_return('/tags/ruby/page3.html')
      pager = described_class.new(2, '3', posts, resolver)

      expect(pager.page).to eq(2)
      expect(pager.per_page).to eq(3)           # "3".to_i => 3
      expect(pager.posts).to eq(%w[p4 p5 p6])   # page 2 slice
      expect(pager.total_posts).to eq(10)
      expect(pager.total_pages).to eq(4)        # 10/3 => 3.34 => 4
      expect(pager.previous_page).to eq(1)
      expect(pager.previous_page_path).to eq('/tags/ruby/index.html')
      expect(pager.next_page).to eq(3)
      expect(pager.next_page_path).to eq('/tags/ruby/page3.html')
    end

    it 'returns all posts when per_page.to_i <= 0' do
      pager_nil = described_class.new(1, nil, posts, resolver)
      expect(pager_nil.per_page).to eq(0)
      expect(pager_nil.posts).to eq(posts)
      expect(pager_nil.total_posts).to eq(10)
      expect(pager_nil.total_pages).to eq(1)
      expect(pager_nil.previous_page).to eq(nil)
      expect(pager_nil.previous_page_path).to eq(nil)
      expect(pager_nil.next_page).to eq(nil)
      expect(pager_nil.next_page_path).to eq(nil)

      pager_zero = described_class.new(1, 0, posts, resolver)
      expect(pager_zero.per_page).to eq(0)
      expect(pager_zero.posts).to eq(posts)
      expect(pager_zero.total_posts).to eq(10)
      expect(pager_zero.total_pages).to eq(1)
      expect(pager_zero.previous_page).to eq(nil)
      expect(pager_zero.previous_page_path).to eq(nil)
      expect(pager_zero.next_page).to eq(nil)
      expect(pager_zero.next_page_path).to eq(nil)

      pager_neg = described_class.new(1, -2, posts, resolver)
      expect(pager_neg.per_page).to eq(0)
      expect(pager_neg.posts).to eq(posts)
      expect(pager_neg.total_posts).to eq(10)
      expect(pager_neg.total_pages).to eq(1)
      expect(pager_neg.previous_page).to eq(nil)
      expect(pager_neg.previous_page_path).to eq(nil)
      expect(pager_neg.next_page).to eq(nil)
      expect(pager_neg.next_page_path).to eq(nil)
    end

    it 'returns empty slice when page is beyond range' do
      expect(resolver).to receive(:url_for).with(4).and_return('/tags/ruby/page4.html')
      pager = described_class.new(5, 3, posts, resolver) # pages would be 4 total
      expect(pager.page).to eq(5)
      expect(pager.per_page).to eq(3)
      expect(pager.posts).to eq([])
      expect(pager.total_posts).to eq(10)
      expect(pager.total_pages).to eq(4)
      expect(pager.previous_page).to eq(4)
      expect(pager.previous_page_path).to eq('/tags/ruby/page4.html')
      expect(pager.next_page).to eq(nil)
      expect(pager.next_page_path).to eq(nil)
    end

    it 'sets previous/next for a middle page' do
      expect(resolver).to receive(:url_for).with(1).and_return('/tags/ruby/index.html')
      expect(resolver).to receive(:url_for).with(3).and_return('/tags/ruby/page3.html')
      pager = described_class.new(2, 4, posts, resolver)

      expect(pager.page).to eq(2)
      expect(pager.per_page).to eq(4)
      expect(pager.posts).to eq(%w[p5 p6 p7 p8])
      expect(pager.total_posts).to eq(10)
      expect(pager.total_pages).to eq(3)
      expect(pager.previous_page).to eq(1)
      expect(pager.previous_page_path).to eq('/tags/ruby/index.html')
      expect(pager.next_page).to eq(3)
      expect(pager.next_page_path).to eq('/tags/ruby/page3.html')
    end

    it 'returns nil previous/next for nil per_page' do
      pager = described_class.new(1, nil, posts, resolver)

      expect(pager.page).to eq(1)
      expect(pager.per_page).to eq(0)
      expect(pager.posts).to eq(%w[p1 p2 p3 p4 p5 p6 p7 p8 p9 p10])
      expect(pager.total_posts).to eq(10)
      expect(pager.total_pages).to eq(1)
      expect(pager.previous_page).to eq(nil)
      expect(pager.previous_page_path).to eq(nil)
      expect(pager.next_page).to eq(nil)
      expect(pager.next_page_path).to eq(nil)
    end

    it 'returns nil for previous on first page' do
      expect(resolver).to receive(:url_for).with(2).and_return('/tags/ruby/page2.html')
      first = described_class.new(1, 4, posts, resolver)

      expect(first.previous_page).to be_nil
      expect(first.previous_page_path).to be_nil
      expect(first.next_page).to eq(2)
      expect(first.next_page_path).to eq('/tags/ruby/page2.html')
    end

    it 'returns nil for next on last page' do
      expect(resolver).to receive(:url_for).with(2).and_return('/tags/ruby/page2.html')
      last = described_class.new(3, 4, posts, resolver) # 10/4 => 3 pages

      expect(last.previous_page).to eq(2)
      expect(last.previous_page_path).to eq('/tags/ruby/page2.html')
      expect(last.next_page).to be_nil
      expect(last.next_page_path).to be_nil
    end
  end

  describe '#to_liquid' do
    let(:posts) { (1..20).map { |i| double("Post#{i}") } }
    let(:per_page) { 6 }
    let(:resolver) { instance_double('TagPath') }

    it 'exposes the paginator attributes as a hash' do
      expect(resolver).to receive(:url_for).with(2).and_return('page2.html')
      pager = described_class.new(1, per_page, posts, resolver)

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
