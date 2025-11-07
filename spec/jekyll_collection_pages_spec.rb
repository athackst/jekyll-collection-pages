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
    end
  end
end

describe Jekyll::TagIndexPage do
  let(:site) { make_site }
  let(:base_dir) { site.source }
  let(:tag) { 'test_tag' }
  let(:layout) { '_layouts/tags.html' }
  let(:posts) { [] }

  context 'without pagination' do
    subject { described_class.new(site, 'tag_dir', 1, tag, layout, posts, false, nil) }

    it 'initializes correctly' do
      expect(subject.data['tag']).to eq(tag)
      expect(subject.data['layout']).to eq(File.basename(layout, '.*'))
      expect(subject.data['posts']).to eq(posts)
    end
  end

  context 'with pagination' do
    subject { described_class.new(site, 'tag_dir', 1, tag, layout, posts, true, 6) }

    it 'initializes with paginator' do
      expect(subject.data['paginator']).to be_a(Jekyll::TagPager)
    end
  end
end

describe Jekyll::TagPager do
  let(:posts) { (1..20).map { |i| double("Post#{i}") } }
  let(:per_page) { 6 }

  subject { described_class.new(2, per_page, posts) }

  it 'calculates pages correctly' do
    expect(described_class.calculate_pages(posts, per_page)).to eq(4)
  end

  it 'initializes with correct values' do
    expect(subject.page).to eq(2)
    expect(subject.per_page).to eq(per_page)
    expect(subject.total_posts).to eq(posts.size)
    expect(subject.posts.size).to eq(per_page)
  end

  it 'sets previous and next pages correctly' do
    subject.set_previous_next(4)
    expect(subject.previous_page).to eq(1)
    expect(subject.next_page).to eq(3)
    expect(subject.previous_page_path).to eq('index.html')
    expect(subject.next_page_path).to eq('page3.html')
  end
end
