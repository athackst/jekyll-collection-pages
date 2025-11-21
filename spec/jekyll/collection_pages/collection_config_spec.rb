# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jekyll::CollectionPages::CollectionConfig do
  it 'sets defaults and normalizes paginate to an integer' do
    config = described_class.new({
                                   'collection' => 'docs',
                                   'field' => 'category',
                                   'path' => 'docs/category',
                                   'paginate' => '5'
                                 })

    expect(config.collection_name).to eq('docs')
    expect(config.tag_field).to eq('category')
    expect(config.tag_base_path).to eq('docs/category')
    expect(config.tag_layout).to eq('collection_layout')
    expect(config.per_page).to eq(5)
  end

  it 'returns nil and logs a warning for non-positive paginate values' do
    allow(Jekyll.logger).to receive(:warn)

    config = described_class.new({
                                   'collection' => 'docs',
                                   'field' => 'category',
                                   'path' => 'docs/category',
                                   'paginate' => 0
                                 })

    expect(config.per_page).to be_nil
    expect(Jekyll.logger).to have_received(:warn).with('CollectionPages:', /Non-positive paginate value/)
  end

  it 'raises an error for non-numeric paginate values' do
    expect do
      described_class.new({
                            'collection' => 'docs',
                            'field' => 'category',
                            'path' => 'docs/category',
                            'paginate' => 'ten'
                          })
    end.to raise_error(ArgumentError, /Invalid paginate value/)
  end

  it 'raises when required keys are missing' do
    expect do
      described_class.new({ 'field' => 'category', 'path' => 'docs/category' })
    end.to raise_error(ArgumentError, /collection/)

    expect do
      described_class.new({ 'collection' => 'docs', 'path' => 'docs/category' })
    end.to raise_error(ArgumentError, /field/)
  end

  it 'defaults path to the collection name when omitted' do
    config = described_class.new({
                                   'collection' => 'docs',
                                   'field' => 'category',
                                   'layout' => 'collection_layout.html'
                                 })

    expect(config.tag_base_path).to eq('docs')
  end

  it 'strips the _layouts prefix but retains subdirectories' do
    config = described_class.new({
                                   'collection' => 'docs',
                                   'field' => 'category',
                                   'layout' => '_layouts/articles/tags.html'
                                 })
    expect(config.tag_layout).to eq('articles/tags')
  end
end
