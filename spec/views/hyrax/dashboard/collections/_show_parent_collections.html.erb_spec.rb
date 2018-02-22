RSpec.describe 'hyrax/dashboard/collections/_show_parent_collections.html.erb', type: :view do
  let(:collection_doc) do
    {
      id: '999',
      "has_model_ssim" => ["Collection"],
      "title_tesim" => ["Title 1"],
      'date_created_tesim' => '2000-01-01'
    }
  end
  let(:subject) { render('show_parent_collections.html.erb', presenter: presenter) }
  let(:ability) { double }
  let(:solr_document) { SolrDocument.new(collection_doc) }
  let(:presenter) { Hyrax::CollectionPresenter.new(solr_document, ability) }
  let(:collection1) { build(:collection, id: 'col1', title: ['col1']) }
  let(:collection2) { build(:collection, id: 'col2', title: ['col2']) }
  let(:collection3) { build(:collection, id: 'col3', title: ['col3']) }
  let(:collection4) { build(:collection, id: 'col4', title: ['col4']) }
  let(:collection5) { build(:collection, id: 'col5', title: ['col5']) }
  let(:parent_collections) { double(Object, documents: parent_docs, response: { "numFound" => parent_docs.size }, total_pages: 1) }

  before do
    assign(:presenter, presenter)
    presenter.parent_collections = parent_collections

    allow(collection1).to receive(:persisted?).and_return true
    allow(collection2).to receive(:persisted?).and_return true
    allow(collection3).to receive(:persisted?).and_return true
    allow(collection4).to receive(:persisted?).and_return true
    allow(collection5).to receive(:persisted?).and_return true
  end

  context 'when parent collections are nil' do
    let(:parent_collections) { nil }

    it "posts a warning message" do
      subject
      expect(rendered).to have_text("There are no visible parent collections.")
    end

    it 'does not render pagination' do
      expect(subject).not_to render_template("hyrax/collections/_paginate")
    end
  end

  context 'when parent collection list is empty' do
    let(:parent_docs) { [] }

    it "posts a warning message" do
      subject
      expect(rendered).to have_text("There are no visible parent collections.")
    end

    it 'does not render pagination' do
      expect(subject).not_to render_template("hyrax/collections/_paginate")
    end
  end

  context 'when parent collection list is not empty, but small' do
    let(:parent_docs) { [collection1, collection2, collection3] }

    it "posts the collection's title with a link to the collection" do
      subject
      expect(rendered).to have_link(collection1.title.first, visible: true)
      expect(rendered).to have_link(collection2.title.first, visible: true)
      expect(rendered).to have_link(collection3.title.first, visible: true)
      expect(rendered).not_to have_button('show more...')
    end

    xit 'includes a count of the parent collections' do
      # TODO: add test when actual count is added to page
    end

    it 'does not render pagination' do
      expect(subject).not_to render_template("hyrax/collections/_paginate")
    end
  end

  context 'when parent collection list exceeds parents_to_show' do
    let(:parent_docs) { [collection1, collection2, collection3, collection4, collection5] }

    it "posts the collection's title with a link to the collection" do
      subject
      expect(rendered).to have_link(collection1.title.first, visible: true)
      expect(rendered).to have_link(collection2.title.first, visible: true)
      expect(rendered).to have_link(collection3.title.first, visible: true)
      expect(rendered).to have_link(collection4.title.first, visible: false)
      expect(rendered).to have_link(collection5.title.first, visible: false)
      expect(rendered).to have_button('show more...', visible: true)
      expect(rendered).to have_button('...show less', visible: false)
    end

    it 'renders pagination' do
      expect(subject).not_to render_template("hyrax/collections/_paginate")
    end
  end

  context 'when parent collection list has multiple pages' do
    let(:parent_docs) { [collection1, collection2, collection3, collection4, collection5] }
    let(:parent_collections) { double(Object, documents: parent_docs, response: { "numFound" => parent_docs.size }, total_pages: 2) }

    before do
      stub_template "hyrax/collections/_paginate" => "paginate"
    end

    it "renders a link to all collections" do
      subject
      expect(rendered).to have_link(collection1.title.first, visible: true)
      expect(rendered).to have_link(collection2.title.first, visible: true)
      expect(rendered).to have_link(collection3.title.first, visible: true)
      expect(rendered).to have_link(collection4.title.first, visible: false)
      expect(rendered).to have_link(collection5.title.first, visible: false)
    end

    it "does not render the more/less buttons" do
      subject
      expect(rendered).not_to have_button('show more...', visible: true)
      expect(rendered).not_to have_button('...show less', visible: false)
    end

    it 'renders pagination' do
      expect(subject).to render_template("hyrax/collections/_paginate")
    end
  end
end