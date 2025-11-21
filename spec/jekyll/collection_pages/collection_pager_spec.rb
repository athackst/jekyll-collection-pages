# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jekyll::CollectionPages::CollectionPager do
  let(:pages) { [] }
  let(:site_data) { {} }
  let(:site) { instance_double(Jekyll::Site, collections: collections, pages: pages, data: site_data) }

  before do
    stub_const('Jekyll::CollectionPages::TagPage', Class.new do
      attr_reader :attributes

      def initialize(site, attributes)
        @attributes = attributes
        @site = site
      end

      def tag
        attributes[:tag]
      end

      def page_num
        attributes[:page_num]
      end

      def posts
        attributes[:posts]
      end
    end)
  end

  describe 'tag discovery' do
    let(:collections) { { 'docs' => instance_double('Collection', docs: [doc_one, doc_two]) } }
    let(:config) do
      Jekyll::CollectionPages::CollectionConfig.new({
                                                      'collection' => 'docs',
                                                      'field' => 'category',
                                                      'path' => 'docs/category'
                                                    })
    end
    let(:doc_one) { instance_double(Jekyll::Document, data: { 'category' => %w[b a] }) }
    let(:doc_two) { instance_double(Jekyll::Document, data: { 'category' => 'c' }) }

    it 'collects tags across documents and sorts them alphabetically' do
      pager = described_class.new(site, config)

      expect(pager.instance_variable_get(:@tags_with_docs)).to eq([
                                                                    ['a', [doc_one]],
                                                                    ['b', [doc_one]],
                                                                    ['c', [doc_two]]
                                                                  ])
    end
  end

  describe '#create_pages' do
    let(:collections) { { 'docs' => instance_double('Collection', docs: documents) } }
    let(:config_hash) do
      {
        'collection' => 'docs',
        'field' => 'category',
        'path' => 'docs/category',
        'layout' => 'category_layout.html',
        'paginate' => paginate_value
      }
    end
    let(:config) { Jekyll::CollectionPages::CollectionConfig.new(config_hash) }

    context 'when collection is missing' do
      let(:collections) { {} }
      let(:documents) { [] }
      let(:paginate_value) { 2 }

      it 'sets empty metadata without generating pages' do
        described_class.new(site, config).create_pages

        expect(site.pages).to be_empty
        registry = site.data['collection_pages']['docs']['category']
        expect(registry['labels']).to eq({})
        expect(registry['pages']).to eq({})
        expect(registry['template']).to eq('/docs/category/:field/page:num/index.html')
        expect(registry['permalink']).to eq('/docs/category/:field/')
      end
    end

    context 'with pagination enabled' do
      let(:paginate_value) { 2 }
      let(:documents) { [doc_alpha_beta, doc_alpha_two, doc_alpha_three] }
      let(:doc_alpha_beta) { instance_double(Jekyll::Document, data: { 'category' => %w[alpha beta] }) }
      let(:doc_alpha_two) { instance_double(Jekyll::Document, data: { 'category' => 'alpha' }) }
      let(:doc_alpha_three) { instance_double(Jekyll::Document, data: { 'category' => 'alpha' }) }

      it 'builds tag pages and stores metadata for each tag' do
        described_class.new(site, config).create_pages

        expect(site.pages.size).to eq(3)
        alpha_pages = site.pages.select { |page| page.tag == 'alpha' }
        beta_pages = site.pages.select { |page| page.tag == 'beta' }

        expect(alpha_pages.map(&:page_num)).to eq([1, 2])
        expect(alpha_pages.first.posts).to eq([doc_alpha_beta, doc_alpha_two])
        expect(alpha_pages.last.posts).to eq([doc_alpha_three])
        expect(beta_pages.map(&:page_num)).to eq([1])
        expect(beta_pages.first.posts).to eq([doc_alpha_beta])

        first_alpha_paginator = alpha_pages.first.attributes[:paginator]
        second_alpha_paginator = alpha_pages.last.attributes[:paginator]
        expect(first_alpha_paginator['previous_page_path']).to be_nil
        expect(first_alpha_paginator['next_page_path']).to eq('/docs/category/alpha/page2/')
        expect(second_alpha_paginator['previous_page_path']).to eq('/docs/category/alpha/')
        expect(second_alpha_paginator['next_page_path']).to be_nil

        registry = site.data['collection_pages']['docs']['category']
        expect(registry['template']).to eq('/docs/category/:field/page:num/index.html')
        expect(registry['permalink']).to eq('/docs/category/:field/')
        expect(registry['pages']['alpha']).to eq(documents)
        expect(registry['pages']['beta']).to eq([doc_alpha_beta])

        labels = registry['labels']
        expect(labels['alpha']['pages']).to eq(alpha_pages)
        expect(labels['alpha']['index']).to eq(alpha_pages.first)
        expect(labels['beta']['pages']).to eq(beta_pages)
      end
    end

    context 'without pagination' do
      let(:paginate_value) { nil }
      let(:documents) { [doc_one, doc_two, doc_three] }
      let(:doc_one) { instance_double(Jekyll::Document, data: { 'category' => 'one' }) }
      let(:doc_two) { instance_double(Jekyll::Document, data: { 'category' => %w[one two] }) }
      let(:doc_three) { instance_double(Jekyll::Document, data: { 'category' => 'two' }) }

      it 'creates a single page per tag without attaching a paginator' do
        described_class.new(site, config).create_pages

        expect(site.pages.size).to eq(2)
        one_page = site.pages.find { |page| page.tag == 'one' }
        two_page = site.pages.find { |page| page.tag == 'two' }

        expect(one_page.page_num).to eq(1)
        expect(two_page.page_num).to eq(1)
        expect(one_page.attributes[:paginator]).to be_nil
        expect(two_page.attributes[:paginator]).to be_nil

        registry = site.data['collection_pages']['docs']['category']
        expect(registry['pages']['one']).to eq([doc_one, doc_two])
        expect(registry['pages']['two']).to eq([doc_two, doc_three])
      end
    end
  end
end
