# frozen_string_literal: true

require 'spec_helper'

describe Jekyll::CollectionPages::TagPage do
  let(:site) { make_site }
  let(:posts) { [] }
  let(:attributes) do
    {
      dir: 'tag_dir',
      name: 'index.html',
      tag: 'test_tag',
      title: 'Test Tag',
      layout: 'tags',
      posts: posts,
      page_num: 2
    }
  end

  context 'without pagination' do
    subject { described_class.new(site, attributes) }

    it 'initializes correctly' do
      expect(subject.data['title']).to eq(attributes[:title])
      expect(subject.data['tag']).to eq(attributes[:tag])
      expect(subject.data['layout']).to eq('tags')
      expect(subject.data['posts']).to eq(posts)
      expect(subject.data['page_num']).to eq(2)
      expect(subject.data['paginator']).to be_nil
    end
  end

  context 'with pagination' do
    subject { described_class.new(site, attributes.merge(paginator: paginator)) }
    let(:paginator) { Jekyll::CollectionPages::TagPager.new(1, 1, posts) }

    it 'initializes with paginator' do
      expect(subject.data['paginator']).to be_a(Jekyll::CollectionPages::TagPager)
      expect(subject.data['paginator']).to eq(paginator)
    end
  end
end
