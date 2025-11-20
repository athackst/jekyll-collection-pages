# frozen_string_literal: true

require 'spec_helper'

describe Jekyll::CollectionPages::TagPager do
  let(:posts) { (1..10).map { |i| "p#{i}" } } # simple stand-in "posts" array
  let(:indexfile) { 'index.html' }

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
      pager = described_class.new(2, '3', posts)

      expect(pager.page).to eq(2)
      expect(pager.per_page).to eq(3)           # "3".to_i => 3
      expect(pager.posts).to eq(%w[p4 p5 p6])   # page 2 slice
      expect(pager.total_posts).to eq(10)
      expect(pager.total_pages).to eq(4)        # 10/3 => 3.34 => 4
      expect(pager.previous_page).to eq(1)
      expect(pager.next_page).to eq(3)
    end

    it 'returns all posts when per_page.to_i <= 0' do
      pager_nil = described_class.new(1, nil, posts)
      expect(pager_nil.per_page).to eq(0)
      expect(pager_nil.posts).to eq(posts)
      expect(pager_nil.total_posts).to eq(10)
      expect(pager_nil.total_pages).to eq(1)
      expect(pager_nil.previous_page).to eq(nil)
      expect(pager_nil.next_page).to eq(nil)

      pager_zero = described_class.new(1, 0, posts)
      expect(pager_zero.per_page).to eq(0)
      expect(pager_zero.posts).to eq(posts)
      expect(pager_zero.total_posts).to eq(10)
      expect(pager_zero.total_pages).to eq(1)
      expect(pager_zero.previous_page).to eq(nil)
      expect(pager_zero.next_page).to eq(nil)

      pager_neg = described_class.new(1, -2, posts)
      expect(pager_neg.per_page).to eq(0)
      expect(pager_neg.posts).to eq(posts)
      expect(pager_neg.total_posts).to eq(10)
      expect(pager_neg.total_pages).to eq(1)
      expect(pager_neg.previous_page).to eq(nil)
      expect(pager_neg.next_page).to eq(nil)
    end

    it 'returns empty slice when page is beyond range' do
      pager = described_class.new(5, 3, posts) # pages would be 4 total
      expect(pager.page).to eq(5)
      expect(pager.per_page).to eq(3)
      expect(pager.posts).to eq([])
      expect(pager.total_posts).to eq(10)
      expect(pager.total_pages).to eq(4)
      expect(pager.previous_page).to eq(4)
      expect(pager.next_page).to eq(nil)
    end

    it 'sets previous/next for a middle page' do
      pager = described_class.new(2, 4, posts)

      expect(pager.page).to eq(2)
      expect(pager.per_page).to eq(4)
      expect(pager.posts).to eq(%w[p5 p6 p7 p8])
      expect(pager.total_posts).to eq(10)
      expect(pager.total_pages).to eq(3)
      expect(pager.previous_page).to eq(1)
      expect(pager.next_page).to eq(3)
    end

    it 'returns nil previous/next for nil per_page' do
      pager = described_class.new(1, nil, posts)

      expect(pager.page).to eq(1)
      expect(pager.per_page).to eq(0)
      expect(pager.posts).to eq(%w[p1 p2 p3 p4 p5 p6 p7 p8 p9 p10])
      expect(pager.total_posts).to eq(10)
      expect(pager.total_pages).to eq(1)
      expect(pager.previous_page).to eq(nil)
      expect(pager.next_page).to eq(nil)
    end

    it 'returns nil for previous on first page' do
      first = described_class.new(1, 4, posts)

      expect(first.previous_page).to be_nil
      expect(first.next_page).to eq(2)
    end

    it 'returns nil for next on last page' do
      last = described_class.new(3, 4, posts) # 10/4 => 3 pages

      expect(last.previous_page).to eq(2)
      expect(last.next_page).to be_nil
    end
  end

  describe '#to_liquid' do
    let(:posts) { (1..20).map { |i| double("Post#{i}") } }
    let(:per_page) { 6 }

    it 'exposes the paginator attributes as a hash' do
      pager = described_class.new(1, per_page, posts)

      expect(pager.to_liquid).to include(
        'page' => 1,
        'per_page' => per_page,
        'total_posts' => posts.size,
        'total_pages' => 4,
        'next_page' => 2
      )
    end
  end
end
